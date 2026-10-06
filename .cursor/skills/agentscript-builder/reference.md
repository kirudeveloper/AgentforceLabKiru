# Agent Script reference cheat sheet

Read this when implementing or reviewing syntax details. Prefer official docs if versions diverge.

## Variables

```agentscript
variables:
    EndUserId: linked string
        source: @MessagingSession.MessagingEndUserId
        description: "MessagingEndUser Id"
    RoutableId: linked string
        source: @MessagingSession.Id
        description: "MessagingSession Id"
    order_placed: mutable boolean = False
    last_case_number: mutable string = ""
```

| Kind | Use |
| --- | --- |
| `linked` | Bound to Messaging / session fields |
| `mutable` | Workflow state across turns/subagents |
| Prompt ref | `{!@variables.name}` |
| Logic ref | `@variables.name` |

System utterance (when available): `@system_variables.user_input`.

## Transitions vs consult

```agentscript
# One-way handoff (typical router)
go_to_billing: @utils.transition to @subagent.billing

# Escalate to human
escalate_to_human: @utils.escalate
    description: "Transfer to a live agent."

# Consult then return (tool-style)
ask_specialist: @subagent.specialist
    description: "Ask the specialist topic, then resume here."
```

## Conditionals

```agentscript
reasoning:
    instructions: ->
        if not @variables.verified:
            | Ask for the verification code. Use {!@actions.verify_code} when they provide it.
        else:
            run @actions.load_profile
            | Help with the verified account {!@variables.profile}. Never invent balances.
```

## `available when`

Gate tools so the LLM cannot call them out of sequence:

```agentscript
reasoning:
    actions:
        place_order: @actions.place_order
            with cart_id = @variables.cart_id
            available when @variables.cart_ready == True
```

## Action definition (Apex example)

```agentscript
actions:
    submit_lead:
        description: "Creates a Lead from the intake form. Use user_input to show the form."
        target: "apex://LeadIntakeService"
        source: "Submit_Lead"
        label: "Submit Lead"
        require_user_confirmation: False
        include_in_progress_indicator: True
        progress_indicator_message: "Saving..."
        inputs:
            lead_data: object
                description: "Form fields for the new lead."
                label: "lead_data"
                is_required: True
                is_user_input: True
                complex_data_type_name: "c__leadIntakeInput"
        outputs:
            lead_id: string
                description: "Created Lead Id."
                label: "lead_id"
                filter_from_agent: False
                is_displayable: False
            lead_result: object
                description: "Confirmation card payload."
                label: "lead_result"
                complex_data_type_name: "c__leadIntakeResult"
                filter_from_agent: False
                is_displayable: True
```

Reasoning binding:

```agentscript
reasoning:
    actions:
        submit_lead: @actions.submit_lead
            with lead_data = ...
            set @variables.lead_created = True
            set @variables.lead_id = @outputs.lead_id
```

## Service Agent connections

```agentscript
connection customer_web_client:
    outbound_route_type: "OmniChannelFlow"
    outbound_route_name: "flow://Your_Outbound_Messaging_Flow"
    escalation_message: "Transferring you to a live agent — please hold on."
    adaptive_response_allowed: False

connection messaging:
    outbound_route_type: "OmniChannelFlow"
    outbound_route_name: "flow://Your_Outbound_Messaging_Flow"
    escalation_message: "Transferring you to a live agent — please hold on."
    adaptive_response_allowed: False
```

## Off-topic / ambiguous stubs

Keep redirects short; do not answer general knowledge; never reveal internals.

## Pattern index (official)

| Pattern | Intent |
| --- | --- |
| Agent Router | `start_agent` routing |
| Fetch Data | `run @actions` before LLM |
| Filtering with Available When | Hide tools until ready |
| Required Subagent Workflow | Force ordered steps |
| Action Chaining & Sequencing | Guaranteed multi-step runs |
| Transitions | `@utils.transition to` |
| Variables | Cross-topic state |
| Context Engineering | What the LLM sees |
| System Overrides | Per-subagent system tweaks |
| Resource References | `{!@actions}` / `{!@variables}` |
| Conditionals | `if` / `else` control |

Source: https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns.html
