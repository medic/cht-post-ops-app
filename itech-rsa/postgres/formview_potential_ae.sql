DROP VIEW formview_potential_ae;
CREATE OR REPLACE VIEW formview_potential_ae AS 
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
        doc #>> '{fields,phone}'                     AS phone,
        doc #>> '{fields,symptoms}'                  AS symptoms,
        doc #>> '{fields,other_symptom}'             AS other_symptom,
        doc #>> '{fields,followup_request}'          AS followup_request,
        doc #>> '{fields,followup_method}'           AS followup_method,
        doc #>> '{fields,ae}'                        AS ae,
        doc #>> '{fields,info}'                      AS info,
        doc #>> '{fields,client_return}'             AS client_return,
        doc #>> '{fields,explanation}'               AS explanation
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'potential_ae'::text
        AND doc #>> '{contact, parent, _id}' = '00c7c0bd-f01f-44b2-9fbe-48c4e12c6fc7';  -- Boom Clinic
ALTER VIEW formview_potential_ae OWNER TO full_access;
