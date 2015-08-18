# Docker Container for Zarafa Collaboration Platform
Almost complete Zarafa setup including additional software

## Notes
Currently just a starting point which will be optimized in the future.
I have a big TODO list which I want to work on.
Pull requests are always welcome.

Here an example how to start quick:
Certificates and keys are defined by environment variables which must contain the content of the certificate.
```shell
docker run -it --hostname=$MAIL_HOST --name zarafa \
	-e "CONF_POSTFIX_SSL_CERT=${CONF_POSTFIX_SSL_CERT}" \
	-e "CONF_POSTFIX_SSL_KEY=${CONF_POSTFIX_SSL_KEY}" \
	-e "CONF_APACHE2_SSL_CERT=${CONF_APACHE2_SSL_CERT}" \
	-e "CONF_APACHE2_SSL_KEY=${CONF_APACHE2_SSL_KEY}" \
	-e "CONF_ZARAFA_SSL_CERT=${CONF_ZARAFA_SSL_CERT}" \
	-e "CONF_ZARAFA_SSL_KEY=${CONF_ZARAFA_SSL_KEY}" \
	-e "CONF_LDAP_PASSWORD=secret" \
	-e "CONF_LDAP_BASE_DN=dc=domain,dc=tld" \
	-e "CONF_LDAP_DOMAIN=domain.tld" \
	-e "CONF_MAIL_DOMAIN=domain.tld" \
	-e "CONF_MYSQL_ROOT_PASSWORD=secret" \
	-e "CONF_MYSQL_ZARAFA_PASSWORD=secret" \
	-e "CONF_MAIL_LOCAL_ALIAS=mycatchall@domain.tld" \
	spali/zarafa \
```


## TODO
- disable anonymous bind in ldap
  - use zarafa specific ldap user for zarafa->ldap connection
  - use postfix specific ldap user for postfix->ldap connection
- option for using external ldap server (ie. if $LDAP_HOST provided then skip ldap stuff and configure everything to use the external server)
- option for using external mysql server (ie. if $MYSQL_HOST provided then skip mysql stuff and configure everything to use the external server)
	- requires definition of $MYSQL_USER too
- zarafa
	- zarafa-server ssl setup
	- z push setup
- fetchmail
- phpldapadmin
- maybe client certificate for auth
- cleanup env variables
	- declare it in Dockerfile
- test env var password with $
- test end to end encryption: http://ubuntuforums.org/archive/index.php/t-493222.html
- sending mail from webapp to external address, the first "recevied from" contains localhost.. get rid of this
- nginx instead of big apache
- try to use debconf-set-selection for mysql password
- remove ldap:// from service and scripts ? just use ldapi:// ?
- better service implementation (replace supervisor?)
  - wait for process to start before continue
  - dependencies
- cron service
- optional roundcube webmail
- think of service which could be easy separated into it's own container (i.e slapd, mysql) does this make sense?



## Credits
* based on ideas of [LECKERBEEFde/docker-zarafa](https://github.com/LECKERBEEFde/docker-zarafa) as starting point
