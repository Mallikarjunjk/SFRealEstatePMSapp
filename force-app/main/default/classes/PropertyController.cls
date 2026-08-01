public with sharing class PropertyController {

    @AuraEnabled(cacheable=true)
    public static PagedResult getProperties(
        Integer pageNumber, Integer pageSize,
        Decimal maxPrice, String availabilityStatus, String furnishingStatus,
        Decimal userLat, Decimal userLng, Decimal withinKm
    ) {
        Integer offset = (pageNumber - 1) * pageSize;

        String query = 'SELECT Id, Name, Address__c, City__c, State__c, Rent__c, ' +
                        'Status__c, Furnishing_Status__c, Type__c, Geolocation__c ' +
                        'FROM Property__c WHERE Id != null ';
        List<Object> binds = new List<Object>();

        if (maxPrice != null) query += 'AND Rent__c <= :maxPrice ';
        if (String.isNotBlank(availabilityStatus)) query += 'AND Status__c = :availabilityStatus ';
        if (String.isNotBlank(furnishingStatus)) query += 'AND Furnishing_Status__c = :furnishingStatus ';

        // Distance filter uses SOQL geolocation DISTANCE function
        if (userLat != null && userLng != null && withinKm != null) {
            query += 'AND DISTANCE(Geolocation__c, GEOLOCATION(:userLat, :userLng), \'km\') <= :withinKm ';
        }

        query += 'ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset';

        List<Property__c> records = Database.query(query);

        Integer totalCount = [SELECT COUNT() FROM Property__c];

        PagedResult result = new PagedResult();
        result.records = records;
        result.totalCount = totalCount;
        return result;
    }

    public class PagedResult {
        @AuraEnabled public List<Property__c> records;
        @AuraEnabled public Integer totalCount;
    }
}