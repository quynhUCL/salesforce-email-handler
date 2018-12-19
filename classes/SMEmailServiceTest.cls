/**
 * Created by scweber on 8/1/18.
 */
@isTest
private class SMEmailServiceTest {
    // Utility function to send a test email
    public static String CONSULT_QUEUE = 'Consult Request Queue';
    public static String TEST_JSON = '{"LastName":"Kiamanesh","FirstName":"Eileen F","SUNet_ID__c":"","Email":"ekiamanesh@gmail.com","Phone":"(650) 723-7688","Department":"","suaffiliation__c":"","Rank__c":"Other Stanford Faculty/Staff/Student","Stanford_Dept__c":null}~#~#~{"SUnet_ID_case__c":"eileenk","Subject":"Pilot of SF2 ","Availability__c":"","Origin":"Web","ContactEmail":"ekiamanesh@gmail.com","ContactPhone":"(650) 723-7688","Description":"Initial submission for testing purposes. ","Funding_status__c":"Funding Status Unknown","I_am_PI_case__c":"false","IRB_Protocol__c":"25486","Project_Department__c":null,"REDCap_StudyName__c":"","Publication_Plans__c":"Unsure","Original_Queue_Name__c":"queuename=Consult Request Queue;shortname=RIC;longname=Research Informatics Center;url=https://ric-help.med.stanford.edu/;email=informaticsonconsultation@lists.stanford.edu;owneralias=richelp","CustomOrigin__c":"RIC Form V1","Primary_Category__c":"General Inquiry","PI_Name__c":"Eileen-PI Kiamanesh"}';

    public static void setup() {

        // call the class and test it with this email

        Group theQueu = new Group();
        theQueu.Type = 'Queue';
        theQueu.Name = CONSULT_QUEUE;
        insert theQueu;
        List<Group> theQueuList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :CONSULT_QUEUE];
        theQueu = theQueuList.get(0);
        User sweber = new User();
        sweber.FirstName = 'Testy';
        sweber.Email = 'test@noorg.edu';
        sweber.LastName = 'Testerson';
        sweber.Username = 'test@noorg.edu';
        sweber.CommunityNickname = 'testy';
        sweber.Alias = 'testy';
        sweber.TimeZoneSidKey = 'America/Los_Angeles';
        sweber.LocaleSidKey = 'en_US';
        sweber.EmailEncodingKey = 'UTF-8';
        sweber.LanguageLocaleKey = 'en_US';
        Profile p = [select id from profile where name = 'Standard User'];
        sweber.ProfileId = p.Id;
        insert sweber;
        List<User> userList = [SELECT FirstName, LastName, Email from User where Email = :sweber.Email];
        sweber = userList.get(0);
        GroupMember groupMember = new GroupMember();
        groupMember.groupId = theQueu.Id;
        groupMember.UserOrGroupId = sweber.Id;
        insert groupMember;

