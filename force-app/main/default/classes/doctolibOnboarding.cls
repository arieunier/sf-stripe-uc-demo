public without sharing class doctolibOnboarding {
    public doctolibOnboarding() {

    }
    @InvocableMethod(label='Creates a Stripe Custom connected account based on a Contact')
    public static List<String> onboardCustomerOnLimitedPayees(List<String> ids)
    {
        System.debug('flow invoked !');
        String country = 'DE';

         // Retrieving STripe Context
		stripeGC__Stripe_Account__c stripeAccount = [ Select Id, stripeGC__Stripe_Account_Id__c from stripeGC__Stripe_Account__c LIMIT 1 ];
        String stripeId = stripeAccount.Id;                
        System.debug('Stripe context is => ' + stripeId);
        
        
        String recordId = ids[0]; // '0035I000003vQLxQAM'; // ids[0] ; //'0010700000j5f7wAAA';
        // get account
        Contact cont = [ select id, name, firstname, lastname, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Stripe_UID__c , IBAN__c from Contact where id= :recordId LIMIT 1];
        if (cont.MailingCountry == 'Germany')
        {
            country = 'DE';
        }
        else if (cont.MailingCountry == 'France')
        {
            country = 'FR';
        }
        System.debug('Treating Id=' + cont.Id + ' / Name=' + cont.Name);
        
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
        // verification part
        stripeGC.CreateTokensReqAccIndividualVerify individualVerif = new stripeGC.CreateTokensReqAccIndividualVerify();
        stripeGC.CreateTokensReqAccIndVerifyDoc verifDoc = new stripeGC.CreateTokensReqAccIndVerifyDoc();
        individualVerif.document = verifDoc;
        accountToken.individual.verification = individualVerif;
        accountToken.individual.verification.document.front='file_identity_document_success';

        System.debug(cont.firstname + '/' + cont.lastname + '/' + cont.Name);
        accountToken.individual.firstName = cont.firstName;
        accountToken.individual.lastName = cont.lastname; 
            

        accountToken.individual.dob.day=27; // fixme -> could be added to the person account profile, but it's a demo so it's hardcoded
        accountToken.individual.dob.month=4;
        accountToken.individual.dob.year=1983;

        accountToken.individual.address.city = cont.MailingCity;
        accountToken.individual.address.country = country;
        accountToken.individual.address.line1 = cont.MailingStreet;
        accountToken.individual.address.postalCode = cont.MailingPostalCode;
        accountToken.individual.address.state = cont.MailingState;            

        stripeGC.CreateTokens.V1 tokenCall = new stripeGC.CreateTokens.V1();
        tokenCall.account = accountToken;
        tokenCall.accountRecordId = stripeId;
        List<stripeGC.CreateTokens.V1> paramsCollection = new List<stripeGC.CreateTokens.V1>{tokenCall};
        List<stripeGC.Token> resultsToken = stripeGC.v01_CreateTokens.createTokens_2022_11_15(paramsCollection);
        String accountTokenId = resultsToken[0].id;
                    
        // Step 2 : Creating the Account
        
        stripeGC.CreateAccounts.V1 accountCall = new stripeGC.CreateAccounts.V1();
        accountCall.type = 'custom'; 
        accountCall.country = country;
        accountCall.accountRecordId = stripeId;
        accountCall.accountToken = accountTokenId;
        stripeGC.CreateAccountsReqBusinessProfile businessProfile = new stripeGC.CreateAccountsReqBusinessProfile();
        businessProfile.name = cont.Name;
        businessProfile.url = 'https://www.doctolibpartner.com';
        accountCall.businessProfile = businessProfile;
        stripeGC.CreateAccountsReqCapabilities capabilities = new stripeGC.CreateAccountsReqCapabilities();
        stripeGC.CreateAccountsReqCapabilitiesXfers transfers = new stripeGC.CreateAccountsReqCapabilitiesXfers();
        transfers.requested = True;
        capabilities.transfers = transfers;
        accountCall.capabilities = capabilities; 
        stripeGC.AccountTosAcceptance tosAcceptance = new stripeGC.AccountTosAcceptance();
        tosAcceptance.serviceAgreement = 'full';
        
        stripeGC.CreateAccountsReqSettings settings = new stripeGC.CreateAccountsReqSettings();
        stripeGC.CreateAccountsReqSettingsPayouts payouts = new stripeGC.CreateAccountsReqSettingsPayouts();
        stripeGC.CreateAccountsReqSettingsPayoutsSch schedule = new stripeGC.CreateAccountsReqSettingsPayoutsSch();
        schedule.interval = 'manual';
        payouts.schedule=schedule;
        payouts.statementDescriptor='Doctolib';
        accountCall.settings = settings;
    
        List<stripeGC.CreateAccounts.V1> paramsCollectionAccounts = new List<stripeGC.CreateAccounts.V1>{accountCall};
        List<stripeGC.Account> resultsAccount = stripeGC.v01_CreateAccounts.createAccounts_2022_11_15(paramsCollectionAccounts);
        String accountId = resultsAccount[0].id;
        

        // Step 4 : Adding external account
        stripeGC.RawInvocableParameters postBankAccounts = new stripeGC.RawInvocableParameters();              
        postBankAccounts.method = 'POST';
        postBankAccounts.endpoint = '/v1/accounts/' + accountId + '/bank_accounts';
        postBankAccounts.accountId = stripeId;
        List<String> postBankAccountParams = new List<String>{
            'bank_account[account_holder_name]=' + cont.Name,
            'bank_account[account_holder_type]=company',
            'bank_account[account_number]=' + cont.IBAN__c,
            'bank_account[currency]=' + 'eur',
            'bank_account[country]=' +  country
        };
        postBankAccounts.requestBody = String.join(postBankAccountParams, '&');
        List<stripeGC.RawInvocableParameters> paramsCollectionpostBankAccounts = new List<stripeGC.RawInvocableParameters>{
            postBankAccounts
        };
        List<String> resultsBankAccount = stripeGC.AgnosticInvocable.callStripeEndpoint(paramsCollectionpostBankAccounts);
        System.debug(resultsBankAccount[0]);

        cont.Stripe_UID__c = accountId;
        update cont;
        // upsert
        List<String> resultFlow = new List<String>();
        resultFlow.add(accountId);
        return resultFlow;
    }
}
