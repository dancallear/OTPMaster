import { LightningElement, api, track, wire } from 'lwc';
import getOTPSettings from '@salesforce/apex/OTPHelper.getOTPSettings';
import generateGUID from '@salesforce/apex/OTPHelper.generateGUID';
import generateOTP from '@salesforce/apex/OTPController.generateOTP';
import validateOTP from '@salesforce/apex/OTPController.validateOTP';
import resendOTP from '@salesforce/apex/OTPController.resendOTP';
import {
    APPLICATION_SCOPE,
    createMessageContext,
    MessageContext,
    publish,
    releaseMessageContext,
    subscribe,
    unsubscribe,
} from 'lightning/messageService';
import guidChannel from '@salesforce/messageChannel/guidChannel__c';

import UserId from '@salesforce/user/Id';

export default class OTPSend extends LightningElement {
    otpSettings;
    currentGUID;
    guidEvent;
    @api guidList = [];
    value = '';

    @wire(MessageContext)
    messageContext;

    get options() {
        return [
            { label: 'Email', value: 'email' },
            { label: 'SMS', value: 'sms' },
        ];
    }

    connectedCallback(){
        getOTPSettings({label:'General_Default'})
            .then(result => {
                console.log('Results >> ' + result);
                this.otpSettings = result;
                console.log('OTP settings >> ' + this.otpSettings);
            })
            .catch(error => {
                console.error(error);
            });
    }

    onSendByChange(event){
        console.log('Send by selected >> ' + event.detail.value);
        this.value = event.detail.value;
    }

    onSendOTPButtonClick(){
        generateGUID()
            .then(result => {
                this.currentGUID = result;

                this.guidEvent = {guid: this.currentGUID, resetguidList: false};
                publish(this.messageContext, guidChannel, this.guidEvent);
               
                
                return generateOTP({guid:this.currentGUID, userId:UserId, otpSettings:this.otpSettings, sendTo:this.value})
                
            })
            .then(result => {
            })
            .catch(error => {
                console.error(error);
            });
    }
}
