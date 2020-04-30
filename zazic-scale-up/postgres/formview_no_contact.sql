DROP VIEW formview_no_contact;
CREATE OR REPLACE VIEW formview_no_contact AS 
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
        doc #>> '{fields,n,client_ok}'               AS client_ok,
        doc #>> '{fields,n,additional_notes}'        AS additional_notes
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'no_contact'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_no_contact OWNER TO full_access;
