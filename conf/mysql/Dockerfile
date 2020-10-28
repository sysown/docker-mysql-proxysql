# Galera Cluster Dockerfile
FROM ubuntu:18.04
MAINTAINER Nick Vyzas <nick@proxysql.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y  software-properties-common
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA
RUN add-apt-repository 'deb https://releases.galeracluster.com/galera-4/ubuntu bionic main'
RUN add-apt-repository 'deb https://releases.galeracluster.com/mysql-wsrep-8.0/ubuntu bionic main'


RUN apt-get update
RUN apt-get install -y galera-4 galera-arbitrator-4 mysql-wsrep-8.0 rsync

RUN chown -R mysql:mysql /var/lib/mysql
RUN mkdir -p /var/run/mysqld/ && chown -R mysql:mysql /var/run/mysqld

ENTRYPOINT ["mysqld"]
