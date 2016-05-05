docker stop jenkinsdindcontainer
docker rm jenkinsdindcontainer
# docker rmi bu-ist/kuali/jenkins-dind:v1.0
docker build \
   -f maven_jenkins_dind_docker_file \
   -t bu-ist/kuali/jenkins-dind:v1.0 \
   https://github.com/whennemuth/hello-world.git#master:docker/build.context/jenkins-dind
docker run \
   -ti \
   -u jenkins \
   --privileged \
   -p 8080:8080 \
   --name jenkinsdindcontainer \
   -v /home/jenkins/home:/var/lib/jenkins_home \
   -v /home/jenkins/log:/var/log/jenkins \
   -v /home/jenkins/.ssh:/var/lib/jenkins_ssh_mount \
   bu-ist/kuali/jenkins-dind:v1.0