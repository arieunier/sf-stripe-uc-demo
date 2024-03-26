if [ $# -ne 1 ]
then
    echo "Usage : deployChanges.sh  OrgsAliases"
    exit 1
fi


for var in "$@"
do
    echo "Deploying changes to --> $var"
    sf project deploy start --ignore-conflicts --target-org $var
    echo "Updating user permissions" 

    for i in `ls force-app/main/default/permissionsets/`
    do
        echo 'Treating Permission file : '$i
        permissionName=`echo $i | cut -d'.' -f1`
        echo permissionName=$permissionName
        #sfdx force:user:permset:assign -n $permissionName -u $DEVHUBALIAS
        sf org assign permset --name $permissionName --target-org $var
    done


done