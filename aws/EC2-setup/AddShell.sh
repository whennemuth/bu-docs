#!/bin/bash

cat <<EOF >> ~/.bashrc

git_ssh(){
  # \$1 = path of local git repo
  # \$2 = name of ssh private key (assumes it exists at ~/.ssh/)
  # \$3 = name of the git remote
  # \$4 = name of the git repository
  eval "ssh-agent -k"
  cd \$1
  eval \`ssh-agent -s\`
  ssh-add ~/.ssh/\$2
  ssh -T git@github.com
  if [ -z "\$(git remote | grep -P ^\$3\$)" ] ; then
    git remote add \$3 git@github.com:\$4
  fi
}

# Below are examples. Modify the arguments to reflect your own repo paths, keynames, etc.
alias gitdocker='git_ssh \
  /path/to/repo/for/kuali-research-docker \
  bu_github_id_docker_rsa \
  github \
  bu-ist/kuali-research-docker.git'

alias gitdocker='git_ssh \
  /c/whennemuth/kuali-research \
  bu_github_id_kc_rsa \
  github \
  bu-ist/kuali-research.git'

alias gitdocker='git_ssh \
  /path/to/repo/for/kuali-research-core \
  bu_github_id_core_rsa \
  github \
  bu-ist/kuali-research-core.git'

# etc...

EOF

source ~/.bashrc