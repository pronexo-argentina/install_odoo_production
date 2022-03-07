#!/bin/bash
##############################################################################
#
#    Copyright (C) 2007  pronexo.com  (https://www.pronexo.com)
#    All Rights Reserved.
#    Author: Juan Manuel De Castro - jm@pronexo.com - pronexo@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
# AVISO IMPORTANTE!!! 
# ASEGURESE DE TENER UN SERVIDOR / VPS CON AL MENOS > 2GB DE RAM
# Ubuntu 20.04 LTS tested
# v2.7.1
# Last updated: 2022-07-03

OS_NAME=$(lsb_release -cs)
usuario=$USER
DIR_PATH=$(pwd)
VCODE=15
VERSION=15.0
PORT=1569
DEPTH=1
PROJECT_NAME=odoo15
PATHBASE=/opt/$PROJECT_NAME
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/$VERSION/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca

if [[ $OS_NAME == "disco" ]];

then
    echo $OS_NAME
    OS_NAME="bionic"

fi

if [[ $OS_NAME == "buster" ]];

then
    echo $OS_NAME
    OS_NAME="buster"

fi

if [[ $OS_NAME == "focal" ]];

then
    echo $OS_NAME
    OS_NAME="focal"

fi

wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1."$OS_NAME"_amd64.deb"
wk32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1."$OS_NAME"_i386.deb"

sudo adduser --system --quiet --shell=/bin/bash --home=$PATHBASE --gecos 'ODOO' --group $usuario
sudo adduser $usuario sudo

# add universe repository & update (Fix error download libraries)
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y git

# Update and install Postgresql
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-14
sudo  -u postgres  createuser -s $usuario

sudo mkdir $PATHBASE
sudo mkdir $PATHBASE/$VERSION
sudo mkdir $PATHREPOS
sudo mkdir $PATHREPOS_OCA
sudo mkdir $PATH_LOG
cd $PATHBASE
# Download Odoo from git source
sudo git clone https://github.com/odoo/odoo.git -b $VERSION --depth $DEPTH $PATHBASE/$VERSION/odoo
####sudo git clone https://github.com/odooerpdevelopers/backend_theme.git -b $VERSION --depth $DEPTH $PATHREPOS/backend_theme
# ATENCION temporalmente dejamos la 14.0 dado que aun no existe el repo para v15, de este solo necesitamos el modulo web_responsive para
sudo git clone https://github.com/oca/web.git -b 15.0 --depth $DEPTH $PATHREPOS_OCA/web


# Install python3 and dependencies for Odoo
sudo apt-get -y install gcc python3-dev libxml2-dev libxslt1-dev \
 libevent-dev libsasl2-dev libldap2-dev libpq-dev \
 libpng-dev libjpeg-dev xfonts-base xfonts-75dpi

sudo apt-get -y install python3 python3-pip python3-setuptools htop zip unzip python3-lxml python3-vatnumber
sudo pip3 install virtualenv

# FIX wkhtml* dependencie Ubuntu Server 20.04.3 LTS
sudo apt-get -y install libxrender1 fontconfig

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

# Download & install WKHTMLTOPDF
sudo rm $PATHBASE/wkhtmltox*.deb

if [[ "`getconf LONG_BIT`" == "32" ]];

then
        sudo wget $wk32
else
        sudo wget $wk64
fi

sudo dpkg -i --force-depends wkhtmltox_0.12.5-1*.deb
sudo apt-get -f -y install
sudo ln -s /usr/local/bin/wkhtml* /usr/bin
sudo rm $PATHBASE/wkhtmltox*.deb
sudo apt-get -f -y install

