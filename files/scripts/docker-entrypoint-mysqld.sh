#!/bin/bash
set -e

echo "Executing $BASH_SOURCE"

if [ ${ENTRYPOINT_INITIALIZED}=false ]; then

	# start service
	/usr/bin/mysqld_safe &
	mysql_safePid=$!
	# wait for mysqld process to start
	while ! [[ "$(cat /var/run/mysqld/mysqld.pid 2>/dev/null)" =~ ^[0-9]+$ ]]; do
  		sleep 1
	done

	# set root password for all connections and check databases
	mysql -uroot <<_EOF
		use mysql;
		update user set password=PASSWORD('${CONF_MYSQL_ROOT_PASSWORD}') where user='root';
		flush privileges;
_EOF
	mysqlcheck --all-databases -uroot -p${CONF_MYSQL_ROOT_PASSWORD}

	# stop service
	kill -TERM ${mysql_safePid}
	wait ${mysql_safePid}

fi

