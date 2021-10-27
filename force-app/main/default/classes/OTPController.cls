public with sharing class OTPController {
    public class OTPControllerException extends Exception {}

    /*
    This method generates the OTP based on the custom metadata settings specification.
    This method then creates a OTP record.
    SendTo is optional - see overloaded method

    Return - Void
    */
    @AuraEnabled
    public static void generateOTP(String guid, String userId, One_Time_Passcode_Setting__mdt otpSettings, String sendTo){
        String otp;

        System.debug('guid' + ' >>' + guid );
        System.debug('userId' + ' >>' + userId );
        System.debug('otpSettings' + ' >>' + otpSettings );
        System.debug('sendTo' + ' >>' + sendTo );
        System.debug('otpSettings.TypeOfCode__c' + ' >>' + otpSettings.TypeOfCode__c );
        System.debug('otpSettings.OTPLength__c' + ' >>' + otpSettings.OTPLength__c );

        Switch on otpSettings.TypeOfCode__c {
            when 'Alpha'{
                otp = OTPHelper.getRandom(otpSettings.TypeOfCode__c, otpSettings.OTPLength__c);
            }
            when 'Alphanumeric'{
                otp = OTPHelper.getRandom(otpSettings.TypeOfCode__c, otpSettings.OTPLength__c);
            }
            when 'Numeric'{
                otp = OTPHelper.getRandom(otpSettings.TypeOfCode__c, otpSettings.OTPLength__c);
            }
        }

        System.debug('otp' + ' >>' + otp );

        if(sendTo == null){
            OTPHelper.createOTPRecord(otp, guid, userId);
        }else{
            OTPHelper.createOTPRecord(otp, guid, userId, sendTo);
        }

        sendOTP(otp);
        
    }

    /*
    This method hands off the validation check to a helper method.

    Return: Validation:True||False, Errors:List<String>Errors
    */
    @AuraEnabled
    public static String validateOTP(String otp, String guid, String userId, One_Time_Passcode_Setting__mdt otpSettings){
        One_Time_Passcode__c otpRecord;
        OTPHelper.ValidationResponse validationResponse;
        try{
            otpRecord = [SELECT Id,
                                OneTimePasscode__c,
                                GUID__c,
                                User__c,
                                IsValidated__c,
                                IsExpired__c,
                                AttemptsMade__c,
                                validTo__c
                        FROM One_Time_Passcode__c
                        WHERE GUID__c = :guid
                        AND User__c = :userId
            ];
                        
        }
        catch (Exception e){
            System.debug(e);
            //Here log to error logging framework
            throw new OTPControllerException('Error retrieveing OTP for this user or session. See logs for details.');
        }

        System.debug('otprecord >> ' + otpRecord);

        System.debug('otp >> ' + otp);
        System.debug('otpSettings >> ' + otpSettings);
        
        validationResponse = OTPHelper.validationChecks(otp, otpRecord, otpSettings);

        System.debug('validationResponse >> ' + validationResponse);

        return JSON.serialize(validationResponse);
    }

    /*
    This method hands off the check of allow/disallow a resend OTP to a helper method.
    THe prevGUID are used to check which OTPs should be checked against in the cooldown check.
    The UI cmp must hold a list of GUIDs for this method.
    If in the ValidationResponse you are returend a cooldown enforcement, once that period is up the GUID list can be reset to null and a new list of GUIDs are to be captured ...
    ... this resets the time of cooldown.
    SendTo is optional - see overloaded method

    Return: Validation:True||False, Errors:List<String>Errors, guid:GUID
    */
    @AuraEnabled
    public static String resendOTP(List<String> prevGUIDs, String userId, One_Time_Passcode_Setting__mdt otpSettings, String sendTo){
        

        OTPHelper.ValidationResponse validationResponse = OTPHelper.validateResendOTP(prevGUIDs, userId, otpSettings);
        if(validationResponse.validation == true){
            String guid = OTPHelper.generateGUID();
            validationResponse.guid = guid;
            
            generateOTP(guid, userId, otpSettings, sendTo);
        }
        return JSON.serialize(validationResponse);
    }


    /*
    This method handles the send logic 

    Returns - Void
    */
    private static void sendOTP(String otp){
        System.debug('Code sent -- ' + otp);
        //Check send method

        //If send to SMS:
        //sendOTPViaSMS()

        //If send to Email:
        //sendOTPViaEmail()

        //If send to Push:
        //sendOTPViaPush()

        //If send to Auth:
        //sendOTPViaAuthenticator()
    }
    
}
