const _ = require('lodash');
const path = require('path');
const { expect } = require('chai');
const Harness = require('medic-conf-test-harness');
const { patient } = require('../contacts');
const { noContact, referralForCare, clientReview } = require('../form-inputs');
const moment = require('moment');
const sinon = require('sinon');

const harness = new Harness({
    xformFolderPath: path.join(__dirname, '../../forms'),
    harnessDataPath: './harness.defaults.json',
});

let clock = sinon.useFakeTimers(moment('2000-01-01').toDate());

describe('Client review request', () => {
    before(async () => { return await harness.start(); });
    after(async () => { return await harness.stop(); });
    beforeEach(async () => {
        await harness.clear();
        clock = sinon.useFakeTimers(moment('2000-01-01').toDate());
        harness.state.contacts.push(patient);
        harness.content.contact = patient;
        return await harness.setNow('2000-01-01');
    });
    afterEach(() => {
        expect(harness.consoleErrors).to.be.empty;
        if (clock) { clock.restore(); }
    });

    it('no report, don\'t show the task', async () => {
        const tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.be.empty;
    });

    it('no_contact report with client_ok = \'yes\', don\'t show the task', async () => {
        const filledForm = await harness.fillForm('no_contact', ...noContact.clientOK)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.be.empty;
    });

    it('no_contact report with client_ok = \'no\', show the task', async () => {
        const filledForm = await harness.fillForm('no_contact', ...noContact.clientNotOK)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('referral_for_care report, show the task', async () => {
        const filledForm = await harness.fillForm('referral_for_care', ...referralForCare.pain)
        expect(filledForm.errors).to.be.empty;
        const tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
    });

    it('resolve the task, coming from no_contact report', async () => {
        let filledForm = await harness.fillForm('no_contact', ...noContact.clientNotOK)
        expect(filledForm.errors).to.be.empty;
        let tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
        await harness.loadAction(tasks[0].actions[0]);
        filledForm = await harness.fillForm(...clientReview.allNo);
        expect(filledForm.errors).to.be.empty;
        tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.be.empty;
    });

    it('resolve the task, coming from referral_for_care report', async () => {
        let filledForm = await harness.fillForm('referral_for_care', ...referralForCare.pain)
        expect(filledForm.errors).to.be.empty;
        let tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.have.property('length', 1);
        await harness.loadAction(tasks[0].actions[0]);
        filledForm = await harness.fillForm(...clientReview.allNo);
        expect(filledForm.errors).to.be.empty;
        tasks = await harness.getTasks({ title: 'task.client-review-request.title' });
        expect(tasks).to.be.empty;
    });
});
