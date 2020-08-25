#!/bin/bash
. constants

printf "$BRIGHT"
printf "##################################################################################\n"
printf "# Started ProxySQL / Orchestrator / MySQL Docker Cluster Provisioner!            #\n"
printf "##################################################################################\n"
printf "$NORMAL"

sleep 1

docker-compose -p galera up -d --build 
./bin/docker-mysql-post.bash && ./bin/docker-proxy-post.bash

if [[ -z "$1" ]]; then
    ./bin/docker-benchmark.bash
fi
