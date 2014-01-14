#!/bin/bash
clear
echo "   _____           _    ____   _____                    __          _    _____                 "
echo "  / ____|         | |  / __ \ / ____|                  / _|        | |  / ____|                "
echo " | |     ___ _ __ | |_| |  | | (___    _ __   ___ _ __| |_ ___  ___| |_| (___   ___ _ ____   __"
echo " | |    / _ \ '_ \| __| |  | |\___ \  | '_ \ / _ \ '__|  _/ _ \/ __| __|\___ \ / _ \ '__\ \ / /"
echo " | |___|  __/ | | | |_| |__| |____) | | |_) |  __/ |  | ||  __/ (__| |_ ____) |  __/ |   \ V / "
echo "  \_____\___|_| |_|\__|\____/|_____/  | .__/ \___|_|  |_| \___|\___|\__|_____/ \___|_|    \_/  "
echo "                                      | |  v0.1beta"
echo "                                      |_|  for auto hosting simply & easily"
echo ""
echo "you can \"tail -f log_script.log\" to see what's happend ;)"
echo ""
echo -e "\033[31mThis script will modify your configuration server.\033[0m"
echo -e "\033[31mIt work with NO guaranty\033[0m"
echo -e "\033[31mDo you know what you do? (type yes UPPERLY)\033[0m"
read areyousure
if [ $areyousure != "YES" ]
then exit 1
else echo -e "\033[31mEvil is coming \m/ ...\033[0m"
fi


LOG=/root/log_script.log

#disabling 169.254route
echo "NOZEROCONF=yes" >> /etc/sysconfig/network

#base and add additionnal repo

yum -y install wget >> $LOG 2>&1

echo -e "[\033[33m*\033[0m] Installing & configuring epel, rpmforge repos..."
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY* >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error importing key /etc/pki/rpm-gpg/RPM-GPG-KEY*"
rpm --import http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error importing key RPM-GPG-KEY.dag"
cd /tmp
wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error downloading RPMForge rpm"
rpm -ivh rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error installing rpmforge rpm"

rpm --import https://fedoraproject.org/static/0608B895.txt >> $LOG 2>&1  || echo -e "[\033[31mX\033[0m] Error importing epel key"
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm >> $LOG 2>&1  || echo -e "[\033[31mX\033[0m] Error downloading epel repo rpm"
rpm -ivh epel-release-6-8.noarch.rpm >> $LOG 2>&1  || echo -e "[\033[31mX\033[0m] Error installing epel repo rpm"

#rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi >> $LOG 2>&1  || echo -e "[\033[31mX\033[0m] Error import key remi"
#rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm >> $LOG 2>&1  || echo -e "[\033[31mX\033[0m] Error installing rpm remi"

yum install yum-priorities -y >> $LOG 2>&1 echo -e "[\033[31mX\033[0m] Error installing yum-priorites"
awk 'NR== 2 { print "priority=10" } { print }' /etc/yum.repos.d/epel.repo > /tmp/epel.repo
rm /etc/yum.repos.d/epel.repo -f
mv /tmp/epel.repo /etc/yum.repos.d

#sed -i -e "0,/5/s/enabled=0/enabled=1/" /etc/yum.repos.d/remi.repo
echo -e "[\033[32m*\033[0m] Base repository, rpmforge, epel & remi set up"


# Installing tools, update, ....
echo -e "[\033[33m*\033[0m] Updating full system (it can take some minutes...)"
yum update -y >> $LOG 2>&1 ||  echo -e "[\033[31mX\033[0m] Error in yum update"
echo -e "[\033[33m*\033[0m] Installing required packages"
yum install -y vim htop iftop nmap screen git expect >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error installing base packages"
echo -e "[\033[33m*\033[0m] Installing Development Tools"
yum groupinstall -y 'Development Tools'  >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error installing Dev Tools metapackage"

#Install and enable NTP at boot
echo -e "[\033[33m*\033[0m] Installing and configure NTPD"
yum install -y ntp  >> $LOG 2>&1
chkconfig ntpd on >> $LOG 2>&1

#disabling firewall
echo -e "[\033[33m*\033[0m] Disabling Firewall (for installation time)"
service iptables save >> $LOG 2>&1
service iptables stop >> $LOG 2>&1
chkconfig iptables off >> $LOG 2>&1

#disabling SELinux
echo -e "[\033[33m*\033[0m] Disabling SELinux"
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled' /etc/selinux/config >> $LOG 2>&1
setenforce 0 >> $LOG 2>&1

#MYSQL
echo -e "[\033[33m*\033[0m] Installing MYSQL Server"
yum install mysql mysql-server -y >> $LOG 2>&1
chkconfig --levels 235 mysqld on >> $LOG 2>&1
/etc/init.d/mysqld start >> $LOG 2>&1

echo "Type the MySQL root password you want to set: "
read -s mysqlrootpw

