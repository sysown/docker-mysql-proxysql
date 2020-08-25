#!/bin/bash
. constants

printf "$BRIGHT"
printf "##################################################################################\n"
printf "# Stopping ProxySQL / Orchestrator / MySQL Docker Cluster instances!             #\n"
printf "##################################################################################\n"
printf "$NORMAL"

docker-compose -p galera stop
docker-compose -p galera rm -f
docker volume prune -f
docker network prune -f
printf "$POWDER_BLUE$BRIGHT[$(date)] Deprovisioning COMPLETE!$NORMAL\n"

