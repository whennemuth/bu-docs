
####################################################################################################
# User 1: Create the local repositories and put in the missing branches and remote tracking branches
####################################################################################################
cd "`dirname $0`"

rm -f -r kc.local1

git clone -o bu -b develop kc.bu-ist/ kc.local1

cd kc.local1/

git config user.name "Bugs Bunny"

git config user.email "bugs@warnerbros.com"

git remote add upstream ../kc.kuali.org/

git fetch upstream master

git checkout -b master upstream/master

git fetch bu bu-master

git checkout -b bu-master bu/bu-master

####################################################################################################
# User 2: Create the local repositories and put in the missing branches and remote tracking branches
####################################################################################################
cd ..

rm -f -r kc.local2

git clone -o bu -b develop kc.bu-ist/ kc.local2

cd kc.local2/

git config user.name "Daffy Duck"

git config user.email "daffy@warnerbros.com"

git remote add upstream ../kc.kuali.org/

git fetch upstream master

git checkout -b master upstream/master

git fetch bu bu-master

git checkout -b bu-master bu/bu-master

git branch -a