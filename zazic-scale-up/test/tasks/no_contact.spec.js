const _ = require('lodash');
const path = require('path');
const { expect } = require('chai');
const Harness = require('medic-conf-test-harness');
const { noContact, enroll } = require('../form-inputs');

const harness = new Harness();

xdescribe('No contact task', () => {
  before(async () => { return await harness.start(); });
  after(async () => { return await harness.stop(); });
  beforeEach(async () => {
    await harness.clear();
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
    await harness.setNow('2000-01-09');
    const tasks = await harness.getTasks({ title: 'task.no-contact.title' });
    expect(tasks).to.have.property('length', 1);
  });

  it('resolves if a no_contact report is submitted', async () => {
    const enrollmentForm = await harness.fillForm('enroll', ...enroll.person)
    expect(enrollmentForm.errors).to.be.empty;
    
    await harness.setNow('2000-01-09');

    // https://github.com/medic/medic-conf-test-harness/issues/114
    enrollmentForm.report.fields.patient_uuid = harness.subject._id;
    const noContactForm = await harness.fillForm('no_contact', ...noContact.clientOK)
    expect(noContactForm.errors).to.be.empty;

    const tasks = await harness.getTasks({ title: 'task.no-contact.title' });
    expect(tasks).to.be.empty;
  });
});
