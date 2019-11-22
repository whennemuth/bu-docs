#!/bin/bash

environment=$1

# Set the mongo URI/HOST and any other connection details (except password)
source $(pwd)/initialize.sh $environment

# Set the username and password for the database
source $(pwd)/private.sh $environment

getUserExport() {
  mongoexport \
  --out /var/mongo/dump/users.json \
  --ssl \
  --host $HOST \
  --verbose \
  --authenticationDatabase admin \
  --username $USERNAME \
  --password $PASSWORD \
  -d "${DB}" \
  -c "users" \
  -f "firstName,lastName,name" \
  -q '{username:{$in:["dhaywood","wrh","mahichy","mukadder","mkousheh","emauro","smorse","cgagnon"]},name:{$eq:null}}'
}

getUserExport
