#!/bin/bash

environment=$1

# Set the mongo URI/HOST and any other connection details (except password)
source $(pwd)/initialize.sh $environment

# Set the username and password for the database
source $(pwd)/private.sh $environment

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
