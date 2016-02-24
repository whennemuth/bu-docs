
###########################################
# Create the downstream (bu-ist) repository
###########################################
cd "`dirname $0`"

rm -f -r kc.bu-ist

git clone -o upstream kc.kuali.org/ kc.bu-ist

cd kc.bu-ist/

git branch develop HEAD

git branch bu-master HEAD

git branch -a