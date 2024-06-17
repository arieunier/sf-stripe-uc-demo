#!/bin/bash


SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# set me
if [ $# -ne 1 ]
then
    echo "Usage : deploy_ToOrg.sh  DevelopperHubAlias"
    exit 1
fi

DEVHUBALIAS=$1
echo "##### WARNING ######"
echo "before running this command, please make sure that you configured in the org Person account properly"
echo "This package will NOT deploy for the moment the SLACK actions as it requires additional configuration on the org side AND that the demo slack account is only valid for 90 days."
echo "We will document it separately".
echo "##### WARNING ######"

read -p "------------- Please type enter to proceed with deployment" 

echo "##### Installing the Universal Connector package ######"
sf package install --package 04tRN0000000CPN --target-org  $DEVHUBALIAS --no-prompt
echo "Type enter WHEN YOU RECEIVED the email from Salesforce saying the installation was successfull. It usually takes 5-10 min"
read -p "------------- Finished, type enter to continue "

echo "##### Installing the API resources ######"
sf package install --package 04t4x0000003Mza --target-org  $DEVHUBALIAS --no-prompt
echo "Type enter WHEN YOU RECEIVED the email from Salesforce saying the installation was successfull. It usually takes 5-10 min"
read -p "------------- Finished, type enter to continue "


#echo "Creating Meta Data api Package"
#rm -rf mdapi_output_dir
#mkdir mdapi_output_dir
#sf project convert source --root-dir ./force-app/ --output-dir mdapi_output_dir
#read -p "------------- Finished, type enter to continue " 

echo "Sending Metadata Api Package to the $DEVHUBALIAS Organisation"
#sf project deploy start --metadata-dir mdapi_output_dir --target-org $DEVHUBALIAS --api-version=60.0
sf project deploy start --ignore-conflicts --target-org $DEVHUBALIAS --api-version=60.0
read -p "------------- If not finished, wait before hitting enter by checking status in Deployment Status on SF" 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=`echo $i | cut -d'.' -f1`
    echo permissionName=$permissionName
    #sfdx force:user:permset:assign -n $permissionName -u $DEVHUBALIAS
    sf org assign permset --name $permissionName --target-org $DEVHUBALIAS
done

read -p "------------- Finished, type enter to continue " 

