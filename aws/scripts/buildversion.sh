#############################################################################
#
# The html footer in the kuali-research web application displays version info
# about the application. It gets this information from the build.version environment
# variable. This environment variable is... 
#    1) specified as an mvn command parameter when building the app. 
# failing this...
#    2) set with the build.version param in found WEB-INF/classes/META-INF/kc-config-build.xml 
# This script cancels itself if it finds 1) to be the case.
# Otherwise it determines what the version info value should be and injects it
# into WEB-INF/classes/META-INF/kc-config-build.xml within the war file using 
# the jar command. 
#
#############################################################################

if [ -z "${KCWAR}" ] ; then KCWAR="kc.war"; fi

if [ -z "${POM_VERSION}" ] ; then POM_VERSION="coeus-unknown-version"; fi
if [ -z "${GIT_BRANCH}" ] ; then GIT_BRANCH="unknown-git-branch"; fi
if [ -z "${GIT_COMMIT}" ] ; then GIT_COMMIT="unknown-git-ref"; fi
	
VERSION_INFO="${POM_VERSION}\\/git:branch=${GIT_BRANCH},ref=${GIT_COMMIT}"
CFG=WEB-INF/classes/META-INF/kc-config-build.xml
CANCELLED=false
FILE_MISSING=false
INSERT=true

if [ -n "$(unzip -l ${KCWAR} | grep ${CFG})" ] ; then
	echo "Found ${CFG} in ${KCWAR}"
	# \x22 = hex for ", \x27 = hex for '
	CONTENT="$(unzip -qp ${KCWAR} ${CFG})"
	echo "" && echo "EXISTING CONFIG CONTENT:" && echo "" && echo "$CONTENT" && echo ""
	
	PARAM="$(echo $CONTENT | grep -i -o -P '<param[^>]+?name=[\x22\x27]?version[\x22\x27]?[^>]*>([^<>]+)</param>')"
	
	if [ -n "$PARAM" ] ; then
		echo "\"${PARAM}\" found in ${CFG}"
		VAL=$(echo $PARAM | grep -i -P -o '>[^<>]*<' | grep -o -P "[^<>]*")
			
		if ([ -n "$(echo ${VAL} | grep -P '[^\\s]+')" ] && [ $VAL != "\${build.version}" ]) ; then
			# If val is not empty, not all whitespace, and not equal to "\${build.version}", then it is specific version.
			# If this is the case, then leave it alone.
			echo "Valid version info already set: ${VAL}"
			CANCELLED=true
		else
			echo "Replacing its element value with \"${VERSION_INFO}\"" 
			NEW_PARAM="<param name=\\\"version\\\">${VERSION_INFO}<\\/param>"
			CONTENT=$(echo $CONTENT | sed -r "s/<param[^>]*name=[\"']?version[\"']?[^>]*>[^<>]*<\/param>/${NEW_PARAM}/g")
		fi
		
	else
		echo "No version parameter element found in ${CFG}"
		echo "Inserting one..."
		INSERT=true
	fi
else
	echo "${CFG} file does not exist in war, placing one there..."
	FILE_MISSING=true
fi

if $CANCELLED; then
	echo "CANCELLED!";
else 
	if $FILE_MISSING; then
		echo "Creating new file with ${VERSION_INFO}"
		echo "<config>" > kc-config-build.xml
		echo "   <param name=\"version\">${CONTENT}</param>" >> kc-config-build.xml
    		echo "   <param name=\"spring.profiles.active\" system=\"true\"></param>" >> kc-config-build.xml
		echo "</config>" >> kc-config-build.xml
	elif $INSERT; then
		echo "Inserting ${VERSION_INFO}"
		echo $CONTENT > kc-config-build.xml
	else
		echo "Replacing with ${VERSION_INFO}"
		echo $CONTENT > kc-config-build.xml
	fi
	echo "" && echo "NEW CONFIG CONTENT:" && echo "" && cat kc-config-build.xml
fi