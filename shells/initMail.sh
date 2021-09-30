#!/bin/bash

dnf install -y postfix dovecot cyrus-sasl

systemctl enable --now postfix dovecot saslauthd
systemctl stop postfix dovecot saslauthd


# edit /etc/postfix/main.cf
mv /etc/postfix/main.cf /etc/postfix/main.cf.old
cat  <<EOL >> /etc/postfix/main.cf
alias_database = hash:/etc/aliases
alias_maps = hash:/etc/aliases
broken_sasl_auth_clients = yes
command_directory = /usr/sbin
compatibility_level = 2
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
debug_peer_level = 2
debugger_command = PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin ddd \$daemon_directory/\$process_name \$process_id & sleep 5
disable_vrfy_command = yes
home_mailbox = Maildir/
html_directory = no
inet_interfaces = all
inet_protocols = all
local_recipient_maps =
luser_relay = unknown_user@localhost
mail_owner = postfix
mailq_path = /usr/bin/mailq.postfix
manpage_directory = /usr/share/man
message_size_limit = 20971520
meta_directory = /etc/postfix
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
mydomain = sasadd.net
myhostname = mail.sasadd.net
myorigin = \$mydomain
newaliases_path = /usr/bin/newaliases.postfix
queue_directory = /var/spool/postfix
readme_directory = /usr/share/doc/postfix/README_FILES
sample_directory = /usr/share/doc/postfix/samples
sendmail_path = /usr/sbin/sendmail.postfix
setgid_group = postdrop
shlib_directory = /usr/lib64/postfix
smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
smtp_tls_CApath = /etc/pki/tls/certs
smtp_tls_security_level = may
smtpd_banner = \$myhostname ESMTP unknown
smtpd_recipient_restrictions = permit_mynetworks permit_sasl_authenticated reject_unauth_destination
smtpd_sasl_auth_enable = yes
smtpd_sasl_local_domain = \$myhostname
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
smtpd_sasl_type = dovecot
smtpd_tls_cert_file = /etc/pki/tls/certs/postfix.pem
smtpd_tls_key_file = /etc/pki/tls/private/postfix.key
smtpd_tls_security_level = may
unknown_local_recipient_reject_code = 550
EOL



# edit /etc/postfix/master.cf
mv /etc/postfix/master.cf /etc/postfix/master.cf.old
cat  <<EOL >> /etc/postfix/master.cf
smtp      inet  n       -       n       -       -       smtpd
submission inet n       -       n       -       -       smtpd
-o smtpd_sasl_auth_enable=yes
pickup    unix  n       -       n       60      1       pickup
cleanup   unix  n       -       n       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
rewrite   unix  -       -       n       -       -       trivial-rewrite
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce
trace     unix  -       -       n       -       0       bounce
verify    unix  -       -       n       -       1       verify
flush     unix  n       -       n       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       n       -       -       smtp
relay     unix  -       -       n       -       -       smtp
        -o syslog_name=postfix/\$service_name
showq     unix  n       -       n       -       -       showq
error     unix  -       -       n       -       -       error
retry     unix  -       -       n       -       -       error
discard   unix  -       -       n       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
EOL


# edit /etc/sasl2/smtpd.conf
mv /etc/sasl2/smtpd.conf /etc/sasl2/smtpd.conf.old
cat  <<EOL >> /etc/sasl2/smtpd.conf
pwcheck_method: saslauthd
mech_list: plain login
EOL


mkdir -p /etc/skel/Maildir/{new,cur,tmp}
chmod -R 700 /etc/skel/Maildir/


# edit /etc/dovecot/dovecot.conf
mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.old
cat <<EOL >> /etc/dovecot/dovecot.conf
# 2.3.8 (9df20d2db): /etc/dovecot/dovecot.conf
# OS: Linux 4.18.0-305.17.1.el8_4.x86_64 x86_64 Rocky Linux release 8.4 (Green Obsidian) 
# Hostname: vultr.guest
auth_debug = yes
auth_mechanisms = plain login
auth_verbose = yes
disable_plaintext_auth = no
first_valid_uid = 1000
listen = *
mail_location = maildir:~/Maildir
mbox_write_locks = fcntl
namespace inbox {
  inbox = yes
  location = 
  mailbox Drafts {
    special_use = \Drafts
  }
  mailbox Junk {
    special_use = \Junk
  }
  mailbox Sent {
    special_use = \Sent
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox Trash {
    special_use = \Trash
  }
  prefix = 
}
passdb {
  driver = pam
}
protocols = imap pop3
service auth {
  unix_listener /var/spool/postfix/private/auth {
    group = postfix
    mode = 0666
    user = postfix
  }
}
ssl = no
ssl_cert = </etc/pki/dovecot/certs/dovecot.pem
ssl_cipher_list = PROFILE=SYSTEM
ssl_key = # hidden, use -P to show it
userdb {
  driver = passwd
}
EOL

firewall-cmd --zone=public --add-service=smtp --permanent
firewall-cmd --zone=public --add-service=pop3 --permanent
firewall-cmd --zone=public --add-service=imap --permanent
firewall-cmd --zone=public --add-port=587 --permanent
firewall-cmd --reload

systemctl start postfix dovecot saslauthd