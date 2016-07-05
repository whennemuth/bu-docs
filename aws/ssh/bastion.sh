close=$1

if [ $# -ne 1 ]; then
   eval `ssh-agent -s`
   ssh-add C:/Users/wrh/.ssh/buaws-kuali-rsa
   ssh -A wrh@ec2-52-205-118-191.compute-1.amazonaws.com
else
   eval `ssh-agent -k`
   exit
fi