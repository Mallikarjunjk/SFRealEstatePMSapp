public with sharing class MaintenanceRequestTriggerHandler {

    public static void assignVendors(List<Maintenance_Request__c> newRequests) {
        // Build a workload map: Vendor Id -> count of active (Open/In Progress) requests
        Map<Id, Integer> vendorWorkload = new Map<Id, Integer>();

        for (Vendor__c v : [SELECT Id FROM Vendor__c]) {
            vendorWorkload.put(v.Id, 0);
        }

        // No vendors exist at all — nothing to assign, exit early
        if (vendorWorkload.isEmpty()) {
            return;
        }

        for (AggregateResult ar : [
            SELECT Vendor__c vId, COUNT(Id) cnt
            FROM Maintenance_Request__c
            WHERE Status__c IN ('Open', 'In Progress') AND Vendor__c != null
            GROUP BY Vendor__c
        ]) {
            vendorWorkload.put((Id) ar.get('vId'), (Integer) ar.get('cnt'));
        }

        // Assign each new request to whichever vendor currently has the least workload,
        // updating the running count as we go so multiple requests in the same batch spread out
        for (Maintenance_Request__c mr : newRequests) {
            if (mr.Vendor__c == null) {
                Id leastLoadedVendor = findLeastLoadedVendor(vendorWorkload);
                if (leastLoadedVendor != null) {
                    mr.Vendor__c = leastLoadedVendor;
                    vendorWorkload.put(leastLoadedVendor, vendorWorkload.get(leastLoadedVendor) + 1);
                }
            }
        }
    }

    private static Id findLeastLoadedVendor(Map<Id, Integer> vendorWorkload) {
        Id leastLoaded = null;
        Integer minCount = null;
        for (Id vId : vendorWorkload.keySet()) {
            Integer count = vendorWorkload.get(vId);
            if (minCount == null || count < minCount) {
                minCount = count;
                leastLoaded = vId;
            }
        }
        return leastLoaded;
    }
}