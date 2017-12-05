# These are helpful shortcuts for your ec2-user. 
# They perform recompiling and re-running tasks.

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

promptMaven() {
  local goals="$1"
  [ -n "$(echo $goals | grep 'compile')" ] && local compile="yes";
  [ -n "$(echo $goals | grep 'package')" ] && local package="yes";
  [ -n "$(echo $goals | grep 'install')" ] && local install="yes";

  local module="$2"
  if [ -n "$goals" ] ; then
    local cmd="cd /opt/kuali/kc; mvn -e $goals -Dmaven.test.skip=true -Dgrm.off=true "
    if [ -n "$module" ] ; then
      cmd="$cmd -pl $module "
    fi
    if [ -n "$compile" ] ; then
      local sources=""
      read -p "Include source jars? ('y' or 'enter' for no): " sources
      if [ -n "$sources" ] ; then
        cmd="$(echo $cmd | sed 's/compile/compile source:jar/g')"
      fi
    fi
    echo $cmd && eval $cmd
  fi
  if [ "$module" == "coeus-impl" ] || [ -z "$module" ] ; then
    rsync-impl-jar
    rsync-impl-resources
  fi
}

rsync-impl-resources() {
  rsync -a --exclude '*.java' /opt/kuali/kc/coeus-impl/src/main/resources /opt/kuali/kc/coeus-impl/target/classes;
}

rsync-impl-jar() {
  rsync -a /opt/kuali/kc/coeus-impl/target/coeus-impl-1705.0034-SNAPSHOT.jar /opt/kuali/kc/coeus-webapp/target/coeus-webapp-1705.0034-SNAPSHOT/WEB-INF/lib
}

gitpull() {
  cd /opt/kuali/kc
  git checkout meatball
  git pull origin meatball
}

killtomcat() {
  local PID="$(ps ax | grep java | grep tomcat | grep "\\-Xdebug" | grep -Po "(\\d+)" | sed -n 1p)"
  if [ -n "$PID" ] ; then
    kill -9 $PID
  fi
}

runkc() {
  killtomcat
  cd /opt/kuali-setup/aws/ec2-setup-developer
  source setup.sh
  runKuali
}

redeploy() {
  local pull=""
  read -p "Pull all code from git first? ('y' or 'enter' for no): " pull
  if [ "$pull" == "y" ] || [ "$pull" == "Y"] ; then
    gitpull
  fi

  local module="$1"
  if [ -n "$module" ] ; then
    promptMaven 'clean compile package' "$module"
  else
    promptMaven 'clean compile package'
  fi
  runkc
}


# User specific aliases and functions
alias setup='vim /opt/kuali-setup/aws/ec2-setup-developer/setup.sh'
alias dev='cd /opt/kuali-setup/aws/ec2-setup-developer && ls -la'
alias compileimpl="promptMaven 'clean compile' 'coeus-impl'"
alias packageimpl="promptMaven 'clean compile package' 'coeus-impl'"
alias installimpl="promptMaven 'clean compile install' 'coeus-impl'"
alias compileall="promptMaven 'clean compile'"
alias packageall="promptMaven 'clean compile package'"
alias installall="promptMaven 'clean compile install'"
alias scpsandbox='scp -C -i ~/.ssh/buaws-kuali-rsa /opt/kuali/kc/coeus-webapp/target/coeus-webapp-1705.0034-SNAPSHOT.war wrh@10.57.237.85:/home/wrh'
alias redeployimpl='redeploy coeus-impl'
alias redeployall='redeploy'
alias runkc='runkc'

