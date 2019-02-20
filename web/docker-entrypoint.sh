#!/bin/bash
USER_ID=${LOCAL_USER_ID:-9001}
echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m standarduser
export HOME=/home/standarduser

set -e
echo "[Entrypoint] VCL Website"

# Set secrets
echo "[Entrypoint] Setting up secrets.php"
cp /var/www/html/.ht-inc/secrets-default.php /var/www/html/.ht-inc/secrets.php
sed -i "s/^\(\$vclhost\s=\s\).*/\1\'${DB_HOST//\//\\/}';/" /var/www/html/.ht-inc/secrets.php
sed -i "s/^\(\$vcldb\s=\s\).*/\1\'${MYSQL_DATABASE//\//\\/}';/" /var/www/html/.ht-inc/secrets.php
sed -i "s/^\(\$vclusername\s=\s\).*/\1\'${MYSQL_USER//\//\\/}';/" /var/www/html/.ht-inc/secrets.php
sed -i "s/^\(\$vclpassword\s=\s\).*/\1\'${MYSQL_PASSWORD//\//\\/}';/" /var/www/html/.ht-inc/secrets.php
sed -i "s/^\(\$cryptkey\s=\s\).*/\1\'${VCL_CRYPT_KEY//\//\\/}';/" /var/www/html/.ht-inc/secrets.php
sed -i "s/^\(\$pemkey\s=\s\).*/\1\'${VCL_PEM_KEY//\//\\/}';/" /var/www/html/.ht-inc/secrets.php
echo "[Entrypoint] secrets.php updated"
cat /var/www/html/.ht-inc/secrets.php

# update conf.php
echo "[Entrypoint] updating conf.php"
if [ ! -f /etc/vcl-web-conf/conf.php ]; then
    echo "[Entrypoint] /etc/vcl-web-conf/conf.php does not exists. cannot update /var/www/html/.ht-inc/conf.php"
else
    echo "[Entrypoint] /etc/vcl-web-conf/conf.php found updating /var/www/html/.ht-inc/conf.php"
    ln -svf /etc/vcl-web-conf/conf.php /var/www/html/.ht-inc/conf.php
fi
echo "[Entrypoint] conf.php updated"
cat /var/www/html/.ht-inc/conf.php

# Configure Postfix MTA
echo "[Entrypoint] Updating postfix configuration"
postconf -e inet_interfaces=all
postconf -e relayhost=${SMTP_RELAY_HOST}:${SMTP_RELAY_PORT}

# Add standarduser to apache group
echo "[Entrypoint] Adding standarduser to apache group"
usermod -a -G apache standarduser
echo "[Entrypoint] Setting apache user to standarduser in /etc/httpd/conf/httpd.conf"
sed -i "s/^User\sapache/User standarduser/" /etc/httpd/conf/httpd.conf
echo "[Entrypoint] Setting directory permissions for maintenance and cryptkey"
if [ ! -d /var/www/html/.ht-inc/maintenance ]; then
    echo "[Entrypoint] creating /var/www/html/.ht-inc/maintenance"
    mkdir /var/www/html/.ht-inc/maintenance
fi
chown -R standarduser /var/www/html/.ht-inc/maintenance
if [ ! -d /var/www/html/.ht-inc/cryptkey ]; then
    echo "[Entrypoint] creating /var/www/html/.ht-inc/cryptkey"
    mkdir /var/www/html/.ht-inc/cryptkey
fi
chown -R standarduser /var/www/html/.ht-inc/cryptkey
chown -R standarduser /var/www/html/.ht-inc/secrets.php

# Run key generation
echo "[Entrypoint] Generating encryption keys and granting permissions to standarduser"
cd /var/www/html/.ht-inc
./genkeys.sh
chown standarduser *.pem

# build themes css
echo "[Entrypoint] Building themes css"
cd /var/www/html/themes/
./copydojocss.sh default
./copydojocss.sh dropdownmenus

# Start HTTPD
echo "[Entrypoint] Starting VCL Website using $@"
exec "$@"
