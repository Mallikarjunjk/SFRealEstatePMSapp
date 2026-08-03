@isTest
private class LeaseExpiryReminderJobTest {

    @TestSetup
    static void setupData() {
        Property__c prop = new Property__c(
            Name = 'Expiry Test Property',
            Address__c = 'Test Street',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Postal_Code__c = '560001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Occupied',
            Rent__c = 25000,
            Description__c = 'Test'
        );
        insert prop;

        Tenant__c tenant = new Tenant__c(
            Name = 'Expiry Test Tenant',
            Phone_Number__c = '9999999999',
            Email__c = 'expirytest@example.com'
        );
        insert tenant;

        // Lease expiring in exactly 30 days
        Lease_Agreement__c lease30 = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = 'Terms',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today().addMonths(-11),
            End_Date__c = Date.today().addDays(30)
        );

        // Lease expiring in exactly 1 day
        Lease_Agreement__c lease1 = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = 'Terms',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today().addMonths(-11),
            End_Date__c = Date.today().addDays(1)
        );

        // Lease not expiring soon (should be ignored)
        Lease_Agreement__c leaseFar = new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = 'Terms',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(10)
        );

        insert new List<Lease_Agreement__c>{ lease30, lease1, leaseFar };
    }

    @isTest
    static void testExecute_sendsRemindersForExpiringLeases() {
        Test.startTest();
        LeaseExpiryReminderJob job = new LeaseExpiryReminderJob();
        job.execute(null);
        Test.stopTest();

        // Two leases (30-day and 1-day) should trigger emails; the far-future lease should not
        System.assertEquals(2, Limits.getEmailInvocations(), 'Exactly two reminder emails should be sent');
    }

    @isTest
    static void testScheduling() {
        Test.startTest();
        String cronExp = '0 0 6 * * ?';
        String jobId = System.schedule('Test Lease Expiry Check', cronExp, new LeaseExpiryReminderJob());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 6 * * ?', ct.CronExpression);
    }

    @isTest
    static void testExecute_noExpiringLeases_noEmails() {
        // Remove the leases created in setup, insert only a far-future one
        delete [SELECT Id FROM Lease_Agreement__c];

        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        Tenant__c tenant = [SELECT Id FROM Tenant__c LIMIT 1];

        insert new Lease_Agreement__c(
            Property__c = prop.Id,
            Tenant__c = tenant.Id,
            Terms__c = 'Terms',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(9)
        );

        Test.startTest();
        LeaseExpiryReminderJob job = new LeaseExpiryReminderJob();
        job.execute(null);
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent when nothing is expiring soon');
    }
}