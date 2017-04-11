#!/bin/bash
set -e

echo "$PEM" > pcf.pem
chmod 0600 pcf.pem

mv /opt/terraform/terraform /usr/local/bin
CWD=$(pwd)
pushd $CWD
  cd aws-concourse/terraform/
  cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .

  while read -r line
  do
    `echo "$line" | awk '{print "export "$1"="$3}'`
  done < <(terraform output)

  export RDS_PASSWORD=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`
popd

scp -i pcf.pem -o StrictHostKeyChecking=no aws-concourse/scripts/databases.sql ubuntu@${OPSMAN_URI}:/tmp/.
ssh -i pcf.pem -o StrictHostKeyChecking=no ubuntu@${OPSMAN_URI} "mysql -h $db_host -u $db_username -p$RDS_PASSWORD < /tmp/databases.sql"
