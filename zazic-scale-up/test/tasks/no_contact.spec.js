const _ = require('lodash');
const path = require('path');
const { expect } = require('chai');
const Harness = require('medic-conf-test-harness');
const { patient } = require('../contacts');
const { noContact, enroll, clientResponse } = require('../form-inputs');

const harness = new Harness({
    xformFolderPath: path.join(__dirname, '../../forms'),
    harnessDataPath: './harness.defaults.json',
});

describe('No contact task', () => {
    before(async () => { return await harness.start(); });
    after(async () => { return await harness.stop(); });
    beforeEach(async () => {
        await harness.clear();
        harness.state.contacts.push(patient);
        harness.content.contact = patient;
        await harness.setNow('2000-01-01 12:00'); // midday
    });
    afterEach(() => {
        expect(harness.consoleErrors).to.be.empty;
    });

    it('does not show immediately after an enrollment', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.person)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'task.no-contact.title' });
        expect(tasks).to.be.empty;
    });

    it('shows on day 8 after enrollment', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.person)
        expect(filledForm.errors).to.be.empty;
        harness.setNow('2000-01-09');
        const tasks = await harness.getTasks({ title: 'task.no-contact.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('resolves if a no_contact report is submitted', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.person)
        expect(filledForm.errors).to.be.empty;
        harness.setNow('2000-01-09');
        await harness.fillForm('no_contact', ...noContact.clientOK)
        const tasks = await harness.getTasks({ title: 'task.no-contact.title' });
        expect(tasks).to.be.empty;
    });
});
