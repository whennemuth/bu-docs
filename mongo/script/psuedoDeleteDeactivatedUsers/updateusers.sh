#!/bin/bash

environment=$1

# Set the mongo URI/HOST and any other connection details (except password)
source ../initialize.sh $environment

# Set the username and password for the database
source ../private.sh $environment

# getUsers() {
#   mongo \
#   --ssl \
#   --host $URI \
#   --verbose \
#   --authenticationDatabase admin \
#   --username $USERNAME \
#   --password $PASSWORD \
#   updateusers.js
#   # --eval 'db.getCollection("users").find({username:{$in:["dhaywood","wrh","mahichy","mukadder","mkousheh","emauro","smorse","cgagnon"]},name:{$eq:null}},{firstName:1,lastName:1,name:1})'
# }

# getUsers |& tee getUsers.log

updateUsers() {
  mongo \
  --ssl \
  --host $URI \
  --quiet \
  --authenticationDatabase admin \
  --username $USERNAME \
  --password $PASSWORD \
  updateusers.js
}

updateUsers |& tee updateUsers.log
