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
sfdx force:org:create -s -f config/project-scratch-def.json -a $SCRATCHORGALIAS
sfdx force:org:open 
read -p "------------- Finished, type enter to continue "

echo "##### WARNING ######"
echo "before going further, please make sure to   : "
echo "- install the Stripe Universal Connector"
echo "- install the 2022 class package"
echo "- configure in the org Person account properly"
echo "This package will NOT deploy for the moment the SLACK actions as it requires additional configuration on the org side AND that the demo slack account is only valid for 90 days."
echo "We will document it separately".
echo "##### WARNING ######"

read -p "------------- Please type enter to proceed with deployment" 

echo "Pushing all source code to the org $SCRATCHORGALIAS" 
sfdx force:source:push --forceoverwrite -u $SCRATCHORGALIAS 
read -p "------------- Finished, type enter to continue " 

echo "Updating user permissions" 
for i in `ls force-app/main/default/permissionsets/`
do
    echo 'Treating Permission file : '$i
    permissionName=`echo $i | cut -d'.' -f1`
    echo permissionName=$permissionName
    sfdx force:user:permset:assign -n $permissionName -u $SCRATCHORGALIAS
done
read -p "------------- Finished, type enter to continue " 

echo "------------- Finished, Launching web browser !" 
sfdx force:org:open 
read -p "------------- Finished, now work on the Org and come back here to deploy to production " 

