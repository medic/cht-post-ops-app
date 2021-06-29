const extras = require('./contact-summary-extras');
const { getNewestReport, getField } = extras;

const thisContact = contact;
const thisLineage = lineage;

const isPatient = () => (thisContact.role === 'patient' || !thisContact.role);
const context = {
    isContact: 'yes'
};

const fields = [
    { appliesToType: ['person'], label: 'person.field.phone', value: thisContact.phone, width: 6, filter: 'phone' },
    { appliesToType: ['person', 'nurse'], label: 'contact.parent', value: thisLineage, filter: 'lineage' },
    { appliesToType: ['district_hospital', 'health_center'], label: 'Contact', value: thisContact.contact && thisContact.contact.name, width: 6 },
    { appliesToType: ['district_hospital', 'health_center'], label: 'person.field.phone', value: thisContact.contact && thisContact.contact.phone, width: 6 },
    { appliesToType: ['district_hospital', 'health_center'], label: 'External ID', value: thisContact.external_id, width: 4 },
    { appliesToType: ['district_hospital', 'health_center'], appliesIf: function () { return thisContact.parent && thisLineage[0]; }, label: 'contact.parent', value: thisLineage, filter: 'lineage' },

];

const latestVisitReport = getNewestReport(reports, ['visit_date_change_outcome']);
let currentVisitDate = getField(latestVisitReport, 'n.new_date');
const cards = [
    {
        label: 'Contact Profile',
        appliesToType: ['person'],
        appliesIf: isPatient,
        fields: function () {
            const fields = [];

            fields.push(
                { label: 'Enrollment_date', value: thisContact.reported_date, filter: 'date', width: 6 },
                { label: 'National ID', value: thisContact.national_id, width: 6 },
                { label: 'Filing Number', value: thisContact.filing_number, width: 6 },
                { label: 'Preferred Language', value: thisContact.language_preference, width: 6, translate: true },
            );

            if (currentVisitDate) {
                fields.push({ label: 'Next Visit Date', value: currentVisitDate, filter: 'date', width: 6 });
            }

            return fields;
        },
        modifyContext: function (ctx) {
            if (!currentVisitDate) {
                currentVisitDate = thisContact.rapidpro.visit_date;
            }
            ctx.current_visit_date = currentVisitDate;
        }
    },

];

module.exports = {
    context: context,
    fields: fields,
    cards: cards
};