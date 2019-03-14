#!/bin/bash
#
# Use this script to bring a blank Amazon Linux AMI to state it can run kuali-research
# with a single command to startup the tomcat instance that it will run on.
# This tomcat instance is started in such a way as to accept remote debugging sessions
# from anyone who is tunnelled in through port 8080
#
# NOTE: Run this script as root.

BASE=/opt/kuali
if [ ! -d $BASE ] ; then
  sudo mkdir -p $BASE
  sudo chown -R ec2-user $BASE
fi
KC=$BASE/kc
TOMCAT_VERSION=8.5.38
TOMCAT_HOME=/usr/share/apache-tomcat-$TOMCAT_VERSION

install() {

  installJava

  installMaven

  installTools

  installTomcat8
}

build() {

  getKuali

  getSchemaSpy

  getRice

  getApi

  getS2sgen

  buildSchemaSpy

  buildRice

  buildApi

  buildS2sgen

  buildKuali

  copyJarsToLibDir

  configureContextXml

  configureLog4j

  configureKcConfig
}

revert() {

  cd $KC
  read -p "Type the name of the branch you want to revert to: " branch
  git log --oneline $branch -1
  [ $? -gt 0 ] && echo "No such branch: $branch" && echo "Cancelling..." && cd - && return 1
  echo "Checking out branch: $branch"
  git checkout $branch
  cd -

  buildKuali

  copyJarsToLibDir

  configureContextXml

  configureLog4j

  configureKcConfig

  [ "${1,,i}" == "run" ] && run
}

run() {
  
  runKuali
}


installJava() {
  if isAmazonLinux ; then
    installCorretto
  elif yummable ; then
    installOpenJDK
  else
    installOracleJDK
  fi
}


installCorretto() {
  curl --location https://d2jnoze5tfhthg.cloudfront.net/java-11-amazon-corretto-devel-11.0.2.9-2.x86_64.rpm > /tmp/java-11-corretto.rpm
  yum install -y /tmp/java-11-corretto.rpm
  idx=$(echo "$(echo "" | alternatives --config java)" | grep -i 'corretto' | grep -i 'java-11' | grep -oP '\s\d\s' | xargs)
  echo $idx | alternatives --config java <&0
  setNewJavaHome
}


installOpenJDK() {
  cd /usr/local
  curl --location https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz | tar -xvzf -
  idx=$(echo "$(echo "" | alternatives --config java)" | grep -iP '((java)|(jdk))\-?11' | grep -oP '\s\d\s' | xargs)
  echo $idx | alternatives --config java <&0
  setNewJavaHome
}


installOracleJDK() {
  wget \
    -O /tmp/jdk-8u141-linux-x64.tar.gz \
    --no-cookies \
    --no-check-certificate \
    --header \
      "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
      "http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.tar.gz"

  tar -zxf /tmp/jdk-8u141-linux-x64.tar.gz -C /usr/lib/jvm
  # Existing java was 1.7, so new install should be 2nd, thus...
  update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.8.0_141/bin/java" 1
  echo "2" | update-alternatives --config java <&0
  setNewJavaHome
}


# Create a script that executes on startup to configure JAVA_HOME and PATH
# Remove all existing java bin directory paths from PATH, replacing with the specified JAVA_HOME parameter as JAVA_HOME/bin.
# Then export both JAVA_HOME and PATH.
# This effectively removes all prior "knowledge" of java executables and resets against the specified JAVA_HOME
setNewJavaHome() {
  local JHOME=$1
  [ -z "$JHOME" ] && local JHOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
  if [ -z "$JHOME" ] ; then
    echo "ERROR! JAVA_HOME and PATH not set!!!"
    return 1
  fi
  
  cat <<-EOF > /etc/profile.d/set-java-home.sh
  export JAVA_HOME=$JHOME
  export PATH=\$(echo \$PATH | awk '
    BEGIN {
      RS = ":" ; ORS = ""
    }
    {
      # Reprint out all PATH elements EXCEPT for those that indicate a jvm/jdk bin directory
      if (\$1 !~ /^.*((\/jvm\/)|(\/jdk)).*$/) {   
        print \$1":"
      }
    }
    END {
      # Having skipped reprinting all java bin directories, print the desired bin directory at the end of PATH
      print "$JHOME/bin" 
    }'
  )
EOF
  source /etc/profile.d/set-java-home.sh
  java -version
  echo "JAVA_HOME = $JAVA_HOME"
  echo "PATH = $PATH"
}


