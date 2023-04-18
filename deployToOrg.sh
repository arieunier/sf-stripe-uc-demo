#!/bin/bash


SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# set me
if [ $# -ne 1 ]
then
    echo "Usage : deploy_ToOrg.sh  DevelopperHubAlias"
    exit 1
fi

echo "##### WARNING ######"
echo "before running this command, please make sure that : "
echo "installed the latest SF unified CLI AND SFDX !! See -> https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_unified.htm "
echo "- you already installed the Stripe Universal Connector"
echo "- you already installed the 2022 class package"
echo "- you configured in the org Person account properly"
echo "This package will NOT deploy for the moment the SLACK actions as it requires additional configuration on the org side AND that the demo slack account is only valid for 90 days."
echo "We will document it separately".
echo "##### WARNING ######"

read -p "------------- Please type enter to proceed with deployment" 

DEVHUBALIAS=$1
echo "Creating Meta Data api Package"
rm -rf mdapi_output_dir
mkdir mdapi_output_dir
#sfdx force:source:convert -d mdapi_output_dir/ --package-name SFUCDemo
sf project convert source --root-dir ./force-app/ --output-dir mdapi_output_dir
read -p "------------- Finished, type enter to continue " 

echo "Sending Metadata Api Package to the $DEVHUBALIAS Organisation"
#sfdx force:mdapi:deploy -d mdapi_output_dir  -u $DEVHUBALIAS -w 3
sf project deploy start --metadata-dir mdapi_output_dir --target-org $DEVHUBALIAS
read -p "------------- If not finished, wait before hitting enter by checking status in Deployment Status on SF" 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=`echo $i | cut -d'.' -f1`
    echo permissionName=$permissionName
    sfdx force:user:permset:assign -n $permissionName -u $DEVHUBALIAS
done

read -p "------------- Finished, type enter to continue " 
