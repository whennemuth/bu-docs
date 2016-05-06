docker stop jenkinscontainer
docker rm jenkinscontainer
docker rmi bu-ist/kuali/jenkins:v1.0
docker build \
   -f maven_jenkins_docker_file \
   -t bu-ist/kuali/jenkins:v1.0 \
   https://github.com/whennemuth/hello-world.git#master:docker/build.context/jenkins
docker run \
   -d \
   -u jenkins \
   -p 80:8080 \
   -p 50000:50000 \
   --name jenkinscontainer \
   --restart unless-stopped \
   -v /home/jenkins/home:/var/jenkins_home \
   -v /home/jenkins/log:/var/log/jenkins \
   -v /home/jenkins/.ssh:/var/jenkins_ssh_mount \
   -v /home/jenkins/.m2/repository:/var/jenkins_m2repo \
   bu-ist/kuali/jenkins:v1.0