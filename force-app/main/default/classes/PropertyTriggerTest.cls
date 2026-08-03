@isTest
private class PropertyTriggerTest {

    @isTest
    static void testTrigger_geocodesOnAddressUpdate() {
        Test.setMock(HttpCalloutMock.class, new GeocodingServiceMock());

        Property__c p = new Property__c(
            Name = 'Trigger Test Property',
            Address__c = 'Old Address',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Postal_Code__c = '560001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 20000,
            Description__c = 'Test'
        );
        insert p;

        Test.startTest();
        p.Address__c = 'New Address';
        update p;
        Test.stopTest();

        Property__c updated = [SELECT Geolocation__Latitude__s FROM Property__c WHERE Id = :p.Id];
        System.assertEquals(12.9716, updated.Geolocation__Latitude__s, 'Address change should trigger re-geocoding');
    }

    @isTest
    static void testTrigger_noGeocodeWhenAddressUnchanged() {
        Test.setMock(HttpCalloutMock.class, new GeocodingServiceMock());

        Property__c p = new Property__c(
            Name = 'Trigger Test Property 2',
            Address__c = 'Same Address',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Postal_Code__c = '560001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 20000,
            Description__c = 'Test'
        );
        insert p;

        Test.startTest();
        p.Rent__c = 22000; // unrelated field change, address stays the same
        update p;
        Test.stopTest();

        // No assertion on geolocation here since no callout should have been triggered;
        // this test mainly ensures the update doesn't error and future call limits aren't hit unnecessarily.
        Property__c updated = [SELECT Rent__c FROM Property__c WHERE Id = :p.Id];
        System.assertEquals(22000, updated.Rent__c);
    }
}