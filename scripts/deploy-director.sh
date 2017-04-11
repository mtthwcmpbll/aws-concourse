#!/bin/bash
set -e

sudo cp tool-om/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

echo "=============================================================================================="
echo "Deploying Director @ https://$OPSMAN_URI ..."
echo "=============================================================================================="

# Apply Changes in Opsman

om-linux --target "https://$OPSMAN_URI" -k \
       --username "$pcf_opsman_admin" \
       --password "$pcf_opsman_admin_passwd" \
  apply-changes
