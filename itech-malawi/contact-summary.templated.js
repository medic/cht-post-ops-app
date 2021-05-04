const extras = require('./contact-summary-extras');
const { getNewestReport, getField } = extras;

const thisContact = contact;
const thisLineage = lineage;

const isPatient = () => (thisContact.role === 'patient' || !thisContact.role);
const context = {
    isContact: 'yes'
};

const fields = [
    { appliesToType: ['person'], label: 'person.field.phone', value: thisContact.phone, width: 6, filter: 'phone' },
    { appliesToType: ['person', 'nurse'], label: 'contact.parent', value: thisLineage, filter: 'lineage' },
    { appliesToType: ['district_hospital', 'health_center'], label: 'Contact', value: thisContact.contact && thisContact.contact.name, width: 6 },
    { appliesToType: ['district_hospital', 'health_center'], label: 'person.field.phone', value: thisContact.contact && thisContact.contact.phone, width: 6 },
    { appliesToType: ['district_hospital', 'health_center'], label: 'External ID', value: thisContact.external_id, width: 4 },
    { appliesToType: ['district_hospital', 'health_center'], appliesIf: function () { return thisContact.parent && thisLineage[0]; }, label: 'contact.parent', value: thisLineage, filter: 'lineage' },

];

const cards = [
    {
        label: 'Contact Profile',
        appliesToType: ['person'],
        appliesIf: isPatient,
        fields: function () {
            const fields = [];

            fields.push(
                { label: 'Enrollment_date', value: thisContact.reported_date, filter: 'date', width: 6 },
                { label: 'MPC N0', value: thisContact.mpc_no, width: 6 },
                { label: 'ARV N0', value: thisContact.arv_no, width: 6 },
                { label: 'Preferred Language', value: thisContact.language_preference, width: 6, translate: true }
            );

            return fields;
        },
        modifyContext: function (ctx) {
            
            const latestVisitReport = getNewestReport(reports, ['date_change_request']);
            const currentVisitDate = getField(latestVisitReport, 'n.new_date');
            // debugger;
            // let lmpDate = getField(report, 'lmp_date_8601');
            // let lmpMethodApprox = getField(report, 'lmp_method_approx');
            // let hivTested = getField(report, 'hiv_status_known');
            // let dewormingMedicationReceived = getField(report, 'deworming_med_received');
            // let ttReceived = getField(report, 'tt_received');
            // const riskFactorCodes = getAllRiskFactors(allReports, report);
            // const riskFactorsCustom = getAllRiskFactorExtra(allReports, report);
            // let pregnancyFollowupDateRecent = getField(report, 't_pregnancy_follow_up_date');
      
            // const followUps = getSubsequentPregnancyFollowUps(allReports, report);
            // followUps.forEach(function (followUpReport) {
            //   if (getField(followUpReport, 'lmp_updated') === 'yes') {
            //     lmpDate = getField(followUpReport, 'lmp_date_8601');
            //     lmpMethodApprox = getField(followUpReport, 'lmp_method_approx');
            //   }
            //   hivTested = getField(followUpReport, 'hiv_status_known');
            //   dewormingMedicationReceived = getField(followUpReport, 'deworming_med_received');
            //   ttReceived = getField(followUpReport, 'tt_received');
            //   if (getField(followUpReport, 't_pregnancy_follow_up') === 'yes') { pregnancyFollowupDateRecent = getField(followUpReport, 't_pregnancy_follow_up_date'); }
      
            // });
            // ctx.lmp_date_8601 = lmpDate;
            // ctx.lmp_method_approx = lmpMethodApprox;
            // ctx.is_active_pregnancy = true;
            // ctx.deworming_med_received = dewormingMedicationReceived;
            // ctx.hiv_tested_past = hivTested;
            // ctx.tt_received_past = ttReceived;
            // ctx.risk_factor_codes = riskFactorCodes.join(' ');
            // ctx.risk_factor_extra = riskFactorsCustom.join('; ');
            // ctx.pregnancy_follow_up_date_recent = pregnancyFollowupDateRecent;
            // ctx.pregnancy_uuid = report._id;
            // console.log(currentVisitDate, report);
            ctx.current_visit_date = currentVisitDate;
          }
    },
    
];

module.exports = {
    context: context,
    fields: fields,
    cards: cards
};