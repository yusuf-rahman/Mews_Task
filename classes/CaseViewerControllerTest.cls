@isTest
public without sharing class CaseViewerControllerTest {

    // Validating a platform event is published when the method is called 
    @isTest
    private static void publishEventTestSuccess(){
       
        Test.startTest();
        CaseViewerController.publishEvent('5008d000009kvuUAAQ', '5008d000009kvuUAAQ', false);
        Integer dmlStatements = Limits.getDMLStatements();
        Test.stopTest();

        System.assertEquals(1, dmlStatements, 'One platform event was expected to fire');
    }

    // Validating that an exception is thrown when bad data is passed to the method
    @isTest
    private static void publishEventTestError(){

        Test.startTest();
        try{
            CaseViewerController.publishEvent('5008d000009kvuUAAQrstuvwxyz', '5008d000009kvuUAAQ', false);
        } catch (Exception e){
            System.assertNotEquals(null, e.getMessage());
        }    
        Test.stopTest();
    }

    // Validating ownerId is returned when the owner is a queue
    @isTest
    private static void getCaseDataTestSuccessA(){
        
        Group testGroup = new Group(Name='test group', Type='Queue');
        insert testGroup;
        
        System.runAs(new User(Id=UserInfo.getUserId())){
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
            insert testQueue;
        }

        Case newCase = new Case(Subject = 'Test', Status = 'New', Origin = 'Web', OwnerId = testGroup.Id);
        insert newCase;

        Test.startTest();
        String result = CaseViewerController.getCaseData(newCase.Id);
        Test.stopTest();

        System.assertEquals(testGroup.Id , result, 'The correct owner Id was not returned');
    }

    // Validating ownerId is not returned when the owner is a user
    @isTest 
    private static void getCaseDataTestSuccessB(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User user = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@mewstest.com');
        insert user;    
        
        Case newCase = new Case(Subject = 'Test', Status = 'New', Origin = 'Web', OwnerId = user.Id);
        insert newCase;

        Test.startTest();
        String result = CaseViewerController.getCaseData(newCase.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'The correct owner Id was not returned');
    }

    // Validating an exception is thrown when bad data is passed to the method 
    @isTest
    private static void getCaseDataTestError(){
        
        Test.startTest();

        try{
            String result = CaseViewerController.getCaseData('5008d000009kvuUAAQ');
        } catch (Exception e){
            System.assertNotEquals(null, e.getMessage());
        }
        
        Test.stopTest();

    }

}
