#!/bin/bash

environment=$1

case $environment in
  "sb"|"sandbox")
    REPLSET="sb-cluster-shard-0"
    DB="core-development"
    SHARDS="sb-cluster-shard-00-00-ozx2o.mongodb.net:27017,\
sb-cluster-shard-00-01-ozx2o.mongodb.net:27017,\
sb-cluster-shard-00-02-ozx2o.mongodb.net:27017"
    HOST="${REPLSET}/${SHARDS}"
    URI="mongodb://${SHARDS}/${DB}?replicaSet=${REPLSET}" ;;
  "ci")
    REPLSET="ci-cluster-shard-0"
    DB="core-development"
    SHARDS="ci-cluster-shard-00-00-nzjcq.mongodb.net:27017,\
ci-cluster-shard-00-01-nzjcq.mongodb.net:27017,\
ci-cluster-shard-00-02-nzjcq.mongodb.net:27017"
    HOST="${REPLSET}/${SHARDS}"
    URI="mongodb://${SHARDS}/${DB}?replicaSet=${REPLSET}" ;;
  "qa")
    REPLSET="qa-cluster-shard-0"
    DB="core-development"
    SHARDS="qa-cluster-shard-00-00-uskeb.mongodb.net:27017,\
qa-cluster-shard-00-01-uskeb.mongodb.net:27017,\
qa-cluster-shard-00-02-uskeb.mongodb.net:27017"
    HOST="${REPLSET}/${SHARDS}"
    URI="mongodb://${SHARDS}/${DB}?replicaSet=${REPLSET}" ;;
  "stg"|"stage"|"staging")
    REPLSET="stg-cluster-shard-0"
    DB="core-development"
    SHARDS="stg-cluster-shard-00-00-yzl76.mongodb.net:27017,\
stg-cluster-shard-00-01-yzl76.mongodb.net:27017,\
stg-cluster-shard-00-02-yzl76.mongodb.net:27017"
    HOST="${REPLSET}/${SHARDS}"
    URI="mongodb://${SHARDS}/${DB}?replicaSet=${REPLSET}" ;;
  "prod"|"production")
    REPLSET="prod-cluster-shard-0"
    DB="core-development"
    SHARDS="prod-cluster-shard-00-00-v4dbc.mongodb.net:27017,\
prod-cluster-shard-00-01-v4dbc.mongodb.net:27017,\
prod-cluster-shard-00-02-v4dbc.mongodb.net:27017"
    HOST="${REPLSET}/${SHARDS}"
    URI="mongodb://${SHARDS}/${DB}?replicaSet=${REPLSET}" ;;
esac    
