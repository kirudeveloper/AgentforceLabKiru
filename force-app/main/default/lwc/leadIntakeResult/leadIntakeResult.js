import { LightningElement, api } from 'lwc';

export default class LeadIntakeResult extends LightningElement {
    @api value;

    get success() {
        return this.value?.success === true;
    }

    get leadName() {
        return this.value?.leadName || 'New lead';
    }

    get company() {
        return this.value?.company || '—';
    }

    get email() {
        return this.value?.email || '—';
    }

    get phone() {
        return this.value?.phone || '—';
    }

    get status() {
        return this.value?.status || '—';
    }

    get leadSource() {
        return this.value?.leadSource || '—';
    }

    get interest() {
        return this.value?.interest || '';
    }

    get createdDate() {
        return this.value?.createdDate || '—';
    }

    get summary() {
        return this.value?.summary || '';
    }

    get heading() {
        return this.success ? 'Lead created' : 'Lead was not created';
    }

    get eyebrow() {
        return this.success ? 'Intake complete' : 'Needs attention';
    }

    get iconName() {
        return this.success ? 'utility:success' : 'utility:error';
    }

    get cardClass() {
        return this.success ? 'result result--success' : 'result result--error';
    }
}
