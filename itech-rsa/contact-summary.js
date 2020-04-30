if(contact.type === 'person') {

    var diff = new Date().getTime() - new Date(contact.reported_date).getTime();
    var daysSinceEnrollment = Math.floor(Math.abs(Math.round(diff / (1000 * 60 * 60 * 24))));
    var fields = [];
    if(contact.is_nurse) {
        fields = [
            { label: 'Nurse profile', value: '', width: 12 },
            { label: 'contact.parent', value: lineage, filter: 'lineage' }
        ];
    } else {
        fields = [
            { label: 'contact.phone_number', value: contact.phone, width: 4, filter: 'phone' },
            { label: 'contact.alternative_phone', value: contact.phone, width: 4, filter: 'phone' },
            { label: 'contact.age', value: contact.age_years, width: 4 },
            { label: 'contact.days_since_enrollment', value: daysSinceEnrollment, width: 6 },
            { label: 'contact.enrollment_date', value: contact.reported_date, width: 6, filter: 'date' },
            { label: 'contact.parent', value: lineage, filter: 'lineage' }
        ];
    }

    return {
        fields: fields
    };
}

