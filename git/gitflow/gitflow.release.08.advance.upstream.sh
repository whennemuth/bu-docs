
###################################################################################################
# Pretend we are the kuali.org team and update the 1509.57 to the new release of 1510.31 and tag it
###################################################################################################
cd "`dirname $0`/kc.kuali.org/"

cat > file1.txt <<EOF
line 1
line 2 (conflicting change by kuali.org)
line 3
EOF

git commit -a -m "kuali.org modifying line 2 for file1.txt"

cat > file2.txt <<EOF
line 1
line 2 (kuali 1510 change)
line 3
EOF

git commit -a -m "kuali.org modifying line 2 for file2.txt"

cat > file5.txt <<EOF
line 1
line 2
line 3
EOF

git add file5.txt

git commit -m "Kuali user adding file5.txt"

cat >> file5.txt <<EOF
line 4
EOF

git commit -a -m "Appending another line to the end of file5.txt"

git tag 1510.31 HEAD