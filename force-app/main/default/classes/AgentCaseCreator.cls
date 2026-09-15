/**
 * Invocable action that logs a new support case on behalf of a customer
 * talking to the Summit Support Agent.
 */
public with sharing class AgentCaseCreator {
    public class CreateRequest {
        @InvocableVariable(
            label='Subject'
            description='Short summary of the customer problem.'
            required=true
        )
        public String subject;

        @InvocableVariable(
            label='Description'
            description='Full description of the problem, including any troubleshooting already attempted.'
            required=true
        )
        public String description;

        @InvocableVariable(
            label='Contact Email'
            description='Email address the customer wants updates sent to.'
        )
        public String contactEmail;

        @InvocableVariable(
            label='Priority'
            description='Case priority: High, Medium, or Low. Defaults to Medium.'
        )
        public String priority;
    }

    public class CreateResult {
        @InvocableVariable(label='Success' description='True when the case was created.')
        public Boolean success;

        @InvocableVariable(label='Case Number' description='Case number of the new case.')
        public String caseNumber;

        @InvocableVariable(label='Summary' description='Plain language confirmation for the customer.')
        public String summary;
    }

    private static final Set<String> ALLOWED_PRIORITIES = new Set<String>{ 'High', 'Medium', 'Low' };

    @InvocableMethod(
        label='Log Support Case'
        description='Creates a new support case for the customer and returns the new case number.'
        category='Agentforce'
    )
    public static List<CreateResult> logCase(List<CreateRequest> requests) {
        List<CreateResult> results = new List<CreateResult>();
        List<Case> toInsert = new List<Case>();

        for (CreateRequest req : requests) {
            String priority = String.isBlank(req.priority) ? 'Medium' : req.priority.capitalize();
            if (!ALLOWED_PRIORITIES.contains(priority)) {
                priority = 'Medium';
            }

            toInsert.add(
                new Case(
                    Subject = req.subject,
                    Description = req.description,
                    SuppliedEmail = req.contactEmail,
                    Priority = priority,
                    Status = 'New',
                    Origin = 'Chat'
                )
            );
        }

        insert as user toInsert;

        for (Case c : [
            SELECT Id, CaseNumber
            FROM Case
            WHERE Id IN :toInsert
            WITH USER_MODE
        ]) {
            CreateResult res = new CreateResult();
            res.success = true;
            res.caseNumber = c.CaseNumber;
            res.summary =
                'Case ' + c.CaseNumber + ' has been logged. A support specialist will follow up by email.';
            results.add(res);
        }
        return results;
    }
}
