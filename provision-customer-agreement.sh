#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. $SCRIPTPATH/setup.config

echo -e "\e[1;32m running in $SCRIPTPATH \e[0m"
echo -e "\e[1;32m => provision customer agreement for \"$instance_image_name\" \e[0m"


#environment variables
compartment_id=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --raw-output --query "data[?contains(\"name\",'$compartment_name')].id | [0]")
echo -e "\e[1;32m compartment_id : $compartment_id \e[0m"

instance_image_ocid_listing=$(oci compute pic listing list --all --raw-output --query "data[?contains(\"display-name\", '$instance_image_name')].\"listing-id\" | [0] ")
echo -e "\e[1;32m instance_image_ocid_listing : $instance_image_ocid_listing \e[0m"


version_list=$(oci compute pic version list --listing-id "$instance_image_ocid_listing" \
    --query 'sort_by(data,&"time-published")[*].join('"'"' '"'"',["listing-resource-version", "listing-resource-id"]) | join(`\n`, reverse(@))' \
    --raw-output)
instance_image_ocid=""
while read instance_image_version instance_image_ocid ;do
# Ensure image is available for shape
available=$(oci compute pic version get --listing-id "$instance_image_ocid_listing" \
  --resource-version "$instance_image_version" \
  --query 'data."compatible-shapes"|contains(@, `'$instance_shape'`)' \
  --raw-output)
if [[ "${available}" = "true" ]]; then
  break
fi
echo_message "Version $instance_image_version not available for your shape; skipping"
done <<< "${version_list}"

echo -e "\e[1;32m instance_image_version : $instance_image_version \e[0m"
echo -e "\e[1;32m instance_image_ocid : $instance_image_ocid \e[0m"


instance_image_agreement=$(oci compute pic agreements get --listing-id "$instance_image_ocid_listing"  --resource-version  "$instance_image_version" --query '[data."oracle-terms-of-use-link", data.signature, data."time-retrieved"] | join(`\n`,@)' --raw-output)

instance_image_signature=$(echo $instance_image_agreement | awk '{print $2;}')
echo -e "\e[1;32m instance_image_signature : $instance_image_signature \e[0m"

instance_image_oracle_terms_of_use_link=$(echo $instance_image_agreement | awk '{print $1;}')
echo -e "\e[1;32m instance_image_oracle_terms_of_use_link : $instance_image_oracle_terms_of_use_link \e[0m"

instance_image_oracle_terms_of_use_time_retrieved=$(echo $instance_image_agreement | awk '{print $3;}')
instance_image_oracle_terms_of_use_time_retrieved=$(echo $instance_image_oracle_terms_of_use_time_retrieved | sed 's/\(.*\)000/\1/')
instance_image_oracle_terms_of_use_time_retrieved=$(echo $instance_image_oracle_terms_of_use_time_retrieved | sed 's/\(.*\):/\1/')
echo -e "\e[1;32m instance_image_oracle_terms_of_use_time_retrieved : $instance_image_oracle_terms_of_use_time_retrieved \e[0m"


instance_image_subscription=$(oci compute pic subscription create --listing-id "$instance_image_ocid_listing" --resource-version  "$instance_image_version" --compartment-id $compartment_id --signature "$instance_image_signature" --oracle-tou-link $instance_image_oracle_terms_of_use_link --time-retrieved "$instance_image_oracle_terms_of_use_time_retrieved" --query "data.\"listing-id\" " --raw-output)
echo -e "\e[1;32m instance_image_subscription : $instance_image_subscription \e[0m"

echo "instance_image_ocid="$instance_image_ocid >$SCRIPTPATH/instance_image_ocid

