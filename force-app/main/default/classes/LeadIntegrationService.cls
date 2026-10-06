/**
 * Publishes and handles Lead Platform Events for webhook.site (outbound)
 * and randomuser.me (inbound). Callouts run from event triggers, not Lead DML.
 */
public with sharing class LeadIntegrationService {
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_SENT = 'Sent';
    public static final String STATUS_FAILED = 'Failed';
    public static final String STATUS_INBOUND = 'Inbound';

    @TestVisible
    static Boolean suppressOutboundCallouts = false;

    public class FetchResult {
        @InvocableVariable(label='Message')
        public String message;
        @InvocableVariable(label='External Id')
        public String externalId;
    }

    public static void stampPending(List<Lead> records) {
        for (Lead record : records) {
            if (record.External_Sync_Status__c != STATUS_INBOUND &&
                String.isBlank(record.External_Sync_Status__c)) {
                record.External_Sync_Status__c = STATUS_PENDING;
            }
        }
    }

    public static void publishOutbound(List<Lead> records) {
        List<Lead_Outbound__e> events = new List<Lead_Outbound__e>();
        for (Lead record : records) {
            if (record.External_Sync_Status__c == STATUS_INBOUND) {
                continue;
            }
            events.add(
                new Lead_Outbound__e(
                    Lead_Id__c = record.Id,
                    Last_Name__c = record.LastName,
                    Company__c = record.Company,
                    Email__c = record.Email,
                    Interest__c = truncate(record.Description, 255)
                )
            );
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    public static void sendOutbound(List<Lead_Outbound__e> events) {
        if (suppressOutboundCallouts || events == null || events.isEmpty()) {
            return;
        }
        List<Lead> updates = new List<Lead>();
        for (Lead_Outbound__e event : events) {
            if (String.isBlank(event.Lead_Id__c)) {
                continue;
            }
            Lead updateRecord = new Lead(Id = event.Lead_Id__c);
            try {
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Webhook_Site');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setTimeout(12000);
                request.setBody(
                    JSON.serialize(
                        new Map<String, Object>{
                            'leadId' => event.Lead_Id__c,
                            'lastName' => event.Last_Name__c,
                            'company' => event.Company__c,
                            'email' => event.Email__c,
                            'interest' => event.Interest__c
                        }
                    )
                );
                HttpResponse response = new Http().send(request);
                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                    updateRecord.External_Sync_Status__c = STATUS_SENT;
                    String requestId = response.getHeader('uuid');
                    if (String.isBlank(requestId)) {
                        requestId = response.getHeader('X-Request-Id');
                    }
                    updateRecord.External_Sync_Id__c = truncate(
                        String.isBlank(requestId) ? String.valueOf(response.getStatusCode()) : requestId,
                        80
                    );
                    updateRecord.External_Sync_Message__c =
                        'HTTP ' + response.getStatusCode() + ' webhook.site';
                } else {
                    updateRecord.External_Sync_Status__c = STATUS_FAILED;
                    updateRecord.External_Sync_Message__c = truncate(
                        'HTTP ' + response.getStatusCode() + ' ' + response.getStatus(),
                        255
                    );
                }
            } catch (Exception ex) {
                updateRecord.External_Sync_Status__c = STATUS_FAILED;
                updateRecord.External_Sync_Message__c = truncate(ex.getMessage(), 255);
            }
            updates.add(updateRecord);
        }
        if (!updates.isEmpty()) {
            Database.update(updates, false, AccessLevel.SYSTEM_MODE);
        }
    }

    @InvocableMethod(
        label='Fetch External Lead'
        description='Gets one person from randomuser.me and publishes Lead_Inbound__e.'
        category='Lead Integration'
    )
    public static List<FetchResult> fetchExternalLead(List<String> unused) {
        Integer callCount = unused == null || unused.isEmpty() ? 1 : unused.size();
        List<FetchResult> results = new List<FetchResult>();
        List<Lead_Inbound__e> events = new List<Lead_Inbound__e>();
        for (Integer i = 0; i < callCount; i++) {
            FetchResult result = new FetchResult();
            try {
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:RandomUser/api/');
                request.setMethod('GET');
                request.setTimeout(12000);
                HttpResponse response = new Http().send(request);
                if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
                    result.message = 'randomuser.me HTTP ' + response.getStatusCode();
                    results.add(result);
                    continue;
                }
                Lead_Inbound__e event = parseRandomUser(response.getBody());
                events.add(event);
                result.externalId = event.External_Id__c;
                result.message =
                    'Published inbound event for ' +
                    event.First_Name__c +
                    ' ' +
                    event.Last_Name__c;
            } catch (Exception ex) {
                result.message = truncate(ex.getMessage(), 255);
            }
            results.add(result);
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
        return results;
    }

    public static void createFromInbound(List<Lead_Inbound__e> events) {
        Set<String> emails = new Set<String>();
        for (Lead_Inbound__e event : events) {
            if (String.isNotBlank(event.Email__c)) {
                emails.add(event.Email__c.toLowerCase());
            }
        }
        Map<String, Lead> existingByEmail = new Map<String, Lead>();
        if (!emails.isEmpty()) {
            for (Lead existing : [
                SELECT Id, Email
                FROM Lead
                WHERE Email IN :emails
                WITH SYSTEM_MODE
            ]) {
                if (String.isNotBlank(existing.Email)) {
                    existingByEmail.put(existing.Email.toLowerCase(), existing);
                }
            }
        }

        List<Lead> toInsert = new List<Lead>();
        for (Lead_Inbound__e event : events) {
            String emailKey = String.isBlank(event.Email__c) ? null : event.Email__c.toLowerCase();
            if (emailKey != null && existingByEmail.containsKey(emailKey)) {
                continue;
            }
            String lastName = String.isBlank(event.Last_Name__c) ? 'Unknown' : event.Last_Name__c;
            String company = String.isBlank(event.Company__c) ? 'Unknown' : event.Company__c;
            toInsert.add(
                new Lead(
                    FirstName = event.First_Name__c,
                    LastName = lastName,
                    Company = company,
                    Email = event.Email__c,
                    Phone = event.Phone__c,
                    LeadSource = 'Web',
                    Status = 'Open - Not Contacted',
                    External_Sync_Status__c = STATUS_INBOUND,
                    External_Sync_Id__c = truncate(event.External_Id__c, 80),
                    External_Sync_Message__c = 'Created from randomuser.me'
                )
            );
        }
        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false, AccessLevel.SYSTEM_MODE);
        }
    }

    @TestVisible
    static Lead_Inbound__e parseRandomUser(String body) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(body);
        List<Object> results = (List<Object>) root.get('results');
        if (results == null || results.isEmpty()) {
            throw new CalloutException('randomuser.me returned no results');
        }
        Map<String, Object> person = (Map<String, Object>) results[0];
        Map<String, Object> name = (Map<String, Object>) person.get('name');
        Map<String, Object> login = (Map<String, Object>) person.get('login');
        Map<String, Object> location = (Map<String, Object>) person.get('location');
        String firstName = name == null ? null : (String) name.get('first');
        String lastName = name == null ? 'Unknown' : (String) name.get('last');
        String city = location == null ? null : (String) location.get('city');
        String uuid = login == null ? null : (String) login.get('uuid');
        return new Lead_Inbound__e(
            External_Id__c = truncate(uuid, 80),
            First_Name__c = firstName,
            Last_Name__c = String.isBlank(lastName) ? 'Unknown' : lastName,
            Company__c = String.isBlank(city) ? 'Unknown Labs' : city + ' Labs',
            Email__c = (String) person.get('email'),
            Phone__c = truncate((String) person.get('phone'), 40)
        );
    }

    private static String truncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return null;
        }
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }
}
