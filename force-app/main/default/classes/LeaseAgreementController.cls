public with sharing class LeaseAgreementController {

    @AuraEnabled(cacheable=true)
    public static LeaseDetails getLeaseDetails(Id leaseId) {
        Lease_Agreement__c lease = [
            SELECT Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c,
                   Property__r.Name, Tenant__r.Name, Tenant__r.Email__c
            FROM Lease_Agreement__c
            WHERE Id = :leaseId
        ];

        LeaseDetails details = new LeaseDetails();
        details.propertyName = lease.Property__r.Name;
        details.tenantName = lease.Tenant__r.Name;
        details.tenantEmail = lease.Tenant__r.Email__c;
        details.rent = lease.Agreed_Monthly_Rent__c;
        details.startDate = lease.Start_Date__c != null ? lease.Start_Date__c.format() : '';
        details.endDate = lease.End_Date__c != null ? lease.End_Date__c.format() : '';
        details.terms = lease.Terms__c;
        return details;
    }

    @AuraEnabled
    public static void sendLeasePdf(Id leaseId, String base64Pdf) {
        Lease_Agreement__c lease = [
            SELECT Tenant__r.Email__c, Tenant__r.Name
            FROM Lease_Agreement__c
            WHERE Id = :leaseId
        ];

        if (String.isBlank(lease.Tenant__r.Email__c)) {
            throw new AuraHandledException('Tenant does not have an email address on file.');
        }

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Lease_Agreement.pdf');
        attachment.setBody(EncodingUtil.base64Decode(base64Pdf));
        attachment.setContentType('application/pdf');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{ lease.Tenant__r.Email__c });
        email.setSubject('Your Lease Agreement');
        email.setPlainTextBody('Hi ' + lease.Tenant__r.Name + ', please find your lease agreement attached.');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{ attachment });

        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
    }

    public class LeaseDetails {
        @AuraEnabled public String propertyName;
        @AuraEnabled public String tenantName;
        @AuraEnabled public String tenantEmail;
        @AuraEnabled public Decimal rent;
        @AuraEnabled public String startDate;
        @AuraEnabled public String endDate;
        @AuraEnabled public String terms;
    }
}