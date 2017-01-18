#SELECTIONS=""
#SELECTIONS="centos, apache-sb, apache-ci, apache-qa, apache-stg, apache-prod"
SELECTIONS="centos, apache-sb, apache-ci, apache-qa, apache-stg, apache-prod, kuali-sb, kuali-ci, kuali-qa, kuali-stg, kuali-prod"
ECR_REGISTRY_URL="730096353738.dkr.ecr.us-east-1.amazonaws.com"
JENKINS_HOME="/var/lib/jenkins"
DEBUG=true

#set +x

CLI=/var/lib/jenkins/jenkins-cli.jar
HOST=http://localhost:8080/
BACKUP_DIR=/var/lib/jenkins/backup/kuali-research/war
CMDS=$()

# BUGFIX: The Active Choices Reactive Parameter Rendering feature is adding 
# a comma to the end of the SELECTIONS hidden input value, so strip off the comma
if ( [ -n "${SELECTIONS}" ] && [ "${SELECTIONS}" != "," ] ); then
	SELECTIONS=$(echo ${SELECTIONS} | grep -i -o -P '^.*[^,](?=,?$)')
fi

if ( [ -n "$(echo "${SELECTIONS}" | grep 'centos')" ] ) ; then

	# 1) Add a command to rebuild the docker centos-java-tomcat image
	CMD="java -jar ${CLI} -s ${HOST} build 'check-centos-1-docker-build-image' -v -f"
	CMDS=("${CMDS[@]}" "${CMD}")

	# 2) Add a command to push the built image to our registry
	CMD="java -jar ${CLI} -s ${HOST} build 'check-centos-2-docker-push-image' -v -f"
	CMDS=("${CMDS[@]}" "${CMD}")
fi

if ( [ -n "$(echo "${SELECTIONS}" | grep 'apache')" ] ) ; then

	# 1) Add a command to call the apache-shibboleth-1-docker-build-image job
	CMD="java -jar ${CLI} -s ${HOST} build 'apache-shibboleth-1-docker-build-image' -v -f"
	CMDS=("${CMDS[@]}" "${CMD}")

	# 2) Add a command to call the apache-shibboleth-2-docker-push-image job
	CMD="java -jar ${CLI} -s ${HOST} build 'apache-shibboleth-2-docker-push-image' -v -f"
	CMDS=("${CMDS[@]}" "${CMD}")

	# 3) Add a command to call the apache-shibboleth-3-docker-run-container for every indicated landscape
	LANDSCAPES=($(echo $SELECTIONS | grep -i -o -P "apache\\-\\w+"))
	for i in $(seq ${#LANDSCAPES[@]}); do
		LANDSCAPE=$(echo "${LANDSCAPES[i-1]}" | grep -o -P "[^\\-]+$")
		CMD="java -jar ${CLI} -s ${HOST} build 'apache-shibboleth-3-docker-run-container' -v -f \
			-p EC2_INSTANCE_ID=EC2ID \
			-p LANDSCAPE=LNDSCP"
		case "$LANDSCAPE" in
		"sb")
			CMD1="$(echo ${CMD} | sed 's/EC2ID/i-099de1c5407493f9b/' | sed 's/LNDSCP/sandbox/')"
			CMD2="$(echo ${CMD} | sed 's/EC2ID/i-0c2d2ef87e98f2088/' | sed 's/LNDSCP/sandbox/')"
			CMDS=("${CMDS[@]}" "${CMD1}" "${CMD2}");;
		"ci")
			CMD1="$(echo ${CMD} | sed 's/EC2ID/i-0258a5f2a87ba7972/' | sed 's/LNDSCP/ci/')"
			CMD2="$(echo ${CMD} | sed 's/EC2ID/i-0511b83a249cd9fb1/' | sed 's/LNDSCP/ci/')"
			CMDS=("${CMDS[@]}" "${CMD1}" "${CMD2}");;
		"qa")
			CMD="$(echo ${CMD} | sed 's/EC2ID/i-011ccd29dec6c6d10/' | sed 's/LNDSCP/qa/')"
			CMDS=("${CMDS[@]}" "${CMD}");;
		"stg")
			CMD1="$(echo ${CMD} | sed 's/EC2ID/i-090d188ea237c8bcf/' | sed 's/LNDSCP/stage/')"
			CMD2="$(echo ${CMD} | sed 's/EC2ID/i-0cb479180574b4ba2/' | sed 's/LNDSCP/stage/')"
			CMDS=("${CMDS[@]}" "${CMD1}" "${CMD2}");;
		"prod")
			CMD1="$(echo ${CMD} | sed 's/EC2ID/i-0534c4e38e6a24009/' | sed 's/LNDSCP/prod/')"
			CMD2="$(echo ${CMD} | sed 's/EC2ID/i-07d7b5f3e629e89ae/' | sed 's/LNDSCP/prod/')"
			CMDS=("${CMDS[@]}" "${CMD1}" "${CMD2}");;
		esac		
	done