SECURE_MYSQL=$(expect -c "
 
set timeout 10
spawn mysql_secure_installation
 
expect \"Enter current password for root (enter for none):\"
send \"\r\"
 
expect \"Set root password?\"
send \"y\r\"

expect \"New password:\"
send \"$mysqlrootpw\r\"

expect \"Re-enter new password:\"
send \"$mysqlrootpw\r\"
 
expect \"Remove anonymous users?\"
send \"y\r\"
 
expect \"Disallow root login remotely?\"
send \"y\r\"
 
expect \"Remove test database and access to it?\"
send \"y\r\"
 
expect \"Reload privilege tables now?\"
send \"y\r\"
 
expect eof
" >> $LOG)

echo "$SECURE_MYSQL" >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error configuring MySQL"

echo -e "[\033[32m*\033[0m] MYSQL set up"

#DOVECOT
echo -e "[\033[33m*\033[0m] Installing DOVECOT Server"
yum install dovecot dovecot-mysql -y >> $LOG 2>&1
chkconfig --levels 235 dovecot on >> $LOG 2>&1
/etc/init.d/dovecot start >> $LOG 2>&1
echo -e "[\033[32m*\033[0m] DOVECOT set up"

#POSTFIX
echo -e "[\033[33m*\033[0m] Installing Postfix Server"
yum install postfix -y >> $LOG 2>&1
chkconfig --levels 235 postfix on >> $LOG 2>&1
/etc/init.d/postfix restart >> $LOG 2>&1
echo -e "[\033[32m*\033[0m] Postfix set up"

#getmail
echo -e "[\033[33m*\033[0m] Installing getmail"
yum install getmail -y >> $LOG 2>&1
echo -e "[\033[32m*\033[0m] getmail set up"

#antivirus
echo -e "[\033[33m*\033[0m] Installing Antivirus/Antispam Layer (it can take some times downloading AV databases)"
yum install -y amavisd-new spamassassin clamav clamd unzip bzip2 unrar perl-DBD-mysql --disablerepo=epel >> $LOG 2>&1
sa-update >> $LOG 2>&1
chkconfig --levels 235 amavisd on >> $LOG 2>&1
/usr/bin/freshclam >> $LOG 2>&1
/etc/init.d/amavisd start >> $LOG 2>&1
echo -e "[\033[32m*\033[0m] Antivirus set up"

#NGINX
echo -e "[\033[33m*\033[0m] Installing & Configuring NGINX Webserver"
yum install nginx --enablerepo=epel -y >> $LOG 2>&1

awk 'NR== 21 { print "map $scheme $https {" ; print "default off;" ; print "https on;"; print "}"} { print }' /etc/nginx/nginx.conf > /tmp/nginx.conf
rm -f /etc/nginx/nginx.conf
mv /tmp/nginx.conf /etc/nginx


chkconfig --del httpd >> $LOG 2>&1
/etc/init.d/httpd stop >> $LOG 2>&1
chkconfig --levels 235 nginx on >> $LOG 2>&1
/etc/init.d/nginx start >> $LOG 2>&1
yum install php php-fpm php-cli php-mysql php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-magickwand php-magpierss php-mbstring php-mcrypt php-mssql php-shout php-snmp php-soap php-tidy -y >> $LOG 2>&1
sed -i -e 's/; cgi.fix_pathinfo=0/cgi.fix_pathinfo=0/' /etc/php.ini >> $LOG 2>&1
chkconfig --levels 235 php-fpm on >> $LOG 2>&1
/etc/init.d/php-fpm start >> $LOG 2>&1
yum install -y fcgi-devel >> $LOG 2>&1

echo -e "  [\033[33m*\033[0m] Compil fcgiwrap (cause it don't exist in rpm for CentOS)"
cd /usr/local/src/
git clone git://github.com/gnosek/fcgiwrap.git >> $LOG 2>&1
echo -e "  [\033[32m*\033[0m] Gitting sources done"
cd fcgiwrap
autoreconf -i >> $LOG 2>&1
./configure >> $LOG 2>&1
make >> $LOG 2>&1
make install >> $LOG 2>&1
echo -e "  [\033[32m*\033[0m] fcgiwrap done"

yum install spawn-fcgi -y >> $LOG 2>&1
echo -e "[\033[33m*\033[0m] Setting /etc/sysconfig/spawn-fcgi configuration file"
cat <<EOF > /etc/sysconfig/spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
#SOCKET=/var/run/php-fcgi.sock
#OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"

FCGI_SOCKET=/var/run/fcgiwrap.socket
FCGI_PROGRAM=/usr/local/sbin/fcgiwrap
FCGI_USER=apache
FCGI_GROUP=apache
FCGI_EXTRA_OPTIONS="-M 0770"
OPTIONS="-u $FCGI_USER -g $FCGI_GROUP -s $FCGI_SOCKET -S $FCGI_EXTRA_OPTIONS -F 1 -P /var/run/spawn-fcgi.pid -- $FCGI_PROGRAM"
EOF

usermod -a -G apache nginx >> $LOG 2>&1
chkconfig --levels 235 spawn-fcgi on >> $LOG 2>&1
/etc/init.d/spawn-fcgi start >> $LOG 2>&1
echo -e "[\033[32m*\033[0m] NGINX set up !"

#install PHPMYADMIN
echo -e "[\033[33m*\033[0m] Setting PHPmyAdmin"
yum install phpmyadmin -y >> $LOG 2>&1
sed -i -e "s/$cfg['Servers'][$i]['auth_type'] = 'cookie';/$cfg['Servers'][$i]['auth_type'] = 'http';/" /usr/share/phpmyadmin/config.inc.php 2>&1

echo -e "[\033[33m*\033[0m] Setting Mailman"
#Mailman
yum install mailman -y >> $LOG 2>&1
/usr/lib/mailman/bin/newlist mailman

cat <<EOF >> /etc/aliases
mailman:              "|/usr/lib/mailman/mail/mailman post mailman"
mailman-admin:        "|/usr/lib/mailman/mail/mailman admin mailman"
mailman-bounces:      "|/usr/lib/mailman/mail/mailman bounces mailman"
mailman-confirm:      "|/usr/lib/mailman/mail/mailman confirm mailman"
mailman-join:         "|/usr/lib/mailman/mail/mailman join mailman"
mailman-leave:        "|/usr/lib/mailman/mail/mailman leave mailman"
mailman-owner:        "|/usr/lib/mailman/mail/mailman owner mailman"
mailman-request:      "|/usr/lib/mailman/mail/mailman request mailman"
mailman-subscribe:    "|/usr/lib/mailman/mail/mailman subscribe mailman"
mailman-unsubscribe:  "|/usr/lib/mailman/mail/mailman unsubscribe mailman"
EOF

newaliases >> $LOG
/etc/init.d/postfix restart >> $LOG 2>&1
chkconfig --levels 235 mailman on >> $LOG 2>&1
/etc/init.d/mailman start >> $LOG 2>&1
cd /usr/lib/mailman/cgi-bin/
ln -s ./ mailman

echo -e "[\033[33m*\033[0m] Setting PureFTPD"
#PureFTPD
yum install pure-ftpd -y >> $LOG 2>&1
chkconfig --levels 235 pure-ftpd on >> $LOG 2>&1
/etc/init.d/pure-ftpd start >> $LOG 2>&1
yum install openssl >> $LOG 2>&1

echo -e "[\033[33m*\033[0m] Setting Bind"
#BIND
yum install bind bind-utils -y >> $LOG 2>&1

cp /etc/named.conf /etc/named.conf_bak
cat <<EOF > /etc/named.conf
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
options {
        listen-on port 53 { any; };
        listen-on-v6 port 53 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { any; };
        recursion yes;
	};
logging {
        channel default_debug {
	        file "data/named.run";
		 severity dynamic;
       };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.conf.local";

EOF

touch /etc/named.conf.local

chkconfig --levels 235 named on >> $LOG 2>&1
/etc/init.d/named start >> $LOG 2>&1

echo -e "[\033[33m*\033[0m] Setting statistics stuffs"
#Stuffs stats
yum install webalizer awstats perl-DateTime-Format-HTTP perl-DateTime-Format-Builder -y >> $LOG 2>&1

echo -e "[\033[33m*\033[0m] Setting Jailkit"
#Jailkit
cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.16.tar.gz >> $LOG 2>&1
tar xvfz jailkit-2.16.tar.gz >> $LOG 2>&1
cd jailkit-2.16
./configure >> $LOG 2>&1
make >> $LOG 2>&1
make install >> $LOG 2>&1
cd ..
rm -rf jailkit-2.16* >> $LOG 2>&1

echo -e "[\033[33m*\033[0m] Setting fail2ban & RootkitHunter"
#fail2ban & rkhunter
yum install fail2ban -y >> $LOG 2>&1

chkconfig --levels 235 fail2ban on >> $LOG 2>&1
/etc/init.d/fail2ban start >> $LOG 2>&1

yum install rkhunter -y >> $LOG 2>&1

echo -e "[\033[33m*\033[0m] Setting ISPConfig !"
#ISPConfig
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz >> $LOG 2>&1
tar xfz ISPConfig-3-stable.tar.gz >> $LOG 2>&1
cd ispconfig3_install/install/

ISPSETUP=$(expect -c "
 
set timeout 10
spawn php -q install.php
 
expect \"Select language (en,de)\"
send \"\r\"

expect \"Installation mode (standard,expert)\"
send \"\r\"

expect \"Full qualified hostname (FQDN) of the server, eg server1.domain.tld\"
send \"\r\"

expect \"MySQL server hostname\"
send \"\r\"

expect \"MySQL root username\"
send \"\r\"

expect \"MySQL root password\"
send \"$mysqlrootpw\r\"

expect \"MySQL database to create\"
send \"\r\"

expect \"MySQL charset\"
send \"\r\"

 
")

echo "$ISPSETUP" >> $LOG 2>&1 || echo -e "[\033[31mX\033[0m] Error installing ISPConfig" 



sed -i -e "s/DEFAULT_SERVER_LANGUAGE =/DEFAULT_SERVER_LANGUAGE = 'en'/" /usr/lib/mailman/Mailman/mm_cfg.py >> $LOG 2>&1
/etc/init.d/mailman restart  >> $LOG 2>&1


