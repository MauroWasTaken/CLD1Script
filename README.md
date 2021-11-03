# Technical specs

| Name                 | Value                |
| -------------------- | -------------------- |
| VMWare version       | 106.1.0              |
| Linux distribution   | Debian 11            |
| Language             | French               |
| Region               | Switzerland          |
| Keyboard layout      | Switzerland - French |
| Hostname             | debian               |
| Cores per processors | 4                    |
| RAM                  | 8192 MB              |
| Disk size            | 20GB                 |

## Network
| Name          | Value       |
| ------------- | ----------- |
| Connection    | NAT         |
| Interface     | ens33       |
| Configuration | dhcp (IPv4) |

# Installation
## Installing the OS
Firstly you'll need to download a Debian iso.

After that, proceed with the installation as usual using the settings above.

When asked to choose the preinstalled packages, be sure to only install the system utilities.

![image-20211028121721757](https://imgur.com/gyFxi8S.png)

Don't forget to install GRUB !!!

## Installing the different components

Start by doing the updates.
```shell
# apt update
# apt upgrade
```
### Sudo (optional)

we are going to setup sudo in order to use the user created during the setup and not root
```shell
# apt install sudo
# usermod -a-G sudo <username>
```

**Reminder that all the # need to be replaced with sudo if you're not using root**

### SSH

Next we are going to install SSH
```shell
# apt install ssh
```

### Nginx
type this two commands to install and start Nginx
```shell
# apt install nginx
# systemctl enable --now nginx
# systemctl status nginx
```
Check if the service is active by the last command

### PHP support
type this two commands to install and start PHP and PHP FPM 

```shell
# apt install php-fpm php-common php-cli
# systemctl enable --now php7.4-fpm
```

### Mariadb

```shell
# apt install mariadb-server
# mysql_secure_installation
    none
    Switch to unix_socket authentication: n
    Change the root password: n
    Remove anonymous users: y
    Disallow root login remotely: y
    Remove test database and access to it: y
    Reload privilege tables now: y
# systemctl enable mariadb
# systemctl status mariadb
```

## Changing the default state for a new user
in order to create a new user, you have to ways of proceding.
## Using the script
in order to download the script you'll need to install git on your machine
```shell
# apt install git
#
```
## Adding the user manually
```shell
# mkdir /etc/skel/html
# echo "<?php phpinfo();" | tee -a /etc/skel/html/index.php > /dev/null
```

If the useradd command doesn't work try 
```shell
# export PATH="$PATH:/sbin:/usr/sbin:usr/local/sbin"
```
Type the following commands to modify the default shell values
```shell
# useradd -D --shell=/bin/bash
# useradd -D
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
```
## Changing /home permissions
Before creating the user, we are going to secure the /home directory in order to stop the user from accessing the other websites.
```shell
# chmod 751 /home

```

## Create a new web user
Now we are going to create a new user
```shell
# useradd <username> -m -p $(openssl passwd -1 '<password>')
```
and we are going to add him to the following groups
```shell
# usermod -a -G <username> www-data
```
Assign the following permissions 
```shell
# mkdir /home/<username>/html -p
# chown -R <username>:<username> /home/<username>
# chmod 750 /home/<username>
```
### Setting up php-fpm 

copy the default pool php file with the following command

```shell
# cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/<username>.conf
```

and now we are going to change open the pool file
```shell
# nano /etc/php/7.4/fpm/pool.d/<username>.conf
```
and change the following
```config
1. At the very top change the [www] to [<username>]
2. Change the "user = www-data" to "user = <username>"
3. Change the "group = www-data" to "group = <username>"
4. Change the "listen = /run/php/php7.4-fpm.sock" to "listen = /run/php/php7.4-fpm-<username>.sock"
```
Restart the php-fpm service
```shell
# systemctl restart php7.4-fpm
```

You can try checking the pools using the following command
```shell
# systemctl status php7.4-fpm
```
and checking if the command returned something like this
```
CGroup: /system.slice/php7.4-fpm.service
             ├─14090 php-fpm: master process (/etc/php/7.4/fpm/php-fpm.conf)
             ├─14093 php-fpm: pool <username>
             ├─14094 php-fpm: pool <username>
             ├─14095 php-fpm: pool www
             └─14096 php-fpm: pool www
```
### Setting up Nginx
start by creating a config file
```shell
# nano /etc/nginx/sites-available/<username>.local
```
copy the following onto the file
```
server {
    listen 80;

    server_name <username>.local;
    root /home/<username>/html;

    access_log /var/log/nginx/<username>.access.log;
    error_log /var/log/nginx/<username>.error.log;

    index index.php index.html;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.4-fpm-<username>.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```
Link files your local sites-available file with the sites-enabled folder
```shell
# ln -s /etc/nginx/sites-available/<username>.local /etc/nginx/sites-enabled
```
Restart Nginx
```shell
# systemctl restart nginx 
```
### Setting up MariaDB
```shell
# mariadb
```
copy the following commands
```mysql
CREATE DATABASE <username>;

CREATE USER <username>@localhost IDENTIFIED BY '<password>';

GRANT ALL PRIVILEGES ON <username>.* TO <username>@localhost;

FLUSH PRIVILEGES;

exit;
```
# Finishing touches

## Trying the website out

change your hosts file:
/etc/hosts on Linux and MacOS
C:\Windows\System32\drivers\etc\hosts on Windows

```
[server_ip]    <username>.local
```

Go to your preferred browser and type the following on the Address bar
```
http://<username>.local/
```

## Site deployment
In order to transfer files using scp to the you'll need to type the following command

```
$ scp -prC <directoryToCopy>/* <username>@<serverIP>:~/html
```