fi

if ( [ -n "$(echo "${SELECTIONS}" | grep 'kuali')" ] ) ; then 

	SANDBOX_REGISTRY_UPDATED=false;
	KUALI_REGISTRY_UPDATED=false;
	LANDSCAPES=($(echo $SELECTIONS | grep -i -o -P "kuali\\-\\w+"))
	for i in $(seq ${#LANDSCAPES[@]}); do
		LANDSCAPE=$(echo "${LANDSCAPES[i-1]}" | grep -o -P "[^\\-]+$")
		case "$LANDSCAPE" in
		"sb")
			BRANCH="master"
			REGISTRY_REPO_NAME="coeus-sandbox"
			SKIP_REGISTRY=$SANDBOX_REGISTRY_UPDATED;;
		"ci"|"qa"|"stg"|"prod"|"production")
			BRANCH="bu-master"
			REGISTRY_REPO_NAME="coeus"
			SKIP_REGISTRY=$KUALI_REGISTRY_UPDATED;;
		esac

		WAR_FILE=$(ls -1 ${BACKUP_DIR}/${BRANCH} | grep -P "^.*war$")
		POM_VERSION=$(echo $WAR_FILE | sed 's/coeus-webapp-//' | sed 's/.war//')

		if [ "$SKIP_REGISTRY" == false ] ; then

			# 1st step) Build the docker image locally 
			CMD="java -jar ${CLI} -s ${HOST} build 'kuali-research-2-docker-build-image' -v -f \
			-p POM_VERSION=${POM_VERSION} \
			-p REGISTRY_REPO_NAME=${REGISTRY_REPO_NAME} \
			-p JENKINS_WAR_FILE=${BACKUP_DIR}/${BRANCH}/${WAR_FILE} \
			-p ECR_REGISTRY_URL=${ECR_REGISTRY_URL}"
			CMDS=("${CMDS[@]}" "${CMD}")
			 
			# 2nd step) Push the docker image to the registry
			CMD="java -jar ${CLI} -s ${HOST} build 'kuali-research-3-docker-push-image' -v -f \
			-p ECR_REGISTRY_URL=${ECR_REGISTRY_URL} \
			-p POM_VERSION=${POM_VERSION} \
			-p REGISTRY_REPO_NAME=${REGISTRY_REPO_NAME}"
			CMDS=("${CMDS[@]}" "${CMD}")

			if [ $LANDSCAPE == "sb" ] ; then SANDBOX_REGISTRY_UPDATED=true; else KUALI_REGISTRY_UPDATED=true; fi
		fi

		# 3rd step) Pull the docker image from the registry to the application instance and start a container there from it.
		CMD="java -jar ${CLI} -s ${HOST} build 'kuali-research-4-docker-run-container' -v -f \
		-p ECR_REGISTRY_URL=${ECR_REGISTRY_URL} \
		-p EC2_INSTANCE_ID=${EC2_INSTANCE_ID} \
		-p POM_VERSION=${POM_VERSION} \
		-p REGISTRY_REPO_NAME=${REGISTRY_REPO_NAME}"
		CMDS=("${CMDS[@]}" "${CMD}")
	done
fi

if [ ${#CMDS[@]} > 0 ] ; then
	for (( i=0; i<${#CMDS[@]}; i++ ));
	do
		# [ "$DEBUG" == true ] && echo ${CMDS[$i]} || eval ${CMDS[$i]}
		[ "$DEBUG" == true ] && echo ${CMDS[$i]} || echo "EXECUTING: ${CMDS[$i]}"
	done	
else
	echo "ERROR! COULD NOT CREATE A LIST OF JOBS TO RUN."
	exit 1;
fi

#set -x