#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. $SCRIPTPATH/setup.config
. $SCRIPTPATH/instance_image_ocid

echo -e "\e[1;32m running in $SCRIPTPATH \e[0m"
echo -e "\e[1;32m => provision \"$instance_name\" compute instance \e[0m"
echo -e "\e[1;32m instance_image_ocid : $instance_image_ocid \e[0m"

compartment_id=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?\"lifecycle-state\" == 'ACTIVE'] | [?contains(\"name\",'$compartment_name')].id | [0]")
echo -e "\e[1;32m compartment_id : $compartment_id \e[0m"


vcn_id=$(oci network vcn list --compartment-id $compartment_id --raw-output --query "data[?contains(\"display-name\",'$vcn_name')].id | [0]")
echo -e "\e[1;32m vcn_id : $vcn_id \e[0m"

vcn_public_subnet_id=$(oci network subnet list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_public_subnet_name')].id | [0]")
echo -e "\e[1;32m vcn_public_subnet_id : $vcn_public_subnet_id \e[0m"


instance_ad=$(oci iam availability-domain list --all --query 'data[?contains(name, `'"${availability_domain}"'`)] | [0].name' --raw-output)
echo -e "\e[1;32m instance_ad : $instance_ad \e[0m"


public_key=$(cat ~/.ssh/id_rsa.pub)
instance_metadata='{"ssh_authorized_keys": "'$public_key'"}'
echo -e "\e[1;32m instance_metadata : $instance_metadata \e[0m"

instance_ocid=$(oci compute instance launch --availability-domain "$instance_ad" --compartment-id "$compartment_id" --shape "$instance_shape" --subnet-id "$vcn_public_subnet_id" --assign-public-ip true --display-name "$instance_name" --image-id "$instance_image_ocid" --metadata "$instance_metadata" --wait-for-state RUNNING --query 'data.id' --raw-output)
echo -e "\e[1;32m instance_ocid : $instance_ocid \e[0m"

instance_public_ip=$(oci compute instance list-vnics --compartment-id "$compartment_id" --instance-id "$instance_ocid" --query 'data[0]."public-ip"' --raw-output)
echo -e "\e[1;32m instance_public_ip : $instance_public_ip \e[0m"

echo  $instance_public_ip > $SCRIPTPATH/instance_public_ip
