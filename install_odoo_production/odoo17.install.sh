#!/bin/bash
# Copyright 2024 pronexo.com
# Hardware Requirements:
#   * >=2GB RAM
#   * >= 20GB SSD
# Software Requirements: 
#   * Ubuntu 22.04 LTS, Ubuntu 23.10,  Debian 12 Bookworm
# v4.0 Production version for Odoo 17.0 Coomunity or Enterprise Edition
# See tutorial for Odoo Enterprise Integration.
# Last updated: 2024-04-10
# step 1: Create pronexo user
# step 2: usermod -aG sudo pronexo
# step 3: Install script

OS_NAME=$(lsb_release -cs)
usuario=pronexo
DIR_PATH=$(pwd)
VCODE=17
VERSION=17.0
OCA_VERSION=17.0
# A. Set Odoo default Port
PORT=1769
DEPTH=1
# B. Set the project name (default /opt/odoo17)
# (Lowercase PROJECT_NAME without spaces. e.g. my_project_name_1)
PROJECT_NAME=odoo17
SERVICE_NAME=$PROJECT_NAME

PATHBASE=/opt/$PROJECT_NAME
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca
# C. Set PostreSQL version:
PG_VERSION=16

wk64=""
wk32=""

if [[ $OS_NAME == "bookworm" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb"

fi

if [[ $OS_NAME == "jammy" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb"

fi


if [[ $OS_NAME == "buster"  ||  $OS_NAME == "bionic" || $OS_NAME == "focal" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1."$OS_NAME"_amd64.deb"
	wk32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1."$OS_NAME"_i386.deb"

fi

if [[ $OS_NAME == "bullseye" ]];

then
	wk64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2."$OS_NAME"_amd64.deb"
	wk32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2."$OS_NAME"_i386.deb"
fi

echo $wk64
sudo useradd -m  -d $PATHBASE -s /bin/bash $usuario
# uncomment if you get sudo permissions
#sudo adduser $usuario sudo

#add universe repository & update (Fix error download libraries)
export DEBIAN_FRONTEND=noninteractive
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade

#### Install Dependencies and Packages
sudo apt-get update && \
sudo apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dirmngr \
    fonts-noto-cjk \
    gnupg \
    libssl-dev \
    node-less \
    npm \
    net-tools \
    xz-utils \
    procps \
    nano \
    htop \
    zip \
    unzip \
    git \
    gcc \
    build-essential \
    libsasl2-dev \
    python3-dev \
    python3-venv \
    libxml2-dev \
    libxml2-dev \
    libxslt1-dev \
    libevent-dev \
    libpng-dev \
    libjpeg-dev \
    xfonts-base \
    xfonts-75dpi \
    libxrender1 \
    python3-pip \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev

##################end python dependencies#####################

############## PG Update and install Postgresql ##############
# Default postgresql install package (old method)
#sudo apt-get install postgresql postgresql-client -y
#sudo  -u postgres  createuser -s $usuario
############## PG Update and install Postgresql ##############

############## PG Update and install Postgresql new way ######
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
sudo apt install -y postgresql-$PG_VERSION postgresql-client-$PG_VERSION
sudo  -u postgres  createuser -s $usuario
############## PG Update and install Postgresql ##############

sudo mkdir $PATHBASE
sudo mkdir $PATHREPOS
sudo mkdir $PATHREPOS_OCA
sudo mkdir $PATH_LOG
cd $PATHBASE
# Download Odoo from git source
sudo git clone https://github.com/odoo/odoo.git -b $VERSION --depth $DEPTH $PATHBASE/odoo
# Download OCA/web (optional backend theme for community only)
sudo git clone https://github.com/oca/web.git -b $OCA_VERSION --depth $DEPTH $PATHREPOS_OCA/web

#nodejs and less
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

sudo dpkg -i --force-depends wkhtmltox_0.12.6*.deb
sudo apt-get -f -y install
sudo ln -s /usr/local/bin/wkhtml* /usr/bin
sudo rm $PATHBASE/wkhtmltox*.deb

# install python requirements file (Odoo)
sudo rm -rf $PATHBASE/venv
sudo mkdir $PATHBASE/venv
sudo chown -R $usuario: $PATHBASE/venv
#virtualenv -q -p python3 $PATHBASE/venv
python3 -m venv $PATHBASE/venv
$PATHBASE/venv/bin/pip3 install --upgrade pip setuptools
$PATHBASE/venv/bin/pip3 install -r $PATHBASE/odoo/requirements.txt

######### Begin Add your custom python extra libs #############
# (e.g. phonenumbers for Odoo WhatsApp App.)
$PATHBASE/venv/bin/pip3 install phonenumbers

######### end extra python pip libs ###########################

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

http_port = $PORT
;dbfilter = odoo$VCODE
logrotate = True
limit_time_real = 6000
limit_time_cpu = 6000
proxy_mode = False

############# addons path ######################################

addons_path =
    $PATHREPOS,
    $PATHREPOS_OCA/web,
    $PATHBASE/odoo/addons

#################################################################
" | sudo tee --append $PATHBASE/config/odoo$VCODE.conf

sudo rm /etc/systemd/system/$SERVICE_NAME.service
sudo touch /etc/systemd/system/$SERVICE_NAME.service
sudo chmod +x /etc/systemd/system/$SERVICE_NAME.service
echo "
[Unit]
Description=Odoo$VCODE-$SERVICE_NAME
After=postgresql.service

[Service]
Restart=on-failure
RestartSec=5s
Type=simple
User=$usuario
ExecStart=$PATHBASE/venv/bin/python3 $PATHBASE/odoo/odoo-bin --config $PATHBASE/config/odoo$VCODE.conf

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/$SERVICE_NAME.service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME.service
sudo systemctl start $SERVICE_NAME.service

sudo chown -R $usuario: $PATHBASE

## Add cron backup project folder (Todos lunes 4:30am)
sudo -u root bash << eof
cd /root
echo "Agregando crontab para backup carpeta instalacion Odoo..."

sudo crontab -l | sed -e '/zip/d; /$PROJECT_NAME/d' > temporal

echo "
30 4 * * * zip -r /opt/$PROJECT_NAME.zip $PATHBASE" >> temporal
crontab temporal
rm temporal
eof







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
vim /opt/odoo17/config/odoo17.conf" | sudo tee --append $PATHBASE/scripts/econf
sudo chmod +x $PATHBASE/scripts/econf

#log
sudo touch $PATHBASE/scripts/log
echo "#!/bin/bash
cat /opt/odoo17/log/odoo17-server.log" | sudo tee --append $PATHBASE/scripts/log
sudo chmod +x $PATHBASE/scripts/log

#pconf
sudo touch $PATHBASE/scripts/pconf
echo "#!/bin/bash

if [[ ! -f "/etc/postgresql/16/main/pg_hba.conf.bak" ]]
then
    sudo cp /etc/postgresql/16/main/pg_hba.conf /etc/postgresql/16/main/pg_hba.conf.bak
fi
sudo vim /etc/postgresql/16/main/pg_hba.conf

sudo /etc/init.d/postgresql restart" | sudo tee --append $PATHBASE/scripts/pconf
sudo chmod +x $PATHBASE/scripts/pconf


#restart
sudo touch $PATHBASE/scripts/restart
echo "#!/bin/bash
truncate -s 0 /opt/odoo17/log/odoo17-server.log
sudo systemctl restart odoo17
date" | sudo tee --append $PATHBASE/scripts/restart
sudo chmod +x $PATHBASE/scripts/restart


#start
sudo touch $PATHBASE/scripts/start
echo "#!/bin/bash
sudo systemctl start odoo17" | sudo tee --append $PATHBASE/scripts/start
sudo chmod +x $PATHBASE/scripts/start

#stop
sudo touch $PATHBASE/scripts/stop
echo "#!/bin/bash
sudo systemctl stop odoo17" | sudo tee --append $PATHBASE/scripts/stop
sudo chmod +x $PATHBASE/scripts/stop


#status
sudo touch $PATHBASE/scripts/status
echo "#!/bin/bash
systemctl status odoo17" | sudo tee --append $PATHBASE/scripts/status
sudo chmod +x $PATHBASE/scripts/status


#status
sudo touch $PATHBASE/scripts/tlog
echo "#!/bin/bash
truncate -s 0 /opt/odoo17/log/odoo17-server.log" | sudo tee --append $PATHBASE/scripts/tlog
sudo chmod +x $PATHBASE/scripts/tlog




echo "Copiando scripts a /usr/bin/"
cd $PATHBASE/scripts
sudo cp $PATHBASE/scripts/* /usr/bin/




sudo chown -R $usuario: $PATHBASE









echo "Odoo $VERSION Installation has finished!! ;) by pronexo.com"
IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
echo "You can access from: http://$IP:$PORT  or http://localhost:$PORT"
