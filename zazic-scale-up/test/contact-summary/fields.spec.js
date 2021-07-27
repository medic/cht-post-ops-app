const { expect } = require('chai');
const TestRunner = require('medic-conf-test-harness');
const harness = new TestRunner();

xdescribe('Tests for fields for Non-Nurse', () => {
  before(async () => { return await harness.start(); });
  after(async () => { return await harness.stop(); });
  beforeEach(async () => {
    await harness.clear();
    return await harness.setNow('2000-01-01');
  });
  afterEach(() => {
    expect(harness.consoleErrors).to.be.empty;
  });

  it('fields for nurses', async () => {
    harness.subject = 'super_nurse_uuid';
    const contactSummary = await harness.getContactSummary();
    expect(contactSummary.fields).to.have.property('length', 2);
    expect(contactSummary.fields.map(field => field.label)).to.deep.equal([
      'contact.profile.nurse',
      'contact.parent',
    ]);
  });

  it('fields for patients', async () => {
    const contactSummary = await harness.getContactSummary();
    expect(contactSummary.fields).to.have.property('length', 6);
    expect(contactSummary.fields.filter(f => f.filter !== 'lineage')).to.deep.equal(
      [
        { label: 'person.field.phone', value: '+1234567892', width: 4, filter: 'phone' },
        { label: 'person.field.alternate_phone', value: '+1234567893', width: 4, filter: 'phone' },
        { label: 'contact.age', value: 23, width: 4 },
        { label: 'contact.days_since_enrollment', value: 0, width: 6 },
        { label: 'contact.enrollment_date', value: '2000-01-01', width: 6, filter: 'date' },
      ]
    );
  });
});
