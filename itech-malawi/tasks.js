module.exports = [
  {
    name: 'day2-sms',
    icon: 'treatment',
    title: 'task.day2-sms.title',
    appliesTo: 'contacts',
    appliesToType: ['person'],
    appliesIf: (contact) => {
      return contact.contact.randomization && contact.contact.randomization === 'texting';
    },
    resolvedIf: (contact, report, event, dueDate) => {
      return Utils.isFormSubmittedInWindow(
        contact.reports,
        'day2_sms',
        contact.contact.reported_date,
        Utils.addDate(dueDate, event.end + 1).getTime()
      );
    },
    actions: [{
      form: 'day2_sms',
      label: 'Follow up client'
    }],
    events: [{
      id: 'sms-followup-day-2',
      days: 2,
      start: 0,
      end: 365
    }]
  },

  {
    name: 'day7-sms',
    icon: 'treatment',
    title: 'task.day7-sms.title',
    appliesTo: 'contacts',
    appliesToType: ['person'],
    appliesIf: (contact) => {
      return contact.contact.randomization && contact.contact.randomization === 'texting';
    },
    resolvedIf: (contact, report, event, dueDate) => {
      return Utils.isFormSubmittedInWindow(
        contact.reports,
        'day7_sms',
        contact.contact.reported_date,
        Utils.addDate(dueDate, event.end + 1).getTime()
      );
    },
    actions: [{
      form: 'day7_sms',
      label: 'Follow up client'
    }],
    events: [{
      id: 'sms-followup-day-7',
      days: 7,
      start: 0,
      end: 365
    }]
  },

  {
    name: 'followup-day-14',
    icon: 'treatment',
    title: 'task.followup-day-14.title',
    appliesTo: 'contacts',
    appliesToType: ['person'],
    appliesIf: (contact) => {
      return !!contact.contact.randomization;
    },
    resolvedIf: (contact) => {
      return contact.reports.some(function (rep) {
        return rep.form === 'client_visit' && rep.fields.visit === 'day14';
      });
    },
    actions: [{
      form: 'client_visit',
      label: '14 Day Follow up client',
    }],
    events: [{
      id: 'followup-day-14',
      days: 14,
      start: 2,
      end: 365
    }]
  },

  {
    name: 'ae-referral',
    icon: 'treatment',
    title: 'task.ae-referral.title',
    appliesTo: 'reports',
    appliesToType: ['potential_ae'],
    appliesIf: (contact, report) => { return Utils.getField(report, 'note.client_return') === 'yes'; },
    resolvedIf: (contact, report, event, dueDate) => {
      return Utils.isFormSubmittedInWindow(
        contact.reports,
        'referral_confirmation',
        report.reported_date,
        Utils.addDate(dueDate, event.end + 1).getTime()
      );
    },
    actions: [{
      form: 'referral_confirmation',
      label: 'SMS Referral',
    }],
    events: [{
      id: 'ae-referral',
      days: 2,
      start: 2,
      end: 365
    }]
  },

  {
    name: 'no-contact-8',
    icon: 'off',
    title: 'task.day8-no-contact.title',
    appliesTo: 'reports',
    appliesToType: ['enroll'],
    resolvedIf: (contact, report, event, dueDate) => {
      const noContactAlreadySubmitted = Utils.isFormSubmittedInWindow(
        contact.reports,
        'day8_no_contact',
        report.reported_date,
        Utils.addDate(dueDate, event.end + 1).getTime()
      );

      const someReportSubmitted = ['0', '1'].some((rep) => Utils.isFormSubmittedInWindow(
        contact.reports,
        rep,
        report.reported_date,
        Utils.addDate(dueDate, 1).getTime())
      );

      return noContactAlreadySubmitted || someReportSubmitted;
    },
    actions: [{
      form: 'day8_no_contact',
      label: 'No Contact until day 8',
      modifyContent: function (content) {
        content.is_task = true;
      }
    }],
    events: [{
      days: 8,
      start: 0,
      end: 365
    }]
  },

  {
    name: 'no-contact-14',
    icon: 'off',
    title: 'task.day14-no-contact.title',
    appliesTo: 'reports',
    appliesToType: ['enroll'],
    resolvedIf: (contact, report, event, dueDate) => {
      const noContactAlreadySubmitted = Utils.isFormSubmittedInWindow(
        contact.reports,
        'day14_no_contact',
        report.reported_date,
        Utils.addDate(dueDate, event.end + 1).getTime()
      );

      const someReportSubmitted = ['0', '1'].some((rep) => Utils.isFormSubmittedInWindow(
        contact.reports,
        rep,
        report.reported_date,
        Utils.addDate(dueDate, 1).getTime())
      );

      return noContactAlreadySubmitted || someReportSubmitted;
    },
    actions: [{
      form: 'day14_no_contact',
      label: 'No Contact until day 14',
      modifyContent: function (content) {
        content.is_task = true;
      }
    }],
    events: [{
      days: 14,
      start: 0,
      end: 365
    }]
  },

  {
    name: 'next-day-reminder_day14-no-contact',
    icon: 'off',
    title: 'task.next-day-reminder_day14-no-contact',
    appliesTo: 'reports',
    appliesToType: ['day14_no_contact'],
    appliesIf: (contact, report) => {
      return Utils.getMostRecentReport(contact.reports, 'day14_no_contact') === report && Utils.getField(report, 'n.client_ok') === 'remind_me';
    },
    actions: [{
      form: 'day14_no_contact',
      label: 'No Contact until day 14',
      modifyContent: function (content) {
        content.is_task = true;
      }
    }],
    events: [{
      days: 1,
      start: 0,
      end: 14
    }],
    resolvedIf: (contact, report) => {
      return Utils.getMostRecentReport(contact.reports, 'day14_no_contact') === report && Utils.getField(report, 'n.client_ok') === 'yes';
    }
  },
  {
    name: 'next-day-reminder_day14-patient-transferred',
    icon: 'off',
    title: 'task.next-day-reminder_patient-transferred',
    appliesTo: 'reports',
    appliesToType: ['patient_transferred'],
    appliesIf: (contact, report) => {
      return Utils.getMostRecentReport(contact.reports, 'patient_transferred') === report && Utils.getField(report, 'n.client_ok') === 'remind_me';
    },
    actions: [{
      form: 'patient_transferred',
      label: 'Patient transferred',
      modifyContent: function (content) {
        content.is_task = true;
      }
    }],
    events: [{
      days: 1,
      start: 0,
      end: 14
    }],
    resolvedIf: (contact, report) => {
      return Utils.getMostRecentReport(contact.reports, 'patient_transferred') === report && Utils.getField(report, 'n.client_ok') === 'yes';
    }
  }
];
