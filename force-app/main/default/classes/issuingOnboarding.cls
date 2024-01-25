public without sharing class issuingOnboarding {
    public issuingOnboarding() {

    }


    @InvocableMethod(label='Creates a Stripe Issuing Card based on the Contact given in param')
    public static List<String> onboardCustomerIssuing(List<String> ids)
    {
        System.debug('flow invoked !');
        String country = 'FR';

         // Retrieving STripe Context
    	stripeGC__Stripe_Account__c stripeAccount = [ Select Id, stripeGC__Stripe_Account_Id__c from stripeGC__Stripe_Account__c LIMIT 1 ];
        String stripeId = stripeAccount.Id;                
        System.debug('Stripe context is => ' + stripeId);
        
        
        String recordId =  ids[0]; //'0010700000lWdSdAAK'; //  '0035I000003vQLxQAM'; // ids[0] ; //'0010700000j5f7wAAA';
        System.debug('RecordId context is => ' + recordId);
        // get account
        Account cont = [ select id, AccountNumber, name, firstname, lastname, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Stripe_Customer_Id__pc FROM Account where id = :recordId LIMIT 1];
        if (cont.BillingCountry == 'Germany')
        {
            country = 'DE';
        }
        else if (cont.BillingCountry == 'France')
        {
            country = 'FR';
        }
        System.debug('Treating Id=' + cont.Id + ' / Name=' + cont.Name);
        
        
        // creating billing Address
        stripeGC.CreateIssuingCardholdersReqBilling billingAddress = new stripeGC.CreateIssuingCardholdersReqBilling();
        stripeGC.CreateIssChldrsReqBillingAddress address = new stripeGC.CreateIssChldrsReqBillingAddress();
        address.city = cont.BillingCity;
        address.country = country;
        address.line1 = cont.BillingStreet;
        address.postalCode = cont.BillingPostalCode;
        address.state = cont.BillingState;            
        billingAddress.address = address;
        // creating Individual
        stripeGC.CreateIssChldrsReqIndividual individual = new stripeGC.CreateIssChldrsReqIndividual();
        stripeGC.CreateIssChldrsReqIndividualDob dob= new stripeGC.CreateIssChldrsReqIndividualDob();
        individual.dob = dob;
        individual.dob.day=27; // fixme -> could be added to the person account profile, but it's a demo so it's hardcoded
        individual.dob.month=4;
        individual.dob.year=1983;
        individual.firstName = cont.firstName;
        individual.lastName = cont.LastName; 
        StripeGC.CreateIssuingCardholders.V1 cardHolder = new StripeGC.CreateIssuingCardholders.V1();
        cardHolder.accountRecordId = stripeId;
        cardHolder.billing = billingAddress;
        cardHolder.individual = individual;
        cardHolder.type = 'individual';
        cardHolder.name = cont.firstName + ' ' + cont.lastName;
        cardHolder.phoneNumber = '+33643395652';
        List<StripeGC.CreateIssuingCardholders.V1> paramsCardHolder = new List<StripeGC.CreateIssuingCardholders.V1>();
        paramsCardHolder.add(cardHolder);
        List<StripeGC.IssuingCardholder> resultsCardHolder = stripeGC.v01_CreateIssuingCardholders.createIssuingCardholders_2022_11_15(paramsCardHolder);
        String cardHolderId = resultsCardHolder[0].id;
        System.debug(cardHolderId);
        // now issues the card
        List<StripeGC.CreateIssuingCards.V1> paramsCard = new List<StripeGC.CreateIssuingCards.V1>();
        StripeGC.CreateIssuingCards.V1 card = new StripeGC.CreateIssuingCards.V1();
        card.accountRecordId = stripeId;
        card.r_currency = 'eur';
        card.type='virtual';
        card.cardholder = cardHolderId;
        paramsCard.add(card);
        List<StripeGC.IssuingCard> resultsCard = stripeGC.v01_CreateIssuingCards.createIssuingCards_2022_11_15(paramsCard);
        String cardId = resultsCard[0].id;
        System.debug(cardId);

        // and activate it POST         /issuing/cards/{card}
        // status  active
        List<StripeGC.UpdateIssuingCards.V1> paramsUpdateCard = new List<StripeGC.UpdateIssuingCards.V1>();
        StripeGC.UpdateIssuingCards.V1 updatedCard = new StripeGC.UpdateIssuingCards.V1();
        updatedCard.accountRecordId = stripeId;
        updatedCard.card = cardId;
        updatedCard.status='active';
        paramsUpdateCard.add(updatedCard);
        List<StripeGC.IssuingCard> resultsUpdateCard = stripeGC.v01_UpdateIssuingCards.updateIssuingCards_2022_11_15(paramsUpdateCard);
        String updatecardId = resultsUpdateCard[0].id;
        System.debug(updatecardId);

        // add here the generated card content 
        List<String> resultFlow = new List<String>();
        resultFlow.add(cardId);
        return resultFlow;
    }
}