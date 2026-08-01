public with sharing class GeocodingService {
    @future(callout=true)
    public static void geocodeProperty(Id propertyId) {
        Property__c prop = [SELECT Address__c, City__c, State__c, Postal_Code__c, Country__c
                             FROM Property__c WHERE Id = :propertyId];
        String address = EncodingUtil.urlEncode(
            prop.Address__c + ', ' + prop.City__c + ', ' + prop.State__c + ', ' + prop.Country__c, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://nominatim.openstreetmap.org/search?q=' + address + '&format=json&limit=1');
        req.setMethod('GET');
        req.setHeader('User-Agent', 'RealEstatePMS/1.0');
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
            if (!results.isEmpty()) {
                Map<String, Object> loc = (Map<String, Object>) results[0];
                Decimal lat = Decimal.valueOf((String) loc.get('lat'));
                Decimal lon = Decimal.valueOf((String) loc.get('lon'));
                prop.Geolocation__Latitude__s = lat;
                prop.Geolocation__Longitude__s = lon;
                update prop;
            }
        }
    }
}