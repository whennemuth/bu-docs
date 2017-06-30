############################################################################
# The following script builds a single js file and deposits the resulting 
# file in the dist folder of the core or coi node app. Node can be running 
# at the time, but you will need to restart in # order for the new js file 
# to take effect.
############################################################################

babel_build_one() {
  if [ -z "$1" ] || [ -z "$2" ] ; then
    echo "Two arguments required";
    return 1;
  fi
  if [ "$1" == "core" ] ; then
    SOURCE_DIR="/var/core"
    SEARCH_DIR="/opt/kuali-research-docker/core/build.context/workspace/deployment"
    CONTAINER="core"
  elif [ "$1" == "coi" ] ; then
    SOURCE_DIR="/var/research-coi"
    SEARCH_DIR="/opt/kuali-research-docker/coi/build.context/workspace/oracle/deployment"
    CONTAINER="coi-oracle"
  else
    echo "First argument must be 'coi' or 'core'"
    return 1;
  fi

  if [ -n "$3" ] ; then
    files=( $(find $SEARCH_DIR -iname $2 -type f -not -path "*/node_modules/*" -not -path "*/dist/*" -wholename "*${3}") )
  else
    files=( $(find $SEARCH_DIR -iname $2 -type f -not -path "*/node_modules/*" -not -path "*/dist/*") )
  fi

  found=${#files[@]}
  if [ $found -eq 0 ] ; then
    echo "$2 not found";
    return 1;
  elif [ $found -gt 1 ] ; then
    echo "More than one matching file found! :"
    for (( i=0; i<$found; i++ )); do
      echo ${files[${i}]}
    done
    return 1;
  fi

  # This is the file outside of the container
  FILE=${files[0]}
  # This is the same file inside the container (somewhere in mounted directory)
  SOURCE_FILE="$SOURCE_DIR/$(echo $FILE | grep -o -P '(?<=/)services/.*')"
  TARGET_FILE="$(echo $SOURCE_FILE | sed 's/\/services\//\/dist\/services\//')"
  BABEL="$SOURCE_DIR/node_modules/babel-cli/bin/babel.js"
  CMD="docker exec -ti $CONTAINER $BABEL $SOURCE_FILE --out-file $TARGET_FILE"
  echo $CMD

  eval $CMD

  docker restart $1

  sleep 5

  docker logs core | grep "chrome-devtools" | tail -n1
}

