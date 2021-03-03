#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo -e "\e[1;32m => provisioning ALL resources \e[0m"
sh $SCRIPTPATH/provision-compartment.sh
sh $SCRIPTPATH/provision-network.sh
sh $SCRIPTPATH/provision-resources.sh
sh $SCRIPTPATH/provision-customer-agreement.sh
sh $SCRIPTPATH/provision-compute.sh


echo -e "\e[1;32m <= DONE \e[0m"
dt=$(cat $SCRIPTPATH/instance_public_ip)
echo -e "\e[1;32m SSH to : $dt \e[0m"
dt=$(cat $SCRIPTPATH/object_storage_preauth_link)
echo -e "\e[1;32m SSH key : $dt \e[0m"



