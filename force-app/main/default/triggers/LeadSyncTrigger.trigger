trigger LeadSyncTrigger on Lead (before insert, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LeadIntegrationService.stampPending(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        LeadIntegrationService.publishOutbound(Trigger.new);
    }
}
