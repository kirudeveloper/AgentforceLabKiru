trigger LeadInboundEventTrigger on Lead_Inbound__e (after insert) {
    LeadIntegrationService.createFromInbound(Trigger.new);
}
