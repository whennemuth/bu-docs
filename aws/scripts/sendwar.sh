if [ -f sendwar_config.cfg ] ; then
   read -p "Enter choices or repeat last? (type "y" for yes, or any other key for no) " CONFIG
else
   CONFIG="y"
fi

CANCELLED=true;
SERVERS=(); 
if [ $CONFIG = "y" ] || [ $CONFIG = "Y" ] ; then
   read -p "Which landscape are you deploying a war file to? (type the number of your choice)
      1) sandbox
      2) ci
      3) qa
      4) staging
      5) production
      6) [cancel]: 
      " \
   LANDSCAPE
   
   if [ -z "$(echo $LANDSCAPE | grep -P '^[1-6]$')" ] ; then
      echo "Invalid entry! Limit to numbers 1 through 6";
   elif [ "6" != $LANDSCAPE ] ; then
      case "$LANDSCAPE" in
      "1")
         LANDSCAPE="sandbox";
         SERVER1="10.57.237.84";
         SERVER2="10.57.237.85";;
      "2")
         LANDSCAPE="ci";
         SERVER1="10.57.237.36";
         SERVER2="10.57.237.37";;
      "3")
         LANDSCAPE="qa";
         SERVER1="10.57.236.244";
         SERVER2="10.57.236.244";;
      "4")
         LANDSCAPE="staging";
         SERVER1="10.57.236.68";
         SERVER2="10.57.236.100";;
      "5")
         LANDSCAPE="production";
         SERVER1="10.57.242.100";
         SERVER2="10.57.243.100";;
      esac
      
      read -p "Deploy to (enter the number of your choice):
      1) ${SERVER1}
      2) ${SERVER2}
      3) Both 
      4) [cancel]:
      " \
      SERVER_CHOICE

      if [ -z "$(echo $SERVER_CHOICE | grep -P '^[1-4]$')" ] ; then
         echo "Invalid entry! Limit to numbers 1 through 4";
      elif [ "4" != $SERVER_CHOICE ] ; then
         case "$SERVER_CHOICE" in
         "1") 
            SERVERS+=(${SERVER1});
            SERVERS+=("\"\"");;
         "2") 
            SERVERS+=("\"\"");
            SERVERS+=(${SERVER2});;
         "3") 
            SERVERS+=(${SERVER1});
            SERVERS+=(${SERVER2});;
         esac
            
         read -p "Where is your private key to access the ${LANDSCAPE} server(s)?
      Enter an absolute or relative path (example: ~/.ssh/my_RSA_key):
      " KEY

         if [ ! -f $KEY ] ; then
            echo "Cannot find key file: ${KEY}"
         else
            read -p "Where is the war file?
      Enter an absolute or relative path (example: /home/me/coeus-webapp-1608.0042.war):
      " WAR
            if [ ! -f $WAR ] ; then
               echo "Cannot find war file: ${WAR}"
            else
               read -p "What is your username on the remote server? (Will be the name of your home directory, ie: /home/myuser)
      " USER

               if [] ; then
                  echo "Username cannot be empty";
               else
                  # All configuration details collected, so save to config file
                  echo "" > sendwar_config;
                  for ((i=0; i<${#SERVERS[*]}; i++));
                  do
                     echo "SERVER$(($i+1))=${SERVERS[i]}" >> sendwar_config;
                  done               
                  echo "KEY=${KEY}" >> sendwar_config;
                  echo "WAR=${WAR}" >> sendwar_config;
                  echo "USER=${USER}" >> sendwar_config;
                  CANCELLED=false;
               fi
            fi
         fi
      fi

   fi
fi

if $CANCELLED; then
   echo "Cancelled."
else
   echo "Proceeding from the following configuration:"
   cat sendwar_config;
   # transfer the war file to your home directory on the server(s)
   if [ -n "$SERVER1" ] ; then
      exec "scp -C -i ${KEY} ${WAR} ${USER}@${SERVER1}:~/
   fi
   if [ -n "$SERVER2" ] ; then
      exec "scp -C -i ${KEY} ${WAR} ${USER}@${SERVER2}:~/
   fi   
fi







#if [ -f /tmp/kc.war ] ; then
#   cd /opt/kuali-research-docker/kuali-research/build.context
#   cp /tmp/kc.war .
#   ls -la
#   if [ -n "$(docker ps --filter name=kuali-research -q)" ] ; then
#      docker rm -f kuali-research;
#   fi
#   source dockerbuild.sh
#   source dockerrun.sh
#   cd /tmp
#else
#   echo 'Forget something? There is no kc.war file in the /tmp directory';
#fi