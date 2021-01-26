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
# v1.9
# Last updated: 2020-07-19
##############################################################################

OS_NAME=$(lsb_release -cs)
usuario=$USER
DIR_PATH=$(pwd)
VCODE=13
VERSION=13.0
PORT=1369
DEPTH=1
# E.G: mycustomer-name
CLIENT=odoosrc
PATHBASE=/opt/$CLIENT
PATH_LOG=$PATHBASE/log
PATHREPOS=$PATHBASE/$VERSION/extra-addons
PATHREPOS_OCA=$PATHREPOS/oca

if [[ $OS_NAME == "disco" ]];

then
	# This code is compatible with Ubuntu 19.04
	OS_NAME="bionic"

fi

wk64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_amd64.deb"
wk32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_NAME"_i386.deb"

sudo adduser --system --quiet --shell=/bin/bash --home=$PATHBASE --gecos 'ODOO' --group $usuario
sudo adduser $usuario sudo

# add universe repository & update (Fix error download libraries)
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y git
# Update and install Postgresql
sudo apt-get install postgresql -y
sudo su - postgres -c "createuser -s $usuario"

sudo mkdir $PATHBASE
sudo mkdir $PATHBASE/$VERSION
sudo mkdir $PATH_LOG
sudo mkdir $PATHREPOS
sudo mkdir $PATHREPOS_OCA
cd $PATHBASE
# Download Odoo from git source
sudo git clone https://github.com/odoo/odoo.git -b $VERSION --depth $DEPTH $PATHBASE/$VERSION/odoo

# Install python3 and dependencies for Odoo
sudo apt-get -y install gcc python3-dev libxml2-dev libxslt1-dev \
 libevent-dev libsasl2-dev libldap2-dev libpq-dev \
 libpng-dev libjpeg-dev

sudo apt-get -y install python3 python3-pip python-pip
sudo pip3 install libsass vobject qrcode num2words setuptools

# FIX wkhtml* dependencie Ubuntu Server 18.04
sudo apt-get -y install libxrender1

# Install nodejs and less
sudo apt-get install -y npm node-less
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less

# Download & install WKHTMLTOPDF
sudo rm $PATHBASE/wkhtmltox_0.12.5-1*.deb
sudo rm wkhtmltox_0.12.5-1*.deb
if [[ "`getconf LONG_BIT`" == "32" ]];

then
	sudo wget $wk32
else
	sudo wget $wk64
fi

sudo dpkg -i --force-depends wkhtmltox_0.12.5-1*.deb
sudo ln -s /usr/local/bin/wkhtml* /usr/bin


# install python requirements file (Odoo)
sudo pip3 install -r $PATHBASE/$VERSION/odoo/requirements.txt
sudo apt-get -f -y install

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
    $PATHBASE/$VERSION/odoo/addons

#################################################################

xmlrpc_port = $PORT
;dbfilter = odoo13
logrotate = True
limit_time_real = 1000
limit_time_cpu = 1000
" | sudo tee --append $PATHBASE/config/odoo$VCODE.conf

sudo rm /etc/systemd/system/odoo$VCODE.service
sudo touch /etc/systemd/system/odoo$VCODE.service
sudo chmod +x /etc/systemd/system/odoo$VCODE.service
echo "
[Unit]
Description=odoo$VCODE
After=postgresql.service

[Service]
Type=simple
User=$usuario
ExecStart=$PATHBASE/$VERSION/odoo/odoo-bin --config $PATHBASE/config/odoo$VCODE.conf

[Install]
WantedBy=multi-user.target
" | sudo tee --append /etc/systemd/system/odoo$VCODE.service
sudo systemctl daemon-reload
sudo systemctl enable odoo$VCODE.service
sudo systemctl start odoo$VCODE

sudo chown -R $usuario: $PATHBASE
sudo chown -R $usuario: $PATHBASE/config


echo "Odoo $VERSION Installation has finished!! ;) by pronexo.com"
echo "You can access from: http://mydomain.com:$PORT  or http://localhost:$PORT"

