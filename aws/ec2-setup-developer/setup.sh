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

  buildSchemaSpy

  buildRice

  build Api

  buildS2sgen

  buildKuali

  configureKuali

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
  HERE="$(pwd)"
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
    local GIT_BU_USER="$(propertyFileLookup GIT_BU_USER)"
    local GIT_BU_PASSWORD="$1"
    if [ -z "$GIT_BU_PASSWORD" ] ; then
      GIT_BU_PASSWORD="$(propertyFileLookup GIT_BU_PASSWORD)"
    fi
    GIT_BU_PASSWORD="$(echo -ne $GIT_BU_PASSWORD | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"

    # Compose the full git url
    if [ -n "$GIT_BU_USER" ] && [ -n "$GIT_BU_PASSWORD" ] ; then 
      echo "No git private ssh key found. Trying http protocol with username and password"
      GIT_BU_URL="https://${GIT_BU_USER}:${$GIT_BU_PASSWORD}@${GIT_BU_HOST}/${GIT_BU_ORG}/${GIT_BU_REPO}.git"
    else
      GIT_BU_PASSWORD=""
      echo "No git authentication available. Assuming public access ..."
      GIT_BU_URL="https://${GIT_BU_HOST}/${GIT_BU_ORG}/${GIT_BU_REPO}.git"
    fi
  fi

  if [ -z "$GIT_BU_PASSWORD" ] ; then
    local CMD="git clone --no-checkout $GIT_BU_URL $KC"
  else
    local CMD="git clone --no-checkout $GIT_BU_URL $KC"
  fi
  
  # Clone from git
  echo $CMD && eval $CMD
 
  # Checkout kuali coeus code
  CMD="cd $KC && git checkout $GIT_BU_REFSPEC"
  echo $CMD && eval $CMD
  cd $HERE
}

# The kuali-research pom file is analyzed here for maven version numbers of each module that needs to be built.
# The results are output to session variables.
getMavenVersion() {
  # Get the content of the pom file with all return/newline characters removed.
  local POM="$1"
  if [ ! -f $POM ] ; then
    return 0
  fi
  local REPO="$2"
  if [ -z "$REPO" ] ; then
    return 0
  fi

  local content=$(cat ${POM} | sed ':a;N;$!ba;s/\n//g')

  # Get versions of dependencies, use a zero width lookbehind for the open element and capture
  # all following characters thereafter until a closing element character is encountered
  if [ -n "$(echo $REPO | grep -i 'schemaspy')" ] ; then
    local REGEX='(?<=<schemaspy\.version>)([^<]+)'
  elif [ -n "$(echo $REPO | grep -i 'rice')" ] ; then
    local REGEX='(?<=<rice\.version>)([^<]+)'
  elif [ -n "$(echo $REPO | grep -i 'api')" ] ; then
    local REGEX='(?<=<coeus\-api\-all\.version>)([^<]+)'
  elif [ -n "$(echo $REPO | grep -i 's2sgen')" ] ; then
    local REGEX='(?<=<coeus\-s2sgen\.version>)([^<]+)'
  fi
  
  echo $(echo "$content" | grep -Po $REGEX)
}

getSchemaSpy() {
  getFromKualiCo GIT_KUALICO_SCHEMASPY_REPO schemaspy
}

# NOTE: Jenkins builds rice on top of a BU customization. Here we are fetching from git without this.
getRice() {
  getFromKualiCo GIT_KUALICO_RICE_REPO rice
}

getApi() {
  getFromKualiCo GIT_KUALICO_API_REPO coeus-api
}

getS2sgen() {
  getFromKualiCo GIT_KUALICO_S2SGEN_REPO coeus-s2sgen
}

