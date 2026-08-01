public with sharing class PropertyController {

    @AuraEnabled(cacheable=true)
    public static PagedResult getProperties(
        Integer pageNumber,
        Integer pageSize,
        Decimal maxPrice,
        String availabilityStatus,
        String furnishingStatus
    ) {
        Integer offset = (pageNumber - 1) * pageSize;

        String query = 'SELECT Id, Name, Address__c, City__c, State__c, Rent__c, ' +
                        'Status__c, Furnishing_Status__c, Type__c ' +
                        'FROM Property__c WHERE Id != null ';

        if (maxPrice != null) query += 'AND Rent__c <= :maxPrice ';
        if (String.isNotBlank(availabilityStatus)) query += 'AND Status__c = :availabilityStatus ';
        if (String.isNotBlank(furnishingStatus)) query += 'AND Furnishing_Status__c = :furnishingStatus ';

        query += 'ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset';

        List<Property__c> records = Database.query(query);
        Integer totalCount = [SELECT COUNT() FROM Property__c];

        PagedResult result = new PagedResult();
        result.records = records;
        result.totalCount = totalCount;
        return result;
    }

    @AuraEnabled
    public static Id createProperty(
        String nameStr,
        String addressStr,
        String cityStr,
        String stateStr,
        String postalCodeStr,
        String countryStr,
        String typeStr,
        String furnishingStr,
        String statusStr,
        Decimal rentNum,
        String descriptionStr
    ) {
        Property__c p = new Property__c(
            Name = nameStr,
            Address__c = addressStr,
            City__c = cityStr,
            State__c = stateStr,
            Postal_Code__c = postalCodeStr,
            Country__c = countryStr,
            Type__c = typeStr,
            Furnishing_Status__c = furnishingStr,
            Status__c = statusStr,
            Rent__c = rentNum,
            Description__c = descriptionStr
        );

        // Geocode synchronously BEFORE insert so lat/long are saved immediately
        Map<String, Decimal> coords = GeocodingService.geocodeAddressSync(
            addressStr, cityStr, stateStr, countryStr
        );
        if (coords != null) {
            p.Geolocation__Latitude__s = coords.get('lat');
            p.Geolocation__Longitude__s = coords.get('lng');
        }

        insert p;
        return p.Id;
    }

    @AuraEnabled
    public static void deleteProperty(Id propertyId) {
        delete new Property__c(Id = propertyId);
    }

    public class PagedResult {
        @AuraEnabled public List<Property__c> records;
        @AuraEnabled public Integer totalCount;
    }
}