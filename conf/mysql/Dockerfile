# Galera Cluster Dockerfile
FROM ubuntu:18.04
MAINTAINER Nick Vyzas <nick@proxysql.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA && \
    add-apt-repository 'deb https://releases.galeracluster.com/galera-4/ubuntu bionic main' && \
    add-apt-repository 'deb https://releases.galeracluster.com/mysql-wsrep-8.0/ubuntu bionic main' && \
    apt-get update && \
    apt-get install -y galera-4 galera-arbitrator-4 mysql-wsrep-8.0 rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN chown -R mysql:mysql /var/lib/mysql && \
    mkdir -p /var/run/mysqld/ && \
    chown -R mysql:mysql /var/run/mysqld

ENTRYPOINT ["mysqld"]
