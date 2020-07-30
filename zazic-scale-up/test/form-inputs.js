module.exports = {
  noContact: {
    clientOK: [
      [],
      ['yes']
    ],
    clientNotOK: [
      [],
      ['no']
    ]
  },

  referralForCare: {
    pain: [
      [],
      ['pain']
    ]
  },

  clientReview: {
    allNo: [
      ['no', 'no', 'no', 'no', 'no']
    ]
  },

  enroll: {
    person: [
      [],
      ['Person A', 'seke_north', 'Location A', '12345', '23', '2000-01-01', '+263732123456', '+263732456780', 'english', 'Nurse A']
    ],
    invalidNames: [
      [],
      ['Person A 832!', 'seke_north', 'Location A', '12345', '23', '2000-01-01', '+263732123456', '+263732456780', 'english', 'Nurse A 83@!']
    ],
    futureEnrollmentDate: [
      [],
      ['Person A', 'seke_north', 'Location A', '12345', '23', '2000-01-07', '+263732123456', '+263732456780', 'english', 'Nurse A']
    ],
    pastEnrollmentDate: [
      [],
      ['Person A', 'seke_north', 'Location A', '12345', '23', '1999-12-20', '+263732123456', '+263732456780', 'english', 'Nurse A']
    ],
    invalidPhone: [
      [],
      ['Person A', 'seke_north', 'Location A', '12345', '23', '2000-01-01', '+2637321234', '+254732456780', 'english', 'Nurse A']
    ],
    invalidVMMCNo: [
      [],
      ['Person A', 'seke_north', 'Location A', '12-345', '23', '2000-01-01', '+263732123456', '+263732456780', 'english', 'Nurse A']
    ]
  }
};
