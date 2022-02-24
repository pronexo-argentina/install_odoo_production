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
# Ubuntu 18.04 LTS tested
# v2.4
# Last updated: 2022-02-23
##############################################################################

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
# AVISO IMPORTANTE!!! (WARNING!!!)
# ASEGURESE DE TENER UN SERVIDOR / VPS CON AL MENOS > 2GB DE RAM
# You must to have at least > 2GB of RAM
# Ubuntu 18.04,LTS tested
# v2.5
# Last updated: 2022-02-249
##############################################################################
OS_NAME=$(lsb_release -cs)
usuario=$USER
DIR_PATH=$(pwd)
VCODE=13
VERSION=13.0
PORT=1369
DEPTH=1
PROJECT_NAME=odoo13
PATHBASE=/opt/$PROJECT_NAME
PATHOPT=/opt/
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/$VERSION/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca

if [[ $OS_NAME == "disco" ]];

then
    echo $OS_NAME
    OS_NAME="bionic"

fi

if [[ $OS_NAME == "focal" ]];

then
    echo $OS_NAME
    OS_NAME="bionic"

fi

wk64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_amd64.deb"
wk32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_i386.deb"

sudo adduser --system --quiet --shell=/bin/bash --home=$PATHBASE --gecos 'ODOO' --group $usuario
sudo adduser $usuario sudo


sudo apt-get -y install software-properties-common


# add universe repository & update (Fix error download libraries)
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade
sudo apt-get  -y install git
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

# Install python3 and dependencies for Odoo
echo "instalando librerías"
sudo apt-get -y install gcc python3-dev swig libssl-dev libxml2-dev libxslt1-dev \
 libevent-dev libsasl2-dev libldap2-dev libpq-dev \
 libpng-dev libjpeg-dev xfonts-base xfonts-75dpi libcups2-dev vsftpd

sudo apt-get -y install python3 python3-pip python3-setuptools htop
sudo pip3 install virtualenv


# FIX wkhtml* dependencie Ubuntu Server 18.04
sudo apt-get -y install libxrender1

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

sudo git clone https://github.com/odoo/odoo.git -b $VERSION --depth $DEPTH $PATHBASE/$VERSION/odoo
sudo git clone https://github.com/odooerpdevelopers/backend_theme.git -b $VERSION --depth $DEPTH $PATHREPOS/backend_theme
sudo git clone https://github.com/oca/web.git -b $VERSION --depth $DEPTH $PATHREPOS_OCA/web


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
$PATHBASE/$VERSION/venv/bin/pip3 install vobject qrcode num2words pysftp
$PATHBASE/$VERSION/venv/bin/pip3 install -r $PATHBASE/$VERSION/odoo/requirements.txt



#cd $PATHOPT


#if [[ ! -f "/opt/odoo13.tar.gz" ]]
#then
#    echo "Descargando odoo13 desde pronexo.com"
#    sudo wget http://d13.pronexo.com/odoo13.tar.gz
#    
#fi

#echo "descomprimiendo odoo 13 box"
#sudo tar xvzf odoo13.tar.gz




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

sudo chown -R $usuario: $PATHBASE


echo "Instalando nginx"
sudo apt-get -y install nginx


echo "Instalando Let’s Encrypt"
sudo add-apt-repository ppa:certbot/certbot
sudo apt update
sudo apt install -y python-certbot-nginx


echo "Creando scripts de comandos"
cd $DIR_PATH





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
upstream odoo {
 server 127.0.0.1:$PORT;
}
upstream odoochat {
 server 127.0.0.1:8072;
}

server {
        #listen 80 default_server;
        #listen [::]:80 default_server;


        server_name _;
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
                 proxy_pass http://odoochat;
        }
        # Redirect requests to odoo backend server

        location / {
                proxy_pass http://odoo;
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



echo "Copiando scripts a /usr/bin/"
cd $PATHBASE/scripts
sudo cp $PATHBASE/scripts/* /usr/bin/






echo "Odoo $VERSION Installation has finished!! ;) by pronexo.com"
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access from: http://$IP:$PORT  or http://localhost:$PORT"
