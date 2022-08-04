public without sharing class CaseViewerController {

    // Method to fire platform events from LWC
    @AuraEnabled
    public static void publishEvent(String caseId, String requestorId, Boolean response){
        try{
            // In this platform event, caseId is used as a key to match cases, RequestorId is used to propogate the user who triggered the intial event 
            // Response is a boolean to indicate the direction of the event, i.e. is it the inital event or the response to another event
            Case_View_Query__e event = new Case_View_Query__e(Case_ID__c = caseId, Requestor_ID__c = requestorId, Response__c = response);
            Database.SaveResult sr = EventBus.publish(event);
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Method to return case owner ID if the owner is a queue
    @AuraEnabled
    public static String getCaseData(String caseId){
        try {
            // Querying case to retrieve owner Id
            Case cs = [SELECT id, OwnerId FROM Case WHERE Id =: caseId];
            // Checking if the owner is a queue using the first three characters
            if(String.valueOf(cs.OwnerId).startsWith('00G')){
                return String.valueOf(cs.OwnerId);
            } else{
                return null;
            }            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