# install python requirements file (Odoo)
sudo rm -rf $PATHBASE/$VERSION/venv
sudo mkdir $PATHBASE/$VERSION/venv
sudo chown -R $usuario: $PATHBASE/$VERSION/venv
virtualenv -q -p python3 $PATHBASE/$VERSION/venv
# sed -i '/libsass/d' $PATHBASE/$VERSION/odoo/requirements.txt
$PATHBASE/$VERSION/venv/bin/pip3 install libsass vobject qrcode num2words
$PATHBASE/$VERSION/venv/bin/pip3 install -r $PATHBASE/$VERSION/odoo/requirements.txt

cd $DIR_PATH

sudo mkdir $PATHBASE/config
sudo rm $PATHBASE/config/odoo$VCODE.conf
sudo touch $PATHBASE/config/odoo$VCODE.conf

echo "
[options]
; This is the password that allows database operations:
;admin_passwd =
db_host = False
db_port = False
;db_user =
;db_password =
data_dir = $PATHBASE/data
logfile= $PATH_LOG/odoo$VCODE-server.log

############# addons path ######################################

addons_path =
    $PATHREPOS,
    $PATHREPOS_OCA/web,
    $PATHBASE/$VERSION/odoo/addons

#################################################################

xmlrpc_port = $PORT
;dbfilter = odoo$VCODE
logrotate = True
limit_time_real = 6000
limit_time_cpu = 6000
" | sudo tee --append $PATHBASE/config/odoo$VCODE.conf

sudo rm /etc/systemd/system/odoo$VCODE.service
sudo touch /etc/systemd/system/odoo$VCODE.service
sudo chmod +x /etc/systemd/system/odoo$VCODE.service
echo "
[Unit]
Description=Odoo$VCODE
After=postgresql.service

[Service]
Type=simple
User=$usuario
ExecStart=$PATHBASE/$VERSION/venv/bin/python $PATHBASE/$VERSION/odoo/odoo-bin --config $PATHBASE/config/odoo$VCODE.conf

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/odoo$VCODE.service
sudo systemctl daemon-reload
sudo systemctl enable odoo$VCODE.service
sudo systemctl start odoo$VCODE

echo "Instalando nginx"
sudo apt-get -y install nginx


echo "Instalando Let’s Encrypt"
sudo apt install -y certbot python3-certbot-nginx


echo "Creando scripts de comandos"
cd $DIR_PATH

echo "Creando carpeta scrips"
sudo mkdir $PATHBASE/scripts



echo "Creando script para host odoo nginx "
sudo rm $PATHBASE/scripts/nginx-odoo-host.sh
sudo touch $PATHBASE/scripts/nginx-odoo-host.sh
echo "#!/bin/bash
echo 'Creando /etc/nginx/sites-available/odoo.host'
sudo touch /etc/nginx/sites-available/odoo.host
sudo rm /etc/nginx/sites-enabled/default
cd /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/odoo.host odoo.host
echo '
upstream odoo.pronexo.com {
 server 127.0.0.1:$PORT;
}
upstream odoochat.pronexo.com {
 server 127.0.0.1:8072;
}

