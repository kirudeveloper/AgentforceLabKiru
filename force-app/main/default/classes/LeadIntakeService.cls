/**
 * Invocable action used by the Lead Intake service agent.
 * Inner classes LeadInput and LeadResult are the custom Lightning type shapes.
 */
public with sharing class LeadIntakeService {
    private static final Set<String> ALLOWED_SOURCES = new Set<String>{
        'Web',
        'Phone Inquiry',
        'Partner Referral',
        'Purchased List',
        'Other'
    };

    public class LeadInput {
        @InvocableVariable(label='First Name' description='Lead first name')
        public String firstName;

        @InvocableVariable(
            label='Last Name'
            description='Lead last name'
            required=true
        )
        public String lastName;

        @InvocableVariable(label='Email' description='Lead email address')
        public String email;

        @InvocableVariable(label='Phone' description='Lead phone number')
        public String phone;

        @InvocableVariable(
            label='Company'
            description='Company or organization name'
            required=true
        )
        public String company;

        @InvocableVariable(label='Job Title' description='Job title')
        public String title;

        @InvocableVariable(label='Lead Source' description='How they heard about us')
        public String leadSource;

        @InvocableVariable(label='Interest' description='What they are interested in')
        public String interest;

        @InvocableVariable(label='Message' description='Additional details from the intake form')
        public String description;
    }

    public class LeadResult {
        @InvocableVariable(label='Success' description='True when the lead was created')
        public Boolean success;

        @InvocableVariable(label='Lead Id' description='Id of the created Lead')
        public String leadId;

        @InvocableVariable(label='Lead Name' description='Full name of the lead')
        public String leadName;

        @InvocableVariable(label='Company' description='Company on the lead')
        public String company;

        @InvocableVariable(label='Email' description='Email on the lead')
        public String email;

        @InvocableVariable(label='Phone' description='Phone on the lead')
        public String phone;

        @InvocableVariable(label='Status' description='Lead status')
        public String status;

        @InvocableVariable(label='Lead Source' description='Lead source')
        public String leadSource;

        @InvocableVariable(label='Interest' description='Stated interest')
        public String interest;

        @InvocableVariable(label='Created Date' description='When the lead was created')
        public String createdDate;

        @InvocableVariable(label='Summary' description='Plain language confirmation')
        public String summary;
    }

    public class SubmitLeadRequest {
        @InvocableVariable(required=true)
        public LeadInput lead_data;
    }

    public class SubmitLeadResponse {
        @InvocableVariable
        public LeadResult lead_result;

        @InvocableVariable
        public String lead_id;
    }

    @InvocableMethod(
        label='Submit Lead'
        description='Creates a Salesforce Lead from the completed intake form and returns the new lead details.'
        category='Agentforce'
    )
    public static List<SubmitLeadResponse> submitLead(List<SubmitLeadRequest> requests) {
        List<SubmitLeadResponse> responses = new List<SubmitLeadResponse>();
        List<Lead> toInsert = new List<Lead>();
        List<Integer> requestIndexes = new List<Integer>();
        List<String> interests = new List<String>();

        for (Integer i = 0; i < requests.size(); i++) {
            SubmitLeadResponse response = new SubmitLeadResponse();
            response.lead_result = new LeadResult();
            responses.add(response);

            LeadInput input = requests[i] == null ? null : requests[i].lead_data;
            if (input == null || String.isBlank(input.lastName) || String.isBlank(input.company)) {
                response.lead_result.success = false;
                response.lead_result.summary =
                    'The intake form was not completed. Call submit_lead action\'s user_input tool. Do not ask the customer for last name or company in chat.';
                continue;
            }

            String source = String.isBlank(input.leadSource) ? 'Web' : input.leadSource.trim();
            if (!ALLOWED_SOURCES.contains(source)) {
                source = 'Web';
            }

            Lead leadRecord = new Lead(
                FirstName = blankToNull(input.firstName),
                LastName = input.lastName.trim(),
                Email = blankToNull(input.email),
                Phone = blankToNull(input.phone),
                Company = input.company.trim(),
                Title = blankToNull(input.title),
                LeadSource = source,
                Status = 'Open - Not Contacted',
                Description = buildDescription(input)
            );
            toInsert.add(leadRecord);
            requestIndexes.add(i);
            interests.add(input.interest);
        }

        if (toInsert.isEmpty()) {
            return responses;
        }

        Database.SaveResult[] saveResults = Database.insert(toInsert, false, AccessLevel.USER_MODE);
        Map<Id, Integer> idToResponseIndex = new Map<Id, Integer>();

        for (Integer i = 0; i < saveResults.size(); i++) {
            Integer responseIndex = requestIndexes[i];
            LeadResult result = responses[responseIndex].lead_result;
            if (!saveResults[i].isSuccess()) {
                result.success = false;
                result.summary = 'The lead could not be created: ' + saveResults[i].getErrors()[0].getMessage();
                continue;
            }
            idToResponseIndex.put(saveResults[i].getId(), responseIndex);
            result.interest = interests[i];
        }

        if (idToResponseIndex.isEmpty()) {
            return responses;
        }

        for (Lead created : [
            SELECT Id, Name, Company, Email, Phone, Status, LeadSource, CreatedDate
            FROM Lead
            WHERE Id IN :idToResponseIndex.keySet()
            WITH USER_MODE
        ]) {
            Integer responseIndex = idToResponseIndex.get(created.Id);
            SubmitLeadResponse response = responses[responseIndex];
            LeadResult result = response.lead_result;
            result.success = true;
            result.leadId = created.Id;
            result.leadName = created.Name;
            result.company = created.Company;
            result.email = created.Email;
            result.phone = created.Phone;
            result.status = created.Status;
            result.leadSource = created.LeadSource;
            result.createdDate = created.CreatedDate.format('MMMM d, yyyy');
            result.summary =
                'Lead ' + created.Name + ' at ' + created.Company +
                ' was created and is ' + created.Status + '.';
            response.lead_id = created.Id;
        }

        return responses;
    }

    private static String buildDescription(LeadInput input) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(input.interest)) {
            parts.add('Interest: ' + input.interest.trim());
        }
        if (String.isNotBlank(input.description)) {
            parts.add(input.description.trim());
        }
        return parts.isEmpty() ? null : String.join(parts, '\n\n');
    }

    private static String blankToNull(String value) {
        return String.isBlank(value) ? null : value.trim();
    }
}
