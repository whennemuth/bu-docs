#!/bin/bash

instanceIds=""

AddUser() {
  local username="$1"
  local pubkey="$2"
  if [ "$(whoami)" != "root" ] ; then     
    sudo su root
  fi

  if [ ! -d /home/$username ] ; then
    useradd -d /home/$username -u 1000 -g docker -m -s /bin/bash $username
    usermod -a -G sudo $username
  fi

  if [ ! -d /home/$username/.ssh ] ; then
    mkdir -m 700 /home/$username/.ssh
    cd /home/$username/.ssh
    echo "$pubkey" >> authorized_keys
    chmod 600 authorized_keys
    chown -R $username:docker /home/$username/.ssh
  fi
}

# Generate a public/private key pair and return the content of the public key.
GenerateKey() {
    local username=$1
    if [ -n "$username" ] ; then
      cd ~/.ssh
      ssh-keygen -b 2048 -t rsa -f ${username}_rsa -q -N ""
      cat ${username}_rsa.pub
    else
      echo "No username parameter provided. Key cannot be generated."
    fi
}

CreateUserOnEC2() {
    local username=$1
    if [ -n "$username" ] ; then
      local pubkey="$(GenerateKey $username)"
    else
      echo "No username parameter provided. Key cannot be sent."
    fi
}

# Set the variables global to the shell from here on that were provided as args.
parseargs() {
  local posargs=""

  while (( "$#" )); do
    case "$1" in
      -t|--task)
        parsing-instance-ids=""
        eval "$(parseValue $1 "$2" 'task')" ;;
      -i|--instance-ids)
        parsing-instance-ids="true"
        eval "$(parseValue $1 "$2" 'instanceIds')" ;;
      -u|--username)
        parsing-instance-ids=""
        eval "$(parseValue $1 "$2" 'username')" ;;
      -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        printusage
        exit 1
        ;;
      *) # preserve positional arguments (should not be any more than the leading command, but collect then anyway) 
        if [ -n "parsing-instance-ids" ] ; then
          instanceIds="$instanceIds $1"
        fi
        posargs="$posargs $1"
        shift
        ;;
    esac
  done

  # set positional arguments in their proper place
  eval set -- "$posargs"
  echo "$posargs"
}

parseValue() {
  local cmd=""

  # Blank out prior values:
  [ "$#" == '3' ] && eval "$3="
  [ "$#" == '2' ] && eval "$2="

  if [ -n "$2" ] && [ ${2:0:1} == '-' ] ; then
    # Named arg found with no value (it is followed by another named arg)
    echo "echo 'ERROR! $1 has no value!' && exit 1"
    exit 1
  elif [ -n "$2" ] && [ "$#" == "3" ] ; then
    # Named arg found with a value
    cmd="$3=\"$2\" && shift 2"
  elif [ -n "$2" ] ; then
    # Named arg found with no value
    echo "echo 'ERROR! $1 has no value!' && exit 1"
    exit 1
  fi

  echo "$cmd"
}

parseargs "$@"

echo "task=$task"
echo "instanceId=$intanceId"
echo "username=$username"
echo "instanceIds=$instanceIds"
