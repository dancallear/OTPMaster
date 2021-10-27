import { LightningElement, api, track, wire } from 'lwc';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext,
} from 'lightning/messageService';
import guidChannel from '@salesforce/messageChannel/guidChannel__c';

export default class OTPContainer extends LightningElement {

   guidList = [];
   currentGUID;

   pubGUIDObj;

    showSendLWC = true;
    showVerifyLWC = false;

    @wire(MessageContext)
    messageContext;

    subscription = null;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                guidChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        if(message.resetguidList == true){
            this.guidList = [];
        }
        this.guidList.push(message.guid);
        this.currentGUID = message.guid;
        console.log('this.guidList >>' + this.guidList)

        if(this.guidList != null){
            this.showSendLWC = false;
            this.showVerifyLWC = true;
        }
    }

    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    
}
