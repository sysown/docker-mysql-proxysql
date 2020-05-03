#!/bin/bash

function die
{
	printf "Fatal error: $1" >&2
	exit
}

function cp_w_mkdir
{
    local src="$1" dst="$2"
    local d=$(dirname $2)
    (mkdir -p $d && cp "$src" "$dst" ) || die "Error copying from $src to $dst"
}

. constants

printf "$BRIGHT"
printf "##################################################################################\n"
printf "# Started ProxySQL / Orchestrator / MySQL Docker Cluster Provisioner!            #\n"
printf "##################################################################################\n"
printf "$NORMAL"

sleep 1

if [ -z "$PROXYSQL_BIN" ] && [ -x "../proxysql/src/proxysql" ]
then
  PROXYSQL_BIN="../proxysql/src/proxysql"
fi

PROXYSQL_DOCKER_BASE="./conf/proxysql"
DOCKER_PROXYSQL="$PROXYSQL_DOCKER_BASE/usr/bin/proxysql"
PROXYSQL_DOCKERBUILD_EXTRA=
PROXYSQL_DOCKERFILE="$PROXYSQL_DOCKER_BASE/Dockerfile"
REBUILD_DOCKER=${REBUILD_DOCKER:-0}
PROXYSQL_BASE_IMAGE="renecannao/proxysql_205_pltx19:debian9"

if [ "$REBUILD_DOCKER" = "1" ]
then
    rm -f $PROXYSQL_DOCKERFILE
fi

if [ ! -f "$PROXYSQL_DOCKERFILE" ]
then
    if [ -x "$PROXYSQL_BIN" ]
    then
        cp_w_mkdir $PROXYSQL_BIN $DOCKER_PROXYSQL
        PROXYSQL_BASE_IMAGE="spachev/proxysql-debian-stretch"
        PROXYSQL_DOCKERBUILD_EXTRA=$(cat <<'eot'
COPY / /
eot
)
        printf "Found proxysql local binary in $PROXYSQL_BIN, putting it in Docker\n"
    fi

    cat >$PROXYSQL_DOCKERFILE <<eot
FROM $PROXYSQL_BASE_IMAGE
$PROXYSQL_DOCKERBUILD_EXTRA
eot
    REBUILD_DOCKER=1
fi

if [ "$REBUILD_DOCKER" = "1" ]
then
    docker-compose build || die "Error building Docker containers"
fi

docker-compose up -d || die "Error bringing Docker containers up"
(./bin/docker-mysql-post.bash && ./bin/docker-orchestrator-post.bash && ./bin/docker-restart-binlog_reader.bash && ./bin/docker-proxy-post.bash) || die "Error running setup"

if [[ -z "$1" ]]; then
    ./bin/docker-benchmark.bash || die "Error running the benchmark"
fi
