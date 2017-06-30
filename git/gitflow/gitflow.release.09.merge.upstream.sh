
##################################################################
# Merge the new 1510 release from kuali.org/kc into the dev branch
##################################################################
cd "`dirname $0`/kc.local1"

####### 1) Pull the master branch from upstream (kuali.org/kc).
git checkout master

git pull upstream master

####### 2) At this point the local dev branch should be identical too both the dev and release branch on origin (bu-master), 
#######    but pull from it just to make sure.
git checkout develop

git pull bu develop

####### 3) Merge the upstream release with a copy of the develop branch (which is now up to date with all customizations).
git checkout -b develop-1510 develop

git merge --squash master

####### 4) Fix the conflict in file1.txt and commit
cat file1.txt

cat > file1.txt <<EOF
line 1
line 2 (daffy+bugs+kuali merge)
line 3
EOF

git commit -a -m "Fixed conflicts in 1510 merge"

####### 5) Once the copied branch has been successfully merged into, merge it in turn to the original develop branch and tag it.
git checkout develop

git merge --ff-only develop-1510

git tag "RELEASE-1510" HEAD

####### 6) Delete the copied branch.
git branch -d develop-1510

####### 7) Push the merged result (with tags) to our origin remote.
git push --follow-tags bu develop

####### 8) Now merge the develop branch into the release (bu-master) branch. It should be fast-forward
git checkout bu-master

git merge --ff-only develop

git push --follow-tags bu bu-master

####### 8) View the log and tags
git tag

git log --oneline --decorate=full

git log --oneline --graph


