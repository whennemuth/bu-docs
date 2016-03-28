close=$1

if [ $# -ne 1 ]; then
   eval `ssh-agent -s`
   ssh-add C:/Users/wrh/.ssh/ec2_rsa
   ssh centos@ec2-54-187-62-124.us-west-2.compute.amazonaws.com
else
   eval `ssh-agent -k`
   exit
fi