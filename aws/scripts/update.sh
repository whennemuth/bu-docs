branchExists() {
  git rev-parse refs/heads/$1 > /dev/null 2>&1 && [ $? -eq 0 ] && true || false
}

upstreamAndMaster() {
  branchExists "master" && branchExists "upstream"
}

masterNoUpstream() {
  branchExists "master" && ! branchExists "upstream"
}

upstreamNoMaster() {
  branchExists "upstream" && ! branchExists "master"
}

masterIsOnlyBranch() {
  if branchExists "master" ; then
    [ $(git branch | wc -l) -eq 1 ] local isTrue="true"
  fi
  [ $isTrue ] && true || false
}

remoteBUBranchExists() {
  [ $(git ls-remote $BU/$1.git $2 | wc -l) -eq 1 ] && true || false
}

update() {
  SEPARATOR="#########################################################################################################"
  SEPARATOR_LINE1="\n$SEPARATOR\n"
  SEPARATOR_LINE2="$SEPARATOR \n"

  if [ ! $KUALICO ] ; then
    read -p "Type the password for the bu-ist-user at github.com/kualico: " pwd
    pwd="$(echo -ne $pwd | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"
    KUALICO=https://bu-ist-user:$pwd@github.com/KualiCo    
  fi
  if [ ! $BU ] ; then
    read -p "Type the name of your user at github.com/bu-ist: " user
    read -p "Type the password for $user: " pwd
    pwd="$(echo -ne $pwd | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"
    BU=https://$user:$pwd@github.com/bu-ist   
  fi

  local upstreamrepo="$1"
  local burepo="$2"
  local merge="$3"

  cd /c/kuali/$upstreamrepo

  printf "$SEPARATOR_LINE1"

  if upstreamAndMaster ; then
    local pushSourceBranch1="upstream"
    local pushSourceBranch2="master"
    local pushTargetBranch1="master"
    local pushTargetBranch2="master"
    local mergeTargetBranch="master"
    if remoteBUBranchExists $burepo "upstream" ; then
      pushTargetBranch1="upstream"
    else
      pushTargetBranch2=""
    fi
  elif upstreamNoMaster ; then
    local pushSourceBranch1="upstream"
    local pushTargetBranch1="master"
    if remoteBUBranchExists $burepo "upstream" ; then
      pushTargetBranch1="upstream"
    fi
    if [ $merge ] ; then
      printf "   WARNING! Merge upstream to master specified, but no master branch exists \n"
      merge=""
    fi
  elif masterNoUpstream ; then
    local pushSourceBranch1="master"
    local pushTargetBranch1="master"
    if remoteBUBranchExists $burepo "upstream" ; then
      pushTargetBranch1="upstream"
    fi
    if [ $merge ] ; then
      printf "   WARNING! Merge upstream to master specified, but no upstream branch exists \n"
      merge=""
    fi
  else
    printf "   ERROR! No upstream or master branch exist! \n"
    printf "$SEPARATOR_LINE2"
    cd - 1> /dev/null
    return 1
  fi

  echo "   $pushSourceBranch1 << $KUALICO/$upstreamrepo.git:master"
  if [ $merge ] && [ $pushSourceBranch1 != $pushSourceBranch2 ] ; then
    printf "   $pushSourceBranch1 merge > $pushSourceBranch2 \n"
  fi
  printf "   $pushSourceBranch1 >> github.com/bu-ist/$burepo:$pushTargetBranch1 \n"
  if [ $merge ] && [ -n "$pushSourceBranch2" ] && [ -n "$pushTargetBranch2" ] ; then
    printf "   $pushSourceBranch2 >> github.com/bu-ist/$burepo:$pushTargetBranch2 \n"
    local push2="true"
  fi
  printf "$SEPARATOR_LINE2"

  git checkout $pushSourceBranch1
  git pull $KUALICO/$upstreamrepo.git master
  git push $BU/$burepo.git $pushTargetBranch1
  if [ $merge ] && [ -n "$pushSourceBranch2" ] && [ -n "$pushTargetBranch2" ] ; then
    git checkout $pushSourceBranch2
    git merge $pushSourceBranch1
    git push $BU/$burepo.git $pushTargetBranch2
  fi
  
  cd - 1> /dev/null
}


updateKcModules() {

  update "schemaspy" "kuali-schemaspy" "merge"

  update "kc-api" "kuali-kc-api" "merge"

  update "kc-s2sgen" "kuali-kc-s2sgen" "merge"

  update "kc-rice" "kuali-kc-rice"

  update "kc" "kuali-research"
}


updateCoreAndCoiModules() {

  update "cor-main" "kuali-core-main"

  update "research-coi" "kuali-research-coi"

  update "cor-common" "kuali-core-common" "merge"

  update "cor-formbot-gadgets" "kuali-cor-formbot-gadgets" "merge"

  update "formbot" "kuali-formbot" "merge"

  update "kuali-ui" "kuali-ui" "merge"
}


updateAllModules() {

  updateKcModules

  updateCoreAndCoiModules
}

