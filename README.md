CentOS perfectServ
==================

This script will install all you need to have a full configuration of ISPConfig 3 on a minimal & new CentOS 6.4 system.
It work with no guaranty and need to be improved for sure !

This work is based from http://www.howtoforge.com/perfect-server-centos-6.4-x86_64-nginx-dovecot-ispconfig-3
You have to read this documentation and the script itself before do anything with it.

You must have a fresh CentOS 6.4 installation, with nothing installed and full internet access.
During setup, you will be asked for prompt input for mysql, mailman, and ISPConfig setup.

It will install and configure :

* Epel and RPMForge repository
* Development Tools (cause we need to compile some packages)
* NTP Daemon
* NGINX, MySql, PHP
* phpMyadmin
* Dovecot, Postfix & getmail
* ClamAV
* Mailman
* Fail2Ban & Rootkit hunter
* PureFTPD
* Bind
* Jailkit
and launch the ISPConfig3 installer !

have fun !


