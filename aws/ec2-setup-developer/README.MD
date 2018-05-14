# Developer environment setup on AWS for Kuali Research (incomplete) #

#### The following are instruction on how to quickly setup kc monolith on a brand new AWS EC2 instance for remote java debugging. ####

#### Depending on the resources available on you local development machine, it may be useful to have the option to quickly setup an environment on an AWS instance and connect you local eclipse/IntelliJ launch configurations to the VM running kc there. Modifications to the codebase could be made and tested in either of two ways: ####

1. Local to remote
   - The codebase is modified locally
   - The code is transferred to the ec2 instance through rsync or git push/pull
   - The codebase is repackaged by maven on the ec2 instance
   - Tomcat is restarted on the ec2 instance
2. Remote only
   - The codebase is modified on the ec2 instance
   - The codebase is repackaged by maven on the ec2 instance
   - The modified codebase is transferred to the local environment via rsync or git push/pull
   - Tomcat is restarted on the ec2 instance

### Steps ###

------

1. **Create a key pair for the AWS ec2 instance and an alias to use it.**

   ```
   cd ~/.ssh
   ssh-keygen -b 2048 -t rsa -f [name of key] -q -N ""
   echo "alias mydevbox='ssh -i ~/.ssh/[name of key] ec2-user@[private ip of ec2 instance]'" >> ~/.bashrc
   source ~/.bashrc
   ```

   - In AWS go to:  `NETWORK & SECURITY --> Key Pairs --> Import Key Pair...`
   - Paste the contents of the public key file into the field provided and click "import"

2. **Create a new ec2 instance on AWS.**

   1. Select an instance type that has enough resources so builds and runtime performance equal or exceed that available in your local environment. Suggested minimum is m4.xlarge
      - AMI: Amazon Linux AMI 64 bit
      - Type: m4.xlarge or better
      - Network: buaws-kuali-vpc-test
      - Subnet: app-sb-azc | us-east-1c
      - IAM Role: ec2RunCommandRole
      - Storage 32GB
      - Tags: Name=[something indicates you are the owner, ex: `buaws-myname-kuali-001`]
      - Security Group: app-sg-sb
   2. Click "launch instance"
   3. You will be presented with the option to create a new ssh key of select from an existing list. Select from one from the list the private key you uploaded.

3. **Shell into the EC2 instance**.
   From now on use only the following command to shell in.

   ```
   mydevbox
   Warning: Permanently added '10.57.237.89' (ECDSA) to the list of known hosts.

          __|  __|_  )
          _|  (     /   Amazon Linux AMI
         ___|\___|___|
         
   ```

4. **Download scripts from github**

   ```
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
   ```

5. **Open setup.properties and modify property values appropriately.** 
   The following properties cannot be left blank:

   - GIT_BU_USER & GIT_BU_PASSWORD
     or...
   - GIT_BU_KEY
     and...
   - GIT_KUALICO_PASSWORD
   - GIT_BU_REFSPEC
   - DB_PASSWORD

6. **Install all software - java, tomcat, maven, and all kuali modules.**
   Installing a kuali module means pulling from git and building it with maven

   ```
   # Become root and install basic software
   sudo su root
   source setup.sh
   install

   # Return to ec2-user and build kuali
   exit
   build
   ```

7. **Run coeus-webapp under tomcat with remote debugging accomodated.**

   ```
   sudo su root
   source setup.sh
   run
   ```

8. **Install rsync locally.**
   Rsync is the best option to synchronize source files and libraries between your local development environment and the EC2 instance because it only transfers the delta between the two endpoints.

   - If running on windows and using git bash, install the Git for Windows SDK:
     https://github.com/git-for-windows/build-extra/releases

   - Navigate to the root of the installation and run mingw64.exe:

     ```
     # Install rsync:
     pacman -Sy
     pacman -S rsync
     ```

     ​

9. Next step

10. Next step


