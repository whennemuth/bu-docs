########################################################################
#
# This script sets up the environment with respect to this docker host
# system to correspond with the needs of the docker container(s) that 
# are to be hosted for the kuali-research application.
#
# Prerequisites:
#    1) Docker installed
#    2) Git installed
# 
########################################################################

sudo su root

# 1) Install awslogs
yum update -y && \
yum install -y awslogs

# 2) Create directories for container logs. These will be mounted to by the docker container(s).
mkdir -p /var/log/tomcat
mkdir -p /var/log/httpd
mkdir -p /var/log/shibboleth
mkdir -p /var/log/shibboleth-www
mkdir -p /var/log/kuali/printing
mkdir -p /var/log/kuali/javamelody
mkdir -p /var/log/kuali/attachments

# 3) Pull certs, keys, etc. from s3 to /opt, retaining the same directory hierarchy. 
#    These also serve as mount points for docker containers.
aws s3 cp s3://kuali-research-ec2-setup/${LANDSCAPE} /opt/ --recursive

# 4) Move the certs and private keys from their temp locations to their permanent locations
if [ ! -d /etc/pki/tls/private ] ; then mkdir -p /etc/pki/tls/private; fi
mv /opt/kuali/tls/private/*.key -t /etc/pki/tls/private/
rm -f "/etc/pki/tls/private/*-${LANDSCAPE}*"
if [ ! -d /etc/pki/tls/certs ] ; then mkdir -p /etc/pki/tls/certs; fi
mv /opt/kuali/tls/certs/* -t /etc/pki/tls/certs/ 
rm -f "/etc/pki/tls/certs/*-${LANDSCAPE}*"
rm -r -f /opt/kuali/tls

# 5) Move awslogs configuration from its temp location to the permanent location and start the logging service
if [ -f /etc/awslogs/awslogs.conf ] ; then
   rm -f /etc/awslogs/awslogs.conf
fi
aws s3 cp s3://kuali-research-ec2-setup/${LANDSCAPE}/awslogs.conf /etc/awslogs/awslogs.conf && \
chkconfig --level 2345 awslogs on && \
service awslogs start

# 6) Pull access keys to make secure REST or Query protocol requests to the ECR AWS service API
if [ ! -d /root/.aws ] ; then mkdir -p /root/.aws; fi
aws s3 cp s3://kuali-research-ec2-setup/${LANDSCAPE}/ecr.credentials.cfg /root/.aws/config
chown -R root:root /root/.aws
chmod 600 -R /root/.aws

# 7) Get the private key from s3 to access the github repository
aws s3 cp s3://kuali-research-ec2-setup/bu_github_id_docker_rsa /root/.ssh/
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
chmod -R 600 /root/.ssh/bu_github_id_docker_rsa

# 8) Clone the github repository for docker build context directories into /opt
eval `ssh-agent -s`
ssh-add /root/.ssh/bu_github_id_docker_rsa
cd /opt
git clone git@github.com:bu-ist/kuali-research-docker.git
eval `ssh-agent -k`

# 9) Make sure docker is running

     if [ -z "$(service docker status | grep -o 'running')" ] ; then 
        service docker start; 
     fi

# 10) Get the necessary items from the docker registry and run them.

#    a) Login into the docker registry
        eval $(aws ecr get-login --profile ecr.access)

#    b) Query each relevant repository in the registry to determine the tag for the "latest" image in each.

        APACHE_TAGS=$(aws ecr list-images \
           --profile ecr.access \
           --repository-name apache-shibboleth \
           --filter tagStatus=TAGGED \
           --output text \
           --query imageIds[*].imageTag)
   
        KUALI_TAGS=$(aws ecr list-images \
           --profile ecr.access \
           --repository-name coeus \
           --filter tagStatus=TAGGED \
           --output text \
           --query imageIds[*].imageTag)

        APACHE_SHIB_TAG=$(echo $APACHE_TAGS | grep 'latest')
        if [ -z "${APACHE_TAG}" ] ; then
           APACHE_SHIB_TAG=$(echo $APACHE_IMAGES | sed -r "s/[[:blank:]]/\n/g" | sort -r | head -n 1);
        fi  

        KUALI_RESEARCH_TAG=$(echo $KUALI_TAGS | grep 'latest')
        if [ -z "${KUALI_TAG}" ] ; then
           KUALI_RESEARCH_TAG=$(echo $KUALI_IMAGES | sed -r "s/[[:blank:]]/\n/g" | sort -r | head -n 1);
        fi

#    c) Run an apache-shibboleth container, referencing the image tag, 
#       which will cause it first to be pulled into the local docker repository.

        source /opt/kuali-research-docker/apache-shib/build.context/dockerrun.sh

#    d) Run a kuali-research container

        source /opt/kuali-research-docker/kuali-research/build.context/dockerrun.sh