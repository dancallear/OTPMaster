public with sharing class OTPHelper {
    public class OTPHelperException extends Exception {}
    public class OTPUtils{
       
        public final String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        public final String lower = upper.toLowerCase();
        public final String numeric = '0123456789';
        public final String alpha = upper + lower;
        public final String alphanumeric = upper + lower + numeric;
    
    
        public final String OneTimePasscodeError = Label.OneTimePasscodeError;
        public final String PrevValidatedError = Label.PrevValidatedError;
        public final String ExpiredError = Label.ExpiredError;
        public final String TimeElapsedError = Label.TimeElapsedError;
        public final String AttemptsError = Label.AttemptsError;
        public final String MaxNumberOfSendsError = Label.MaxNumberOfSendsError;
        public final String OTPGenerationCooldownError = Label.OTPGenerationCooldownError;
        
        
    }

    public class ValidationResponse{
        public Boolean validation;
        public List<String> errors;
        public string guid;
    }

    /* Used to query OTP settings so that multiple queries are not needed (this is more for CPU than SOQL query as .mtd does not count against SOQL limit)
    *
    * Returns - Custom Metadata record
    */
    public static One_Time_Passcode_Setting__mdt getOTPSettings(String label) {
        One_Time_Passcode_Setting__mdt otpSettings;

        try{
            otpSettings = [SELECT 
                                Id,
                                MaxNumberOfOTPAttempts__c,
                                MaxNumberOfOTPSends__c,
                                OTPGenerationCooldown__c,
                                OTPLength__c,
                                TypeOfCode__c,
                                ValidFor__c
                            FROM One_Time_Passcode_Setting__mdt 
                            WHERE MasterLabel = :label];
        }
        catch (Exception e){
            System.debug(e);
            //Log to error logging framework here
            throw new OTPHelperException('Error retrieveing OTP settings. See logs for details.');
        }


        return otpSettings;
    }

    //SendTo is optional - see overloaded method
    //Return - Void
    public static void createOTPRecord(String otp, String guid, String userId){
        //TEMP VALUE FOR DEV - this needs to be sourced from Metadata
        String sendTo = 'email';
        One_Time_Passcode__c otpRecord = new One_Time_Passcode__c(
                                                                    GUID__c = guid,
                                                                    IsValidated__c = false,
                                                                    AttemptsMade__c = 0,
                                                                    OneTimePasscode__c = otp,
                                                                    User__c = userId,
                                                                    SendTo__c = sendTo
                                                                );

        try{
            insert otpRecord;
        }catch(Exception e){
            //Log to error logging framework here
            throw new OTPHelperException('Error creating OTP. See logs for details.');
        }
    }

    //Overeload incase we want to force where we send 
    //Return - Void
    public static void createOTPRecord(String otp, String guid, String userId, String sendTo){
        One_Time_Passcode__c otpRecord = new One_Time_Passcode__c(
                                                                    GUID__c = guid,
                                                                    IsValidated__c = false,
                                                                    AttemptsMade__c = 0,
                                                                    OneTimePasscode__c = otp,
                                                                    User__c = userId,
                                                                    SendTo__c = sendTo
                                                                );

        try{
            insert otpRecord;
        }catch(Exception e){
            //Log to error logging framework here
            throw new OTPHelperException('Error creating OTP. See logs for details.');
        }
    }

    //Single method for update and exception capture
    //Return - Void
    public static void updateOTPRecord(One_Time_Passcode__c otpRecord){
        try{
            update otpRecord;
        }
        catch(Exception e){
            System.debug(e);
            //Log to error logging framework here
            throw new OTPHelperException('Error updating OTP. See logs for details.');
        }

        
    }

    //Single method for GUID generation
    //Return - String GUID
    public static String generateGUID(){
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);

        return guid;
    }

    //Helper method for OTP generation
    //Return - String OTP
    public static String getRandom(String type, Decimal otpLength){
        OTPUtils utils = new OTPUtils();
        String utilString;
        String otp;

        Switch on type{
            when 'Alpha'{
                utilString = utils.alpha;
            }
            when 'Numeric'{
                utilString = utils.numeric;
            }
            when 'Alphanumeric'{
                utilString = utils.alphanumeric;
            }
        }

        for(Integer i; i <= otpLength; i++){
            otp = otp + (utilString.charAt(Integer.valueOf(Math.floor(Math.random() * utilString.length()))));
        }

        return otp;
    }

    //Checks OTP is valid
    //Return - V Return: Validation:True||False, Errors:List<String>Errors
    public static ValidationResponse validationChecks(String otp, One_Time_Passcode__c  otpRecord, one_Time_Passcode_Setting__mdt otpSettings){
        List<String> validationErrors;
        Integer validationErrorCount;
        ValidationResponse validationResponse = new ValidationResponse();

        OTPUtils utils = new OTPUtils();
        

        if(otp != otpRecord.OneTimePasscode__c){
            validationErrorCount =+ 1;
            validationErrors.add(utils.OneTimePasscodeError);
            
        }

        if(otpRecord.IsValidated__c){
            validationErrorCount =+ 1;
            validationErrors.add(utils.PrevValidatedError);
        }

        if(otpRecord.ValidTo__c < Datetime.now()){
            validationErrorCount =+ 1;
            validationErrors.add(utils.TimeElapsedError);
        }

        if(otpRecord.AttemptsMade__c > otpSettings.MaxNumberOfOTPAttempts__c){
            validationErrorCount =+ 1;
            validationErrors.add(utils.AttemptsError);
        }

        if(otpRecord.IsExpired__c){
            validationErrorCount =+ 1;
            validationErrors.add(utils.ExpiredError);
        }

        System.debug('validationErrorCount > ' + validationErrorCount);
        System.debug('validationErrors > ' + validationErrors);

        otpRecord.AttemptsMade__c = otpRecord.AttemptsMade__c + 1;

        updateOTPRecord(otpRecord);

        if(validationErrorCount == 0){
            validationResponse.validation = true;
            return validationResponse;
        }else{
            validationResponse.validation = false;
            validationResponse.errors = validationErrors;
            return validationResponse;
        }
    }


    //Checks OTP can be resent
    //Return - V Return: Validation:True||False, Errors:List<String>Errors
    public static ValidationResponse validateResendOTP(List<String> prevGUIDs, String userId, One_Time_Passcode_Setting__mdt otpSettings){
        List<String> validationErrors;
        Integer validationErrorCount;
        ValidationResponse validationResponse = new ValidationResponse();

        OTPUtils utils = new OTPUtils();

        List<One_Time_Passcode__c> cleanUpOldOTPRecords = new List<One_Time_Passcode__c>();
        List<One_Time_Passcode__c> otpRecords;
        
        try{
            otpRecords = [SELECT 
                                GUID__c, 
                                User__c, 
                                CreatedDate,
                                SystemModstamp 
                            FROM One_Time_Passcode__c
                            WHERE GUID__c IN :prevGUIDs
                            AND User__c = :userId
                            ORDER BY SystemModstamp desc];
        }catch(Exception e){

            //Log to error logging framework here
            throw new OTPHelperException('Error validating OTP resend checks. See logs for details.');
        }

        if(otpRecords.size() > otpSettings.MaxNumberOfOTPSends__c){
            validationErrorCount =+ 1;
            validationErrors.add(utils.MaxNumberOfSendsError);
        }
        if(otpRecords[0].SystemModstamp < Datetime.now()+otpSettings.OTPGenerationCooldown__c){
            validationErrorCount =+ 1;
            validationErrors.add(utils.OTPGenerationCooldownError);
        }
        
        if(validationErrorCount == 0){
            validationResponse.validation = true;
            return validationResponse;
        }else{
            validationResponse.validation = false;
            validationResponse.errors = validationErrors;
            return validationResponse;
        }
                            
    }
}