server {
        #listen 80 default_server;
        #listen [::]:80 default_server;


        server_name odoo.pronexo.com;
        proxy_buffers 16 64k;
        proxy_buffer_size 128k;
        proxy_read_timeout 900s;
        proxy_connect_timeout 900s;
        proxy_send_timeout 900s;

        # Add Headers for odoo proxy mode
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        add_header X-Frame-Options \"SAMEORIGIN\";
        add_header X-XSS-Protection \"1; mode=block\";
        proxy_set_header X-Client-IP \$remote_addr;
        proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;

        #   odoo    log files
        access_log  /var/log/nginx/odoo.pronexo.com-access.log;
        error_log   /var/log/nginx/odoo.pronexo.com-error.log;

        #   force   timeouts    if  the backend dies
        proxy_next_upstream error   timeout invalid_header  http_500    http_502
        http_503;
        types {
        text/less less;
        text/scss scss;
        }

        #   enable  data    compression
        gzip    on;
        gzip_min_length 1100;
        gzip_buffers    4   32k;
        gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
        gzip_vary   on;
        client_header_buffer_size 4k;
        large_client_header_buffers 4 64k;
        client_max_body_size 0;
# Redirect longpoll requests to odoo longpolling port
        location /longpolling {
                 proxy_pass http://odoochat.pronexo.com;
        }
        # Redirect requests to odoo backend server

        location / {
                proxy_pass http://odoo.pronexo.com;
                proxy_redirect off;

        }



        location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
        expires 2d;
        proxy_pass http://127.0.0.1:$PORT;
        add_header Cache-Control \"public, no-transform\";
        }
        # cache some static data in memory for 60mins.
        location ~ /[a-zA-Z0-9_-]*/static/ {
        proxy_cache_valid 200 302 60m;
        proxy_cache_valid 404      1m;
        proxy_buffering    on;
        expires 864000;
        proxy_pass    http://127.0.0.1:$PORT;
        }




}' > /etc/nginx/sites-enabled/odoo.host" | sudo tee --append $PATHBASE/scripts/nginx-odoo-host.sh
sudo chmod +x $PATHBASE/scripts/nginx-odoo-host.sh
sudo sh $PATHBASE/scripts/nginx-odoo-host.sh

#econf
sudo touch $PATHBASE/scripts/econf
echo "#!/bin/bash
vim /opt/odoo15/config/odoo15.conf" | sudo tee --append $PATHBASE/scripts/econf
sudo chmod +x $PATHBASE/scripts/econf

#log
sudo touch $PATHBASE/scripts/log
echo "#!/bin/bash
cat /opt/odoo15/log/odoo15-server.log" | sudo tee --append $PATHBASE/scripts/log
sudo chmod +x $PATHBASE/scripts/log

#pconf
sudo touch $PATHBASE/scripts/pconf
echo "#!/bin/bash

if [[ ! -f "/etc/postgresql/14/main/pg_hba.conf.bak" ]]
then
    sudo cp /etc/postgresql/14/main/pg_hba.conf /etc/postgresql/14/main/pg_hba.conf.bak
fi
sudo vim /etc/postgresql/14/main/pg_hba.conf

sudo /etc/init.d/postgresql restart" | sudo tee --append $PATHBASE/scripts/pconf
sudo chmod +x $PATHBASE/scripts/pconf


#restart
sudo touch $PATHBASE/scripts/restart
echo "#!/bin/bash
truncate -s 0 /opt/odoo15/log/odoo15-server.log
sudo systemctl restart odoo15
date" | sudo tee --append $PATHBASE/scripts/restart
sudo chmod +x $PATHBASE/scripts/restart


#start
sudo touch $PATHBASE/scripts/start
echo "#!/bin/bash
sudo systemctl start odoo15" | sudo tee --append $PATHBASE/scripts/start
sudo chmod +x $PATHBASE/scripts/start

#stop
sudo touch $PATHBASE/scripts/stop
echo "#!/bin/bash
sudo systemctl stop odoo15" | sudo tee --append $PATHBASE/scripts/stop
sudo chmod +x $PATHBASE/scripts/stop


#status
sudo touch $PATHBASE/scripts/status
echo "#!/bin/bash
systemctl status odoo15" | sudo tee --append $PATHBASE/scripts/status
sudo chmod +x $PATHBASE/scripts/status


#status
sudo touch $PATHBASE/scripts/tlog
echo "#!/bin/bash
truncate -s 0 /opt/odoo15/log/odoo15-server.log" | sudo tee --append $PATHBASE/scripts/tlog
sudo chmod +x $PATHBASE/scripts/tlog




echo "Copiando scripts a /usr/bin/"
cd $PATHBASE/scripts
sudo cp $PATHBASE/scripts/* /usr/bin/




sudo chown -R $usuario: $PATHBASE

echo "Odoo $VERSION Installation has finished!! ;) by pronexo.com"
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access from: http://$IP:$PORT  or http://localhost:$PORT"

