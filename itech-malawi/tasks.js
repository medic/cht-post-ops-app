const VISIT_DATE_CHANGE_REQUEST = 'visit_date_change_request';
// const PATIENT_TRANSFER_REQUEST = 'patient_transfer_request';
// const STOP_MESSAGE_REQUEST = 'stop_message_request';

const VISIT_DATE_CHANGE_OUTCOME = 'visit_date_change_outcome';
// const PATIENT_TRANSFER_OUTCOME = 'patient_transfer_outcome';
// const STOP_MESSAGE_OUTCOME = 'stop_message_outcome';

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
    title: 'Day 14 no contact',
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
    title: 'Patient Transferred',
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
      start: 5,
      end: 14
    }],
    resolvedIf: (contact, report) => {
      return Utils.getMostRecentReport(contact.reports, 'patient_transferred') === report && Utils.getField(report, 'n.client_ok') === 'yes';
    }
  },
  {
    name: VISIT_DATE_CHANGE_REQUEST,
    icon: 'calendar',
    title: 'Visit Date Change Outcome',
    appliesTo: 'reports',
    appliesToType: [VISIT_DATE_CHANGE_REQUEST],
    actions: [{
      form: 'visit_date_change_outcome',
      label: 'Visit Date Change Outcome',
      modifyContent: function (content, contact, report) {
        content.is_task = true;
        content.current_visit_date = contact.contact.rapidpro.visit_date;
        content.request_id = report._id;
        content.request_date = report.reported_date;
      }
    }],
    resolvedIf: (contact, report) => {
      // console.log(contact.reports, report);
      return contact.reports.find(r => {
        if (r.form !== VISIT_DATE_CHANGE_OUTCOME || r.is_task || !(r.fields && r.fields.n.request)) return false;
        return  r.fields.n.request._id === report._id;
      });
    },
    events: [{
      days: 0,
      start:2,
      end: 14
    }]
  },
  {
    name: 'patient-transferred',
    icon: 'off',
    title: 'Patient Transfer',
    appliesTo: 'reports',
    appliesToType: ['patient_transferred'],
    actions: [{
      form: 'patient_transferred',
      label: 'Patient Transferred',
      modifyContent: function (content) {
        content.is_task = true;
      }
    }],
    resolvedIf: (contact, report) => {
      const mostRecentTransferReport = Utils.getMostRecentReport(contact.reports, 'patient_transferred');
      // There is been a newer change report making this obsolete
      return report.form === 'patient_transferred' && mostRecentTransferReport.reported_date > report.reported_date;
    },
    events: [{
      days: 0,
      start:2,
      end: 14
    }]
  }
];
