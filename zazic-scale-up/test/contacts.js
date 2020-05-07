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
        date_of_birth: '1970-01-01',
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
        date_of_birth: '1970-01-02',
        phone: '+1234567892',
        alternate_phone: '+1234567893',
        sex: 'female',
        reported_date: '2000-01-01',
        _id: 'patient_uuid',
        patient_id: 'patient_id',
        _rev: '1-b'
    }

};
