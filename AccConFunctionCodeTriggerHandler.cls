/**
*   Description: 
*       1. After Insert: Update Contact IR Flag
*
*   Modification Log :
---------------------------------------------------------------------------
    Developer               Date            Description
---------------------------------------------------------------------------
    Nagaraju Chikka         05/18/2016      Created: CSR-0005369: Function Codes
    Nagaraju Chikka         08/25/2016      Updated code: Story 553514 - CSR-0006512 Restrict S3 function code to specific users
******************************************************************************************/
public class AccConFunctionCodeTriggerHandler {
    private static boolean isTrgExecuting=false;
    public static List<Account_Contact_Function_Code__c> acfcsLst = new List<Account_Contact_Function_Code__c>();
    
    /**
    * Constructor to initialize
    *
    * @param isExecuting    Has value of which context it is executing.
    */
    public AccConFunctionCodeTriggerHandler(boolean isExecuting) {
        isTrgExecuting=isExecuting;
    }
    
    /**
    * Description: Updates Contact IR Flag
    * CSR-0005369
    * @param newAccConFCs    Get new AccountContactFunctionCode records.
    */
    public void OnBeforeInsert(Account_Contact_Function_Code__c[] newAccConFCs){
        doSetFunctionCodeType(newAccConFCs, null);
    }
    
    /**
    * Description: Updates Contact IR Flag
    * CSR-0005369
    * @param newAccConFCs    Get new AccountContactFunctionCode records.
    */
    public void OnAfterInsert(Account_Contact_Function_Code__c[] newAccConFCs){
        Set<Id> contactsSet = new Set<Id>();
        List<Contact> contactsUpdate = new List<Contact>();
        
        for(Account_Contact_Function_Code__c acfc: newAccConFCs){
            contactsSet.add(acfc.Contact__c);
        }
        
        if(!contactsSet.isEmpty()){
            for(Contact cont: [Select Id, IR_Flag__c From Contact Where Id In: contactsSet AND IR_Flag__c=:False]){
                cont.IR_Flag__c = TRUE;
                contactsUpdate.add(cont);
            }
        }
        
        if(!contactsUpdate.isEmpty())
            update contactsUpdate;
    }
    
    /*
     * Description: 
     * @param newAccConFCs    Get new AccountContactFunctionCode records.
     * @param oldAccConFCs    Get map of old AccountContactFunctionCode records.
    */
    public void onBeforeUpdate(Account_Contact_Function_Code__c[] newAccConFCs, Map<Id, Account_Contact_Function_Code__c> oldAccConFCsMap){
        doSetFunctionCodeType(newAccConFCs, oldAccConFCsMap);
    }
    
    /*
     * Description: updates s3 function code status to ACR record.
     * @param delACFCodes    Get new AccountContactFunctionCode records.
    */
    public void OnAfterDelete(Account_Contact_Function_Code__c[] delACFCodes){
        
        List<Account_Contact_Relationship__c> acrsUpdateList = new List<Account_Contact_Relationship__c>();
        Set<Id> acrIdsSet = new Set<Id>();
        
        for(Account_Contact_Function_Code__c acfc: delACFCodes){
            if(acfc.Related_Function_Code__c == System.Label.Label_S3_FunctionCode)
                acrIdsSet.add(acfc.Account_Contact_Relationship__c);
        }
        
        if(!acrIdsSet.isEmpty()){
            for(Account_Contact_Relationship__c acr: [Select Id, Name,Request_we_Do_Not_Survey__c,S3_Approval_Status__c,S3_Function_Code_Approver__c,S3_Function_Code_Submitter__c From Account_Contact_Relationship__c Where Id In: acrIdsSet]){
                acr.Request_we_Do_Not_Survey__c = false;
                acr.S3_Approval_Status__c = null;
                acr.S3_Reason__c = null;
                acr.S3_Function_Code_Approver__c = null;
                acr.S3_Function_Code_Submitter__c = null;
                
                acrsUpdateList.add(acr);
            }
            
            if(!acrsUpdateList.isEmpty())
                update acrsUpdateList;
        }
        
        
    }
    
    /*
     * Description: to set Function Code's type to ACFC Function Code Type field
     * @param newAccConFCs    Get new AccountContactFunctionCode records.
     * @param oldAccConFCs    Get map of old AccountContactFunctionCode records.
    */
    public void doSetFunctionCodeType(Account_Contact_Function_Code__c[] newAccConFCs, Map<Id, Account_Contact_Function_Code__c> oldAccConFCsMap){
        
        Map<Id, String> fcsMap = new Map<Id, String>();
        for(Account_Contact_Function_Code__c acfc: newAccConFCs){
            if(null != acfc.Related_Function_Code__c){
                if((null == oldAccConFCsMap) || (null != oldAccConFCsMap && oldAccConFCsMap.containsKey(acfc.Id) && oldAccConFCsMap.get(acfc.Id).Related_Function_Code__c != acfc.Related_Function_Code__c))
                    fcsMap.put(acfc.Related_Function_Code__c, null);
            }
        }
        
        if(!fcsMap.isEmpty()){
            for(Function_Code__c fc: [Select Id, Type__c From Function_Code__c Where Id In: fcsMap.keySet() AND Active__c =: True]){
                fcsMap.put(fc.Id, fc.Type__c);
            }
        }
        
        for(Account_Contact_Function_Code__c acfc: newAccConFCs){
            if(null != acfc.Related_Function_Code__c && fcsMap.containsKey(acfc.Related_Function_Code__c)){
                acfc.Function_Code_Type__c = fcsMap.get(acfc.Related_Function_Code__c);
            }
        }
    }
}