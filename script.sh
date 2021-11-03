#!/bin/bash
set -x
set -e
if [ -z "$1" ];
then
    echo "you're missing the Username"
    exit 1
else
    echo "has username"
    name=$1
fi
read -r -p "password pls: " password
if [ -z "$password" ];
then
    echo "you're missing the password"
    exit 1
else
    echo "has password"
    
fi
export PATH="$PATH:/sbin:/usr/sbin:usr/local/sbin"
##Create a new web user
useradd $name -m -p $(openssl passwd -1 "$password")
usermod -a -G $name www-data
mkdir /home/$name/html -p
chown -R $name:$name /home/$name
chmod 750 /home/$name
#Setting up php-fpm
echo "
[$name]
user = $name
group = $name
listen = /run/php/php7.4-fpm-$name.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
" > /etc/php/7.4/fpm/pool.d/$name.conf
systemctl restart php7.4-fpm

##Setting up Nginx
echo "
server {
    listen 80;

    server_name $name.local;
    root /home/$name/html;

    access_log /var/log/nginx/$name.access.log;
    error_log /var/log/nginx/$name.error.log;

    index index.php index.html;

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.4-fpm-$name.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

" > /etc/nginx/sites-available/$name.local

ln -s /etc/nginx/sites-available/$name.local /etc/nginx/sites-enabled
systemctl restart nginx
##Setting up MariaDB
mysql -p --execute="
CREATE DATABASE $name;
GRANT ALL PRIVILEGES ON ${name}.* TO ${name}@localhost IDENTIFIED BY '${password}';
FLUSH PRIVILEGES;
"
exit