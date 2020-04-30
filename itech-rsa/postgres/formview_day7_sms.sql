DROP VIEW formview_day7_sms;
CREATE OR REPLACE VIEW formview_day7_sms AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id,
        doc #>> '{fields,inputs,source}'             AS source,
        doc #>> '{fields,patient_id}'                AS patient_id,
        doc #>> '{fields,patient_name}'              AS patient_name,
        doc #>> '{fields,response}'                  AS response,
        doc #>> '{fields,symptom}'                   AS symptom,
        doc #>> '{fields,other_symptom}'             AS symptom_other,
        doc #>> '{fields,comments}'                  AS comments
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'day2_sms'::text
        AND doc #>> '{contact, parent, _id}' = '00c7c0bd-f01f-44b2-9fbe-48c4e12c6fc7';  -- Boom Clinic
ALTER VIEW formview_day7_sms OWNER TO full_access;
