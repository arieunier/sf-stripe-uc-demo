#!/bin/bash


SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
# set me
if [ $# -ne 2 ]
then
    echo "Usage : deploy_sfdx.sh ScratchOrgAlias DevelopperHubAlias"
    exit 1
fi

SCRATCHORGALIAS=$1
DEVHUBALIAS=$2


echo "Creating a new ScratchOrg=$SCRATCHORGALIAS in the developper hub $DEVHUBALIAS"
sf org create scratch -a $SCRATCHORGALIAS -f config/project-scratch-def.json -v $DEVHUBALIAS -y 30
sf org open --target-org $SCRATCHORGALIAS
read -p "------------- Finished, type enter to continue "
# generating password
echo "generating a new password for the user (to install packages)"
sf org generate password --target-org $SCRATCHORGALIAS

echo "##### Installing the Universal Connector package ######"
sf package install --package 04tRN0000000CPN --target-org  $SCRATCHORGALIAS --no-prompt
echo "Type enter WHEN YOU RECEIVED the email from Salesforce saying the installation was successfull. It usually takes 5-10 min"
read -p "------------- Finished, type enter to continue "

echo "##### Installing the API resources ######"
sf package install --package 04t4x0000003Mza --target-org  $SCRATCHORGALIAS --no-prompt
echo "Type enter WHEN YOU RECEIVED the email from Salesforce saying the installation was successfull. It usually takes 5-10 min"
read -p "------------- Finished, type enter to continue "


read -p "------------- Please type enter to proceed with deployment" 

echo "Pushing all source code to the org $SCRATCHORGALIAS" 
sf project deploy start --ignore-conflicts --target-org $SCRATCHORGALIAS  --api-version=60.0
read -p "------------- Finished, type enter to continue " 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=`echo $i | cut -d'.' -f1`
    echo permissionName=$permissionName
    #sf org assign permset -n $permissionName -u $SCRATCHORGALIAS
    # sfdx force:user:permset assign --permesetname $permissionName -u $SCRATCHORGALIAS
    sf org assign permset --name $permissionName --target-org $SCRATCHORGALIAS
done
read -p "------------- Finished, type enter to continue " 

echo "------------- Finished, Launching web browser !" 
sfdx force:org:open 
read -p "------------- Finished, now work on the Org and come back here to deploy to production " 
