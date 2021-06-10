const { expect } = require('chai');
const Harness = require('medic-conf-test-harness');
const moment = require('moment');

const { enroll } = require('../form-inputs');

const localMidnightDate = moment('2000-01-01 23:45').toDate();
const harness = new Harness();

describe('Enrollment', () => {
  before(async () => { return await harness.start(); });
  after(async () => { return await harness.stop(); });
  beforeEach(async () => {
    await harness.clear();
    harness.subject = 'health_center_id';
    return await harness.setNow('2000-01-01 23:45');
  });
  afterEach(() => {
    expect(harness.consoleErrors).to.be.empty;
  });

  it('should create a contact with all fields captured', async () => {
    const filledForm = await harness.fillForm('enroll', ...enroll.person);
    console.log("filledForm.errors", filledForm.errors);
    expect(filledForm.errors).to.be.empty;
    const newestContact = harness.state.contacts[harness.state.contacts.length - 1];
    expect(newestContact).to.deep.include({
      type: 'person',
      name: 'Person A',
      enrollment_facility: {
        '_id': 'guruve_hospital',
        'name': ''
      },
      enrollment_location: 'Location A',
      vmmc_no: '12345',
      age_years: '23',
      phone: '+263732123456',
      alternative_phone: '+263732456780',
      language_preference: 'english',
    })
  });

  it('should fail due to invalid name', async () => {
    const filledForm = await harness.fillForm('enroll', ...enroll.invalidName);
    expect(filledForm.errors).to.have.lengthOf(1);
    const errorMsg = 'Please type in name characters e.g letters and space.';
    expect(filledForm.errors[0].msg).to.equal(errorMsg);
  });

  it('should fail due to invalid phone', async () => {
    const filledForm = await harness.fillForm('enroll', ...enroll.invalidPhone);
    expect(filledForm.errors).to.have.lengthOf(4); // should be 2
    // see https://github.com/medic/medic-conf-test-harness/issues/67 for more
    const errorMsg = 'Please enter a valid mobile number';
    expect(filledForm.errors.map(err => err.msg)).to.include.members([errorMsg]);
  });

  it('should fail due to invalid vmmc no', async () => {
    const filledForm = await harness.fillForm('enroll', ...enroll.invalidVMMCNo);
    expect(filledForm.errors).to.have.lengthOf(1);
    const errorMsg = 'Please enter between 5 - 9 digits';
    expect(filledForm.errors[0].msg).to.equal(errorMsg);
  });
});
