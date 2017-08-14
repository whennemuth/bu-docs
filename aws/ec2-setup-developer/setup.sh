#!/bin/bash
#
# Use this script to bring a blank Amazon Linux AMI to state it can run kuali-research
# with a single command to startup the tomcat instance that it will run on.
# This tomcat instance is started in such a way as to accept remote debugging sessions
# from anyone who is tunnelled in through port 8080

BASE=/opt/kuali
KC=$BASE/kc

run() {

  installJava

  installMaven

  installTools

  installTomcat8

  getKuali

  getSchemaSpy

  getRice

  getApi

  getS2sgen

  configureKuali

  buildKuali

  runKuali
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
  [ -z "$KC" ] && KC=/opt/kuali/kc
  if [ -f $KC/pom.xml ] ; then
    echo "Kuali codebase already exists at $KC"
    echo "Cancelling git clone."
    return 0
  fi

  local GIT_BU_HOST="$(propertyFileLookup GIT_BU_HOST)"
  local GIT_BU_ORG="$(propertyFileLookup GIT_BU_ORG)"
  local GIT_BU_REPO="$(propertyFileLookup GIT_BU_REPO)"
  local GIT_BU_REFSPEC="$(propertyFileLookup GIT_BU_REFSPEC)"
  local GIT_BU_KEY="$(propertyFileLookup GIT_BU_KEY)"
  local GIT_BU_URL=""

  if [ -n "$GIT_BU_KEY" ] ; then
    echo "Git private ssh key found. Using ssh to clone repo"
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts;
    chmod 600 $GIT_BU_KEY;
    eval `ssh-agent -s`
    ssh-add $GIT_BU_KEY    
    GIT_BU_URL="git@$GIT_BU_HOST:${GIT_BU_ORG}/${GIT_BU_REPO}.git"
  else
    # Get the user and password. NOTE Assume the git password is an arg passed to this function, 
    # else go to the properties file for it.
    GIT_BU_USER="$(propertyFileLookup GIT_BU_USER)"
    GIT_BU_PASSWORD="$1"
    [ -z "$GIT_BU_PASSWORD" ] && GIT_BU_PASSWORD="$(propertyFileLookup GIT_BU_PASSWORD)"

    # Compose the full git url
    if [ -n "$GIT_BU_USER" ] && [ -n "$GIT_BU_PASSWORD" ] ; then 
      echo "No git private ssh key found. Trying http protocol with username and password"
      GIT_BU_URL="https://${GIT_BU_USER}@${GIT_BU_HOST}/${GIT_BU_ORG}/${GIT_BU_REPO}.git"
    else
      GIT_BU_PASSWORD=""
      echo "No git authentication available. Assuming public access ..."
      GIT_BU_URL="https://${GIT_BU_HOST}/${GIT_BU_ORG}/${GIT_BU_REPO}.git"
    fi
  fi

  if [ -z "$GIT_BU_PASSWORD" ] ; then
    local CMD="git clone --no-checkout $GIT_BU_URL $KC"
    echo $CMD
  else
    local CMD="echo \"$GIT_BU_PASSWORD\" | git clone --no-checkout $GIT_BU_URL $KC <&0"
    echo "echo \"*******\" | git clone --no-checkout $GIT_BU_URL $KC <&0"
  fi
  
  # Clone from git
  eval $CMD
 
  # Checkout kuali coeus code
  CMD="cd $KC && git checkout $GIT_BU_REFSPEC"
  echo $CMD && eval $CMD
}

# The kuali-research pom file is analyzed here for maven version numbers of each module that needs to be built.
# The results are output to session variables.
setMavenVersions() {
  # Get the content of the pom file with all return/newline characters removed.
  local POM="$1"
  if [ ! -f $POM ] ; then
    echo "Cannot find $POM"
    return 0
  fi

  local content=$(cat ${POM} | sed ':a;N;$!ba;s/\n//g')

  # Get versions of dependencies, use a zero width lookbehind for the open element and capture
  # all following characters thereafter until a closing element character is encountered

  SCHEMASPY_VERSION=$(echo "$content" | grep -Po '(?<=<schemaspy\.version>)([^<]+)')
  RICE_VERSION=$(echo "$content" | grep -Po '(?<=<rice\.version>)([^<]+)')
  API_VERSION=$(echo "$content" | grep -Po '(?<=<coeus\-api\-all\.version>)([^<]+)')
  S2SGEN_VERSION=$(echo "$content" | grep -Po '(?<=<coeus\-s2sgen\.version>)([^<]+)')

  echo "SCHEMASPY_VERSION = $SCHEMASPY_VERSION"
  echo "RICE_VERSION = $RICE_VERSION"
  echo "API_VERSION = $API_VERSION"
  echo "S2SGEN_VERSION = $S2SGEN_VERSION"
}

getSchemaSpy() {
  local version="$1"
  if [ -z "$version" ] ; then
    version="$(getMavenVersion $KC/pom.xml schemaspy)"
  fi
  if [ -z "$version" ] ; then
    echo "Could not resolve schemaspy maven version"
    return 1
  fi

  local GIT_KUALICO_HOST="$(propertyFileLookup GIT_KUALICO_HOST)"
  local GIT_KUALICO_ORG="$(propertyFileLookup GIT_KUALICO_ORG)"
  local GIT_KUALICO_USER="$(propertyFileLookup GIT_KUALICO_USER)"
  local GIT_KUALICO_PASSWORD="$(propertyFileLookup GIT_KUALICO_PASSWORD)"
  local GIT_KUALICO_SCHEMASPY_REPO="$(propertyFileLookup GIT_KUALICO_SCHEMASPY_REPO)"
  GIT_URL="https://${GIT_KUALICO_USER}@${GIT_KUALICO_HOST}/${GIT_KUALICO_ORG}/${GIT_KUALICO_SCHEMASPY_REPO}.git"

  local CMD="echo \"$GIT_KUALICO_PASSWORD\" | git clone --no-checkout $GIT_URL $BASE/$GIT_KUALICO_SCHEMASPY_REPO <&0"
  echo "echo \"*******\" | git clone --no-checkout $GIT_BU_URL $BASE/$GIT_KUALICO_SCHEMASPY_REPO <&0"
  
  # Clone from git
  eval $CMD
 
  # Checkout kuali coeus code by tag
  CMD="cd $KC && git checkout $schemaspy-version"
  echo $CMD && eval $CMD
}

getRice() {
  [ -z "$RICE_VERSION" ] && setMavenVersions /opt/kuali/kc/pom.xml
}

getApi() {
  [ -z "$API_VERSION" ] && setMavenVersions /opt/kuali/kc/pom.xml
}

getS2sgen() {
  [ -z "$S2SGEN_VERSION" ] && setMavenVersions /opt/kuali/kc/pom.xml
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
  echo "NOT DONE"
}

runKuali() {
  echo "NOT DONE"
}

propertyFileLookup() {
  [ -z "$1" ] && return 1
  [ ! -f $(pwd)/setup.properties ] && return 1
  echo "$(cat setup.properties | grep -Po '(?<='$1')\s*=.*' | sed  's/=//' | trim)"
}

trim() {
  read input
  [ -z "$input" ] && input="$1"
  echo $input | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'
}

