const { expect } = require('chai');
const path = require('path');
const moment = require('moment');
const sinon = require('sinon');
const TestRunner = require('medic-conf-test-harness');
const { nurse, patient } = require('../contacts');
const harness = new TestRunner({
    xformFolderPath: path.join(__dirname, '../../forms'),
});

let clock = sinon.useFakeTimers(moment('2000-01-01').toDate());
describe('Tests for fields for Non-Nurse', () => {
    before(async () => { return await harness.start(); });
    after(async () => { return await harness.stop(); });
    beforeEach(async () => {
        await harness.clear();
        clock = sinon.useFakeTimers(moment('2000-01-01').toDate());
        return await harness.setNow('2000-01-01');
    });
    afterEach(() => {
        expect(harness.consoleErrors).to.be.empty;
        if (clock) { clock.restore(); }
    });

    it('test fields', async () => {
        harness.state.contacts.push(nurse);
        harness.content.contact = nurse;
        const contactSummary = harness.getContactSummary();
        expect(contactSummary.fields).to.have.property('length', 2);
        expect(contactSummary.fields).to.deep.equal(
            [
                { label: 'contact.profile.nurse', value: '', width: 12 },
                {
                    label: 'contact.parent',
                    value: [
                        { _id: 'chw_area_id', parent: { _id: 'district_id' } },
                        { _id: 'district_id' }
                    ],
                    filter: 'lineage'
                }
            ]
        );
    });

    it('test fields', async () => {
        harness.state.contacts.push(patient);
        harness.content.contact = patient;
        const contactSummary = harness.getContactSummary();
        expect(contactSummary.fields).to.have.property('length', 6);
        expect(contactSummary.fields).to.deep.equal(
            [
                { label: 'person.field.phone', value: '+1234567892', width: 4, filter: 'phone' },
                { label: 'person.field.alternate_phone', value: '+1234567893', width: 4, filter: 'phone' },
                { label: 'contact.age', value: 23, width: 4 },
                { label: 'contact.days_since_enrollment', value: 0, width: 6 },
                { label: 'contact.enrollment_date', value: '2000-01-01', width: 6, filter: 'date' },
                {
                    label: 'contact.parent',
                    value: [
                        { _id: 'patient_parent_id', parent: { _id: 'chw_area_id', parent: { _id: 'district_id' } } },
                        { _id: 'chw_area_id', parent: { _id: 'district_id' } },
                        { _id: 'district_id' }
                    ],
                    filter: 'lineage'
                }
            ]
        );
    });
});
