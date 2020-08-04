SELECT deps_save_and_drop_dependencies('public', 'formview_enrollment');
DROP VIEW formview_enrollment;
CREATE OR REPLACE VIEW formview_enrollment AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        to_char(to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
                                                     AS enrollment_date,
        doc #>> '{parent, _id}'                      AS parent_uuid,
        doc ->> 'name'                               AS name,
        doc ->> 'enrollment_facility'                AS enrollment_facility,
        doc ->> 'enrollment_location'                AS enrollment_location,
        doc ->> 'vmmc_no'                            AS vmmc_no,
        doc ->> 'age_years'                          AS age_years,
        doc ->> 'phone'                              AS phone,
        doc ->> 'alternative_phone'                  AS alternative_phone,
        doc ->> 'language_preference'                AS language_preference,
        doc ->> 'enrollment_nurse'                   AS enrollment_nurse
    FROM couchdb form
    WHERE form.doc ->> 'type'::text = 'person'::text
        AND COALESCE(form.doc ->> 'is_nurse') IS NULL
        AND doc #>> '{parent,_id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_enrollment OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_enrollment');
