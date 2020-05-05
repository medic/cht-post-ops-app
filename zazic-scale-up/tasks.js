const pilot_users = [
    '58284f3c-9c2e-49f5-a039-8d90071c8022',
    '303f9f4c-0c6f-405c-940a-b2f573a85a0c',
    'fcac5344-c15d-4c04-b888-df0cf77fc275',
    'f69d7760-fd9c-418a-a41d-a349cbe5cba2',
    'f8af310b-ffb3-4ecf-b345-b46c196f6d5c',
    '711fe306-e072-433b-9de7-1666d709e87b',
    'd36fb82a-c150-4745-a991-4644f10e1883',
    '3457a5f1-e806-438a-929b-a246ffdb98d4',
    '749cc214-d05a-4f19-8ce0-61e233bac7b2',
    '323d1b41-3427-4109-9336-32e5f37c03dd',
    '4bccd638-6f69-4fbd-914a-c115eba1563b',
    '72a86cdc-4d32-4cb0-85c2-7b5c63d0bb32',
    '4b9ac080-a3ee-4959-94dd-c5b7ea29e7a1',
    '112d37f9-25e2-49b7-b289-d4ead1ce248c',
    '5fe44ccb-8cc2-4d26-9157-df01d4899d34',
    'f4d7b1e7-ff89-40b3-9d70-9afa5685c6fa'
];

module.exports = [
    {
        name: 'scheduled-msgs',
        icon: 'network',
        title: 'tasks.scheduled-msgs.title',
        appliesTo: 'contacts',
        appliesToType: ['person'],
        appliesIf: (contact) => {
            return !pilot_users.includes(contact.contact._id) && !contact.contact.is_nurse;
        },
        resolvedIf: (contact, report, event, dueDate) => {
            return Utils.isFormSubmittedInWindow(
                contact.reports,
                'scheduled_msgs',
                Utils.addDate(dueDate, -event.start).getTime(),
                Utils.addDate(dueDate, event.end + 1).getTime()
            );
        },
        actions: [{
            form: 'scheduled_msgs',
            label: 'Send 14-day scheduled SMSs'
        }],
        events: [{
            days: 0,
            start: 1,
            end: 365
        }]
    },

    {
        name: 'client-review-request',
        icon: 'network',
        title: 'tasks.client-review-request.title',
        appliesTo: 'reports',
        appliesToType: ['no_contact', 'referral_for_care'],
        appliesIf: (contact, report) => {
            return report.form === 'referral_for_care' ||
                report.form === 'no_contact' && Utils.getField(report, 'n.client_ok') !== 'yes';
        },
        resolvedIf: (contact, report, event, dueDate) => {
            return Utils.isFormSubmittedInWindow(
                contact.reports,
                'scheduled_msgs',
                Utils.addDate(dueDate, -event.start).getTime(),
                Utils.addDate(dueDate, event.end + 1).getTime()
            );
        },
        actions: [{
            form: 'client_review',
            label: 'Client review',
            modifyContent: function (content, contact, report) {
                if (report.form === 'no_contact') {
                    content.is_no_contact = true;
                }
                else {
                    content.is_referral_for_care = true;
                }
            }
        }],
        events: [{
            days: 0,
            start: 1,
            end: 365
        }]
    }
];