# Developer environment setup on AWS for Kuali Research #

#### The following are instruction on how to quickly setup kc monolith on a brand new AWS EC2 instance for remote java debugging. ####

#### Depending on the resources available on you local development machine, it may be useful to have the option to quickly setup an environment on an AWS instance and connect you local eclipse/IntelliJ launch configurations to the VM running kc there. Modifications to the codebase could be made and tested in either of two ways: ####
<ol>
  <li> <b>Local to remote</b>
    <ol>
      <li type="a">The codebase is modified locally</li>
      <li type="a">The code is transferred to the ec2 instance through rsync or git push/pull</li>
      <li type="a">The codebase is repackaged by maven on the ec2 instance</li>
      <li type="a">Tomcat is restarted on the ec2 instance</li>
    </ol>
  </li>
  <li> <b>Remote only</b>
    <ol>
      <li type="a">The codebase is modified on the ec2 instance</li>
      <li type="a">The codebase is repackaged by maven on the ec2 instance</li>
      <li type="a">The modified codebase is transferred to the local environment via rsync or git push/pull</li>
      <li type="a">Tomcat is restarted on the ec2 instance</li>
    </ol>
  </li>
</ol>

### Steps ###
<ol style=" font-family:arial; font-size: 16px;">
  <li>Create a key pair for the AWS ec2 instance and an alias to use it.
      <br><pre>
cd ~/.ssh
ssh-keygen -b 2048 -t rsa -f [name of key] -q -N ""
echo "alias mydevbox='ssh -i ~/.ssh/[name of key] ec2-user@[private ip of ec2 instance]'" >> ~/.bashrc
source ~/.bashrc</pre>
      In AWS go to: <code>NETWORK & SECURITY --> Key Pairs --> Import Key Pair...</code><br>
      Paste the contents of the public key file into the field provided and click "import"  <br><br>
  </li>

  <li>Create a new ec2 instance on AWS
    <ol>
      <li type="a">Select an instance type that has enough resources so builds and runtime performance equal or exceed that available in your local environment. Suggested minimum is m4.xlarge.<br>
      <ul>
        <li>AMI: Amazon Linux AMI 64 bit</li>
        <li>Type: m4.xlarge or better</li>
        <li>Network: buaws-kuali-vpc-test</li>
        <li>Subnet: app-sb-azc | us-east-1c</li>
        <li>IAM Role: ec2RunCommandRole</li>
        <li>Storage 32GB</li>
        <li>Tags: Name=[something indicates you are the owner, ex: "buaws-myname-kuali-001"]</li>
        <li>Security Group: app-sg-sb</li>
      </ul>
      </li>
      <li type="a">Click "launch instance"</li>
      <li type="a">You will be presented with the option to create a new ssh key of select from an existing list. Select from one from the list the private key you uploaded.
      </li>
    </ol>
  </li><br>

  <li>Create a new ec2 instance on AWS
      <br><pre>
# From now on use only the following command to shell in.
mydevbox
Warning: Permanently added '10.57.237.89' (ECDSA) to the list of known hosts.

       __|  __|_  )
       _|  (     /   Amazon Linux AMI
      ___|\___|___|

</pre>
  </li><br>

  <li>Open setup.properties and modify property values appropriately. <br>
      The following properties cannot be left blank:<br>
    <ul>
      <li>GIT_BU_USER & GIT_BU_PASSWORD<br>
      or...
      <li>GIT_BU_KEY<br>
      and...
      <li>GIT_KUALICO_PASSWORD</li>
      <li>GIT_BU_REFSPEC</li>
      <li>DB_PASSWORD</li>
    </ul>
  </li><br>

  <li>Download scripts from github<br>
      <pre>
# Pull the bash scripts and supporting "build context" items from git
sudo yum -y update
sudo yum install -y git-all
sudo mkdir -p /opt/kuali-setup
sudo chown ec2-user /opt/kuali-setup
cd /opt/kuali-setup/
git init
git remote add github https://github.com/bu-ist/kuali-research-docker.git
git config core.sparsecheckout true
echo aws/ec2-setup-developer/ >> .git/info/sparse-checkout
cd aws/ec2-setup-developer
git pull github master
</pre>
  </li>

  <li>Install all software - java, tomcat, maven, and all kuali modules<br>
    Installing a kuali module means pulling from git and building it with maven<br>
    <pre>
# Become root and install basic software
sudo su root
source setup.sh
install

# Return to ec2-user and build kuali
exit
build</pre>
  </li>
  
  <li>
    Run coeus-webapp under tomcat with remote debugging accomodated.<br>
    <pre>
sudo su root
source setup.sh
run</pre>
  </li>

  <li>
    Rsync is the best option to synchronize source files and libraries between your local development environment and the EC2 instance because it only transfers the delta between the two endpoints.
    <ol>
      <li type="a">
        If running on windows and using git bash, install the Git for Windows SDK:<br>   <code>https://github.com/git-for-windows/build-extra/releases</code><br>
      </li>
      <li type="a">
        Navigate to the root of the installation and run mingw64.exe:<br>
        <pre># Install rsync:
pacman -Sy
pacman -S rsync</pre>
      </li>
    </ol>
  </li>

</ol>