getFromKualiCo() {
  local HERE="$(pwd)"
  local VERSION=""
  local PROPERTY="$1"
  local MAVEN_TAG="$2"
  if [ "$#" -eq 0 ]; then
    echo "ERROR! Expected 1 or 2 parameters!"
    return 1
  elif [ "$#" -eq 1 ]; then
    VERSION="$1"
  elif [ "$#" -eq 2 ]; then
    VERSION="$(getMavenVersion $KC/pom.xml $MAVEN_TAG)"
  fi
  
  if [ -z "$VERSION" ] ; then
    echo "Could not resolve schemaspy maven version"
    return 1
  fi

  local HOST="$(propertyFileLookup GIT_KUALICO_HOST)"
  local ORG="$(propertyFileLookup GIT_KUALICO_ORG)"
  local USER="$(propertyFileLookup GIT_KUALICO_USER)"
  # urlencode every byte of the password
  local PASSWORD="$(propertyFileLookup GIT_KUALICO_PASSWORD)"
  PASSWORD="$(echo -ne $PASSWORD | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"
  local REPO="$(propertyFileLookup $PROPERTY)"
  local URL="https://${USER}:${PASSWORD}@${HOST}/${ORG}/${REPO}.git"
  local TARGET="$BASE/$REPO"

  # Clone or fetch from git
  if [ -d $TARGET ] ; then
    echo "$TARGET already cloned, fetching instead..."
    local CMD="cd $TARGET && git fetch --tags $URL"
  else
    local CMD="git clone --no-checkout $URL $TARGET"
  fi  
  echo $CMD && eval $CMD

  # Checkout kuali coeus code by tag
  echo "$MAVEN_TAG-$VERSION" 
  if [ -d $TARGET ] ; then
    CMD="cd $TARGET && git checkout $MAVEN_TAG-$VERSION"
    echo $CMD && eval $CMD
  else
    echo "ERROR! Failed to clone to $TARGET"
  fi
  cd $HERE
}

buildSchemaSpy() {
  buildModule GIT_KUALICO_SCHEMASPY_REPO
}

buildRice() {
  buildModule GIT_KUALICO_RICE_REPO
}

buildApi() {
  buildModule GIT_KUALICO_API_REPO
}

buildS2sgen() {
  buildModule GIT_KUALICO_S2SGEN_REPO
}

buildKuali() {
  buildModule "kc"
}

buildModule() {
  local BUILD_CONTEXT="$(pwd)"
  if [ $1 == "kc" ] ; then
    cd $BASE/kc
    
    checkAwardNotice "$BUILD_CONTEXT/bu-awardnotice-1.1.jar"

    mvn clean compile package -e -Dgrm.off=true -Dmaven.test.skip=true
  else
    local REPO="$(propertyFileLookup $1)"
    cd $BASE/$REPO    
    if [ -n "$(echo $1 | grep -i rice)" ] ; then
      # If the local maven repo does not have the artifacts required to run tests, then you
      # cannot skip tests in the build. That is, "-Dmaven.test.skip=true" has to be ommitted.
      # You may, however, be able to skip tests on subsequent builds.
      mvn clean compile install -e -Dgrm.off=true
    else
      mvn clean compile install -e -Dgrm.off=true -Dmaven.test.skip=true
    fi
  fi
  cd $BUILD_CONTEXT
}

# This is a custom BU jar that has been pre-built. 
# Making sure it is installed in the local maven repository.
checkAwardNotice() {
  local SOURCE_JAR="$1"
  if [ ! -f $SOURCE_JAR ] ; then
    "WARNING! $SOURCE_JAR does not exist! - coeus-impl portion of maven build may fail!"
    return 0
  fi
  local GROUP="edu.bu"
  local ARTIFACTID="bu-awardnotice"
  local VERSION="1.1"
  local ARTIFACT="$GROUP:$ARTIFACTID:$VERSION"
  local LOCALREPO="file://~/.m2/repository"

  local AWARDNOTICE=mvn dependency:get -Dartifact=$ARTIFACT -o -DrepoUrl=$LOCALREPO | grep 'BUILD SUCCESS'

  if [ -z "$AWARDNOTICE" ] ; then
    mvn install:install-file \
      -Dfile=$SOURCE_JAR \
      -DgroupId=$GROUP \
      -DartifactId=$ARTIFACTID \
      -Dversion=$VERSION \
      -Dpackaging=jar
  fi
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

