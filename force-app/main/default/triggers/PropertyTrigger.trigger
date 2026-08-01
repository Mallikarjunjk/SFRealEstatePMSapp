trigger PropertyTrigger on Property__c (after update) {
    for (Property__c p : Trigger.new) {
        Property__c oldP = Trigger.oldMap.get(p.Id);
        if (p.Address__c != oldP.Address__c || p.City__c != oldP.City__c ||
            p.Postal_Code__c != oldP.Postal_Code__c || p.Country__c != oldP.Country__c) {
            GeocodingService.geocodeProperty(p.Id);
        }
    }
}