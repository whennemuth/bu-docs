docker stop kuali-research-container
docker rm kuali-research-container
docker rmi bu-ist/kuali-research:v1.0
docker build \
   -f kuali_research_docker_file \
   -t bu-ist/kuali-research:v1.0 \
   https://github.com/whennemuth/hello-world.git#master:docker/build.context/kuali-research
docker run \
   -d \
   -u root \
   -p 8080:8080 \
   -p 80:80 \
   -p 3306:3306 \
   --name kuali-research-container \
   -v /var/jenkins/kc/war:/usr/local/tomcat/webapp_mount \
   -v /var/jenkins/kc/logs:/usr/local/tomcat/logs \
   -e JAVA_OPTS='-Xmx3072m -Xms512m -XX:MaxPermSize=256m' \
   bu-ist/kuali-research:v1.0
tail -f /var/jenkins/kc/logs/localhost.2016-04-29.log
