#!/bin/bash
set -e

echo "Executing $BASH_SOURCE"

if [ ${ENTRYPOINT_INITIALIZED}=false ]; then

	# setup users groups
	adduser clamav amavis
	adduser amavis clamav

	setConfigValue /etc/clamav/clamd.conf Foreground True
	
	# setup razor and pyzor
	su - amavis -s /bin/bash -c 'razor-admin -create; razor-admin -register; pyzor discover'

	# enable virus and spam check
	sed -i /etc/amavis/conf.d/15-content_filter_mode \
		-e '/^#\(@bypass\|[ \t]*\\\(%\|@\|\$\)\)/s/^#//'

	# enable content filter in postfix
	postconf -e "content_filter = smtp-amavis:[127.0.0.1]:10024"
	# setup services
	postconf -M smtp-amavis/unix="smtp-amavis     unix    -       -       -       -       2       smtp"
	postconf -P "smtp-amavis/unix/smtp_data_done_timeout=1200"
	postconf -P "smtp-amavis/unix/smtp_send_xforward_command=yes"
	postconf -P "smtp-amavis/unix/disable_dns_lookups=yes"
	postconf -P "smtp-amavis/unix/max_use=20"
	postconf -M 127.0.0.1:10025/inet="127.0.0.1:10025 inet    n       -       -       -       -       smtpd"
	postconf -P "127.0.0.1:10025/inet/content_filter="
	postconf -P "127.0.0.1:10025/inet/local_recipient_maps="
	postconf -P "127.0.0.1:10025/inet/relay_recipient_maps="
	postconf -P "127.0.0.1:10025/inet/smtpd_restriction_classes="
	postconf -P "127.0.0.1:10025/inet/smtpd_delay_reject=no"
	postconf -P "127.0.0.1:10025/inet/smtpd_client_restrictions=permit_mynetworks,reject"
	postconf -P "127.0.0.1:10025/inet/smtpd_helo_restrictions="
	postconf -P "127.0.0.1:10025/inet/smtpd_sender_restrictions="
	postconf -P "127.0.0.1:10025/inet/smtpd_recipient_restrictions=permit_mynetworks,reject"
	postconf -P "127.0.0.1:10025/inet/smtpd_data_restrictions=reject_unauth_pipelining"
	postconf -P "127.0.0.1:10025/inet/smtpd_end_of_data_restrictions="
	postconf -P "127.0.0.1:10025/inet/mynetworks=127.0.0.0/8"
	postconf -P "127.0.0.1:10025/inet/smtpd_error_sleep_time=0"
	postconf -P "127.0.0.1:10025/inet/smtpd_soft_error_limit=1001"
	postconf -P "127.0.0.1:10025/inet/smtpd_hard_error_limit=1000"
	postconf -P "127.0.0.1:10025/inet/smtpd_client_connection_count_limit=0"
	postconf -P "127.0.0.1:10025/inet/smtpd_client_connection_rate_limit=0"
	postconf -P "127.0.0.1:10025/inet/receive_override_options=no_header_body_checks,no_unknown_recipient_checks"
	# prevent spam report messages to be classified as spam
	postconf -P "pickup/unix/content_filter="
	postconf -P "pickup/unix/receive_override_options=no_header_body_checks"

	# set mailname (amavis does report this as error, but maybe just cosmetics)
	echo "$(hostname --fqdn)" >/etc/mailname
	
fi

# refresh clamav database
freshclam --stdout --quiet
if [ ! -d /var/run/clamav ]; then
	mkdir /var/run/clamav
fi
chown -R clamav:clamav /var/run/clamav


