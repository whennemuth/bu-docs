# 1) Get a token to present with a REST web service request to the dockerhub remote api.
MYTOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/centos:pull" | grep -i -P -o "(?<=\"token\":\")[^\"]+")

# 2) Make the REST web service call to get the manifest for the official centos7 dockerhub image.
# RAW_JSON=$(curl -s -i -H "Authorization: Bearer ${MYTOKEN}" https://registry-1.docker.io/v2/library/centos/manifests/latest)
# RAW_JSON=$(curl -s -i -H "Authorization: Bearer ${MYTOKEN}" https://registry-1.docker.io/v2/library/centos/tags/list)
RAW_JSON=$(curl -s -i -H "Authorization: Bearer ${MYTOKEN}" https://registry-1.docker.io/v2/library/centos/manifests/7)

if [ -n "${RAW_JSON}" ] ; then

	# 3) Make sure the jenkins home directory is known.
	if [ -z "${JENKINS_HOME}" ] ; then
		#JENKINS_HOME='/var/lib/jenkins'
		JENKINS_HOME='C:/Users/wrh/Desktop/docker.io.test/backup/centos7/manifest'
	fi
	
	# 4) Set variables.
	MANIFEST_DIR="${JENKINS_HOME}/backup/centos7/manifest"
	JSON_FILE_RAW="${MANIFEST_DIR}/dockerhub.centos7.manifest.raw.json"
	JSON_FILE_PRETTY="${MANIFEST_DIR}/dockerhub.centos7.manifest.pretty.json"
	DIGEST_FILE="${MANIFEST_DIR}/dockerhub.centos7.manifest.digest"
	OUR_HASH_FILE="${MANIFEST_DIR}/jenkins.centos7.manifest.sha256"
	THEIR_HASH_FILE="${MANIFEST_DIR}/dockerhub.centos7.manifest.sha256"

	# 5) Make sure the target directory for this script exists.
	if [ ! -d $MANIFEST_DIR ] ; then
		mkdir -p $MANIFEST_DIR
	fi

	# 6) Put the manifest json out to a file.
	echo $RAW_JSON > $JSON_FILE_RAW

	# 7) (Optional) parse the json into human-readable form (prettify).
	if [ -z "$(python --help | grep -i 'command not found')" ] ; then
	   echo $RAW_JSON | grep -i -P -o "^[^\{]+" > $JSON_FILE_PRETTY
	   echo $RAW_JSON | grep -i -P -o "\{.*\}" | python -m json.tool >> $JSON_FILE_PRETTY
	fi

	# 8) (Optional) Output the digest of the manifest to its own file
	# NOTE: Non-capturing look-behind regex expressions must be fixed length, hence multiple chained grep expressions.
	if [ -n "$(echo $RAW_JSON | grep -i 'Docker-Content-Digest')" ] ; then
		echo $RAW_JSON \
		   | grep -i -P -o '(?<=Docker\-Content\-Digest)\W*sha256\W*[\w]*' \
		   | grep -i -P -o '(?<=sha256)\W*\w*' \
		   | grep -i -P -o '\w*' \
		   > $DIGEST_FILE
	fi

	# 9) Output the hash code for the most recent image	
	echo $RAW_JSON \
		| grep -i -P -o "\{.*\}" \
		| python -c 'import sys, json; print json.load(sys.stdin)["history"][0]["v1Compatibility"]' \
		| python -c 'import sys, json; print json.load(sys.stdin)["config"]["Image"]' \
		| grep -i -o -P '(?<=sha256:)[\w]+' \
		> $THEIR_HASH_FILE

	# 10) Output the hash code for the current image in our local docker repository
	# NOTE: This assumes that nobody has performed a manual docker pull command for centos:7 and the current image was the result of the most  
	#       recent jenkins job that built an image based on top of the centos:7 image where no local version of centos:7 existed at the time.  
	docker inspect centos:7 \
		| python -c 'import sys, json; print json.load(sys.stdin)[0]["Config"]["Image"]' \
		| grep -i -o -P '(?<=sha256:)[\w]+' \
		> $OUR_HASH_FILE
else
	echo "No value for RAW_JSON"
fi