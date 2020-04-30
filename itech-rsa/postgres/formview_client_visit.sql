DROP VIEW client_visit;
CREATE OR REPLACE VIEW client_visit AS 
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
        doc #>> '{fields,visit}'                     AS visit,
        doc #>> '{fields,ae_severity}'               AS ae_severity,
        doc #>> '{fields,ae_code}'                   AS ae_code,
        doc #>> '{fields,care_provider}'             AS care_provider,
        doc #>> '{fields,comments}'                  AS comments
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'client_visit'::text
        AND doc #>> '{contact, parent, _id}' = '00c7c0bd-f01f-44b2-9fbe-48c4e12c6fc7';  -- Boom Clinic
ALTER VIEW client_visit OWNER TO full_access;
