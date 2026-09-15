import { api, LightningElement } from 'lwc';

export default class LeadIntakeForm extends LightningElement {
    @api readOnly = false;

    _value = {};
    firstName = '';
    lastName = '';
    email = '';
    phone = '';
    company = '';
    title = '';
    leadSource = 'Web';
    interest = '';
    description = '';

    leadSourceOptions = [
        { label: 'Web', value: 'Web' },
        { label: 'Phone inquiry', value: 'Phone Inquiry' },
        { label: 'Partner referral', value: 'Partner Referral' },
        { label: 'Purchased list', value: 'Purchased List' },
        { label: 'Other', value: 'Other' }
    ];

    interestOptions = [
        { label: 'Product demo', value: 'Product Demo' },
        { label: 'Pricing quote', value: 'Pricing Quote' },
        { label: 'Partnership', value: 'Partnership' },
        { label: 'Implementation', value: 'Implementation' },
        { label: 'Other', value: 'Other' }
    ];

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val || {};
        if (val) {
            this.firstName = val.firstName ?? '';
            this.lastName = val.lastName ?? '';
            this.email = val.email ?? '';
            this.phone = val.phone ?? '';
            this.company = val.company ?? '';
            this.title = val.title ?? '';
            this.leadSource = val.leadSource || 'Web';
            this.interest = val.interest ?? '';
            this.description = val.description ?? '';
        }
    }

    handleInputChange(event) {
        event.stopPropagation();
        const name = event.target.name;
        this[name] = event.target.value;
        this.publishValue();
    }

    publishValue() {
        const value = {
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phone: this.phone,
            company: this.company,
            title: this.title,
            leadSource: this.leadSource || 'Web',
            interest: this.interest,
            description: this.description
        };
        this._value = value;
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                bubbles: true,
                composed: true,
                detail: { value }
            })
        );
    }
}
