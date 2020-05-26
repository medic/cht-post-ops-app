module.exports = {
    nurse: {
        type: 'person',
        parent: {
            _id: 'chw_area_id',
            parent: {
                _id: 'district_id'
            }
        },
        name: 'Nurse Name',
        role: 'nurse',
        is_nurse: true,
        phone: '+1234567890',
        alternate_phone: '+1234567891',
        reported_date: '2000-01-01',
        _id: 'nurse_uuid',
        patient_id: 'nurse_id',
        _rev: '1-a'
    },
    patient: {
        type: 'person',
        parent: {
            _id: 'patient_parent_id',
            parent: {
                _id: 'chw_area_id',
                parent: {
                    _id: 'district_id'
                }
            }
        },
        name: 'Patient Name',
        role: 'patient',
        is_nurse: false,
        age_years: 23,
        phone: '+1234567892',
        alternate_phone: '+1234567893',
        sex: 'female',
        reported_date: '2000-01-01',
        _id: 'patient_uuid',
        patient_id: 'patient_id',
        _rev: '1-b'
    },
    site1: {
        type: 'health_center',
        parent: {
            _id: 'district_id'
        },
        contact: {
            _id: 'site1_nurse',
        },
        name: 'Site 1',
        reported_date: '2000-01-01',
        _id: 'site1_uuid',
        _rev: '1-c'
    },

    site1_nurse: {
        type: 'person',
        parent: {
            _id: 'site1_uuid',
            parent: {
                _id: 'district_id'
            }
        },
        name: 'Site Nurse',
        role: 'nurse',
        is_nurse: true,
        date_of_birth: '1970-01-01',
        phone: '+1234567890',
        alternate_phone: '+1234567891',
        reported_date: '2000-01-01',
        _id: 'nurse_uuid',
        patient_id: 'nurse_id',
        _rev: '1-a'
    },

};
