close=$1

if [ $# -ne 1 ]; then
   eval `ssh-agent -s`
   ssh-add C:/Users/wrh/.ssh/jenkins_vm_id_rsa
   ssh warren@jenkinsvm2
else
   eval `ssh-agent -k`
   exit
fi