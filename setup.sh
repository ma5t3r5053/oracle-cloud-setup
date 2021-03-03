#!/bin/bash
echo -e "\e[1;32m => provisioning ALL resources \e[0m"
sh ./provision-compartment.sh
sh ./provision-network.sh
sh ./provision-resources.sh
sh ./provision-customer-agreement.sh
sh ./provision-compute.sh

