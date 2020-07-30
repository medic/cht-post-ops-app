const path = require('path');
const { expect } = require('chai');
const Harness = require('medic-conf-test-harness');
const { site1, site1_nurse } = require('../contacts');
const { enroll } = require('../form-inputs');
const moment = require('moment');
const sinon = require('sinon');
const localMidnightDate = moment('2000-01-01 23:45').toDate();

const harness = new Harness({
    xformFolderPath: path.join(__dirname, '../../forms'),
    harnessDataPath: './harness.defaults.json',
});

let clock;// = sinon.useFakeTimers(localMidnightDate);
describe('Enrollment', () => {
    before(async () => { return await harness.start(); });
    after(async () => { return await harness.stop(); });
    beforeEach(async () => {
        await harness.clear();
        harness.state.contacts.push(site1);
        harness.state.contacts.push(site1_nurse);
        harness.content.contact = site1;
        clock = sinon.useFakeTimers(localMidnightDate);
        return await harness.setNow('2000-01-01 23:45');
    });
    afterEach(() => {
        if (clock) { clock.restore(); }
        expect(harness.consoleErrors).to.be.empty;
    });

    it('should create a contact with all fields captured', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.person);
        expect(filledForm.errors).to.be.empty;
        expect(harness.state.contacts[2]).to.deep.equal({
            parent: {
                _id: 'site1_uuid',
                parent: {
                    _id: 'district_id'
                }
            },
            type: 'person',
            name: 'Person A',
            enrollment_facility: 'seke_north',
            enrollment_location: 'Location A',
            vmmc_no: '12345',
            age_years: '23',
            enrollment_date: '2000-01-01',
            phone: '+263732123456',
            alternative_phone: '+263732456780',
            language_preference: 'english',
            enrollment_nurse: 'Nurse A',
            reported_date: localMidnightDate.getTime()
        })
    });

    it('should fail due to invalid name', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.invalidNames);
        expect(filledForm.errors).to.have.lengthOf(2);
        const errorMsg = 'Please type in name characters e.g letters and space.';
        expect(filledForm.errors[0].msg).to.equal(errorMsg);
        expect(filledForm.errors[1].msg).to.equal(errorMsg);
    });

    it('should fail due to an enrollment date in the future', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.futureEnrollmentDate);
        expect(filledForm.errors).to.have.lengthOf(1);
        const errorMsg = "Only today's date is allowed.";
        expect(filledForm.errors[0].msg).to.equal(errorMsg);
    });

    it('should fail due to an enrollment date in the past', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.pastEnrollmentDate);
        expect(filledForm.errors).to.have.lengthOf(1);
        const errorMsg = "Only today's date is allowed.";
        expect(filledForm.errors[0].msg).to.equal(errorMsg);
    });

    it('should fail due to invalid phone', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.invalidPhone);
        expect(filledForm.errors).to.have.lengthOf(2);
        const errorMsg = 'Please enter phone number in the format +263xxxxxxxxx';
        expect(filledForm.errors[0].msg).to.equal(errorMsg);
        expect(filledForm.errors[1].msg).to.equal(errorMsg);
    });

    it('should fail due to invalid vmmc no', async () => {
        const filledForm = await harness.fillForm('enroll', ...enroll.invalidVMMCNo);
        expect(filledForm.errors).to.have.lengthOf(1);
        const errorMsg = 'Must be 5 – 9 numeric digits';
        expect(filledForm.errors[0].msg).to.equal(errorMsg);
    });
});
