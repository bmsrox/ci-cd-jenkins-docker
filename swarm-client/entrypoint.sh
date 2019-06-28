#!/bin/sh
set -e

SERVERNAME="${SERVERNAME:-docker}"
EXECUTORS="${EXECUTORS:-3}"
FSROOT="${FSROOT:-/tmp/jenkins}"

mkdir -p $FSROOT
java -jar swarm-client.jar -labels=$SERVERNAME -executors=$EXECUTORS -fsroot=/tmp/jenkins -name=$SERVERNAME-$(hostname) $(cat /run/secrets/jenkins)