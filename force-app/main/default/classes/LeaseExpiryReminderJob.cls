global class LeaseExpiryReminderJob implements Schedulable {

    global void execute(SchedulableContext ctx) {
        Date in30Days = Date.today().addDays(30);
        Date in1Day = Date.today().addDays(1);

        List<Lease_Agreement__c> expiringIn30 = [
            SELECT Id, Tenant__r.Email__c, Tenant__r.Name, Property__r.Name
            FROM Lease_Agreement__c
            WHERE End_Date__c = :in30Days AND Tenant__r.Email__c != null
        ];

        List<Lease_Agreement__c> expiringIn1 = [
            SELECT Id, Tenant__r.Email__c, Tenant__r.Name, Property__r.Name
            FROM Lease_Agreement__c
            WHERE End_Date__c = :in1Day AND Tenant__r.Email__c != null
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Lease_Agreement__c l : expiringIn30) {
            emails.add(buildEmail(l, 30));
        }
        for (Lease_Agreement__c l : expiringIn1) {
            emails.add(buildEmail(l, 1));
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    private Messaging.SingleEmailMessage buildEmail(Lease_Agreement__c l, Integer daysLeft) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{ l.Tenant__r.Email__c });
        email.setSubject('Lease Agreement Expiring in ' + daysLeft + ' Day(s)');
        email.setPlainTextBody(
            'Hi ' + l.Tenant__r.Name + ',\n\n' +
            'Your lease agreement for ' + l.Property__r.Name + ' expires in ' + daysLeft + ' day(s).\n' +
            'Please contact us to renew or discuss next steps.\n\n' +
            'Thank you.'
        );
        return email;
    }
}