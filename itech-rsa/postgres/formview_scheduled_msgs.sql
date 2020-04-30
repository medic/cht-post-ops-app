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
        doc #>  '{tasks}'                              AS tasks,
        doc #>  '{scheduled_tasks}'                    AS scheduled_tasks
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'scheduled_msgs'::text
        AND doc #>> '{contact, parent, _id}' = '00c7c0bd-f01f-44b2-9fbe-48c4e12c6fc7';  -- Boom Clinic
ALTER VIEW formview_scheduled_msgs OWNER TO full_access;