installMaven() {
  local mvndir='/usr/share/maven'
  if [ -d $mvndir ] ; then
    echo "Maven installation found at $mvndir Deleting"
    rm -rf $mvndir
  fi
  mkdir -p $mvndir
  curl -fsSL http://apache.osuosl.org/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz | tar -xzC $mvndir --strip-components=1
  # The following symlink should make mvn available as a command because /usr/bin is already part of the PATH env variable.
  ln -f -s $mvndir/bin/mvn /usr/bin/mvn
  mvn --version
}

installTools() {
  yum -y update && \
  yum install -y git nginx aws-cli && \
  yum install -y gcc-c++ make

  # Doesn't seem to be necessary to install node and npm as the build bundles its own version and uses that.
  # curl -sL https://rpm.nodesource.com/setup_8.x | sudo -E bash - && \
  # yum install -y nodejs 
}

yummable() {
  yum --help > /dev/null 2>&1
  [ $? -eq 0 ]
}

isAmazonLinux() {
  local rls=$(cat /etc/*-release 2> /dev/null)
  local isAmznLnx="true" # Assume false to start
  [ -z "$(echo $rls | grep -i amazon)" ] && isAmznLnx="false"
  [ -z "$(echo $rls | grep -i linux)" ] && isAmznLnx="false"
  [ $isAmznLnx == "true" ] && true || false
}

installTomcat8() {
  if [ -d ${TOMCAT_HOME} ] ; then
    rm -rf ${TOMCAT_HOME}
  fi
  curl -fsSL http://ftp.itu.edu.tr/Mirror/Apache/tomcat/tomcat-8/v8.5.38/bin/apache-tomcat-8.5.38.tar.gz | tar -xzC /usr/share
  sudo chown -R ec2-user ${TOMCAT_HOME}
  sudo chmod -R 777 ${TOMCAT_HOME}
}

getKuali() {
  [ ! -f setup.properties ] && echo "Cannot find $(pwd)/setup.properties" && exit 1
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
    # url encode the password
    GIT_BU_PASSWORD="$(echo -ne $GIT_BU_PASSWORD | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"

    # Compose the full git url
    if [ -n "$GIT_BU_USER" ] && [ -n "$GIT_BU_PASSWORD" ] ; then 
      echo "No git private ssh key found. Trying http protocol with username and password"
      GIT_BU_URL="https://${GIT_BU_USER}:${GIT_BU_PASSWORD}@${GIT_BU_HOST}/${GIT_BU_ORG}/${GIT_BU_REPO}.git"
    else
      GIT_BU_PASSWORD=""
      echo "No git authentication available. Assuming public access ..."
      GIT_BU_URL="https://${GIT_BU_HOST}/${GIT_BU_ORG}/${GIT_BU_REPO}.git"
    fi
  fi

  local CMD="git clone --no-checkout $GIT_BU_URL $KC"
  
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
  [ ! -f setup.properties ] && echo "Cannot find $(pwd)/setup.properties" && exit 1
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
  runMaven GIT_KUALICO_SCHEMASPY_REPO build
}

buildRice() {
  runMaven GIT_KUALICO_RICE_REPO build
}

buildApi() {
  runMaven GIT_KUALICO_API_REPO build
}

buildS2sgen() {
  runMaven GIT_KUALICO_S2SGEN_REPO build
}

buildKuali() {
  runMaven "kc" build
}

compileKuali() {
  runMaven "kc" compile
}

runMaven() {
  [ ! -f setup.properties ] && echo "Cannot find $(pwd)/setup.properties" && exit 1
  local BUILD_CONTEXT="$(pwd)"
  local TARGET="$2"
  if [ $1 == "kc" ] ; then
    cd $KC
    
    checkAwardNotice "$BUILD_CONTEXT/bu-awardnotice-1.1.jar"
    
    if [ "$TARGET" == "build" ] ; then
      mvn clean compile package -e -Dgrm.off=true -Dmaven.test.skip=true
      
      # Transfer newly packaged jar to coeus-webapp lib directory
      local webtar=$KC/coeus-webapp/target
      local impltar=$KC/coeus-impl/target 
      local implname=$(ls -1 $impltar/ | grep -iP '^coeus-impl.*?(?!\.jar)$' | sed 's/.jar//' | head -n1)
      local webname=$(ls -1 $webtar/ | grep -iP '^coeus-webapp.*?(?!\.war)$' | sed 's/.war//' | head -n1)
      local weblib=$webtar/$webname/WEB-INF/lib
      local impljar=$impltar/${implname}.jar
      if [ ! -d $weblib ] ; then
        echo "ERROR!!! $weblib does not exist. Could not transfer $impljar"
      elif [ ! -f $impljar ] ; then
        echo "ERROR!!! $impjar does not exist. Could not transfer to $weblib"
      else
        echo "Copying $impljar to $weblib"
        cp $impljar $weblib
      fi
    elif [ "$TARGET" == "compile" ] ; then
      mvn compiler:compile -e -Dgrm.off=true
    fi
  else
    local REPO="$(propertyFileLookup $1)"
    cd $BASE/$REPO 
    if [ "$TARGET" == "build" ] ; then
      if [ -n "$(echo $1 | grep -i rice)" ] ; then
        # If the local maven repo does not have the artifacts required to run tests, then you
        # cannot skip tests in the build. That is, "-Dmaven.test.skip=true" has to be ommitted.
        # You may, however, be able to skip tests on subsequent builds.
        mvn clean compile source:jar install -e -Dgrm.off=true
      else
        mvn clean compile source:jar install -e -Dgrm.off=true -Dmaven.test.skip=true
      fi
    elif [ "$TARGET" == "compile" ] ; then
      mvn compiler:compile -e -Dgrm.off=true
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

  local AWARDNOTICE="$(mvn dependency:get -Dartifact=$ARTIFACT -o -DrepoUrl=$LOCALREPO | grep 'BUILD SUCCESS')"

  if [ -z "$AWARDNOTICE" ] ; then
    mvn install:install-file \
      -Dfile=$SOURCE_JAR \
      -DgroupId=$GROUP \
      -DartifactId=$ARTIFACTID \
      -Dversion=$VERSION \
      -Dpackaging=jar
  fi
}

copyJarsToLibDir() {
  local lib=$TOMCAT_HOME/lib
  local conf=$TOMCAT_HOME/conf/Catalina/localhost

  # Add to the tomcat lib directory the extra jars needed.
  #${TOMCAT_HOME} cp spring-instrument-tomcat-3.2.13.RELEASE.jar $lib
  cp ojdbc7.jar $lib
  cp org.eclipse.persistence.oracle-2.7.2.jar $lib
}

configureContextXml() {
  local lib=$TOMCAT_HOME/lib
  local conf=$TOMCAT_HOME/conf/Catalina/localhost

  # Put the context xml for kuali where tomcat will look for it.
  [ ! -d $conf ] && mkdir -p $conf

  local TARGETDIR=$KC/coeus-webapp/target
  if [ ! -d $TARGETDIR ] ; then
    echo "$TARGETDIR does not exist. Cannot configure kc.xml"
    return 1
  fi
  local DOCBASE=$TARGETDIR/$(ls -1 $TARGETDIR/ | grep -iP '^coeus-webapp.*?(?!\.war)$' | sed 's/.war//' | head -n1)
  local DOCLIB=$DOCBASE/WEB-INF/lib
  local IMPL_TARGET=$KC/coeus-impl/target
  local IMPL_CLASSES=$IMPL_TARGET/classes
  local WORKDIR=$TARGETDIR/workdir

  [ ! -d $WORKDIR ] && mkdir -p $WORKDIR

  cat kc.xml \
    | sed "s|DOCBASE|$DOCBASE|" \
    | sed "s|IMPL_CLASSES|$IMPL_CLASSES|" \
    | sed "s|WORKDIR|$WORKDIR|" \
    | sed "s|COEUS_IMPL_JAR|$(ls -1 $DOCLIB | grep -i 'coeus\-impl\-.*\.jar')|g" \
    > $conf/kc.xml
}

# catalina.sh unsets CLASSPATH, then rebuilds in part using instructions in setenv.sh. So, you cannot simply set CLASSPATH before you start tomcat.
# Extract the log4j jars from the war file and put them into the tomcat lib directory so they can appear in the bootstrap classpath.
# Need to also supply jackson libraries as log4j2-tomcat.xml configuration has a <JsonLayout for one of its appenders.
# woodstox-core if for xml-based appenders in case those are used.
configureLog4j() {
  local lib=${TOMCAT_HOME}/log4j2/lib
  local TARGETDIR=$KC/coeus-webapp/target
  local DOCBASE=$TARGETDIR/$(ls -1 $TARGETDIR/ | grep -iP '^coeus-webapp.*?(?!\.war)$' | sed 's/.war//' | head -n1)
  local DOCLIB=$DOCBASE/WEB-INF/lib

  [ ! -d $TOMCAT_HOME/log4j2/lib ] && mkdir -p $TOMCAT_HOME/log4j2/lib
  [ ! -d $TOMCAT_HOME/log4j2/conf ] && mkdir -p $TOMCAT_HOME/log4j2/conf
  \cp -f log4j2-tomcat.xml $TOMCAT_HOME/conf
  \cp -f log4j2-tomcat.xml $TOMCAT_HOME/log4j2/conf
 
  copyMavenDependency "log4j-core" "$DOCLIB" "$lib"
  copyMavenDependency "log4j-api" "$DOCLIB" "$lib"
  copyMavenDependency "log4j-jul" "$DOCLIB" "$lib"
  copyMavenDependency "log4j-appserver" "$DOCLIB" "$lib"
  copyMavenDependency "woodstox-core" "$DOCLIB" "$lib"
  copyMavenDependency "stax" "$DOCLIB" "$lib"
  copyMavenDependency "jackson-core" "$DOCLIB" "$lib"
  copyMavenDependency "jackson-databind" "$DOCLIB" "$lib"
  copyMavenDependency "jackson-annotations" "$DOCLIB" "$lib"
}

# Search a specified directory for a maven dependency artifact and copy it to the specified target directory if found.
# If not found, analyze the pom.xml file for enough artifact info to download the artifact from maven central to the target directory.
copyMavenDependency() {
  local artifactId="$1"
  local sourcedir="$2"
  local targetdir="$3"

  if [ -n "$(ls -1 $sourcedir | grep $artifactId)" ] ; then
    # The artifact was built and can be found in the target directory
    echo "At least 1 $sourcedir/${artifactId}* found. Copying to $targetdir"
    \cp "$sourcedir/${artifactId}"* $targetdir
  else
    # Query the pom for artifact details and download the artifact from maven central repository
    echo "No artifacts found in $sourcedir matching $artifactId. Downloading from maven central"
    local property="maven-dependency-plugin.version"
    local pluginver=$(cat $KC/pom.xml | grep -oP "(?<=<${property}>).*(?=</${property}>)")
    local groupId="$(getMavenDependencyAttribute $artifactId 'groupId')"
    local version="$(getMavenDependencyAttribute $artifactId 'version')"
    property="$(echo "$version" | grep -oP '(?<=\$\{).*?(?=\})')"
    # If the version holds a property, get the property value set the version with it.
    [ -n "$property" ] && version=$(cat $KC/pom.xml | grep -oP "(?<=<${property}>).*(?=</${property}>)")
    
    mvn -f $KC/pom.xml \
      org.apache.maven.plugins:maven-dependency-plugin:${pluginver}:copy \
      -Dartifact=${groupId}:${artifactId}:${version} \
      -DoutputDirectory=$targetdir
  fi
}

getMavenDependencyAttribute() {
  local artifactId="$1"
  local attribute="$2"
  tr -d '\n\t ' < $KC/pom.xml \
    | sed -e 's/<\/dependency>/\n/g' \
    | grep '<artifactId>log4j-appserver</artifactId>' \
    | grep -oP '(?<=<'$attribute'>).*?(?=</'$attribute'>)'
}


# Put the missing values into kc-config.xml
configureKcConfig() {
  [ ! -f setup.properties ] && echo "Cannot find $(pwd)/setup.properties" && exit 1
  DB_HOST="$(propertyFileLookup DB_HOST)"
  DB_SERVICE_NAME="$(propertyFileLookup DB_SERVICE_NAME)"
  DB_SCHEMA="$(propertyFileLookup DB_SCHEMA)"
  DB_PASSWORD="$(propertyFileLookup DB_PASSWORD)"
  AUTH_SYSTEM_TOKEN="$(propertyFileLookup AUTH_SYSTEM_TOKEN)"

  cat kc-config.xml \
    | sed "s/DB_HOST/$DB_HOST/g" \
    | sed "s/DB_SERVICE_NAME/$DB_SERVICE_NAME/g" \
    | sed "s/DB_SCHEMA/$DB_SCHEMA/g" \
    | sed "s/DB_PASSWORD/$DB_PASSWORD/g" \
    | sed "s/AUTH_SYSTEM_TOKEN/$AUTH_SYSTEM_TOKEN/g" \
    > $BASE/kc-config.xml
}

java8orLess() {
  java --version > /dev/null 2>&1
  [ $? -gt 0 ]
}

runKuali() {

  local classpath="$TOMCAT_HOME/bin/tomcat-juli.jar"
  classpath="$classpath:$TOMCAT_HOME/bin/bootstrap.jar"
  classpath="$classpath:$TOMCAT_HOME/lib/*"
  classpath="$classpath:$TOMCAT_HOME/log4j2/lib/*"
  classpath="$classpath:$TOMCAT_HOME/log4j2/conf"
  if java8orLess ; then
    classpath="$classpath:$JAVA_HOME/lib/tools.jar"
    local endorsed="-Djava.endorsed.dirs=$TOMCAT_HOME/endorsed"
  fi
  local CMD=$(cat <<EOF
    java
      -cp $classpath
      -Xdebug
      -Xrunjdwp:transport=dt_socket,address=1043,server=y,suspend=n
      -Xms1024m
      -Xmx4096m
      -Xmn1024m
      -XX:PermSize=256m
      -XX:MaxPermSize=512m
      -noverify
      -Dalt.config.location=/opt/kuali/kc-config.xml
      -Dcatalina.home=$TOMCAT_HOME
      -Dcatalina.base=$TOMCAT_HOME
      -Djava.io.tmpdir=$TOMCAT_HOME/temp
      -Dfile.encoding=UTF8
      -Dlog4j.configurationFile=$TOMCAT_HOME/log4j2/conf/log4j2-tomcat.xml
      -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager
      $endorsed
      org.apache.catalina.startup.Bootstrap
      -config $TOMCAT_HOME/conf/server.xml start
EOF
  )

  echo $CMD 
  eval $CMD 

  # OR, if to start from catalina.sh use the following:
  # --------------------------------------------------
  # local opts="-Xmx4096m"
  # opts="$opts -Xms2048m"
  # opts="$opts -XX:MaxPermSize=1024m"
  # opts="$opts -Xdebug"
  # opts="$opts -Xrunjdwp:transport=dt_socket,address=1043,server=y,suspend=n"
  # opts="$opts -Dalt.config.location=/opt/kuali/kc-config.xml"
  # export JAVA_OPTS="$opts"
  # ${TOMCAT_HOME}/bin/catalina.sh run
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

