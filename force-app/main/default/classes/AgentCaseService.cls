/**
 * Invocable actions used by the Summit Support Agent (Agent Script authoring bundle).
 * Each @InvocableMethod is surfaced to the agent as an action in the .agent file.
 */
public with sharing class AgentCaseService {
    public class LookupRequest {
        @InvocableVariable(
            label='Case Number'
            description='The case number the customer provided, such as 00001002.'
            required=true
        )
        public String caseNumber;
    }

    public class LookupResult {
        @InvocableVariable(label='Found' description='True when a matching case exists.')
        public Boolean found;

        @InvocableVariable(label='Case Number' description='Case number of the matched case.')
        public String caseNumber;

        @InvocableVariable(label='Subject' description='Subject of the case.')
        public String subject;

        @InvocableVariable(label='Status' description='Current status of the case.')
        public String status;

        @InvocableVariable(label='Priority' description='Priority of the case.')
        public String priority;

        @InvocableVariable(label='Last Updated' description='Date the case was last updated.')
        public String lastUpdated;

        @InvocableVariable(label='Summary' description='Plain language summary for the customer.')
        public String summary;
    }

    @InvocableMethod(
        label='Look Up Support Case'
        description='Returns the current status of a support case given its case number.'
        category='Agentforce'
    )
    public static List<LookupResult> lookupCase(List<LookupRequest> requests) {
        List<LookupResult> results = new List<LookupResult>();

        for (LookupRequest req : requests) {
            LookupResult res = new LookupResult();
            String caseNumber = req.caseNumber == null ? '' : req.caseNumber.trim();

            List<Case> matches = [
                SELECT CaseNumber, Subject, Status, Priority, LastModifiedDate
                FROM Case
                WHERE CaseNumber = :caseNumber
                WITH USER_MODE
                LIMIT 1
            ];

            if (matches.isEmpty()) {
                res.found = false;
                res.caseNumber = caseNumber;
                res.summary = 'No case was found with case number ' + caseNumber + '.';
            } else {
                Case c = matches[0];
                res.found = true;
                res.caseNumber = c.CaseNumber;
                res.subject = c.Subject;
                res.status = c.Status;
                res.priority = c.Priority;
                res.lastUpdated = c.LastModifiedDate.format('MMMM d, yyyy');
                res.summary =
                    'Case ' + c.CaseNumber + ' (' + c.Subject + ') is currently ' + c.Status +
                    ' with ' + c.Priority + ' priority. Last updated ' + res.lastUpdated + '.';
            }
            results.add(res);
        }
        return results;
    }
}
