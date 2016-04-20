close=$1

if [ $# -ne 1 ]; then
   eval `ssh-agent -s`
   ssh-add C:/Users/wrh/.ssh/ec2_rsa
   ssh ec2-user@ec2-52-37-253-82.us-west-2.compute.amazonaws.com
else
   eval `ssh-agent -k`
   exit
fi