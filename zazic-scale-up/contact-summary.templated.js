const thisContact = contact;
const thisLineage = lineage;

const isNurse = () => { return !!contact.is_nurse; };
const isNotNurse = () => { return !isNurse(); };
let daysSinceEnrollment;
if (contact.type === 'person' && !isNurse()) {
    const diff = new Date().getTime() - new Date(contact.reported_date).getTime();
    daysSinceEnrollment = Math.floor(Math.abs(Math.round(diff / (1000 * 60 * 60 * 24))));
}

const fields = [
    { appliesToType: 'person', appliesIf: isNurse, label: 'contact.profile.nurse', value: '', width: 12 },
    { appliesToType: 'person', appliesIf: isNotNurse, label: 'person.field.phone', value: thisContact.phone, width: 4, filter: 'phone' },
    { appliesToType: 'person', appliesIf: isNotNurse, label: 'person.field.alternate_phone', value: thisContact.alternate_phone, width: 4, filter: 'phone' },
    { appliesToType: 'person', appliesIf: isNotNurse, label: 'contact.age', value: thisContact.date_of_birth, width: 4, filter: 'age' },
    { appliesToType: 'person', appliesIf: isNotNurse, label: 'contact.days_since_enrollment', value: daysSinceEnrollment, width: 6 },
    { appliesToType: 'person', appliesIf: isNotNurse, label: 'contact.enrollment_date', value: contact.reported_date, width: 6, filter: 'date' },
    { appliesToType: 'person', label: 'contact.parent', value: thisLineage, filter: 'lineage' },
    { appliesToType: '!person', label: 'Contact', value: thisContact.contact && thisContact.contact.name, width: 4 },
    { appliesToType: '!person', label: 'contact.phone_number', value: thisContact.contact && thisContact.contact.phone, width: 4 },
    { appliesToType: '!person', label: 'External ID', value: thisContact.external_id, width: 4 },
    { appliesToType: '!person', appliesIf: function () { return thisContact.parent && thisLineage[0]; }, label: 'contact.parent', value: thisLineage, filter: 'lineage' }
];

module.exports = {
    fields: fields
};