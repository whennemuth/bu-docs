#!/bin/bash

getValue() {
  return "hello";
}

function echoValue() {
  getValue

  VAL="$1"
  echo $VAL
}

echoValue
