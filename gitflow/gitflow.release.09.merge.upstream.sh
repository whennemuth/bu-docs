
##############################################
# Merge the new 1510 release from kuali.org/kc 
##############################################
cd "`dirname $0`/kc.local1"

####### 1) Pull the master branch from upstream (kuali.org/kc).
git checkout master

git pull upstream master

####### 2) bu-master should be unchanged, but refresh it just in case.
git checkout bu-master

git pull bu bu-master

####### 3) Assume the develop branch is always a direct descendent of the bu-master branch, and hence merging should be fast-forward.
git merge --ff-only develop

####### 4) Merge the upstream release with a copy of the bu-master branch (which is now up to date with all customizations).
git checkout -b bu-master-1510 bu-master

# git merge --squash master
git merge master

####### 5) Fix the conflict in file1.txt and commit
cat file1.txt

cat > file1.txt <<EOF
line 1
line 2 (daffy+bugs+kuali merge)
line 3
EOF

git commit -a -m "Fixed conflicts in 1510 merge"

####### 6) Once the copied branch has been successfully merged into, merge it in turn to the original bu-master branch and tag it.
git checkout bu-master

git merge --ff-only bu-master-1510

git tag "RELEASE-1510" HEAD

####### 7) Delete the copied branch.
git branch -d bu-master-1510

####### 8) Push the merged result (with tags) to our origin remote.
git push --follow-tags bu bu-master

####### 9) View the log and tags
git tag

git log --oneline --decorate=full

git log --oneline --graph


