@isTest
private class GeocodingServiceTest {

    @isTest
    static void testGeocodeAddressSync_success() {
        Test.setMock(HttpCalloutMock.class, new GeocodingServiceMock());

        Test.startTest();
        Map<String, Decimal> result = GeocodingService.geocodeAddressSync(
            'MG Road', 'Bengaluru', 'Karnataka', 'India'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return coordinates for a successful mock response');
        System.assertEquals(12.9716, result.get('lat'));
        System.assertEquals(77.5946, result.get('lng'));
    }

    @isTest
    static void testGeocodeProperty_updatesRecord() {
        Test.setMock(HttpCalloutMock.class, new GeocodingServiceMock());

        Property__c p = new Property__c(
            Name = 'Test Property',
            Address__c = 'MG Road',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Postal_Code__c = '560001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 20000,
            Description__c = 'Test description'
        );
        insert p;

        Test.startTest();
        GeocodingService.geocodeProperty(p.Id);
        Test.stopTest();

        Property__c updated = [SELECT Geolocation__Latitude__s, Geolocation__Longitude__s FROM Property__c WHERE Id = :p.Id];
        System.assertEquals(12.9716, updated.Geolocation__Latitude__s);
        System.assertEquals(77.5946, updated.Geolocation__Longitude__s);
    }

    @isTest
    static void testGeocodeAddressSync_noResults() {
        Test.setMock(HttpCalloutMock.class, new EmptyGeocodingMock());

        Test.startTest();
        Map<String, Decimal> result = GeocodingService.geocodeAddressSync(
            'Nonexistent Street', 'Nowhere', 'XX', 'Nowhereland'
        );
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when geocoding finds no match');
    }

    // Inline mock for the empty-results scenario
    private class EmptyGeocodingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[]');
            res.setStatusCode(200);
            return res;
        }
    }
}