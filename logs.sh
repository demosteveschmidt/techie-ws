#!/bin/bash

if [ "$1" == "" ]
then
  echo "usage: $0 image-build-pod-name"
  exit 1
fi

BLUE="\033[0;36m"; NORM="\033[0m"

POD="$1"

CONTAINERS=$(kubectl get pod $POD -o json | jq ".spec.initContainers[].name" | tr -d '"')

for container in $CONTAINERS completion
do
  echo ""; echo -e "${BLUE}---- $container ----${NORM}"; echo ""
  kubectl logs $POD -c $container -f
  if [ $container != "completion" ]
  then
    read -p "[Enter to continue]" ans
  fi
done
