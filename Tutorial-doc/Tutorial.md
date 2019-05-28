## Get familiar with the system

```
mysql -uradmin -pradmin -h127.0.0.1 --prompt 'Admin> ' -P16032
```
```
\s
SELECT @@version;
SHOW DATABASES;
SHOW TABLES;
SHOW TABLES FROM main;
SHOW TABLES FROM disk;
SHOW TABLES FROM stats;
SHOW TABLES FROM monitor;
SHOW TABLES FROM stats_history;
SELECT name AS tables FROM sqlite_master WHERE type='table';
SELECT name AS tables FROM disk.sqlite_master WHERE type='table';
```
```
SHOW CREATE TABLE mysql_users\G
SHOW CREATE TABLE disk.mysql_users\G
SHOW CREATE TABLE runtime_mysql_users\G
SHOW CREATE TABLE mysql_servers\G
SHOW CREATE TABLE disk.mysql_servers\G
SHOW CREATE TABLE runtime_mysql_servers\G
SHOW CREATE TABLE mysql_replication_hostgroups\G
SHOW CREATE TABLE disk.mysql_replication_hostgroups\G
SHOW CREATE TABLE runtime_mysql_replication_hostgroups\G
```
```
SHOW VARIABLES;
SELECT * FROM global_variables;
SHOW ADMIN VARIABLES;
SELECT * FROM global_variables WHERE variable_name LIKE 'admin%';
SHOW MYSQL VARIABLES;
SHOW VARIABLES LIKE '%monitor%timeout';
```

Repeat the same on other 2 proxysql instances.
```
mysql -uradmin -pradmin -h127.0.0.1 -P16042
mysql -uradmin -pradmin -h127.0.0.1 -P16052
```


## Create a user on first proxysql instance:

Try to connect to ProxySQL:
```
mysql -uroot -proot -h 127.0.0.1 -P16033
```

Create user:
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
```
```
INSERT INTO mysql_users (username,password,active) values ('root','root',1);
```

Try to connect to ProxySQL:
```
mysql -uroot -proot -h 127.0.0.1 -P16033
```

Manage user:
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
```
```
SELECT * FROM mysql_users;
SELECT * FROM runtime_mysql_users;
SELECT * FROM disk.mysql_users;
LOAD MYSQL USERS TO RUNTIME;
SELECT * FROM runtime_mysql_users;
SAVE MYSQL USERS TO DISK;
SELECT * FROM disk.mysql_users;
```

Try to connect to ProxySQL:
```
mysql -uroot -proot -h 127.0.0.1 -P16033
```

Try to connect on other 2 instances:
```
mysql -uroot -proot -h 127.0.0.1 -P16043
```
```
mysql -uroot -proot -h 127.0.0.1 -P16053
```

## Enabling cluster
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
```
```
SHOW VARIABLES LIKE 'admin-cluster%';

SET admin-cluster_username='radmin';
SET admin-cluster_password='radmin';
LOAD ADMIN VARIABLES TO RUNTIME;
SAVE ADMIN VARIABLES TO DISK;

SELECT * FROM proxysql_servers;
SHOW CREATE TABLE proxysql_servers\G

INSERT INTO proxysql_servers (hostname) VALUES ('proxysql1'),('proxysql2'),('proxysql3');
LOAD PROXYSQL SERVERS TO RUNTIME;
SAVE PROXYSQL SERVERS TO DISK;

SHOW TABLES FROM stats;
SELECT * FROM stats_proxysql_servers_checksums;
```

Note: check at `epoch`, `version`, and `diff_check`.


```
mysql -uradmin -pradmin -h127.0.0.1 -P16042
SELECT * FROM proxysql_servers;
SELECT * FROM stats_proxysql_servers_checksums;
source conf/proxysql/enable_cluster.sql
```

```
mysql -uradmin -pradmin -h127.0.0.1 -P16052
SELECT * FROM proxysql_servers;
SELECT * FROM stats_proxysql_servers_checksums;
source conf/proxysql/enable_cluster.sql

