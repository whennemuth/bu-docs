close=$1

if [ $# -ne 1 ]; then
   eval `ssh-agent -s`
   ssh-add C:/Users/wrh/.ssh/buaws-kuali-rsa
   ssh -A wrh@ec2-54-172-65-242.compute-1.amazonaws.com
else
   eval `ssh-agent -k`
   exit
fi