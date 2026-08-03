@isTest
private class MaintenanceRequestTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        Property__c prop = new Property__c(
            Name = 'Maintenance Test Property',
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

        insert new List<Vendor__c>{
            new Vendor__c(Name = 'Vendor A', Phone_Number__c = '1111111111', Email__c = 'vendora@example.com'),
            new Vendor__c(Name = 'Vendor B', Phone_Number__c = '2222222222', Email__c = 'vendorb@example.com')
        };
    }

    @isTest
    static void testAutoAssign_singleRequest() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];

        Test.startTest();
        Maintenance_Request__c mr = new Maintenance_Request__c(
            Property__c = prop.Id,
            Status__c = 'Open',
            Description__c = 'Test issue'
        );
        insert mr;
        Test.stopTest();

        Maintenance_Request__c saved = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :mr.Id];
        System.assertNotEquals(null, saved.Vendor__c, 'A vendor should be auto-assigned');
    }

    @isTest
    static void testAutoAssign_spreadsAcrossVendors() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        List<Vendor__c> vendors = [SELECT Id FROM Vendor__c];

        Test.startTest();
        List<Maintenance_Request__c> requests = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < 4; i++) {
            requests.add(new Maintenance_Request__c(
                Property__c = prop.Id,
                Status__c = 'Open',
                Description__c = 'Bulk test issue ' + i
            ));
        }
        insert requests;
        Test.stopTest();

        Map<Id, Integer> vendorCounts = new Map<Id, Integer>();
        for (Maintenance_Request__c mr : [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id IN :requests]) {
            Integer count = vendorCounts.containsKey(mr.Vendor__c) ? vendorCounts.get(mr.Vendor__c) : 0;
            vendorCounts.put(mr.Vendor__c, count + 1);
        }

        System.assertEquals(2, vendorCounts.size(), 'Requests should be spread across both vendors, not piled on one');
        for (Integer count : vendorCounts.values()) {
            System.assertEquals(2, count, 'Each vendor should get exactly 2 of the 4 requests');
        }
    }

    @isTest
    static void testAutoAssign_respectsExistingWorkload() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        List<Vendor__c> vendors = [SELECT Id FROM Vendor__c ORDER BY Name LIMIT 2];

        // Give Vendor A an existing open request so Vendor B should win the next assignment
        insert new Maintenance_Request__c(
            Property__c = prop.Id,
            Vendor__c = vendors[0].Id,
            Status__c = 'Open',
            Description__c = 'Existing issue'
        );

        Test.startTest();
        Maintenance_Request__c newRequest = new Maintenance_Request__c(
            Property__c = prop.Id,
            Status__c = 'Open',
            Description__c = 'New issue'
        );
        insert newRequest;
        Test.stopTest();

        Maintenance_Request__c saved = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :newRequest.Id];
        System.assertEquals(vendors[1].Id, saved.Vendor__c, 'Should assign to the less busy vendor');
    }

    @isTest
    static void testAutoAssign_doesNotOverrideExplicitVendor() {
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];
        Vendor__c chosenVendor = [SELECT Id FROM Vendor__c LIMIT 1];

        Test.startTest();
        Maintenance_Request__c mr = new Maintenance_Request__c(
            Property__c = prop.Id,
            Vendor__c = chosenVendor.Id,
            Status__c = 'Open',
            Description__c = 'Manually assigned issue'
        );
        insert mr;
        Test.stopTest();

        Maintenance_Request__c saved = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :mr.Id];
        System.assertEquals(chosenVendor.Id, saved.Vendor__c, 'Explicit vendor selection should not be overridden');
    }

    @isTest
    static void testAutoAssign_noVendorsExist_doesNotError() {
        delete [SELECT Id FROM Vendor__c];
        Property__c prop = [SELECT Id FROM Property__c LIMIT 1];

        Test.startTest();
        Maintenance_Request__c mr = new Maintenance_Request__c(
            Property__c = prop.Id,
            Status__c = 'Open',
            Description__c = 'No vendors available scenario'
        );
        insert mr;
        Test.stopTest();

        Maintenance_Request__c saved = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :mr.Id];
        System.assertEquals(null, saved.Vendor__c, 'Should insert successfully with no vendor assigned when none exist');
    }
}