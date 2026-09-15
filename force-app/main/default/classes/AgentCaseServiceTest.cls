@IsTest
private class AgentCaseServiceTest {
    @IsTest
    static void lookupReturnsCaseDetails() {
        Case c = new Case(Subject = 'Generator will not start', Status = 'New', Priority = 'High');
        insert c;
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :c.Id].CaseNumber;

        AgentCaseService.LookupRequest req = new AgentCaseService.LookupRequest();
        req.caseNumber = caseNumber;

        Test.startTest();
        List<AgentCaseService.LookupResult> results = AgentCaseService.lookupCase(
            new List<AgentCaseService.LookupRequest>{ req }
        );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result expected');
        Assert.isTrue(results[0].found, 'Case should be found');
        Assert.areEqual('New', results[0].status, 'Status should match');
        Assert.areEqual('Generator will not start', results[0].subject, 'Subject should match');
    }

    @IsTest
    static void lookupHandlesUnknownCaseNumber() {
        AgentCaseService.LookupRequest req = new AgentCaseService.LookupRequest();
        req.caseNumber = '99999999';

        List<AgentCaseService.LookupResult> results = AgentCaseService.lookupCase(
            new List<AgentCaseService.LookupRequest>{ req }
        );

        Assert.isFalse(results[0].found, 'No case should be found');
        Assert.isTrue(results[0].summary.contains('99999999'), 'Summary should name the case number');
    }

    @IsTest
    static void logCaseCreatesCaseWithDefaultPriority() {
        AgentCaseCreator.CreateRequest req = new AgentCaseCreator.CreateRequest();
        req.subject = 'Standby generator tripping breaker';
        req.description = 'Breaker trips about a minute after the unit starts.';
        req.contactEmail = 'customer@example.com';

        Test.startTest();
        List<AgentCaseCreator.CreateResult> results = AgentCaseCreator.logCase(
            new List<AgentCaseCreator.CreateRequest>{ req }
        );
        Test.stopTest();

        Assert.isTrue(results[0].success, 'Case should be created');
        Case created = [
            SELECT Priority, Status, Origin, SuppliedEmail
            FROM Case
            WHERE CaseNumber = :results[0].caseNumber
        ];
        Assert.areEqual('Medium', created.Priority, 'Priority should default to Medium');
        Assert.areEqual('Chat', created.Origin, 'Origin should be Chat');
        Assert.areEqual('customer@example.com', created.SuppliedEmail, 'Email should be stored');
    }

    @IsTest
    static void logCaseNormalizesInvalidPriority() {
        AgentCaseCreator.CreateRequest req = new AgentCaseCreator.CreateRequest();
        req.subject = 'Parts question';
        req.description = 'Need a replacement rotor assembly.';
        req.priority = 'Urgent';

        List<AgentCaseCreator.CreateResult> results = AgentCaseCreator.logCase(
            new List<AgentCaseCreator.CreateRequest>{ req }
        );

        Case created = [SELECT Priority FROM Case WHERE CaseNumber = :results[0].caseNumber];
        Assert.areEqual('Medium', created.Priority, 'Unknown priority should fall back to Medium');
    }
}
