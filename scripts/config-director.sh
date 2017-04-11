#!/bin/bash
set -ex

mv /opt/terraform/terraform /usr/local/bin
CWD=$(pwd)
cd aws-concourse/terraform/
cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .

while read -r line
do
  `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output)

export AWS_ACCESS_KEY_ID=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
export RDS_PASSWORD=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`

cd $CWD
# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="aws-concourse/json-opsman/${AWS_TEMPLATE}"
json_file_template="${json_file_path}/opsman-template.json"
json_file="${json_file_path}/opsman.json"

cp ${json_file_template} ${json_file}

export S3_ESCAPED=${S3_ENDPOINT//\//\\/}

perl -pi -e "s/{{aws_vpc_id}}/${vpc_id}/g" ${json_file}
perl -pi -e "s/{{aws_sg_id}}/${pcf_security_group}/g" ${json_file}
perl -pi -e "s/{{aws_keypair_name}}/${AWS_KEY_NAME}/g" ${json_file}
perl -pi -e "s/{{aws_region}}/${AWS_REGION}/g" ${json_file}
perl -pi -e "s/{{s3_endpoint}}/${S3_ESCAPED}/g" ${json_file}
perl -pi -e "s/{{s3_bucket}}/${s3_pcf_bosh}/g" ${json_file}
perl -pi -e "s/{{rds_host}}/${db_host}/g" ${json_file}
perl -pi -e "s/{{rds_user}}/${db_username}/g" ${json_file}
perl -pi -e "s/{{rds_database}}/${db_database}/g" ${json_file}
perl -pi -e "s/{{aws_az1}}/${az1}/g" ${json_file}
perl -pi -e "s/{{aws_az2}}/${az2}/g" ${json_file}
perl -pi -e "s/{{aws_az3}}/${az3}/g" ${json_file}
perl -pi -e "s/{{vpc_dns}}/${dns}/g" ${json_file}

perl -pi -e "s/{{deployment_subnet_1}}/${ert_subnet_id_az1}/g" ${json_file}
perl -pi -e "s|{{deployment_subnet_1_cidr}}|${ert_subnet_cidr_az1}|g" ${json_file}
perl -pi -e "s/{{deployment_subnet_1_reserved}}/${ert_subnet_reserved_ranges_z1}/g" ${json_file}
perl -pi -e "s/{{deployment_subnet_1_gw}}/${ert_subnet_gw_az1}/g" ${json_file}

perl -pi -e "s/{{deployment_subnet_2}}/${ert_subnet_id_az2}/g" ${json_file}
perl -pi -e "s|{{deployment_subnet_2_cidr}}|${ert_subnet_cidr_az2}|g" ${json_file}
perl -pi -e "s/{{deployment_subnet_2_reserved}}/${ert_subnet_reserved_ranges_z2}/g" ${json_file}
perl -pi -e "s/{{deployment_subnet_2_gw}}/${ert_subnet_gw_az2}/g" ${json_file}

perl -pi -e "s/{{deployment_subnet_3}}/${ert_subnet_id_az3}/g" ${json_file}
perl -pi -e "s|{{deployment_subnet_3_cidr}}|${ert_subnet_cidr_az3}|g" ${json_file}
perl -pi -e "s/{{deployment_subnet_3_reserved}}/${ert_subnet_reserved_ranges_z3}/g" ${json_file}
perl -pi -e "s/{{deployment_subnet_3_gw}}/${ert_subnet_gw_az3}/g" ${json_file}

perl -pi -e "s/{{services_subnet_1}}/${services_subnet_id_az1}/g" ${json_file}
perl -pi -e "s|{{services_subnet_1_cidr}}|${services_subnet_cidr_az1}|g" ${json_file}
perl -pi -e "s/{{services_subnet_1_reserved}}/${services_subnet_reserved_ranges_z1}/g" ${json_file}
perl -pi -e "s/{{services_subnet_1_gw}}/${services_subnet_gw_az1}/g" ${json_file}

perl -pi -e "s/{{services_subnet_2}}/${services_subnet_id_az2}/g" ${json_file}
perl -pi -e "s|{{services_subnet_2_cidr}}|${services_subnet_cidr_az2}|g" ${json_file}
perl -pi -e "s/{{services_subnet_2_reserved}}/${services_subnet_reserved_ranges_z2}/g" ${json_file}
perl -pi -e "s/{{services_subnet_2_gw}}/${services_subnet_gw_az2}/g" ${json_file}

perl -pi -e "s/{{services_subnet_3}}/${services_subnet_id_az3}/g" ${json_file}
perl -pi -e "s|{{services_subnet_3_cidr}}|${services_subnet_cidr_az3}|g" ${json_file}
perl -pi -e "s/{{services_subnet_3_reserved}}/${services_subnet_reserved_ranges_z3}/g" ${json_file}
perl -pi -e "s/{{services_subnet_3_gw}}/${services_subnet_gw_az3}/g" ${json_file}

perl -pi -e "s/{{infra_subnet}}/${infra_subnet_id_az1}/g" ${json_file}
perl -pi -e "s|{{infra_subnet_cidr}}|${infra_subnet_cidr_az1}|g" ${json_file}
perl -pi -e "s/{{infra_subnet_reserved}}/${infra_subnet_reserved_ranges_z1}/g" ${json_file}
perl -pi -e "s/{{infra_subnet_gw}}/${infra_subnet_gw_az1}/g" ${json_file}

echo "=============================================================================================="
echo "Configuring Director @ https://$OPSMAN_URI ..."
cat $json_file
echo "=============================================================================================="

sudo cp tool-om-beta/om-linux /usr/local/bin
sudo chmod 755 /usr/local/bin/om-linux

om-linux -t "https://$OPSMAN_URI" -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" -k \
  aws -a $AWS_ACCESS_KEY_ID \
  -s $AWS_SECRET_ACCESS_KEY \
  -d $RDS_PASSWORD \
  -p "$PEM" -c "$(cat ${json_file})"
