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
      ['no', 'none', 'do not have enough info', '', 'ann']
    ]
  },

  enroll: {
    person: [
      [],
      ['Person A', 'guruve_hospital', 'Location A', '12345', '23', '+263732123456', '+263732456780', 'english']
    ],
    invalidName: [
      [],
      ['Person A 832!', 'guruve_hospital', 'Location A', '12345', '23', '+263732123456', '+263732456780', 'english']
    ],
    invalidPhone: [
      [],
      ['Person A', 'guruve_hospital', 'Location A', '12345', '23', '+2637321234', '+254732456780', 'english']
    ],
    invalidVMMCNo: [
      [],
      ['Person A', 'guruve_hospital', 'Location A', '1-2345', '23', '+263732123456', '+263732456780', 'english']
    ]
  }
};
