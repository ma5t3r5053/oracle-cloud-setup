#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. $SCRIPTPATH/setup.config

echo -e "\e[1;32m running in $SCRIPTPATH \e[0m"
echo -e "\e[1;32m => provision \"$compartment_name\" compartment \e[0m"

#create compartment
root_compartment_id=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"id\",'tenancy')].id | [0]")
echo -e "\e[1;32m root_compartment_id : $root_compartment_id \e[0m"


compartment_id=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?\"lifecycle-state\" == 'ACTIVE'] | [?contains(\"name\",'$compartment_name')].id | [0]")
[ -z "$compartment_id" ] && \
compartment_id=$(oci iam compartment create --name "$compartment_name" --description "$compartment_description" --compartment-id $root_compartment_id --query data.id)
compartment_id=${compartment_id//\"}
echo -e "\e[1;32m compartment_id : $compartment_id \e[0m"


#update cli config
#echo -e "\e[1;32m => update oci cli config \e[0m"
#mkdir ~/.oci
#touch ~/.oci/oci_cli_rc
#echo "[DEFAULT]" >>~/.oci/oci_cli_rc
#echo "compartment-id = "$compartment_id >>~/.oci/oci_cli_rc


