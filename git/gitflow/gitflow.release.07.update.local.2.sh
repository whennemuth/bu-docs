
################################################################################################################
# User1: Commit multiple changes to the feature branch and then merge the feature branch into the develop branch
################################################################################################################
cd "`dirname $0`/kc.local1"

git checkout -b bugs.1509.feature1 develop

cat > file1.txt <<EOF
line 1
line 2 (bugs)
line 3
EOF

git commit -a -m "Bugs modifying line 2"

cat > file4.txt <<EOF
line 1
line 2
line 3
EOF

git add file4.txt

git commit -m "Bugs adding file4.txt"

cat >> file4.txt <<EOF
line 4
EOF

git commit -a -m "Appending another line to the end of file4.txt"

git checkout develop

git pull bu develop

####### Check if fast-forward merge is possible
git merge --ff-only bugs.1509.feature1

####### fast-forward not possible so get a preview of the differences between branches
git diff HEAD bugs.1509.feature1

git merge bugs.1509.feature1

cat > file1.txt <<EOF
line 1
line 2 (daffy+bugs merge)
line 3
EOF

git commit -a -m "Merging daffys changes into mine (bugs bunny)"

git push bu develop

git tag 1509.feature1and2 HEAD

git push bu 1509.feature1and2