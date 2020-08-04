SELECT deps_save_and_drop_dependencies('public', 'formview_referral_for_care');
DROP VIEW formview_referral_for_care;
CREATE OR REPLACE VIEW formview_referral_for_care AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id,
        doc #>> '{fields,inputs,source}'             AS source,
        doc #>> '{fields,patient_uuid}'              AS patient_id,
        doc #>> '{fields,patient_name}'              AS patient_name,
        doc #>> '{fields,phone}'                     AS phone,
        doc #>> '{fields,n,symptoms_list}'           AS symptoms_list,
        doc #>> '{fields,n,symptoms_other}'          AS symptoms_other,
        doc #>> '{fields,n,additional_notes}'        AS additional_notes
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'referral_for_care'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_referral_for_care OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_referral_for_care');
