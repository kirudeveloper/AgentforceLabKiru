/**
 * Platform Event triggers cannot make HTTP callouts in this org.
 * Queue the POST to webhook.site after the event is delivered.
 */
public class LeadOutboundCalloutJob implements Queueable, Database.AllowsCallouts {
    private List<Lead_Outbound__e> events;

    public LeadOutboundCalloutJob(List<Lead_Outbound__e> events) {
        this.events = events == null ? new List<Lead_Outbound__e>() : events;
    }

    public void execute(QueueableContext context) {
        LeadIntegrationService.sendOutbound(events);
    }
}
