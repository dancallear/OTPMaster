import { LightningElement } from 'lwc';

export default class OTPInitial extends LightningElement {
    value = '';

    get options() {
        return [
            { label: 'Email', value: 'email' },
            { label: 'SMS', value: 'sms' },
        ];
    }

    onOptionsChange(event){
        this.value = event.target.value;
    }

    sendOTP(){
        
    }
}