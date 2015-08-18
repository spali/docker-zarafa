#!/bin/bash
set -e

echo "Executing $BASH_SOURCE"

if [ ${ENTRYPOINT_INITIALIZED}=false ]; then

	# prepare initial data
	sed -i /root/ldap.ldif \
                -e 's/dc=REPLACE,dc=ME/'${CONF_LDAP_BASE_DN}'/' \
		-e 's/REPLACE\.ME/'${CONF_MAIL_DOMAIN}'/'

	# start slapd service
	/usr/sbin/slapd -h "ldapi:///" -g openldap -u openldap -F /etc/ldap/slapd.d

	# adding zarafa schema
	zcat /usr/share/doc/zarafa/zarafa.ldif.gz | ldapadd -H ldapi:/// -Y EXTERNAL

	# add zarafa indexes
	ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/olcDbIndex_zarafa.ldif

	# add initial data
	ldapadd -H ldapi:/// -x -D cn=admin,${CONF_LDAP_BASE_DN} -w ${CONF_LDAP_PASSWORD} -f /root/ldap.ldif
	
	# stop slapd service
	killall slapd # workaround, due some reason pid file is not written

	# start mysql service
	/usr/bin/mysqld_safe &
	mysql_safePid=$!
	# wait for mysqld process to start
	while ! [[ "$(cat /var/run/mysqld/mysqld.pid 2>/dev/null)" =~ ^[0-9]+$ ]]; do
  		sleep 1
	done

	# setup mysql for zarafa
	mysql -uroot -p${CONF_MYSQL_ROOT_PASSWORD} <<_EOF
		GRANT ALL PRIVILEGES ON zarafa.* TO 'zarafa'@'localhost' IDENTIFIED BY '${CONF_MYSQL_ZARAFA_PASSWORD}';
		flush privileges;
_EOF

	# stop mysql service
	kill -TERM ${mysql_safePid}
	wait ${mysql_safePid}

	# setup ssl certificate and key
	if [ -n "${CONF_ZARAFA_SSL_CERT}" ]; then
		echo "${CONF_ZARAFA_SSL_CERT}" >${SSL_DIR}/zarafa.pem
	else
		# fallback to snakeoil cert
		cat /etc/ssl/certs/ssl-cert-snakeoil.pem >${SSL_DIR}/zarafa.pem
	fi
	if [ -n "${CONF_ZARAFA_SSL_KEY}" ]; then
		echo "${CONF_ZARAFA_SSL_KEY}" >${SSL_DIR}/zarafa.key
	else
		# fallback to snakeoil key
		cat /etc/ssl/private/ssl-cert-snakeoil.key >${SSL_DIR}/zarafa.key
	fi

	# configure zarafa
	cp /etc/zarafa/ldap.openldap.cfg /etc/zarafa/ldap.cfg
	setConfigValue /etc/zarafa/ldap.cfg ldap_search_base "${CONF_LDAP_BASE_DN}" "="
	setConfigValue /etc/zarafa/ldap.cfg ldap_bind_user "cn=admin,${CONF_LDAP_BASE_DN}" "="
	setConfigValue /etc/zarafa/ldap.cfg ldap_bind_passwd "${CONF_LDAP_PASSWORD}" "="
	setConfigValue /etc/zarafa/server.cfg mysql_user "zarafa" "="
	setConfigValue /etc/zarafa/server.cfg mysql_password "${CONF_MYSQL_ZARAFA_PASSWORD}" "="
	setConfigValue /etc/zarafa/server.cfg user_plugin "ldap" "="
	setConfigValue /etc/zarafa/gateway.cfg pop3_enable "no" "="
	setConfigValue /etc/zarafa/gateway.cfg imap_enable "no" "="
	setConfigValue /etc/zarafa/gateway.cfg imaps_enable "yes" "="
	setConfigValue /etc/zarafa/gateway.cfg ssl_certificate_file "${SSL_DIR}/zarafa.pem" "="
	setConfigValue /etc/zarafa/gateway.cfg ssl_private_key_file "${SSL_DIR}/zarafa.key" "="

	# enable web access
	a2ensite zarafa-webaccess
	a2ensite zarafa-webapp

	# proxy ical
	a2enmod proxy
	a2enmod proxy_http
	a2ensite zarafa-ical

fi

