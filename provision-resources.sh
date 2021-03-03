#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. $SCRIPTPATH/setup.config
echo -e "\e[1;32m running in $SCRIPTPATH \e[0m"

#environment variables
compartment_id=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"name\",'$compartment_name')].id | [0]")
echo -e "\e[1;32m compartment_id : $compartment_id \e[0m"

echo -e "\e[1;32m => provision \"$object_storage_bucket_name\" object storage bucket \e[0m"
#create object storage
oci os bucket create --compartment-id $compartment_id --name $object_storage_bucket_name

echo -e "\e[1;32m => generating key pair \e[0m"
#generate keypair
cat /dev/zero | ssh-keygen -q -N ""
public_key=$(cat ~/.ssh/id_rsa.pub)
echo -e "\e[1;32m public_key : $public_key \e[0m"

#upload keys to object storage
echo "y" | oci os object put --bucket-name $object_storage_bucket_name --name keys/id_rsa --file ~/.ssh/id_rsa --metadata '{"key-type":"private","uploaded-by":"automation"}'
echo "y" | oci os object put --bucket-name $object_storage_bucket_name --name keys/id_rsa.pub --file ~/.ssh/id_rsa.pub --metadata '{"key-type":"public","uploaded-by":"automation"}'


#create pre-authenticated download links for private key
echo -e "\e[1;32m => provision pre-authenticated path to auth key \e[0m"
time_expires=$(date -d "+7 days" +"%Y-%m-%dT%H:%MZ")
access_uri=$(oci os preauth-request create --name "download key" --access-type ObjectRead --bucket-name $object_storage_bucket_name --time-expires $time_expires --object-name "keys/id_rsa" --query data.\"access-uri\")
home_region=$(oci iam region-subscription list --raw-output --query "data [?\"is-home-region\"].\"region-name\" | [0]" )
object_storage_preauth_link=${object_storage_preauth_link/\/PATH/$access_uri}
object_storage_preauth_link=${object_storage_preauth_link/REGION/$home_region}
object_storage_preauth_link=${object_storage_preauth_link//\"}
echo -e "\e[1;32m object_storage_preauth_link : $object_storage_preauth_link \e[0m"

echo $object_storage_preauth_link >$SCRIPTPATH/object_storage_preauth_link
