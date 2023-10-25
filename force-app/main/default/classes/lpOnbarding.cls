public with sharing class lpOnbarding {
    public lpOnbarding() {

    }
    @InvocableMethod(label='Onboards an existing Stripe Customer synced as a Person Account to Limited Payees')
    public static List<String> onboardCustomerOnLimitedPayees(List<String> ids)
    {
        System.debug('flow invoked !');
         // Retrieving STripe Context
		stripeGC__Stripe_Account__c stripeAccount = [ Select Id, stripeGC__Stripe_Account_Id__c from stripeGC__Stripe_Account__c LIMIT 1 ];
        String stripeId = stripeAccount.Id;                
        System.debug('Stripe context is => ' + stripeId);
        
        
        String recordId = ids[0] ; //'0010700000j5f7wAAA';
        // get account
        Account act = [ select id, AccountNumber, name, firstname, lastname, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Stripe_Customer_Id__pc FROM account where id= :recordId LIMIT 1];
        String Name = act.Name;
        System.debug('Treating Id=' + act.Id + ' / Name=' + act.Name);
        
            // STEP 1 : Creating Token
        stripeGC.CreateTokensReqAccount accountToken = new stripeGC.CreateTokensReqAccount();
        accountToken.businessType = 'individual';
        accountToken.tosShownAndAccepted = True;

        stripeGC.CreateTokensReqAccountIndividual individualStructure = new stripeGC.CreateTokensReqAccountIndividual();
        accountToken.individual = individualStructure;
        stripeGC.CreateTokensReqAccIndividualAddress individualAddress = new stripeGC.CreateTokensReqAccIndividualAddress();
        accountToken.individual.address = individualAddress;
        stripeGC.CreateTokensReqAccountIndividualDob individualDob = new stripeGC.CreateTokensReqAccountIndividualDob();
        accountToken.individual.dob = individualDob;
        System.debug(act.firstname + '/' + act.lastname + '/' + act.Name);
        if (act.FirstName != '' && act.FirstName != null )
        {
            accountToken.individual.firstName = act.firstName;
        }
        else
        {
            accountToken.individual.firstName = act.Name; 
        }

        if (act.LastName != ''&& act.LastName != null )
        {
            accountToken.individual.lastName = act.lastname; 
        }
        else
        {
            accountToken.individual.lastName = act.Name; 
        }
            

        accountToken.individual.dob.day=27; // fixme -> could be added to the person account profile, but it's a demo so it's hardcoded
        accountToken.individual.dob.month=4;
        accountToken.individual.dob.year=1983;

        accountToken.individual.address.city = act.BillingCity;
        accountToken.individual.address.country = act.BillingCountry;
        accountToken.individual.address.line1 = act.BillingStreet;
        accountToken.individual.address.postalCode = act.BillingPostalCode;
        accountToken.individual.address.state = act.BillingState;            

        stripeGC.CreateTokens.V1 tokenCall = new stripeGC.CreateTokens.V1();
        tokenCall.account = accountToken;
        tokenCall.accountRecordId = stripeId;
        List<stripeGC.CreateTokens.V1> paramsCollection = new List<stripeGC.CreateTokens.V1>{tokenCall};
        List<stripeGC.Token> resultsToken = stripeGC.v01_CreateTokens.createTokens_2022_11_15(paramsCollection);
        String accountTokenId = resultsToken[0].id;
                    
        // Step 2 : Creating the Account
        
        stripeGC.CreateAccounts.V1 accountCall = new stripeGC.CreateAccounts.V1();
        accountCall.type = 'custom'; 
        accountCall.country = act.BillingCountry; 
        accountCall.accountRecordId = stripeId;
        accountCall.accountToken = accountTokenId;
        stripeGC.CreateAccountsReqBusinessProfile businessProfile = new stripeGC.CreateAccountsReqBusinessProfile();
        businessProfile.name = act.Name;
        businessProfile.url = 'https://www.pinnaclepetgroup.com';
        accountCall.businessProfile = businessProfile;
        stripeGC.CreateAccountsReqCapabilities capabilities = new stripeGC.CreateAccountsReqCapabilities();
        stripeGC.CreateAccountsReqCapabilitiesXfers transfers = new stripeGC.CreateAccountsReqCapabilitiesXfers();
        transfers.requested = True;
        capabilities.transfers = transfers;
        accountCall.capabilities = capabilities; 
        stripeGC.AccountTosAcceptance tosAcceptance = new stripeGC.AccountTosAcceptance();
        tosAcceptance.serviceAgreement = 'recipient';
        
        stripeGC.CreateAccountsReqSettings settings = new stripeGC.CreateAccountsReqSettings();
        stripeGC.CreateAccountsReqSettingsPayouts payouts = new stripeGC.CreateAccountsReqSettingsPayouts();
        stripeGC.CreateAccountsReqSettingsPayoutsSch schedule = new stripeGC.CreateAccountsReqSettingsPayoutsSch();
        schedule.interval = 'manual';
        payouts.schedule=schedule;
        payouts.statementDescriptor='PPG Payment';
        accountCall.settings = settings;
    
        List<stripeGC.CreateAccounts.V1> paramsCollectionAccounts = new List<stripeGC.CreateAccounts.V1>{accountCall};
        List<stripeGC.Account> resultsAccount = stripeGC.v01_CreateAccounts.createAccounts_2022_11_15(paramsCollectionAccounts);
        String accountId = resultsAccount[0].id;
        
        
        // Step 3 : Retrieving payment methods attached to the customer profile
        /**
        stripeGC.RawInvocableParameters GetSetupIntentsParameters = new stripeGC.RawInvocableParameters();              
        GetSetupIntentsParameters.method = 'GET';
        GetSetupIntentsParameters.endpoint = '/v1/setup_intents';
        GetSetupIntentsParameters.accountId = stripeId;
        List<String> getSetupIntentsParams = new List<String>{
            'customer=' + 'cus_OsdS9ckyYMIcoY', //act.Stripe_Customer_Id__pc,
            'expand[0]=' + 'data.payment_method.sepa_debit.iban'
        };
        GetSetupIntentsParameters.requestBody = String.join(getSetupIntentsParams, '&');
        List<stripeGC.RawInvocableParameters> paramsCollectionGetSetupIntents = new List<stripeGC.RawInvocableParameters>{
            GetSetupIntentsParameters
        };
        List<String> results = stripeGC.AgnosticInvocable.callStripeEndpoint(paramsCollectionGetSetupIntents);
        System.debug(results[0]);
        */

        // Step 4 : Adding external account
        stripeGC.RawInvocableParameters postBankAccounts = new stripeGC.RawInvocableParameters();              
        postBankAccounts.method = 'POST';
        postBankAccounts.endpoint = '/v1/accounts/' + accountId + '/bank_accounts';
        postBankAccounts.accountId = stripeId;
        List<String> postBankAccountParams = new List<String>{
            'bank_account[account_holder_name]=' + act.Name,
            'bank_account[account_holder_type]=individual',
            'bank_account[account_number]=' + 'BE62510007547061',
            'bank_account[currency]=' + 'eur',
            'bank_account[country]=' + act.BillingCountry
        };
        postBankAccounts.requestBody = String.join(postBankAccountParams, '&');
        List<stripeGC.RawInvocableParameters> paramsCollectionpostBankAccounts = new List<stripeGC.RawInvocableParameters>{
            postBankAccounts
        };
        List<String> resultsBankAccount = stripeGC.AgnosticInvocable.callStripeEndpoint(paramsCollectionpostBankAccounts);
        System.debug(resultsBankAccount[0]);


        // upsert
        List<String> resultFlow = new List<String>();
        resultFlow.add(accountId);
        return resultFlow;
    }
}
