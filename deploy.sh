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

echo "##### WARNING ######"
echo "before going further, please make sure to   : "
echo "- install the Stripe Universal Connector"
echo "SANDBOX/Scratch org URL -> https://test.salesforce.com/packaging/installPackage.apexp?p0=04tRN0000000CPN "
echo "Production URL -> https://login.salesforce.com/packaging/installPackage.apexp?p0=04tRN0000000CPN" 
echo "- install the API Extension"
echo "SANDBOX/Scratch org URL -> https://test.salesforce.com/packaging/installPackage.apexp?p0=04t4x0000003Mza"
echo "Production URL -> https://login.salesforce.com/packaging/installPackage.apexp?p0=04t4x0000003Mza" 
echo "- install the 2022 class package"
echo "- configure in the org Person account properly"
echo "This package will NOT deploy for the moment the SLACK actions as it requires additional configuration on the org side AND that the demo slack account is only valid for 90 days."
echo "We will document it separately".
echo "##### WARNING ######"

read -p "------------- Please type enter to proceed with deployment" 

echo "Pushing all source code to the org $SCRATCHORGALIAS" 
#sf force source deploy start --forceoverwrite --target-org $SCRATCHORGALIAS 
sf project deploy start --ignore-conflicts --target-org $SCRATCHORGALIAS 
#sfdx force:source:push --forceoverwrite -u $SCRATCHORGALIAS 
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
