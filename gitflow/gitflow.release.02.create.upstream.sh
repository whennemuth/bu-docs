
################################################
# Create the upstream (kualia.org/kc) repository
################################################
cd "`dirname $0`"

rm -f -r kc.kuali.org

mkdir kc.kuali.org

cd kc.kuali.org/

git init

git config user.name "kuali.org user"

git config user.email "user@kuali.org"

cat > file1.txt <<EOL
line 1
line 2
line 3
EOL

cat > file2.txt <<EOL
line 1
line 2
line 3
EOL

git add --all

git commit -m "1509.57 commit by kc.kuali.org"

git tag 1509.57 HEAD