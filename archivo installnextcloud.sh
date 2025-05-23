#!/bin/bash

# -----------------------------------
# Instala Nextcloud en Ubuntu Server
# Autor: Daniel Jimenez y Jose David Gomez
# -----------------------------------

set -e

# Variables básicas
NEXTCLOUD_DIR="/var/www/nextcloud"
DB_NAME="nextcloud"
DB_USER="nextclouduser"
DB_PASS="admin23456$"
DOMAIN_NAME="nextcloud.tu-dominio.com"

# Actualizar e instalar paquetes
apt update && apt upgrade -y

# Instalamos Apache, PHP y MariaDB..
apt install -y apache2 mariadb-server libapache2-mod-php php php-gd php-json php-mysql \
php-curl php-mbstring php-intl php-imagick php-xml php-zip php-bcmath php-gmp unzip wget curl

# Configurar base de datos
mysql -u root <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Descargar Nextcloud
cd /tmp
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
mv nextcloud ${NEXTCLOUD_DIR}
chown -R www-data:www-data ${NEXTCLOUD_DIR}
chmod -R 755 ${NEXTCLOUD_DIR}

# Configurar Apache
echo "🛠️ Configurando Apache..."
cat <<EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME}
    DocumentRoot ${NEXTCLOUD_DIR}

    <Directory ${NEXTCLOUD_DIR}>
        Require all granted
        AllowOverride All
        Options FollowSymlinks MultiViews
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOF

a2ensite nextcloud.conf
a2enmod rewrite headers env dir mime ssl
systemctl restart apache2

echo "✅ Instalación completada. Accede a https://${DOMAIN_NAME} para finalizar la configuración desde el navegador."
