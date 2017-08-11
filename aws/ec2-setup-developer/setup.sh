#!/bin/bash
#
# Use this script to bring a blank Amazon Linux AMI to state it can run kuali-research
# with a single command to startup the tomcat instance that it will run on.
# This tomcat instance is started in such a way as to accept remote debugging sessions
# from anyone who is tunnelled in through port 8080


install() {
  installEnvironment
  installKuali
}

run() {
  runKuali
}

installEnvironment() {
  installJava
  installMaven
  installTools
  installTomcat8
}

installKuali() {
  getKuali
  configureKuali
  buildKuali
}

runKuali() {
  
}

installJava() {
  yum install -y java-1.8.0-openjdk-devel
  # Existing java was 1.7, so new install should be 2nd, thus...
  echo "2" | update-alternatives --config java <&0
  # Make path and java home get set at startup
  cat <<-EOF > /etc/profile.d/set-java-home.sh
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0/
    if [ -z "$(echo $PATH | grep /usr/lib/jvm/java-1.8.0/)" ] ; then
      export PATH=$PATH:/usr/lib/jvm/java-1.8.0/bin
    fi
EOF
  source /etc/profile.d/set-java-home.sh
  # The version should now read as "1.8.0_141"
  java -version
}

installMaven() {
  local mvndir='/usr/share/maven'
  if [ -d $mvndir ] ; then
    echo "Maven installation found at $mvndir Deleting"
    rm -rf $mvndir
  fi
  mkdir -p 
  curl -fsSL http://apache.osuosl.org/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz | tar -xzC $mvndir --strip-components=1
  # The following symlink should make mvn available as a command because /usr/bin is already part of the PATH env variable.
  ln -s $mvndir/bin/mvn /usr/bin/mvn
  mvn --version
}

installTools() {
  yum -y update && \
  yum install -y git nginx aws-cli && \
  yum install -y nodejs npm --enablerepo=epel
}

installTomcat8() {
  if [ -d /usr/share/apache-tomcat-8.5.20 ] ; then
    rm -rf /usr/share/apache-tomcat-8.5.20
  fi
  curl -fsSL http://ftp.itu.edu.tr/Mirror/Apache/tomcat/tomcat-8/v8.5.20/bin/apache-tomcat-8.5.20.tar.gz | tar -xzC /usr/share
}

getKuali() {
  # Make the necessary directory structure
  [ ! -d /opt/kuali ] && mkdir -p /opt/kuali

  GIT_HOST="$(propertyFileLookup GIT_HOST)"
  GIT_REFSPEC="$(propertyFileLookup GIT_REFSPEC)"
  GIT_KEY="$(propertyFileLookup GIT_KEY)"

  local GIT_URL=""
  GIT_KEY="$(propertyFileLookup GIT_KEY)"
  if [ -n "$GIT_KEY" ] ; then
    echo "Git private ssh key found. Using ssh to clone repo"
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts;
    chmod 600 $GIT_KEY;
    eval `ssh-agent -s`
    ssh-add $GIT_KEY    
    GIT_URL="git@$GIT_HOST:${GIT_REPO}.git"
  else
    GIT_USER="$(propertyFileLookup GIT_USER)"
    GIT_PASSWORD="$(propertyFileLookup GIT_PASSWORD)"
    if [ -n "$GIT_USER" ] && [ -n "$GIT_PASSWORD" ] ; then 
      echo "No git private ssh key found. Trying http protocol with username and password"
      GIT_URL="https://${GIT_USER}@${GIT_HOST}/${GIT_REPO}.git"
    else
      GIT_PASSWORD=""
      echo "No git authentication available. Assuming public access ..."
      GIT_URL="https://${GIT_HOST}/${GIT_REPO}.git"
    fi
  fi

  if [ -z "$GIT_PASSWORD" ] ; then
    git clone --no-checkout GIT_URL
  else
    echo "$GIT_PASSWORD" | git clone --no-checkout GIT_URL <&0
  fi
  
  git checkout $GIT_REFSPEC
}

configureKuali() {
  local base=/usr/share/apache-tomcat-8.5.20
  local lib=$base/lib
  local conf=$base/conf/Catalina/localhost

  # Add to the tomcat lib directory the extra jars needed.
  cp spring-instrument-tomcat-3.2.13.RELEASE.jar $lib
  cp ojdbc7.jar $lib
  cp org.eclipse.persistence.oracle-2.4.2.jar $lib

  # Put the context xml for kuali where tomcat will look for it.
  [ ! -d $tomcat/conf/Catalina/localhost ] && mkdir -p $conf
  cp kc.xml $conf

  # Put the missing values into kc-config.xml
  DB_HOST="$(propertyFileLookup DB_HOST)"
  DB_SERVICE_NAME="$(propertyFileLookup DB_SERVICE_NAME)"
  DB_SCHEMA="$(propertyFileLookup DB_SCHEMA)"
  sed -i "s/DB_HOST/$DB_HOST/g" kc-config.xml
  sed -i "s/DB_SERVICE_NAME/$DB_SERVICE_NAME/g" kc-config.xml
  sed -i "s/DB_SCHEMA/$DB_SCHEMA/g" kc-config.xml  
}

buildKuali() {

}

