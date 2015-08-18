#!/bin/bash
set -e

echo "Executing $BASH_SOURCE"

if [ ${ENTRYPOINT_INITIALIZED}=false ]; then

	# setup ssl certificate and key
	if [ -n "${CONF_POSTFIX_SSL_CERT}" ]; then
		echo "${CONF_POSTFIX_SSL_CERT}" >${SSL_DIR}/postfix.pem
	else
		# fallback to snakeoil cert
		cat /etc/ssl/certs/ssl-cert-snakeoil.pem >${SSL_DIR}/postfix.pem
	fi
	if [ -n "${CONF_POSTFIX_SSL_KEY}" ]; then
		echo "${CONF_POSTFIX_SSL_KEY}" >${SSL_DIR}/postfix.key
	else
		# fallback to snakeoil key
		cat /etc/ssl/private/ssl-cert-snakeoil.key >${SSL_DIR}/postfix.key
	fi

	# setup ldap lookup configuration
	sed -i /etc/postfix/ldap-users.cf \
		-e 's/dc=REPLACE,dc=ME/'${CONF_LDAP_BASE_DN}'/g'
	sed -i /etc/postfix/ldap-aliases.cf \
		-e 's/dc=REPLACE,dc=ME/'${CONF_LDAP_BASE_DN}'/g'

	# configure postfix
	postconf "smtpd_tls_cert_file = ${SSL_DIR}/postfix.pem"
	postconf "smtpd_tls_key_file = ${SSL_DIR}/postfix.key"
	#postconf "mydestination = ${HOSTNAME}"
	#postconf "myhostname = ${HOSTNAME}"
	#postconf "mydestination = ${HOSTNAME}, localhost.${CONF_MAIL_DOMAIN}, localhost"
	postconf "virtual_mailbox_domains = ${CONF_MAIL_DOMAIN}"
	postconf "virtual_mailbox_maps = ldap:/etc/postfix/ldap-users.cf"
	postconf "virtual_alias_maps = ldap:/etc/postfix/ldap-aliases.cf"
	postconf "virtual_transport = lmtp:127.0.0.1:2003"
	
	# disable chroot
	postconf -F smtp/inet/chroot=n

	# redirect all local mail aliases to specified address
	sed -i /etc/aliases \
		-e 's/\([^:]*: \).*/\1'${CONF_MAIL_LOCAL_ALIAS}'/'
	# be sure to redirect root to
	setConfigValue /etc/aliases root "${CONF_MAIL_LOCAL_ALIAS}" ":"
	# make new aliases active
	newaliases

fi

# copy config files required postfix
cp /etc/services /var/spool/postfix/etc/services
cp /etc/resolv.conf /var/spool/postfix/etc


