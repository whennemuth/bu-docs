# The user is about to build coi - they must pull it from git.
# It would be enough to trust that the user has specified an existing refspec to pull from git.
# However, in addition to this the refspec must be of a commit that contains a package.json
# file with a version of kuali-iu that itself exists as a tag in the kuali-ui git repository.
# It has been found that this will not always be the case, and in that event the git logs of
# both repositories are traversed displaying whether or not commits fulfill this criteria. 
#
# USE CASE: This information is useful when you want to determine if you can merge your own 
# custom # branch with the head of upstream research-coi. If head is disqualified by this 
# function you can find the next best commit to merge against.
checkGitRefspec() {
        local STARTING_POINT=$(pwd)

        # We need to access the log for research-coi, so make a directory to clone it to.
        local TEMPCOI="/tmp"
        TEMPCOI="$TEMPCOI/coi"
        [ -d $TEMPCOI ] && echo "$TEMPCOI already exists. Removing..." && rm -rf $TEMPCOI
        mkdir -p $TEMPCOI
        [ ! -d $TEMPCOI ] && echo "ERROR! Cannot create $TEMPCOI" && return 1

        # We need to access versions of package.json in kuali-ui, so make a directory to clone it to.
        local TEMPUI="/tmp"
        TEMPUI="$TEMPUI/kualiui"
        [ -d $TEMPUI ] && echo "$TEMPUI already exists. Removing..." && rm -rf $TEMPUI
        mkdir -p $TEMPUI
        [ ! -d $TEMPUI ] && echo "ERROR! Cannot create $TEMPUI" && return 1

        # Clone research-coi from github
        local GIT_USER && read -p "Clone research-coi and kuali-ui git repos with what user? Enter name: " GIT_USER
        local GIT_PASSWORD && read -p "What is the password for $GIT_USER? Enter password: " GIT_PASSWORD
        local ENCODED_PASSWORD="$(echo -ne $GIT_PASSWORD | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"
        local URL="https://$GIT_USER:$ENCODED_PASSWORD@github.com/bu-ist/kuali-research-coi"
        local CMD="git clone --bare $URL $TEMPCOI"
        echo $CMD && eval $CMD

        # Clone kuali-ui from github
        local URL="https://$GIT_USER:$ENCODED_PASSWORD@github.com/bu-ist/kuali-ui"
        local CMD="git clone --bare $URL $TEMPUI"
        echo $CMD && eval $CMD

        # Get all the tags from kuali-ui
        cd $TEMPUI
        local TAGS=$(git tag)

        # Get the most recent commits
        cd $TEMPCOI
        local COMMITS=$(git rev-list --first-parent upstream -100)

        # Get the most recent commit whose package.json has a file specifying a version of kuali-ui that can be obtained by tag
        while read -r COMMIT ; do
                local VERSION="$(git show $COMMIT:package.json | grep '@kuali/kuali-ui')"
                [ -z "$VERSION" ] && break
                VERSION="v$(echo $VERSION | sed s/[^0-9\.]//g)"
                if [ -z "$(echo "$TAGS" | grep $VERSION)" ] ; then
                        echo "$COMMIT: $VERSION DISQUALFIED!"
                else
                        echo "$COMMIT: $VERSION"
                fi
        done <<< "$COMMITS"
        cd $STARTING_POINT

        # Cleanup
        [ -d $TEMPCOI ] && echo "Removing $TEMPCOI..." && rm -rf $TEMPCOI
        [ -d $TEMPUI ] && echo "Removing $TEMPUI..." && rm -rf $TEMPUI
}
