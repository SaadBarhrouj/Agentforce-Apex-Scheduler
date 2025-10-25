public with sharing class AppointmentScheduler {

    public class AppointmentRequest {
        @InvocableVariable(required=true)
        public DateTime inputDateTime;

        @InvocableVariable(required=true)
        public String skillNeeded; 

        @InvocableVariable(required=true)
        public String territory;
    }

    public class AvailabilityResult {
        @InvocableVariable
        public Boolean isAvailable;

        @InvocableVariable
        public List<String> suggestedSlots; 

        public AvailabilityResult() {
            this.isAvailable = false; 
            this.suggestedSlots = new List<String>();
        }
    }

    @InvocableMethod(label='Check & Suggest Availability (FSL-Light)')
    public static List<AvailabilityResult> checkAvailability(List<AppointmentRequest> requests) {
        
        AppointmentRequest req = requests[0];
        AvailabilityResult result = new AvailabilityResult();

        Set<Id> validTechnicianIds = new Map<Id, ServiceResource>([
            SELECT Id FROM ServiceResource
            WHERE Skills__c INCLUDES (:req.skillNeeded) 
            AND Territory__c = :req.territory
            AND Active = true 
            WITH SECURITY_ENFORCED
        ]).keySet();

        List<ServiceAppointment> conflictingAppointments = new List<ServiceAppointment>();
        if (!validTechnicianIds.isEmpty()) {
            conflictingAppointments = [
                SELECT Id FROM ServiceAppointment
                WHERE SchedStartTime = :req.inputDateTime
                AND ServiceResourceId IN :validTechnicianIds
                WITH SECURITY_ENFORCED
            ];
        }

        if (conflictingAppointments.isEmpty() && !validTechnicianIds.isEmpty()) {
            result.isAvailable = true;
        
        } else {
            result.isAvailable = false;
            
            DateTime nextSlot = req.inputDateTime;
            Integer slotsFound = 0;
            Integer maxChecks = 8; 

            while (slotsFound < 3 && maxChecks > 0) {
                
                nextSlot = nextSlot.addHours(1);
                
                List<ServiceAppointment> nextConflicts = [
                    SELECT Id FROM ServiceAppointment
                    WHERE SchedStartTime = :nextSlot
                    AND ServiceResourceId IN :validTechnicianIds
                    WITH SECURITY_ENFORCED
                ];

                if (nextConflicts.isEmpty()) {
                    String formattedTime = nextSlot.formatGmt('HH:mm');
                    result.suggestedSlots.add(formattedTime);
                    slotsFound++;
                }
                
                maxChecks--;
            }
        }
        
        return new List<AvailabilityResult>{ result };
    }
}