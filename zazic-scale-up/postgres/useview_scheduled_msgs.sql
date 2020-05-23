SELECT deps_save_and_drop_dependencies('public', 'useview_scheduled_msgs');
DROP MATERIALIZED VIEW IF EXISTS useview_scheduled_msgs;
CREATE MATERIALIZED VIEW useview_scheduled_msgs AS (
    WITH schedule_report AS (
        SELECT
        uuid, patient_id, tasks, scheduled_tasks
        FROM formview_scheduled_msgs
    ),
    task AS (
        SELECT
        uuid                        AS doc_uuid,
        patient_id                  AS patient_id,
        jsonb_array_elements(tasks) AS task
        FROM schedule_report
    ),
    scheduled_task AS (
        SELECT
        uuid                        AS doc_uuid,
        patient_id                  AS patient_id,
        jsonb_array_elements(scheduled_tasks) AS task
        FROM schedule_report
    ),
    free_text_task AS (
        SELECT
        doc ->> '_id'                           AS doc_uuid,
        jsonb_array_elements(doc -> 'tasks')    AS task
        FROM couchdb where COALESCE(doc ->> 'kujua_message')::boolean IS TRUE
    ),
    auto_response as (
        SELECT
            a.task -> 'messages' -> 0 ->> 'uuid'             as uuid,
            a.task ->> 'due'                                 as due,
            a.task ->> 'type'                                as schedule,
            a.task -> 'messages' -> 0 ->> 'to'               as recipient,
            a.task -> 'messages' -> 0 ->> 'message'          as message,
            a.task -> 'state_history' -> -1 ->> 'state'      as state,
            a.task -> 'state_history' -> -1 ->> 'timestamp'  as timestamp,
            a.doc_uuid                                       as doc_uuid,
            a.patient_id                                     as patient_id,
            'auto_response'::text                            as type
        FROM task a
    ),
    scheduled_msg AS (
        SELECT
            a.task -> 'messages' -> 0 ->> 'uuid'             as uuid,
            a.task ->> 'due'                                 as due,
            a.task ->> 'type'                                as schedule,
            a.task -> 'messages' -> 0 ->> 'to'               as recipient,
            a.task -> 'messages' -> 0 ->> 'message'          as message,
            a.task -> 'state_history' -> -1 ->> 'state'      as state,
            a.task -> 'state_history' -> -1 ->> 'timestamp'  as timestamp,
            a.doc_uuid                                       as doc_uuid,
            a.patient_id                                     as patient_id,
            'scheduled'::text                                as type
        FROM scheduled_task a
    ),
    free_text_msg AS (
        SELECT
            a.task -> 'messages' -> 0 ->> 'uuid'             as uuid,
            a.task ->> 'due'                                 as due,
            a.task ->> 'type'                                as schedule,
            a.task -> 'messages' -> 0 ->> 'to'               as recipient,
            a.task -> 'messages' -> 0 ->> 'message'          as message,
            a.task -> 'state_history' -> -1 ->> 'state'      as state,
            a.task -> 'state_history' -> -1 ->> 'timestamp'  as timestamp,
            a.doc_uuid                                       as doc_uuid,
            c.doc ->> 'patient_id'                           as patient_id,
            'free_text'::text                                as type
        FROM free_text_task a
        LEFT JOIN raw_contacts c ON c.doc ->> '_id' =  a.task -> 'messages' -> 0 -> 'contact' ->> '_id'
        WHERE c.doc ->> 'patient_id' IN (SELECT patient_id from formview_enrollment)
    )
    SELECT * FROM auto_response
    UNION
    SELECT * FROM scheduled_msg
    UNION
    SELECT * FROM free_text_msg
);
CREATE UNIQUE INDEX useview_scheduled_msgs_uuid ON useview_scheduled_msgs USING btree (uuid);
ALTER MATERIALIZED VIEW useview_scheduled_msgs OWNER TO full_access;
GRANT SELECT ON useview_scheduled_msgs TO klipfolio, full_access, read_only, lgaccess;
SELECT deps_restore_dependencies('public', 'useview_scheduled_msgs');
