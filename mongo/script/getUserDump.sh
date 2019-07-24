#!/bin/bash

environment=$1

# Set the mongo URI/HOST and any other connection details (except password)
source initialize.sh $environment

# Set the username and password for the database
source private.sh $environment

getUserDump() {
  mongodump \
  --out /var/mongo/dump/ \
  --ssl \
  --host $HOST \
  --verbose \
  --authenticationDatabase admin \
  --username $USERNAME \
  --password $PASSWORD \
  -d "${DB}" \
  -c "users" \
  -q '{username:{$in:["dhaywood","wrh","mahichy","mukadder","mkousheh","emauro","smorse","cgagnon"]},name:{$eq:null}},{firstName:1,lastName:1,name:1}'
}

getUserDump
