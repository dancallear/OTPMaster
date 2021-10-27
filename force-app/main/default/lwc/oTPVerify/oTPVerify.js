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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import UserId from '@salesforce/user/Id';

export default class OTPVerify extends LightningElement {

    otpSettings;
    otp = '';
    @api currentGUID;
    validateOTPCorrect;

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

    handleInputChange(event){
        this.otp = event.target.value;
    }

    verifyOTP(){
        validateOTP({otp:this.otp, guid:this.currentGUID, userId:UserId, otpSettings:this.otpSettings})
        .then(result => {
            console.log(result);
            let validationResult = JSON.parse(result);
            console.log(validationResult.validation);
            if(validationResult.validation == true){
                const evt = new ShowToastEvent({
                    title: 'Onetime Passcode Varified',
                    message: 'Your Onetime Passcode was correct, well done!',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            }
            
        })
        .catch(error => {
            console.error(error);
        })
    }

    newOTPButtonClick(){


    }
}
