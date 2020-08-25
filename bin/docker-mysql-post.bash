#!/bin/bash
. constants

SUPPRESS=""
#SUPPRESS="> /dev/null 2>&1"

printf "$YELLOW[$(date)] Waiting for MySQL service on Galera node 1"
# INIT REPL ONCE SLAVE IS UP
RC=1
while [ $RC -eq 1 ]
do
 sleep 1
 printf "."
 docker exec -ti galera_mysql1_1 "/usr/bin/mysqladmin" "ping" "-uroot" "-p$MYSQL_PWD" $SUPPRESS
 RC=$?
done
printf "$LIME_YELLOW\n"

docker exec -ti galera_mysql1_1 "/usr/bin/mysql" "-vvv" "-uroot" "-p$MYSQL_PWD" "-e SET GLOBAL read_only=0" $SUPPRESS
docker exec -ti galera_mysql1_1 "/usr/bin/mysql" "-vvv" "-uroot" "-p$MYSQL_PWD" "-e CREATE USER IF NOT EXISTS root@'%' IDENTIFIED WITH mysql_native_password BY 'root';" $SUPPRESS
docker exec -ti galera_mysql1_1 "/usr/bin/mysql" "-vvv" "-uroot" "-p$MYSQL_PWD" "-e GRANT ALL ON *.* TO root@'%' WITH GRANT OPTION;" $SUPPRESS

printf "$YELLOW[$(date)] Waiting for MySQL service on Galera node 2"
RC=1
while [ $RC -eq 1 ]
do
 sleep 1
 printf "."
 mysqladmin ping -h127.0.0.1 -P13307 -uroot -p$MYSQL_PWD $SUPPRESS
 RC=$?
done
printf "$LIME_YELLOW\n"

printf "$YELLOW[$(date)] Waiting for MySQL service on Galera node 3"
RC=1
while [ $RC -eq 1 ]
do
 sleep 1
 printf "."
 mysqladmin ping -h127.0.0.1 -P13308 -uroot -p$MYSQL_PWD $SUPPRESS
 RC=$?
done
printf "$LIME_YELLOW\n"

printf "$YELLOW[$(date)] Waiting for Galera Cluster Size to reach 3... (i.e. sync)"
RC=1
while [ $RC -lt 1 ]
do
 sleep 1
 printf "."
 RC=$(mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD -e"show status like 'wsrep_cluster_size'" -NB | awk '{print $2}')
done
printf "$LIME_YELLOW\n"

printf "$YELLOW[$(date)] Waiting for MySQL service on Async Replica 1"
RC=1
while [ $RC -eq 1 ]
do
 sleep 1
 printf "."
 mysqladmin ping -h127.0.0.1 -P13309 -uroot -p$MYSQL_PWD $SUPPRESS
 RC=$?
done
printf "$LIME_YELLOW\n"

printf "$POWDER_BLUE[$(date)] Configuring replica 1...$LIME_YELLOW\n"
mysql -h127.0.0.1 -P13309 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='mysql1',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" $SUPPRESS 
mysql -h127.0.0.1 -P13309 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" $SUPPRESS 



printf "$POWDER_BLUE[$(date)] Create additional database(s) on master...['sysbench']$LIME_YELLOW\n"

mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD -e"CREATE USER monitor@'%' identified by 'monitor';" $SUPPRESS
mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%';" $SUPPRESS 
mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" $SUPPRESS 

printf "$POWDER_BLUE$BRIGHT[$(date)] MySQL Provisioning COMPLETE!$NORMAL\n"

