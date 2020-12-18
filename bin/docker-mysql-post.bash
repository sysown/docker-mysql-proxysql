#!/bin/bash
. constants

printf "$YELLOW[$(date)] Waiting for MySQL service on primary"
# INIT REPL ONCE SLAVE IS UP
RC=1
while [ $RC -eq 1 ]
do
  sleep 1
  printf "."
  mysqladmin ping -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD  > /dev/null 2>&1
  RC=$?
done
printf "$LIME_YELLOW\n"

mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD -e" \
CREATE USER rpl_user@'%' IDENTIFIED BY 'password'; \
GRANT REPLICATION SLAVE, BACKUP_ADMIN ON *.* TO rpl_user@'%'; \
FLUSH PRIVILEGES; \
CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery'; \
SET GLOBAL group_replication_bootstrap_group=ON; \
START GROUP_REPLICATION; \
SET GLOBAL group_replication_bootstrap_group=OFF; \
SELECT * FROM performance_schema.replication_group_members;"

printf "$YELLOW[$(date)] Waiting for MySQL service on replica 1"
# INIT REPL ONCE SLAVE IS UP
RC=1
while [ $RC -eq 1 ]
do
  sleep 1
  printf "."
  mysqladmin ping -h127.0.0.1 -P13307 -uroot -p$MYSQL_PWD > /dev/null 2>&1
  RC=$?
done
printf "$LIME_YELLOW\n"

mysql -h127.0.0.1 -P13307 -uroot -p$MYSQL_PWD -e" \
RESET MASTER; \
CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery'; \
START GROUP_REPLICATION; \
SELECT * FROM performance_schema.replication_group_members;"

printf "$YELLOW[$(date)] Waiting for MySQL service on replica 2"
RC=1
while [ $RC -eq 1 ]
do
  sleep 1
  printf "."
  mysqladmin ping -h127.0.0.1 -P13308 -uroot -p$MYSQL_PWD > /dev/null 2>&1
  RC=$?
done
printf "$LIME_YELLOW\n"

mysql -h127.0.0.1 -P13308 -uroot -p$MYSQL_PWD -e" \
RESET MASTER; \
CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery'; \
START GROUP_REPLICATION; \
SELECT * FROM performance_schema.replication_group_members;"

printf "$YELLOW[$(date)] Adding ProxySQL cluster state monitor script and user:"
mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD < ./conf/mysql/addition_to_sys.sql 2>&1

mysql -h127.0.0.1 -P13306 -uroot -p$MYSQL_PWD -e" \
CREATE USER monitor@'%' identified by 'monitor'; \
GRANT usage,replication client on *.* to monitor@'%'; \
GRANT SELECT on sys.* to monitor@'%';" 2>&1

printf "$POWDER_BLUE$BRIGHT[$(date)] MySQL Provisioning COMPLETE!$NORMAL\n"
