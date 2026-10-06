@IsTest
private class LeadIntegrationServiceTest {
    @IsTest
    static void outboundLeadPostsToWebhook() {
        Test.setMock(HttpCalloutMock.class, new LeadIntegrationCalloutMock());
        Lead created = new Lead(
            LastName = 'Chen',
            Company = 'Northwind Solar',
            Email = 'avery@example.com'
        );
        LeadIntegrationService.suppressOutboundCallouts = true;
        insert created;

        Test.setMock(HttpCalloutMock.class, new LeadIntegrationCalloutMock());
        Test.startTest();
        LeadIntegrationService.suppressOutboundCallouts = false;
        LeadIntegrationService.sendOutbound(
            new List<Lead_Outbound__e>{
                new Lead_Outbound__e(
                    Lead_Id__c = created.Id,
                    Last_Name__c = 'Chen',
                    Company__c = 'Northwind Solar',
                    Email__c = 'avery@example.com',
                    Interest__c = 'Demo'
                )
            }
        );
        LeadIntegrationService.suppressOutboundCallouts = true;
        Test.stopTest();

        created = [
            SELECT External_Sync_Status__c, External_Sync_Id__c, External_Sync_Message__c
            FROM Lead
            WHERE Id = :created.Id
        ];
        Assert.areEqual('Sent', created.External_Sync_Status__c, created.External_Sync_Message__c);
        Assert.areEqual('wh-123', created.External_Sync_Id__c);
        Assert.isTrue(created.External_Sync_Message__c.contains('200'));
    }

    @IsTest
    static void outboundQueueablePostsToWebhook() {
        Test.setMock(HttpCalloutMock.class, new LeadIntegrationCalloutMock());
        Lead created = new Lead(
            LastName = 'Queueable',
            Company = 'Yuki Digital',
            Email = 'queueable@example.com'
        );
        LeadIntegrationService.suppressOutboundCallouts = true;
        insert created;

        Test.startTest();
        LeadIntegrationService.suppressOutboundCallouts = false;
        new LeadOutboundCalloutJob(
            new List<Lead_Outbound__e>{
                new Lead_Outbound__e(
                    Lead_Id__c = created.Id,
                    Last_Name__c = 'Queueable',
                    Company__c = 'Yuki Digital',
                    Email__c = 'queueable@example.com',
                    Interest__c = 'Demo'
                )
            }
        )
            .execute(null);
        LeadIntegrationService.suppressOutboundCallouts = true;
        Test.stopTest();

        created = [
            SELECT External_Sync_Status__c, External_Sync_Id__c
            FROM Lead
            WHERE Id = :created.Id
        ];
        Assert.areEqual('Sent', created.External_Sync_Status__c);
        Assert.areEqual('wh-123', created.External_Sync_Id__c);
    }

    @IsTest
    static void inboundEventCreatesLeadWithoutOutboundLoop() {
        LeadIntegrationService.suppressOutboundCallouts = true;
        Test.setMock(HttpCalloutMock.class, new LeadIntegrationCalloutMock());

        Test.startTest();
        EventBus.publish(
            new Lead_Inbound__e(
                External_Id__c = 'ext-ada-1',
                First_Name__c = 'Ada',
                Last_Name__c = 'Lovelace',
                Company__c = 'London Labs',
                Email__c = 'ada.lovelace@example.com',
                Phone__c = '555-0100'
            )
        );
        Test.getEventBus().deliver();
        Test.stopTest();

        Lead created = [
            SELECT FirstName, LastName, Company, Email, External_Sync_Status__c, External_Sync_Id__c
            FROM Lead
            WHERE Email = 'ada.lovelace@example.com'
        ];
        Assert.areEqual('Ada', created.FirstName);
        Assert.areEqual('Lovelace', created.LastName);
        Assert.areEqual('London Labs', created.Company);
        Assert.areEqual('Inbound', created.External_Sync_Status__c);
        Assert.areEqual('ext-ada-1', created.External_Sync_Id__c);
        Assert.areEqual(1, [SELECT COUNT() FROM Lead]);
    }

    @IsTest
    static void fetchExternalLeadPublishesInboundPerson() {
        LeadIntegrationService.suppressOutboundCallouts = true;
        Test.setMock(HttpCalloutMock.class, new LeadIntegrationCalloutMock());

        Test.startTest();
        List<LeadIntegrationService.FetchResult> results = LeadIntegrationService.fetchExternalLead(
            new List<String>{ 'run' }
        );
        Test.getEventBus().deliver();
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.areEqual('ext-ada-1', results[0].externalId);
        Lead created = [SELECT LastName, Company, External_Sync_Status__c FROM Lead LIMIT 1];
        Assert.areEqual('Lovelace', created.LastName);
        Assert.areEqual('London Labs', created.Company);
        Assert.areEqual('Inbound', created.External_Sync_Status__c);
    }

    @IsTest
    static void inboundDedupesByEmail() {
        LeadIntegrationService.suppressOutboundCallouts = true;
        insert new Lead(
            LastName = 'Lovelace',
            Company = 'Existing',
            Email = 'ada.lovelace@example.com',
            External_Sync_Status__c = 'Inbound'
        );

        Test.startTest();
        LeadIntegrationService.createFromInbound(
            new List<Lead_Inbound__e>{
                new Lead_Inbound__e(
                    External_Id__c = 'ext-ada-1',
                    Last_Name__c = 'Lovelace',
                    Company__c = 'London Labs',
                    Email__c = 'ada.lovelace@example.com'
                )
            }
        );
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Lead]);
    }
}
