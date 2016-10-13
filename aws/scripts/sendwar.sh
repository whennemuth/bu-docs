SERVER_SB1=10.57.237.84
SERVER_SB2=10.57.237.85
SERVER_CI1=10.57.237.36
SERVER_CI2=10.57.237.37
SERVER_QA=10.57.236.244
SERVER_STG1=10.57.236.68
SERVER_STG2=10.57.236.100
SERVER_PROD1=10.57.242.100
SERVER_PROD2=10.57.243.100

CANCELLED=true;
SERVERS=(); 

if [ -f sendwar.cfg ] ; then
	echo "Most recently used parameters:"
	echo "   $(cat sendwar.cfg | perl -p -e 's/([\r\n\f])/\n   /g')"
	read -p "Reuse these parameters? [y/N] : " REUSE_CONFIG
else
	REUSE_CONFIG="y"
fi

if [ $REUSE_CONFIG = "y" ] || [ $REUSE_CONFIG = "Y" ] ; then
	source sendwar.cfg
	if [ -n "${SERVER1}" ] ; then SERVERS+=(${SERVER1}); fi
	if [ -n "${SERVER2}" ] ; then SERVERS+=(${SERVER2}); fi
	if [ ! -f $KEY ] ; then
		echo "Cannot find key file: ${KEY}";
	elif [ ! -f $WAR ] ; then
		echo "Cannot find key file: ${WAR}";
	else
		CANCELLED=false;
	fi
else
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
			SERVER1=SERVER_SB1;
			SERVER2=SERVER_SB2;;
		"2")
			LANDSCAPE="ci";
			SERVER1="SERVER_CI1";
			SERVER2="SERVER_CI2";;
		"3")
			LANDSCAPE="qa";
			SERVER1="SERVER_QA";
			SERVER2="SERVER_QA";;
		"4")
			LANDSCAPE="staging";
			SERVER1="SERVER_STG1";
			SERVER2="SERVER_STG2";;
		"5")
			LANDSCAPE="production";
			SERVER1="SERVER_PROD1";
			SERVER2="SERVER_PROD2";;
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
			# escape "/" characters in $HOME
			HME=$(echo $HOME | sed -r "s/\\//\\\\\//g")
			# replace shortcut home directory syntax with full home directory path
			KEY=$(echo $KEY | sed -r "s/~\//${HME}\//g")
			if [ ! -f $KEY ] ; then
				echo "Cannot find key file: ${KEY}"
			else
				read -p "Where is the war file?
		Enter an absolute or relative path (example: /home/me/coeus-webapp-1608.0042.war):
		" WAR
				# replace shortcut home directory syntax with full home directory path
				WAR=$(echo $WAR | sed -r "s/~\//${HME}\//g")
				if [ ! -f $WAR ] ; then
					echo "Cannot find war file: ${WAR}"
				else
					read -p "What is your username on the remote server? (Will be the name of your home directory, ie: /home/myuser)
		" USER

					if [] ; then
						echo "Username cannot be empty";
					else
						# All configuration details collected, so save to config file
						echo "" > sendwar.cfg;
						for ((i=0; i<${#SERVERS[*]}; i++));
						do
							echo "SERVER$(($i+1))=${SERVERS[i]}" >> sendwar.cfg;
						done					
						echo "KEY=${KEY}" >> sendwar.cfg;
						echo "WAR=${WAR}" >> sendwar.cfg;
						echo "USER=${USER}" >> sendwar.cfg;
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
	cat sendwar.cfg;
	# transfer the war file to your home directory on the server(s)
	echo "Transferring war file(s)..."
	for ((i=0; i<${#SERVERS[*]}; i++));
	do
		echo "scp -C -i ${KEY} ${WAR} \"${USER}@${SERVERS[i]}:~/\""
		scp -C -i ${KEY} ${WAR} "${USER}@${SERVERS[i]}:~/"
		echo "Remotely triggering dockerrerun.sh"
		WARNAME=$(echo $WAR | grep -o -P "[^\/]+$")
		ssh -i ${KEY} "${USER}@${SERVERS[i]}" \
			"cd /opt/kuali-research-docker/kuali-research/build.context && " \
			"sudo cp -f ~/${WARNAME} kc.war && " \
			"sudo cat dockerrerun.sh | sudo sh"
	done					
fi

echo "FINISHED!"
