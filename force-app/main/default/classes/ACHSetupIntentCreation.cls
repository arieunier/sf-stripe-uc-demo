public with sharing class ACHSetupIntentCreation {
    public ACHSetupIntentCreation() {

    }

    @InvocableMethod(label='Creates a Setup Intent using ACH Routing Number, ACH Account Number, and Account Id')
    public static List<String> createSetupIntent(List<String> ids)
    {
        System.debug('flow ACH Setup Intent invoked');

        // Retrieving STripe Context
    	stripeGC__Stripe_Account__c stripeAccount = [ Select Id, stripeGC__Stripe_Account_Id__c from stripeGC__Stripe_Account__c LIMIT 1 ];
        String stripeId = stripeAccount.Id;                
        System.debug('Stripe context is => ' + stripeId);
        System.debug('Ids received =>' + ids);

        String[] VarIds = ids[0].split(',');

        String recordId =  VarIds[0];
        String ACHRoutingNumber = VarIds[1];
        String ACHAccountNumber =  VarIds[2];
        String stripeAccountId = VarIds[3];
        stripeId = stripeAccountId;
        
        System.debug('RecordId context is => ' + recordId);
        System.debug('ACHRoutingNumber context is => ' + ACHRoutingNumber);
        System.debug('ACHAccountNumber context is => ' + ACHAccountNumber);

        // get account
        Account act = [ select BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Default_Stripe_Contact__c FROM Account where id = :recordId LIMIT 1];
        // get Contact
        Contact cont = [ select id, name, firstname, lastname, Stripe_Customer_Id__c, email  from Contact where id= :act.Default_Stripe_Contact__c LIMIT 1 ];
 
        
        // us bank account structure
        StripeGC.CreateSisReqPaymentMethodDataUsBacct usba = new StripeGC.CreateSisReqPaymentMethodDataUsBacct();
        usba.accountNumber = ACHAccountNumber;
        usba.routingNumber = ACHRoutingNumber;
        usba.accountHolderType = 'individual';
        // billing details structure
        StripeGC.CreateSisReqPmDataBdAddress address = new StripeGC.CreateSisReqPmDataBdAddress();
        address.city = act.BillingCity;
        address.country = act.BillingCountry;
        address.line1 = act.BillingStreet;
        address.postalCode = act.BillingPostalCode;
        address.state = act.BillingState;            
        StripeGC.CreateSisReqPmDataBillingDetails billingDetails = new StripeGC.CreateSisReqPmDataBillingDetails();
        billingDetails.address = address;
        billingDetails.email = cont.Email;
        billingDetails.name = cont.FirstName + ' ' + cont.LastName;
        // pm data structure - create and add us ba + billing
        StripeGC.CreateSisReqPaymentMethodData pmData = new StripeGC.CreateSisReqPaymentMethodData();
        pmData.billingDetails = billingDetails;
        pmData.usBankAccount = usba;
        pmData.type = 'us_bank_account';
        // customer acceptance structure
        StripeGC.CreateSisReqMandateDataCusAcceptance customerAcceptance = new StripeGC.CreateSisReqMandateDataCusAcceptance();
        customerAcceptance.acceptedAt = 1717757424;
        customerAcceptance.type = 'offline';
        // mandate data structure 
        StripeGC.CreateSetupIntentsReqMandateData mandateData = new StripeGC.CreateSetupIntentsReqMandateData();
        mandateData.customerAcceptance = customerAcceptance;
        // pm method option - us bank account 
        StripeGC.CreateSisReqPMOUsBankAccount  pmOptionsBA = new StripeGC.CreateSisReqPMOUsBankAccount();
        pmOptionsBA.verificationMethod='skip';
        // pm method option - create and assign us ba
        StripeGC.CreateSetupIntentsReqPMO pmOptions = new StripeGC.CreateSetupIntentsReqPMO();
        pmOptions.usBankAccount = pmOptionsBA;

        // now does the setup intent part
        List<StripeGC.CreateSetupIntents.V1> setupIntents = new List<StripeGC.CreateSetupIntents.V1>();
        StripeGC.CreateSetupIntents.V1 setupIntent = new StripeGC.CreateSetupIntents.V1();
        setupIntent.mandateData = mandateData;
        setupIntent.paymentMethodData = pmData;
        setupIntent.paymentMethodOptions = pmOptions;
        setupIntent.customer = cont.Stripe_Customer_Id__c;
        setupIntent.confirm = true;
        setupIntent.usage = 'off_session';
        setupIntent.accountRecordId=stripeId;
        setupIntent.paymentMethodTypes = new List<String>{'us_bank_account'};   
        setupIntents.add(setupIntent);
        List<StripeGC.SetupIntent> resultSetupIntents = 
            stripeGC.v01_CreateSetupIntents.createSetupIntents_2022_11_15(setupIntents);
        // gets the id and return it
        List<String> resultFlow = new List<String>();
        resultFlow.add(resultSetupIntents[0].paymentMethod);
        return resultFlow;
    }
}