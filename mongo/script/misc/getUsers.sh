#!/bin/bash

environment=$1

# Set the mongo URI/HOST and any other connection details (except password)
source $(pwd)/initialize.sh $environment

# Set the username and password for the database
source $(pwd)/private.sh $environment

getUsers() {
  mongo \
  --ssl \
  --host $URI \
  --verbose \
  --authenticationDatabase admin \
  --username $USERNAME \
  --password $PASSWORD \
  --eval 'db.getCollection("users").find({username:{$in:["dhaywood","wrh","mahichy","mukadder","mkousheh","emauro","smorse","cgagnon"]},name:{$eq:null}},{firstName:1,lastName:1,name:1})'
}

getUsers
