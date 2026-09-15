@IsTest
private class LeadIntakeServiceTest {
    @IsTest
    static void submitLeadCreatesLeadRecord() {
        LeadIntakeService.LeadInput input = new LeadIntakeService.LeadInput();
        input.firstName = 'Avery';
        input.lastName = 'Chen';
        input.email = 'avery.chen@example.com';
        input.phone = '415-555-0199';
        input.company = 'Northwind Solar';
        input.title = 'Operations Manager';
        input.leadSource = 'Web';
        input.interest = 'Product Demo';
        input.description = 'Wants a walkthrough of the commercial package.';

        LeadIntakeService.SubmitLeadRequest request = new LeadIntakeService.SubmitLeadRequest();
        request.lead_data = input;

        Test.startTest();
        List<LeadIntakeService.SubmitLeadResponse> responses = LeadIntakeService.submitLead(
            new List<LeadIntakeService.SubmitLeadRequest>{ request }
        );
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response expected');
        Assert.isTrue(responses[0].lead_result.success, 'Lead should be created');
        Assert.isNotNull(responses[0].lead_id, 'Lead Id should be returned');

        Lead created = [
            SELECT FirstName, LastName, Email, Phone, Company, Title, LeadSource, Status, Description
            FROM Lead
            WHERE Id = :responses[0].lead_id
        ];
        Assert.areEqual('Avery', created.FirstName);
        Assert.areEqual('Chen', created.LastName);
        Assert.areEqual('avery.chen@example.com', created.Email);
        Assert.areEqual('Northwind Solar', created.Company);
        Assert.areEqual('Web', created.LeadSource);
        Assert.areEqual('Open - Not Contacted', created.Status);
        Assert.isTrue(created.Description.contains('Product Demo'), 'Interest should be stored on the lead');
        Assert.areEqual('Avery Chen', responses[0].lead_result.leadName);
    }

    @IsTest
    static void submitLeadRequiresLastNameAndCompany() {
        LeadIntakeService.LeadInput input = new LeadIntakeService.LeadInput();
        input.firstName = 'Sam';
        input.email = 'sam@example.com';

        LeadIntakeService.SubmitLeadRequest request = new LeadIntakeService.SubmitLeadRequest();
        request.lead_data = input;

        List<LeadIntakeService.SubmitLeadResponse> responses = LeadIntakeService.submitLead(
            new List<LeadIntakeService.SubmitLeadRequest>{ request }
        );

        Assert.isFalse(responses[0].lead_result.success, 'Missing required fields should fail');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'No lead should be inserted');
    }

    @IsTest
    static void submitLeadNormalizesUnknownSource() {
        LeadIntakeService.LeadInput input = new LeadIntakeService.LeadInput();
        input.lastName = 'Patel';
        input.company = 'Patel Logistics';
        input.leadSource = 'Chat Widget';

        LeadIntakeService.SubmitLeadRequest request = new LeadIntakeService.SubmitLeadRequest();
        request.lead_data = input;

        List<LeadIntakeService.SubmitLeadResponse> responses = LeadIntakeService.submitLead(
            new List<LeadIntakeService.SubmitLeadRequest>{ request }
        );

        Lead created = [SELECT LeadSource FROM Lead WHERE Id = :responses[0].lead_id];
        Assert.areEqual('Web', created.LeadSource, 'Unknown source should fall back to Web');
    }
}
