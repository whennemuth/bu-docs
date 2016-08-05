close=$1

if [ $# -ne 1 ]; then
   echo "Hello "$USER". Enter the aws url and press [ENTER]: "
   read url
   eval `ssh-agent -s`
   ssh-add C:/Users/wrh/.ssh/buaws-kuali-rsa
   eval "ssh ec2-user@$url"
else
   eval `ssh-agent -k`
   exit
fi
