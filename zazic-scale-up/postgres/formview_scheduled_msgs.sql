DROP VIEW formview_scheduled_msgs;
CREATE OR REPLACE VIEW formview_scheduled_msgs AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id,
        doc #>> '{fields,patient_id}'                AS patient_id,
        doc #>> '{fields,patient_name}'              AS patient_name,
        doc #>> '{fields,language_preference}'       AS language_preference,
        doc #>  '{tasks}'                            AS tasks,
        doc #>  '{scheduled_tasks}'                  AS scheduled_tasks
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'scheduled_msgs'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_scheduled_msgs OWNER TO full_access;
