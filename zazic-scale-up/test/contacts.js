module.exports = {
    contactIsNurse: { _id: 'nurse_guid', type: 'person', is_nurse: true, reported_date: new Date().getTime() },
    contactIsNotNurse: { _id: 'nurse_guid', type: 'person', is_nurse: false, reported_date: new Date().getTime() },
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
        date_of_birth: '1970-07-09',
        sex: 'female',
        reported_date: new Date().getTime(),
        _id: 'patient_id',
        patient_id: 'patient_id',
        _rev: '1-b'
    }

};