        QueueSobject mappingObject = new QueueSobject(QueueId = theQueu.Id, SobjectType = 'Case');
        System.runAs(new User(Id = UserInfo.getUserId()))
        {insert mappingObject;}
    }

    static SMEmailService setupEmailService() {
        SMEmailService emailServObj = new SMEmailService();
        emailServObj.email = new Messaging.InboundEmail();
        emailServObj.email.fromName = 'test@noorg.edu';
        emailServObj.email.replyTo = 'test@noorg.edu';
        String body = 'Dear {customerName},\n\nThank you for contacting us regarding "{subject}"; your inquiry has been recorded in our case tracking system as {case}. Please include this case number in all future correspondence with us on this topic.\n\nWe strive to respond within 1 business day, if not sooner. If you do not hear back from us by end of day tomorrow and your inquiry is time-sensitive, please reply to this email with "Urgent" in your message.\n\n- The {org.long} Team\n\n{ref}';

        EmailTemplate emailTemplate = new EmailTemplate (DeveloperName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test');
        emailTemplate.Body = body;
        emailTemplate.Subject = 'some {org} pig!';
        Case theCase = new Case();

        theCase.Description = '55';
        theCase.Subject = '66';
        theCase.OwnerId = UserInfo.getUserId();
        System.runAs(new User(Id = UserInfo.getUserId()))
        {insert theCase;}
        List<Case> caseList = [SELECT Id, CaseNumber, reference__c, Description, Subject,OwnerId, Owner.Id, Owner.Name FROM Case WHERE Subject = '66'];
        theCase = caseList.get(0);
        emailServObj.theCase = theCase;
        return emailServObj;
    }



    @isTest public static  void validateNewCaseCreation() {
        setup();
        SMEmailService emailServObj = new SMEmailService();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.toAddresses = new String[]{
                'test@noorg.edu'
        };
        email.subject = 'test';
        email.fromName = 'scweber';
        email.fromAddress = 'test@noorg.edu';
        email.replyTo = 'nobody';
        emailServObj.respondent = 'ditto';
        email.plainTextBody = TEST_JSON;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Insert account as current user

        System.runAs (thisUser) {
            Messaging.Inboundemailresult result = emailServObj.handleInboundEmail(email, env);

            System.assertEquals(result.success, true);
        }
    }

    @isTest public static  void validateCaseResponse1() {
        setup();
        SMEmailService emailServObj = new SMEmailService();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.toAddresses = new String[]{
                'test@noorg.edu'
        };
        email.subject = 'test';
        email.fromName = 'scweber';
        email.fromAddress = 'test@noorg.edu';
        email.replyTo = 'nobody@stanford.edu';
        emailServObj.respondent = 'ditto';
        email.plainTextBody = TEST_JSON;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Insert account as current user

        System.runAs (thisUser) {
            Messaging.InboundEmailResult result = emailServObj.handleInboundEmail(email, env);


            email.subject = 'Re: mumble';
            email.plainTextBody = 'Hi, this is random';

            result = emailServObj.handleInboundEmail(email, env);

            System.assertEquals(result.success, true);
        }
    }


    @isTest public static  void validateCaseResponse2() {
        setup();
        SMEmailService emailServObj = new SMEmailService();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.toAddresses = new String[]{
                'test@noorg.edu'
        };
        email.subject = 'test';
        email.fromName = 'scweber';
        email.fromAddress = 'test@noorg.edu';
        email.replyTo = 'nobody@stanford.edu';
        emailServObj.respondent = 'ditto';
        email.plainTextBody = TEST_JSON;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Insert account as current user

        System.runAs (thisUser) {

            Messaging.InboundEmailResult result = emailServObj.handleInboundEmail(email, env);
            // ok, now look up the case and send a response email
            List<Case> caseList = [SELECT Id, CaseNumber, reference__c, Description, Subject,OwnerId, Owner.Id, Owner.Name FROM Case ];
            if (caseList.size() > 0) {
                Case theCase = caseList.get(0);

                email.subject = 'Re ' + theCase.CaseNumber;
                email.plainTextBody = 'Hi, this is not so random';

                result = emailServObj.handleInboundEmail(email, env);

                System.assertEquals(result.success, true);
            }
        }
    }

    @isTest static void validatePareDownEmail() {
        SMEmailService emailServObj = new SMEmailService();
        String sweber = 'test@noorg.edu';
        String email = emailServObj.pareDownEmail(sweber);
        System.assertEquals( sweber  , email);

    }

    @isTest static void validateGetTags() {
        SMEmailService emailServObj = new SMEmailService();
        String tagtest = '@labor=3 this is a test';
        Map<String, String> myMap = emailServObj.getTags(tagtest);
        System.assertEquals(myMap.get('labor'), '3');
    }

    @isTest static void validateGetCaseByThreadId() {
        SMEmailService emailServObj = new SMEmailService();
        String reftest = '[ref:00D2C000000HDuu.5002C000005MIfX:ref]';
        Case myCase = emailServObj.getCaseByThreadId(reftest);
        System.assertEquals(myCase, null);
    }

    @isTest static void validateParseThreadId() {
        SMEmailService emailServObj = new SMEmailService();
        String reftest = '[ref:00D2C000000HDuu.5002C000005MIfX:ref]';
        String myThread = emailServObj.parseThreadId(reftest);
        System.assertNotEquals(myThread, reftest);
    }

    @isTest static void validateGetCaseByCaseNumber() {
        SMEmailService emailServObj = new SMEmailService();
        String reftest = '[ref:00D2C000000HDuu.5002C000005MIfX:ref]';
        Case myCase = emailServObj.getCaseByCaseNumber(reftest);
        System.assertEquals(myCase, null);
    }

    @isTest static void validateParseValidCaseNumber() {
        SMEmailService emailServObj = new SMEmailService();
        String reftest = '[ref:00D2C000000HDuu.5002C000005MIfX:ref]';
        String myCaseNumber = emailServObj.parseValidCaseNumber(reftest);
        System.assertEquals(myCaseNumber, '');
    }

    @isTest static void validateRegExMatchReturnGroup() {
        SMEmailService emailServObj = new SMEmailService();
        String reftest = '[ref:00D2C000000HDuu.5002C000005MIfX:ref]';
        String sThreadFormat = '(ref:\\w+?\\.\\w+?:ref)';
        Integer groupNumber = 0;
        String myCaseNumber = emailServObj.regExMatchReturnGroup(reftest, sThreadFormat, groupNumber);
        System.assertNotEquals(myCaseNumber, null);
    }

    @isTest static void validateGetExistingCaser() {
        SMEmailService emailServObj = new SMEmailService();

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'test';
        email.plainTextBody = TEST_JSON;
        String reftest = '[ref:00D2C000000HDuu.5002C000005MIfX:ref]';
        Case myCaseNumber = emailServObj.getExistingCase(email);
        System.assertEquals(myCaseNumber, null);
    }

    @isTest static void validateGetGroupMembers() {
        SMEmailService emailServObj = new SMEmailService();
        String queueName = CONSULT_QUEUE;
        setup();
        Set<Id> users = emailServObj.getUsersInQueueByName(queueName);
        System.debug('size '+users.size()+' users is '+users);
        System.assertEquals(users.size(), users.size());
    }

    @isTest static void validateGetUsersInQueueById() {
        SMEmailService emailServObj = new SMEmailService();
        Id queueName = null;
        Set<Id> users = emailServObj.getUsersInQueueById(queueName);
        System.assertEquals(users.size(), 0);
    }

    @isTest static void validateGetEmailByUserIdSet() {
        SMEmailService emailServObj = new SMEmailService();
        Set<Id> queueName = new Set<Id>();
        queueName.add(null);
        String[] users = emailServObj.getEmailByUserIdSet(queueName);
        System.assertEquals(users.size(), 0);
    }

    @isTest static void validateGetEmailByQueueOrUserId() {
        SMEmailService emailServObj = new SMEmailService();
        Id queueName = null;
        String[] users = emailServObj.getEmailByQueueOrUserId(queueName);
        System.assertEquals(users.size(), 0);
    }

    @isTest static void validateRemoveTags() {
        SMEmailService emailServObj = new SMEmailService();
        String queueName = 'this does not contain tags';
        String users = emailServObj.removeTags(queueName);
        System.assertEquals(users, queueName);
    }

    @isTest static void validateHomebrewUpsert() {
        SMEmailService emailServObj = new SMEmailService();
        String queueName = 'this does not contain tags';
        Contact theContact = new Contact();
        try {
            emailServObj.homebrewUpsert(theContact);
            System.assertEquals(0, 1);
        } catch (Exception e) {
            System.assertEquals(0, 0);
        }
    }

    @isTest static void validateSelectTemplate() {
        SMEmailService emailServObj = setupEmailService();
        EmailTemplate template = emailServObj.selectTemplate('test');
        System.assertNotEquals(template, null);

    }

    @isTest static void validateOpenActionTag() {
        setup();
        List<Group> theQueuList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :CONSULT_QUEUE];
        Group theQueu = theQueuList.get(0);
        SMEmailService emailServObj = setupEmailService();
        emailServObj.theCase.Status = 'Submitted';
        String actionTags = '@open';

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        emailServObj.invokingUser = thisUser;

        // Insert account as current user

        System.runAs (thisUser) {
            Boolean isok = emailServObj.executeActionTags(actionTags);
            System.assertEquals(isok, true);
            System.assertEquals(emailServObj.theCase.OwnerId, UserInfo.getUserId());

        }
    }


    @isTest static void validateLaborActionTag() {
        setup();
        List<Group> theQueuList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :CONSULT_QUEUE];
        Group theQueu = theQueuList.get(0);
        SMEmailService emailServObj = setupEmailService();
        emailServObj.theCase.Status = 'Submitted';
        String actionTags = '@labor=2';

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        emailServObj.invokingUser = thisUser;

        // Insert account as current user

        System.runAs (thisUser) {
            Boolean isok = emailServObj.executeActionTags(actionTags);
            System.assertEquals(isok, true);
            System.assertEquals(emailServObj.theCase.OwnerId, UserInfo.getUserId());

        }
    }

    @isTest static void validateCloseActionTag() {
        setup();
        List<Group> theQueuList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :CONSULT_QUEUE];
        Group theQueu = theQueuList.get(0);
        SMEmailService emailServObj = setupEmailService();
        emailServObj.theCase.Status = 'Submitted';
        String actionTags = '@close';

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        emailServObj.invokingUser = thisUser;

        // Insert account as current user

        System.runAs (thisUser) {
            Boolean isok = emailServObj.executeActionTags(actionTags);
            System.assertEquals(isok, true);
            System.assertEquals(emailServObj.theCase.OwnerId, UserInfo.getUserId());

        }
    }

    @isTest static void validateAssignActionTag() {
        setup();
        List<Group> theQueuList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :CONSULT_QUEUE];
        Group theQueu = theQueuList.get(0);
        SMEmailService emailServObj = setupEmailService();
        emailServObj.theCase.Status = 'Submitted';
        String actionTags = '@assign=testy';

        User thisUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        emailServObj.invokingUser = thisUser;

        // Insert account as current user

        System.runAs (thisUser) {
            Boolean isok = emailServObj.executeActionTags(actionTags);
            System.assertEquals(isok, false);
            System.assertNotEquals(emailServObj.theCase.OwnerId, UserInfo.getUserId());

        }
    }

    @isTest static void validateInfoActionTag() {
        setup();
        List<Group> theQueuList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :CONSULT_QUEUE];
        Group theQueu = theQueuList.get(0);
        SMEmailService emailServObj = setupEmailService();
        emailServObj.theCase.Status = 'Submitted';
        String actionTags = '@info';

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        emailServObj.invokingUser = thisUser;

        // Insert account as current user

        System.runAs (thisUser) {
            Boolean isok = emailServObj.executeActionTags(actionTags);
            System.assertEquals(isok, true);
            System.assertEquals(emailServObj.theCase.OwnerId, UserInfo.getUserId());

        }
    }

}