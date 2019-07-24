#!/bin/bash

build() {
  docker build -t mongoclient .
}

run() {
  mkdir script 2> /dev/null
  mkdir dump 2> /dev/null
  winpty docker run \
    -ti \
    -v c:\\whennemuth\\documentation\\bu\\mongo\\dump:/var/mongo/dump \
    -v c:\\whennemuth\\documentation\\bu\\mongo\\script:/var/mongo/script \
    -p 27017:27017 \
    mongoclient
}

cleanup() {
  docker rm -f $(docker ps -a --filter Ancestor=mongoclient -q) 2> /dev/null
  docker rmi $(docker images -a --filter dangling=true -q) 2> /dev/null
}