```

## Configure backends

```
mysql -uradmin -pradmin -h127.0.0.1 -P16032 --prompt='Admin1> '
```

```
DELETE FROM mysql_servers;
INSERT INTO mysql_servers (hostgroup_id,hostname,port,max_replication_lag) VALUES (1,'mysql1',3306,1);
INSERT INTO mysql_servers (hostgroup_id,hostname,port,max_replication_lag) VALUES (1,'mysql2',3306,1);
INSERT INTO mysql_servers (hostgroup_id,hostname,port,max_replication_lag) VALUES (1,'mysql3',3306,1);
SELECT * FROM mysql_servers;
SELECT * FROM disk.mysql_servers;
SELECT * FROM runtime_mysql_servers;
LOAD MYSQL SERVERS TO RUNTIME;
SELECT * FROM disk.mysql_servers;
SELECT * FROM runtime_mysql_servers;
SAVE MYSQL SERVERS TO DISK;
SELECT * FROM disk.mysql_servers;
SELECT * FROM runtime_mysql_servers;
SHOW TABLES FROM monitor;
SELECT * FROM mysql_server_read_only_log;
SELECT * FROM mysql_server_replication_lag_log;
```

Verify the same on other proxies.
```
SELECT * FROM stats_proxysql_servers_checksums WHERE name='mysql_servers';
```

Verify monitor.
```
SHOW TABLES FROM monitor;
SELECT * FROM mysql_server_ping_log;
SHOW VARIABLES LIKE '%mon%ping%';
```

```
SELECT * FROM mysql_replication_hostgroups;
SHOW CREATE TABLE mysql_replication_hostgroups\G
DELETE FROM mysql_replication_hostgroups;
INSERT INTO mysql_replication_hostgroups (writer_hostgroup,reader_hostgroup,comment) VALUES (0,1,'');
SELECT * FROM mysql_replication_hostgroups;
SELECT * FROM runtime_mysql_replication_hostgroups;
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
SELECT * FROM runtime_mysql_replication_hostgroups;
SELECT * FROM mysql_servers;
SELECT * FROM runtime_mysql_servers;
SELECT * FROM disk.mysql_servers;
SHOW TABLES FROM monitor;
SELECT * FROM mysql_server_read_only_log;
SELECT * FROM mysql_server_replication_lag_log;
```



### Rollback of mistakes in ProxySQL Cluster
```
mysql -uradmin -pradmin -h127.0.0.1 -P16052 --prompt='Admin3> '
```

```
SELECT * FROM mysql_servers;
SELECT * FROM runtime_mysql_servers;
SELECT * FROM disk.mysql_servers;
DELETE FROM mysql_servers;
LOAD MYSQL SERVERS TO RUNTIME;
SELECT * FROM mysql_servers;
SELECT * FROM runtime_mysql_servers;

```

```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
SELECT * FROM mysql_servers;
SELECT * FROM runtime_mysql_servers;
SELECT * FROM disk.mysql_servers;
```

```
mysql -uradmin -pradmin -h127.0.0.1 -P16052
SELECT * FROM disk.mysql_servers;
LOAD MYSQL SERVERS FROM DISK;
LOAD MYSQL SERVERS TO RUNTIME;

SELECT * FROM stats_proxysql_servers_checksums;
```

## Query rules

```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
SELECT * FROM mysql_query_rules\G
SHOW CREATE TABLE mysql_query_rules\G
INSERT INTO mysql_query_rules (rule_id,active,match_digest,destination_hostgroup,apply) VALUES (1,1,'^SELECT.*FOR UPDATE',0,1),(2,1,'^SELECT',1,1);
SELECT * FROM mysql_query_rules;
SELECT * FROM mysql_query_rules\G
SELECT * FROM runtime_mysql_query_rules;
SELECT * FROM disk.mysql_query_rules;
SELECT * FROM stats_proxysql_servers_checksums WHERE name='mysql_query_rules';
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
SELECT * FROM runtime_mysql_query_rules;
SELECT * FROM stats_proxysql_servers_checksums WHERE name='mysql_query_rules';

```


### Testing multiplexing

```
mysql -uradmin -pradmin -h127.0.0.1 -P16032 -e 'SELECT * FROM stats_mysql_connection_pool WHERE Queries > 0;'
```
```
for i in `seq 1 20` ; do echo "SELECT @@hostname;" ; done | mysql -uroot -proot -h 127.0.0.1 -P16033 -N -B -e "SELECT @@hostname" 2> /dev/null | sort | uniq -c
```
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032 -e 'SELECT * FROM stats_mysql_connection_pool WHERE Queries > 0;'
```
```
for i in `seq 1 20` ; do mysql -uroot -proot -h 127.0.0.1 -P16033 -N -B -e "SELECT @@hostname" 2> /dev/null ; done | sort | uniq -c
```
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032 -e 'SELECT * FROM stats_mysql_connection_pool WHERE Queries > 0;'
```
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032 -e 'SELECT * FROM stats_mysql_connection_pool_reset WHERE Queries > 0;'
```



## read/write split
```
mysql -uroot -proot -h127.0.0.1 -P16033

source ./conf/mysql/mysql1/perconalive_schema.sql

use perconalive
SHOW TABLES;
INSERT INTO customer VALUES (NULL, '987-65-4321');
SELECT * FROM customer;
```


```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
SELECT * FROM stats_mysql_query_rules;
SELECT hostgroup, digest_text, count_star FROM stats_mysql_query_digest;
SELECT * FROM stats_mysql_query_digest WHERE hostgroup = 0;
SELECT * FROM stats_mysql_query_digest WHERE hostgroup = 1;
SELECT hostgroup, SUM(count_star) , SUM(sum_time), COUNT(DISTINCT digest) FROM stats_mysql_query_digest GROUP BY hostgroup ORDER BY SUM(sum_time) LIMIT 3;
```


## query rewrite
```
INSERT INTO mysql_query_rules (rule_id,active,match_pattern,replace_pattern,destination_hostgroup,apply)
          VALUES (3,1,'^select (.*)sensitive_number([ ,])(.*)',
                "SELECT \1CONCAT(REPEAT('X',8),RIGHT(sensitive_number,4)) sensitive_number\2\3",0,1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

```
mysql -uroot -proot -h127.0.0.1 -P16033
use perconalive
SELECT id, sensitive_number FROM customer;
```

```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
SELECT * FROM mysql_query_rules\G


