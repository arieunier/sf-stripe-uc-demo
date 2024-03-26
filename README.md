# Introduction
This package contains source code you can deploy on any Salesforce org in order to demo the interoperability between Stripe & Salesforce using the [universal connector](https://stripe.com/docs/plugins/stripe-connector-for-salesforce/overview) 

# Deployment to Scratch Org
Run the shell script `deployScratchOrg.sh` giving in parameter the name of DevHub and a name for the Scratch org. Follow then the instructions. It will install all connectors.

# Deployment to Production Org or Dev Org
run the shell script `deployToOrg.sh` giving in parameter the name of your org. It will install all connectors.

# Only pushing the source
After installing properly all connectors, run the shell script `pushChanges.sh` giving in parameter the name of your org.

# Deployment
See [video](https://drive.google.com/file/d/1lZ3MnLDeajA6JHnEN7sJAqaK_3WwV9qm/view?usp=share_link) of the deployment