DROP VIEW formview_enrollment;
CREATE OR REPLACE VIEW formview_enrollment AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc ->> 'patient_id'                         AS patient_id,
        doc ->> '{parent, _id}'                      AS parent_uuid,
        doc ->> 'name'                               AS name,
        doc ->> 'study_no'                           AS study_no,
        doc ->> 'enrollment_date'                    AS enrollment_date,
        doc ->> 'consent'                            AS consent,
        doc ->> 'phone'                              AS phone,
        doc ->> 'language_preference'                AS language_preference,
        doc ->> 'mobile_company'                     AS mobile_company,
        doc ->> 'transport_cost'                     AS transport_cost,
        doc ->> 'clinic_trip'                        AS clinic_trip,
        doc ->> 'food_cost'                          AS food_cost,
        doc ->> 'wage_period'                        AS wage_period,
        doc ->> 'patient_id'                         AS signal_id
    FROM couchdb form
    WHERE form.doc ->> 'type'::text = 'person'::text
        AND COALESCE(form.doc ->> 'is_nurse') IS NULL
        AND doc #>> '{parent,_id}' = '00c7c0bd-f01f-44b2-9fbe-48c4e12c6fc7';  -- boom clinic uuid
ALTER VIEW formview_enrollment OWNER TO full_access;
