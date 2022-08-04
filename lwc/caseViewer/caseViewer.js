import { LightningElement, api, wire} from 'lwc';
import { subscribe, unsubscribe, onError} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import publishEvent from '@salesforce/apex/CaseViewerController.publishEvent';
import getCaseData from '@salesforce/apex/CaseViewerController.getCaseData';
import uId from '@salesforce/user/Id';

export default class CaseViewer extends LightningElement {
    @api recordId; // Variable to store record Id for use in imperative calls
    @api channelName ='/event/Case_View_Query__e'; // Variable to store platform event channel name 
    userId = uId; // Variable to store Id of user viewing page
    subscription = {}; // Array to store subscription for subscribe and unsubscribe functionality

    // Method to run intial setup logic when element is inserted into DOM
    connectedCallback(){

        this.registerErrorListener(); // Invoke empAPI error listener
        this.handleSubscribe(); // Invoke empAPI subscribe handler

        // Call apex method to retrieve case owner ID, this could not be done through wire method due to timing
        getCaseData({caseId:this.recordId})
        .then(result => {
            console.log('Successfully retrieved Owner ID: ' + result);
            // Check if a result is returned
            if(result != null){
                // Fire intitial event via apex, to be handled by the same compnent in other clients
                publishEvent({caseId:this.recordId, requestorId: this.userId, response: false})
                .then(result => {
                    console.log('Successfully sent platform event');
                })
                .catch(error => {
                    console.log(error);
                });
            }
        })
        .catch(error => {
            this.error = error;
            console.log(error);
        });

    }

    // Using lifecycle hook to unsubscribe from event channel to prevent unwanted back and forth
    disconnectedCallback(){
        console.log('Disconnected callback invoked');
        this.handleUnsubscribe();
    }

    // Function to handle subscribing to event channel
    handleSubscribe() {

        // Callback invoked whenever a new event message is received
        const messageCallback = (response) => {

            // Parse response and store in variables
            var obj = JSON.parse(JSON.stringify(response));
            console.log(obj.data.payload);
            var caseId = obj.data.payload.Case_ID__c;
            var sent = obj.data.payload.Response__c;
            var requestorId = obj.data.payload.Requestor_ID__c;

            // Call response handler function 
            this.handleResponse(caseId, sent, requestorId);
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }

    // Function to handle unsubscribing from event channel
    handleUnsubscribe() {

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    // Fucntion to enable error event listener
    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    // Function to check 
    handleResponse(record, received, requestor){
        
        // Check if platform event received relates to current record and if it was requested by another user
        // These checks prevent recursion 
        if((record == this.recordId) && (received == false) && (requestor != this.userId)){
            
            // Publish event back to original requesting user 
            publishEvent({caseId:this.recordId, requestorId: requestor, response: true})
            .then(result => {
                this.contacts = result;
                console.log('Response sent');
            })
            .catch(error => {
                this.error = error;
                console.log(error);
            });
        // Check if event received is a response from user viewing the same record using recordId and requestorId as keys
        } else if((record == this.recordId) && (received == true) && (requestor == this.userId)){
            // Show a toast message to notify the user that another user is viewing the case
            const event = new ShowToastEvent({
                title: 'Warning',
                message:'Another agent is viewing this case',
                mode: 'sticky'
            });
            this.dispatchEvent(event);
            this.handleUnsubscribe(); // Unsubsubscribe from the event channel to prevent further events being handled (duplication)
        }
    }
}