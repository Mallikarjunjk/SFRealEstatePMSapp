@isTest
private class LeaseAgreementControllerTest {

    @TestSetup
    static void setupData() {
        Property__c prop = new Property__c(
            Name = 'Lease Test Property',
            Address__c = 'Test Street',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Postal_Code__c = '560001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 25000,
            Description__c = 'Test'
        );
        insert prop;

        Tenant__c tenant = new Tenant__c(
            Name = 'Test Tenant',
            Phone_Number__c = '9999999999',
            Email__c = 'testtenant@example.com'
        );
        insert tenant;

        Lease_Agreement__c lease = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = 'Standard lease terms for testing.',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(11)
        );
        insert lease;
    }

    @isTest
    static void testGetLeaseDetails() {
        Lease_Agreement__c lease = [SELECT Id FROM Lease_Agreement__c LIMIT 1];

        Test.startTest();
        LeaseAgreementController.LeaseDetails details = LeaseAgreementController.getLeaseDetails(lease.Id);
        Test.stopTest();

        System.assertEquals('Lease Test Property', details.propertyName);
        System.assertEquals('Test Tenant', details.tenantName);
        System.assertEquals(25000, details.rent);
    }

    @isTest
    static void testSendLeasePdf_success() {
        Lease_Agreement__c lease = [SELECT Id FROM Lease_Agreement__c LIMIT 1];
        String fakeBase64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Fake PDF content for testing'));

        Test.startTest();
        LeaseAgreementController.sendLeasePdf(lease.Id, fakeBase64Pdf);
        Test.stopTest();

        // Confirm an email invocation actually occurred
        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should have been sent');
    }

    @isTest
    static void testSendLeasePdf_noTenantEmail_throws() {
        Tenant__c tenantNoEmail = new Tenant__c(Name = 'No Email Tenant', Phone_Number__c = '8888888888');
        insert tenantNoEmail;

        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        Lease_Agreement__c leaseNoEmail = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenantNoEmail.Id,
            Terms__c = 'Terms',
            Agreed_Monthly_Rent__c = 20000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(6)
        );
        insert leaseNoEmail;

        String fakeBase64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Fake PDF content'));
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            LeaseAgreementController.sendLeasePdf(leaseNoEmail.Id, fakeBase64Pdf);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw an exception when tenant has no email address');
    }
}