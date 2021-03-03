#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. $SCRIPTPATH/setup.config

echo -e "\e[1;32m running in $SCRIPTPATH \e[0m"
echo -e "\e[1;32m => provision \"$vcn_name\" network \e[0m"

#get compartment
compartment_id=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?\"lifecycle-state\" == 'ACTIVE'] | [?contains(\"name\",'$compartment_name')].id | [0]")
echo -e "\e[1;32m compartment_id : $compartment_id \e[0m"


#create VCN
vcn_id=$(oci network vcn list --compartment-id $compartment_id --raw-output --query "data[?contains(\"display-name\",'$vcn_name')].id | [0]")
[ -z "$vcn_id" ] && \
vcn_id=$(oci network vcn create --cidr-block $vcn_cidr --display-name "$vcn_name" --compartment-id $compartment_id --wait-for-state AVAILABLE --query data.id )
vcn_id=${vcn_id//\"}
echo -e "\e[1;32m vcn_id : $vcn_id \e[0m"


#create Internet Gateway
echo -e "\e[1;32m => provision \"$vcn_internet_gateway_name\" internet gateway \e[0m"
vcn_internet_gateway_id=$(oci network internet-gateway list --compartment-id $compartment_id --raw-output --query "data[?contains(\"display-name\",'$vcn_internet_gateway_name')].id | [0]")
[ -z "$vcn_internet_gateway_id" ] && \
vcn_internet_gateway_id=$(oci network internet-gateway create --display-name "$vcn_internet_gateway_name" --compartment-id $compartment_id --is-enabled true --vcn-id $vcn_id --wait-for-state AVAILABLE --query data.id)
vcn_internet_gateway_id=${vcn_internet_gateway_id//\"}
echo -e "\e[1;32m vcn_internet_gateway_id : $vcn_internet_gateway_id \e[0m"


#create NAT Gateway
echo -e "\e[1;32m => provision \"$vcn_nat_gateway_name\" NAT gateway \e[0m"
vcn_nat_gateway_id=$(oci network nat-gateway list --compartment-id $compartment_id --raw-output --query "data[?contains(\"display-name\",'$vcn_nat_gateway_name')].id | [0]")
[ -z "$vcn_nat_gateway_id" ] && \
vcn_nat_gateway_id=$(oci network nat-gateway create --display-name "$vcn_nat_gateway_name" --compartment-id $compartment_id --vcn-id $vcn_id --wait-for-state AVAILABLE  --query data.id)
vcn_nat_gateway_id=${vcn_nat_gateway_id//\"}
echo -e "\e[1;32m vcn_nat_gateway_id : $vcn_nat_gateway_id \e[0m"


echo -e "\e[1;32m => provision \"$vcn_public_subnet_name\" subnet \e[0m"
#create public security list
vcn_public_security_list_id=$(oci network security-list list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_public_security_list_name')].id | [0]")
[ -z "$vcn_public_security_list_id" ] && \
vcn_public_security_list_id=$(oci network security-list create --display-name "$vcn_public_security_list_name" --compartment-id $compartment_id --egress-security-rules "$vcn_public_security_list_egress" --ingress-security-rules "$vcn_public_security_list_ingress" --vcn-id $vcn_id  --wait-for-state AVAILABLE --query data.id )
vcn_public_security_list_id=${vcn_public_security_list_id//\"}
echo -e "\e[1;32m vcn_public_security_list_id : $vcn_public_security_list_id \e[0m"


#create public route table
vcn_public_route_table_rule=${vcn_public_route_table_rule/ocid1.internetgateway.oc1/$vcn_internet_gateway_id}
vcn_public_route_table_id=$(oci network route-table list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_public_route_table_name')].id | [0]")
[ -z "$vcn_public_route_table_id" ] && \
vcn_public_route_table_id=$(oci network route-table create --compartment-id $compartment_id  --vcn-id $vcn_id --display-name "$vcn_public_route_table_name" --route-rules "$vcn_public_route_table_rule"  --wait-for-state AVAILABLE --query data.id)
vcn_public_route_table_id=${vcn_public_route_table_id//\"}
echo -e "\e[1;32m vcn_public_route_table_id : $vcn_public_route_table_id \e[0m"


#create public subnet
vcn_public_security_list_ids=${vcn_public_security_list_ids/ID/$vcn_public_security_list_id}
vcn_public_subnet_id=$(oci network subnet list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_public_subnet_name')].id | [0]")
[ -z "$vcn_public_subnet_id" ] && \
vcn_public_subnet_id=$(oci network subnet create --cidr-block "$vcn_public_subnet_cidr" --compartment-id $compartment_id  --vcn-id $vcn_id --display-name "$vcn_public_subnet_name" --prohibit-public-ip-on-vnic false --route-table-id "$vcn_public_route_table_id" --security-list-ids "$vcn_public_security_list_ids" --wait-for-state AVAILABLE --query data.id)
vcn_public_subnet_id=${vcn_public_subnet_id//\"}
echo -e "\e[1;32m vcn_public_subnet_id : $vcn_public_subnet_id \e[0m"


echo -e "\e[1;32m => provision \"$vcn_private_subnet_name\" subnet \e[0m"
#create private security list
vcn_private_security_list_id=$(oci network security-list list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_private_security_list_name')].id | [0]")
[ -z "$vcn_private_security_list_id" ] && \
vcn_private_security_list_id=$(oci network security-list create --display-name "$vcn_private_security_list_name" --compartment-id $compartment_id --egress-security-rules "$vcn_private_security_list_egress" --ingress-security-rules "$vcn_private_security_list_ingress" --vcn-id $vcn_id  --wait-for-state AVAILABLE --query data.id ) && \
vcn_private_security_list_id=${vcn_private_security_list_id//\"}
echo -e "\e[1;32m vcn_private_security_list_id : $vcn_private_security_list_id \e[0m"


#create private route table
vcn_private_route_table_rule=${vcn_private_route_table_rule/ocid1.internetgateway.oc1/$vcn_internet_gateway_id}
vcn_private_route_table_id=$(oci network route-table list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_private_route_table_name')].id | [0]")
[ -z "$vcn_private_route_table_id" ] && \
vcn_private_route_table_id=$(oci network route-table create --compartment-id $compartment_id  --vcn-id $vcn_id --display-name "$vcn_private_route_table_name" --route-rules "$vcn_private_route_table_rule"  --wait-for-state AVAILABLE --query data.id)
vcn_private_route_table_id=${vcn_private_route_table_id//\"}
echo -e "\e[1;32m vcn_private_route_table_id : $vcn_private_route_table_id \e[0m"


#create private subnet
vcn_private_security_list_ids=${vcn_private_security_list_ids/ID/$vcn_private_security_list_id}
vcn_private_subnet_id=$(oci network subnet list --compartment-id $compartment_id --vcn-id $vcn_id --raw-output --query "data[?contains(\"display-name\",'$vcn_private_subnet_name')].id | [0]")
[ -z "$vcn_private_subnet_id" ] && \
vcn_private_subnet_id=$(oci network subnet create --cidr-block "$vcn_private_subnet_cidr" --compartment-id $compartment_id  --vcn-id $vcn_id --display-name "$vcn_private_subnet_name" --route-table-id "$vcn_private_route_table_id" --security-list-ids "$vcn_private_security_list_ids" --wait-for-state AVAILABLE --query data.id)
vcn_private_subnet_id=${vcn_private_subnet_id//\"}
echo -e "\e[1;32m vcn_private_subnet_id : $vcn_private_subnet_id \e[0m"