UPDATE mysql_query_rules SET active=0 WHERE rule_id=2;
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;

```

```
mysql -uroot -proot -h127.0.0.1 -P16033
use perconalive
SELECT id, sensitive_number FROM customer;
```

## Mirror queries

```
INSERT INTO mysql_query_rules (rule_id,active,match_pattern,mirror_flagOUT,apply) VALUES (4,1,'^insert into customer(.*)',5,1);
mysql -uradmin -pradmin -h127.0.0.1 -P16032
INSERT INTO mysql_query_rules (rule_id,active,match_pattern,replace_pattern,flagIN,apply) VALUES (5,1,'^insert into customer(.*)',"INSERT INTO perconalive.audit (`user_name`, `table_name`) VALUES (USER(), 'customer')",5,1);

LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

```
mysql -uroot -proot -h127.0.0.1 -P16033
use perconalive
SELECT * FROM customer;
SELECT * FROM audit;
INSERT INTO customer VALUES (NULL, '987-65-4321');
SELECT * FROM customer;
SELECT * FROM audit;
```

```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
SELECT * FROM stats_mysql_query_rules;

SELECT hostgroup, digest_text, count_star FROM stats_mysql_query_digest;
```

## Enable audit log
```
mysql -uradmin -pradmin -h127.0.0.1 -P16032
```
```
SHOW VARIABLES LIKE '%audit%';
SET mysql-auditlog_filename='audit.log';
LOAD MYSQL VARIABLES TO RUNTIME;
SAVE MYSQL VARIABLES TO DISK;
```

```
mysql -uroot -proot -h 127.0.0.1 -P16033 -e "SELECT 1; SELECT SLEEP(0.2);"
```


```
docker exec docker-mysql-proxysql_proxysql1_1 ls -l /var/lib/proxysql/
docker exec docker-mysql-proxysql_proxysql1_1 cat /var/lib/proxysql/audit.log.00000001
```




## MySQL failover with Orchestrator

```
export ORCHESTRATOR_API="http://localhost:23101/api http://localhost:23102/api http://localhost:23103/api"

orchestrator-client -c topology -a $(orchestrator-client -c clusters)

mysql -uroot -proot -h 127.0.0.1 -P16033 -e "SHOW DATABASES"

mysql -uradmin -pradmin -h127.0.0.1 --prompt 'Admin1> ' -P16032 -e "SELECT * FROM runtime_mysql_servers"

orchestrator-client -c set-read-only -i mysql1

mysql -uradmin -pradmin -h127.0.0.1 --prompt 'Admin1> ' -P16032 -e "SELECT * FROM runtime_mysql_servers"

mysql -uroot -proot -h 127.0.0.1 -P16033 -e "SHOW DATABASES"

# try to read from sql interface: mysql -uroot -proot -h127.0.0.1 -P16033

orchestrator-client -c set-writeable -i mysql1

mysql -uradmin -pradmin -h127.0.0.1 --prompt 'Admin1> ' -P16032 -e "SELECT * FROM runtime_mysql_servers"

mysql -uroot -proot -h 127.0.0.1 -P16033 -e "SHOW DATABASES"

```

```
docker-compose stop mysql1

mysql -uradmin -pradmin -h127.0.0.1 --prompt 'Admin1> ' -P16032 -e "SELECT * FROM runtime_mysql_servers"
```





## Processlist

Use 2 connections.

Terminal 1:

````
mysql -uroot -proot -h 127.0.0.1 -P16033 -e "SELECT SLEEP(20)"
````

Terminal 2:

```
mysql -uradmin -pradmin -h127.0.0.1 --prompt 'Admin1> ' -P16032
```

```
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;
SHOW TABLES FROM stats;
SELECT * FROM stats_mysql_processlist;
SELECT * FROM stats_mysql_processlist WHERE command='Query' ORDER BY time_ms DESC LIMIT 1\G
SELECT user, COUNT(*) FROM stats_mysql_processlist GROUP BY user;
SELECT * FROM stats_mysql_users;
```

#### processlist extended_info - JSON

```
SHOW VARIABLES LIKE '%processlist%';
SET mysql-show_processlist_extended=1;
LOAD MYSQL VARIABLES TO RUNTIME;
SELECT * FROM stats_mysql_processlist\G
SET mysql-show_processlist_extended=1;
LOAD MYSQL VARIABLES TO RUNTIME;
SELECT * FROM stats_mysql_processlist\G
```



### JSON functions

```
SELECT SessionID, JSON_EXTRACT(extended_info,'$.conn.autocommit') autocommit, JSON_EXTRACT(extended_info,'$.conn.charset') charset , JSON_EXTRACT(extended_info,'$.backends[0].conn.mysql') mysql_backend FROM stats_mysql_processlist\G
```



### stats_mysql_free_connections

```
SELECT * FROM stats_mysql_free_connections\G
```

