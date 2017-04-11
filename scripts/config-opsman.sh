#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Configuring OpsManager @ https://$OPSMAN_URI ..."
echo "=============================================================================================="

#Configure Opsman
om-linux --target https://$OPSMAN_URI -k \
     configure-authentication \
       --username "$OPSMAN_USER" \
       --password "$OPSMAN_PASSWORD" \
       --decryption-passphrase "$OPSMAN_PASSWORD"
