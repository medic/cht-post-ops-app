const _ = require('lodash');
const path = require('path');
const { expect } = require('chai');
const Harness = require('medic-conf-test-harness');
const { contactIsNurse, contactIsNotNurse, patient } = require('../contacts');
const { noContact, referralForCare, clientReview } = require('../form-inputs');

const harness = new Harness({
    xformFolderPath: path.join(__dirname, '../../forms'),
    harnessDataPath: './harness.defaults.json',
});



describe('Scheduled messages task', () => {

    before(async () => { return await harness.start(); });
    after(async () => { return await harness.stop(); });
    beforeEach(async () => { await harness.clear(); });
    afterEach(() => { expect(harness.consoleErrors).to.be.empty; });

    it('no contact, don\'t show the task', async () => {
        const tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.be.empty;
    });

    it('nurse contact, don\'t show the task', async () => {
        harness.state.contacts.push(contactIsNurse);
        const tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.be.empty;
    });

    it('other contact, show the task', async () => {
        harness.state.contacts.push(contactIsNotNurse);
        const tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('show the task until day 365', async () => {
        harness.state.contacts.push(contactIsNotNurse);
        let tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.have.property('length', 1);
        harness.flush(365);
        tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('don\'t show the task on the 366th day', async () => {
        harness.state.contacts.push(contactIsNotNurse);
        let tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.have.property('length', 1);
        harness.flush(365);
        tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.have.property('length', 1);
        harness.flush(1);
        tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.be.empty;
    });

    it('should resolve task', async () => {
        harness.state.contacts.push(patient);
        harness.content.contact = patient;
        let tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.have.property('length', 1);
        await harness.loadAction(tasks[0].actions[0]);
        const filledForm = await harness.fillForm([]);
        expect(filledForm.errors).to.be.empty;
        tasks = await harness.getTasks({ title: 'tasks.scheduled-msgs.title' });
        expect(tasks).to.be.empty;
    });
});

describe('Client review request', () => {
    before(async () => { return await harness.start(); });
    after(async () => { return await harness.stop(); });
    beforeEach(async () => {
        await harness.clear();
        harness.state.contacts.push(patient);
        harness.content.contact = patient;
    });
    afterEach(() => {
        expect(harness.consoleErrors).to.be.empty;
    });

    it('no report, don\'t show the task', async () => {
        const tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.be.empty;
    });

    it('no_contact report with client_ok = \'yes\', don\'t show the task', async () => {
        const filledForm = await harness.fillForm('no_contact', ...noContact.clientOK)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.be.empty;
    });

    it('no_contact report with client_ok = \'no\', show the task', async () => {
        const filledForm = await harness.fillForm('no_contact', ...noContact.clientNotOK)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('referral_for_care report, show the task', async () => {
        const filledForm = await harness.fillForm('referral_for_care', ...referralForCare.pain)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('resolve the task, coming from no_contact report', async () => {
        let filledForm = await harness.fillForm('no_contact', ...noContact.clientNotOK)
        expect(filledForm.errors).to.be.empty;
        let tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
        await harness.loadAction(tasks[0].actions[0]);
        filledForm = await harness.fillForm(...clientReview.allNo);
        expect(filledForm.errors).to.be.empty;
        tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.be.empty;
    });

    it('resolve the task, coming from referral_for_care report', async () => {
        let filledForm = await harness.fillForm('referral_for_care', ...referralForCare.pain)
        expect(filledForm.errors).to.be.empty;
        let tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
        await harness.loadAction(tasks[0].actions[0]);
        filledForm = await harness.fillForm(...clientReview.allNo);
        expect(filledForm.errors).to.be.empty;
        tasks = await harness.getTasks({ title: 'tasks.client-review-request.title' });
        expect(tasks).to.be.empty;
    });
});
