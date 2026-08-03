@isTest
private class PropertyControllerTest {

    @TestSetup
    static void setupData() {
        List<Property__c> properties = new List<Property__c>();
        for (Integer i = 0; i < 30; i++) {
            properties.add(new Property__c(
                Name = 'Test Property ' + i,
                Address__c = 'Test Street ' + i,
                City__c = 'Bengaluru',
                State__c = 'Karnataka',
                Postal_Code__c = '560001',
                Country__c = 'India',
                Type__c = (Math.mod(i, 2) == 0) ? 'Residential' : 'Commercial',
                Furnishing_Status__c = 'Furnished',
                Status__c = (Math.mod(i, 3) == 0) ? 'Occupied' : 'Available',
                Rent__c = 10000 + (i * 1000),
                Description__c = 'Test description ' + i
            ));
        }
        insert properties;
    }

    @isTest
    static void testGetProperties_firstPage() {
        Test.startTest();
        PropertyController.PagedResult result = PropertyController.getProperties(1, 25, null, null, null);
        Test.stopTest();

        System.assertEquals(30, result.totalCount, 'Total count should reflect all inserted records');
        System.assertEquals(25, result.records.size(), 'First page should return page size worth of records');
    }

    @isTest
    static void testGetProperties_secondPage() {
        Test.startTest();
        PropertyController.PagedResult result = PropertyController.getProperties(2, 25, null, null, null);
        Test.stopTest();

        System.assertEquals(5, result.records.size(), 'Second page should return the remaining 5 records');
    }

    @isTest
    static void testGetProperties_withMaxPriceFilter() {
        Test.startTest();
        PropertyController.PagedResult result = PropertyController.getProperties(1, 25, 15000, null, null);
        Test.stopTest();

        for (Property__c p : result.records) {
            System.assert(p.Rent__c <= 15000, 'All returned records should respect the max price filter');
        }
    }

    @isTest
    static void testGetProperties_withAvailabilityFilter() {
        Test.startTest();
        PropertyController.PagedResult result = PropertyController.getProperties(1, 25, null, 'Occupied', null);
        Test.stopTest();

        for (Property__c p : result.records) {
            System.assertEquals('Occupied', p.Status__c);
        }
    }

    @isTest
    static void testGetProperties_withFurnishingFilter() {
        Test.startTest();
        PropertyController.PagedResult result = PropertyController.getProperties(1, 25, null, null, 'Furnished');
        Test.stopTest();

        for (Property__c p : result.records) {
            System.assertEquals('Furnished', p.Furnishing_Status__c);
        }
    }

    @isTest
    static void testCreateProperty_withGeocodingMock() {
        Test.setMock(HttpCalloutMock.class, new GeocodingServiceMock());

        Test.startTest();
        Id newId = PropertyController.createProperty(
            'New Test Property', 'Test Address', 'Bengaluru', 'Karnataka', '560001', 'India',
            'Residential', 'Furnished', 'Available', 25000, 'A new test property'
        );
        Test.stopTest();

        Property__c created = [SELECT Name, Geolocation__Latitude__s, Geolocation__Longitude__s FROM Property__c WHERE Id = :newId];
        System.assertEquals('New Test Property', created.Name);
        System.assertEquals(12.9716, created.Geolocation__Latitude__s);
    }

    @isTest
    static void testDeleteProperty() {
        Property__c p = [SELECT Id FROM Property__c LIMIT 1];

        Test.startTest();
        PropertyController.deleteProperty(p.Id);
        Test.stopTest();

        List<Property__c> remaining = [SELECT Id FROM Property__c WHERE Id = :p.Id];
        System.assertEquals(0, remaining.size(), 'Property should be deleted');
    }

    @isTest
    static void testGetThumbnails_noFiles() {
        List<Property__c> props = [SELECT Id FROM Property__c LIMIT 3];
        List<Id> propIds = new List<Id>();
        for (Property__c p : props) propIds.add(p.Id);

        Test.startTest();
        Map<Id, String> thumbnails = PropertyController.getThumbnails(propIds);
        Test.stopTest();

        System.assertEquals(0, thumbnails.size(), 'No files attached, so no thumbnails expected');
    }

    @isTest
    static void testGetThumbnails_withFile() {
        Property__c p = [SELECT Id FROM Property__c LIMIT 1];

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Image';
        cv.PathOnClient = 'test.jpg';
        cv.VersionData = Blob.valueOf('Test Image Content');
        insert cv;

        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = insertedCv.ContentDocumentId;
        link.LinkedEntityId = p.Id;
        link.ShareType = 'V';
        insert link;

        Test.startTest();
        Map<Id, String> thumbnails = PropertyController.getThumbnails(new List<Id>{ p.Id });
        Test.stopTest();

        System.assert(thumbnails.containsKey(p.Id), 'Should return a thumbnail URL for the property with an attached file');
    }

    @isTest
    static void testGetThumbnails_emptyList() {
        Test.startTest();
        Map<Id, String> thumbnails = PropertyController.getThumbnails(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, thumbnails.size());
    }
}