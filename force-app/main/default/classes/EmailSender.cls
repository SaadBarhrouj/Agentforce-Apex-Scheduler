public with sharing class EmailSender {

    public class EmailRequest {
        @InvocableVariable(required=true)
        public String contactEmail;
        @InvocableVariable(required=true)
        public String subject;
        @InvocableVariable(required=true)
        public String htmlBody;
    }

    @InvocableMethod(label='Send AI-Generated Email')
    public static void sendEmail(List<EmailRequest> requests) {
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (EmailRequest req : requests) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ req.contactEmail });
            email.setSubject(req.subject);
            email.setHtmlBody(req.htmlBody);
            emailsToSend.add(email);
        }

        if (!emailsToSend.isEmpty() && Schema.sObjectType.Contact.isAccessible()) {
             Messaging.sendEmail(emailsToSend);
        }
    }
}