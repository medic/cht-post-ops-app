DROP VIEW formview_client_review;
CREATE OR REPLACE VIEW formview_client_review AS 
    SELECT
        doc ->> '_id'                                                 AS uuid,
        doc ->> 'reported_date'                                       AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                                      AS reported,
        doc #>> '{contact,_id}'                                       AS reported_by_id,
        doc #>> '{contact,parent,_id}'                                AS reported_by_parent_id,
        doc #>> '{fields,inputs,source}'                              AS source,
        doc #>> '{fields,patient_id}'                                 AS patient_id,
        doc #>> '{fields,patient_name}'                               AS patient_name,
        doc #>> '{fields,phone}'                                      AS phone,
        doc #>> '{fields,is_referral_for_care}'                       AS is_referral_for_care,
        doc #>> '{fields,is_no_contact}'                              AS is_no_contact,
        doc #>> '{fields,n,client_came}'                              AS client_came,
        doc #>> '{fields,n,return_client,clinic_name}'                AS clinic_name,
        doc #>> '{fields,n,return_client,visit_date}'                 AS visit_date,
        COALESCE(doc #>> '{fields,n,return_client,ae_positive}', doc #>> '{fields,n,trace_client,ae_positive}')
                                                                      AS ae_positive,
        COALESCE(doc #>> '{fields,n,return_client,ae_severity}', doc #>> '{fields,n,trace_client,ae_severity}')
                                                                      AS ae_severity,
        COALESCE(doc #>> '{fields,n,return_client,ae_type}', doc #>> '{fields,n,trace_client,ae_type}')
                                                                      AS ae_type,
        doc #>> '{fields,n,trace_client,client_traced}'               AS client_traced,
        doc #>> '{fields,n,trace_client,client_not_traced_reason}'    AS client_not_traced_reason,
        doc #>> '{fields,n,trace_client,client_ok}'                   AS client_ok,
        doc #>> '{fields,n,nurse}'                                    AS nurse,
        doc #>> '{fields,n,additional_comments}'                      AS additional_comments
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'client_review'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_client_review OWNER TO full_access;
