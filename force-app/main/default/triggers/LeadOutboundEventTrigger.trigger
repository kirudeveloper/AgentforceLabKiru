trigger LeadOutboundEventTrigger on Lead_Outbound__e (after insert) {
    System.enqueueJob(new LeadOutboundCalloutJob(Trigger.new));
}
