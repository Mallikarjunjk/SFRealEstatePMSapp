public with sharing class GeocodingService {

    // Synchronous version — used when called directly from a UI action (like property creation)
    public static Map<String, Decimal> geocodeAddressSync(
        String addressStr, String cityStr, String stateStr, String countryStr
    ) {
        String fullAddress = addressStr + ', ' + cityStr + ', ' + stateStr + ', ' + countryStr;
        String encodedAddress = EncodingUtil.urlEncode(fullAddress, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://nominatim.openstreetmap.org/search?q=' + encodedAddress + '&format=json&limit=1');
        req.setMethod('GET');
        req.setHeader('User-Agent', 'RealEstatePMS/1.0');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
            if (!results.isEmpty()) {
                Map<String, Object> loc = (Map<String, Object>) results[0];
                Map<String, Decimal> coords = new Map<String, Decimal>();
                coords.put('lat', Decimal.valueOf((String) loc.get('lat')));
                coords.put('lng', Decimal.valueOf((String) loc.get('lon')));
                return coords;
            }
        }
        return null;
    }

    // Async version — used by the trigger when a property's address is edited later
    @future(callout=true)
    public static void geocodeProperty(Id propertyId) {
        Property__c prop = [
            SELECT Address__c, City__c, State__c, Postal_Code__c, Country__c
            FROM Property__c WHERE Id = :propertyId
        ];
        Map<String, Decimal> coords = geocodeAddressSync(
            prop.Address__c, prop.City__c, prop.State__c, prop.Country__c
        );
        if (coords != null) {
            Property__c toUpdate = new Property__c(Id = propertyId);
            toUpdate.Geolocation__Latitude__s = coords.get('lat');
            toUpdate.Geolocation__Longitude__s = coords.get('lng');
            update toUpdate;
        }
    }
}