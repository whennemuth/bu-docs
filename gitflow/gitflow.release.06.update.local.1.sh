
################################################################################################################
# User2: Commit multiple changes to the feature branch and then merge the feature branch into the develop branch
################################################################################################################
cd c:/kc.local2

git checkout -b daffy.1509.feature2 develop

cat > file1.txt <<EOF
line 1
line 2 (daffy)
line 3
EOF

git commit -a -m "Daffy modifying line 2"

cat > file3.txt <<EOF
line 1
line 2
line 3
EOF

git add file3.txt

git commit -m "Daffy adding file3.txt"

cat >> file3.txt <<EOF
line 4
EOF

git commit -a -m "Appending another line to the end of file3.txt"

git checkout develop

git pull bu develop

git merge daffy.1509.feature2

git push bu develop

git tag 1509.feature2 HEAD

git push bu 1509.feature2