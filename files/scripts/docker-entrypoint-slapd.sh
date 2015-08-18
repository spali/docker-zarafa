#!/bin/bash
set -e

echo "Executing $BASH_SOURCE"

if [ ${ENTRYPOINT_INITIALIZED}=false ]; then

	# delete old database
	rm -rf /var/lib/ldap/*

	# set initial configuration
	echo "slapd slapd/password1 password ${CONF_LDAP_PASSWORD}" | debconf-set-selections
	echo "slapd slapd/password2 password ${CONF_LDAP_PASSWORD}" | debconf-set-selections
	echo "slapd slapd/internal/adminpw password ${CONF_LDAP_PASSWORD}" | debconf-set-selections
	echo "slapd slapd/internal/generated_adminpw password ${CONF_LDAP_PASSWORD}" | debconf-set-selections
	echo "slapd slapd/allow_ldap_v2 boolean false" | debconf-set-selections
	echo "slapd slapd/invalid_config boolean true" | debconf-set-selections
	echo "slapd slapd/move_old_database boolean false" | debconf-set-selections
	echo "slapd slapd/backend select HDB" | debconf-set-selections
	echo "slapd shared/organization string ${CONF_LDAP_BASE_DN}" | debconf-set-selections
	echo "slapd slapd/domain string ${CONF_LDAP_DOMAIN}" | debconf-set-selections
	echo "slapd slapd/no_configuration boolean false" | debconf-set-selections
	echo "slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION" | debconf-set-selections
	echo "slapd slapd/purge_database boolean true" | debconf-set-selections

	# reconfigure
	dpkg-reconfigure -f noninteractive slapd

	# start slapd service
	/usr/sbin/slapd -h "ldapi:///" -g openldap -u openldap -F /etc/ldap/slapd.d

	# add basic indexes
	ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/olcDbIndex_base.ldif

	# stop slapd service
	kill -INT `cat /var/run/slapd/slapd.pid`

fi

