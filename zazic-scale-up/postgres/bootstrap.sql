 -- GENERATED 2020-07-30T21:56:52.417717144


/*
Adapted from http://pretius.com/postgresql-stop-worrying-about-table-and-view-dependencies/
 Need:
-- If you ever need to update a base object without worrying about the hustle of restoring the dependent objects

-- Usage
-- SELECT deps_save_and_drop_dependencies(_schema_, _object_name_)
-- .. Update the base object ....
-- SELECT deps_restore_dependencies(_schema_, _object_name_)

*/
DROP TABLE IF EXISTS deps_saved_ddl;
create table deps_saved_ddl
(
  deps_id serial primary key, 
  deps_view_schema varchar(255), 
  deps_view_name varchar(255), 
  deps_ddl_to_run text
);

create or replace function deps_save_and_drop_dependencies(p_view_schema varchar, p_view_name varchar) returns void as
$$
declare
  v_curr record;
begin
for v_curr in 
(
  select obj_schema, obj_name, obj_type from
  (
  with recursive recursive_deps(obj_schema, obj_name, obj_type, depth) as 
  (
    select p_view_schema, p_view_name, null::varchar, 0
    union
    select dep_schema::varchar, dep_name::varchar, dep_type::varchar, recursive_deps.depth + 1 from 
    (
      select ref_nsp.nspname ref_schema, ref_cl.relname ref_name, 
	  rwr_cl.relkind dep_type,
      rwr_nsp.nspname dep_schema,
      rwr_cl.relname dep_name
      from pg_depend dep
      join pg_class ref_cl on dep.refobjid = ref_cl.oid
      join pg_namespace ref_nsp on ref_cl.relnamespace = ref_nsp.oid
      join pg_rewrite rwr on dep.objid = rwr.oid
      join pg_class rwr_cl on rwr.ev_class = rwr_cl.oid
      join pg_namespace rwr_nsp on rwr_cl.relnamespace = rwr_nsp.oid
      where dep.deptype = 'n'
      and dep.classid = 'pg_rewrite'::regclass
    ) deps
    join recursive_deps on deps.ref_schema = recursive_deps.obj_schema and deps.ref_name = recursive_deps.obj_name
    where (deps.ref_schema != deps.dep_schema or deps.ref_name != deps.dep_name)
  )
  select obj_schema, obj_name, obj_type, depth
  from recursive_deps 
  where depth > 0
  ) t
  group by obj_schema, obj_name, obj_type
  order by max(depth) desc
) loop

  insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
  select p_view_schema, p_view_name, 'COMMENT ON ' ||
  case
  when c.relkind = 'v' then 'VIEW'
  when c.relkind = 'm' then 'MATERIALIZED VIEW'
  else ''
  end
  || ' ' || n.nspname || '.' || c.relname || ' IS ''' || replace(d.description, '''', '''''') || ''';'
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  join pg_description d on d.objoid = c.oid and d.objsubid = 0
  where n.nspname = v_curr.obj_schema and c.relname = v_curr.obj_name and d.description is not null;

  insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
  select p_view_schema, p_view_name, 'COMMENT ON COLUMN ' || n.nspname || '.' || c.relname || '.' || a.attname || ' IS ''' || replace(d.description, '''', '''''') || ''';'
  from pg_class c
  join pg_attribute a on c.oid = a.attrelid
  join pg_namespace n on n.oid = c.relnamespace
  join pg_description d on d.objoid = c.oid and d.objsubid = a.attnum
  where n.nspname = v_curr.obj_schema and c.relname = v_curr.obj_name and d.description is not null;
  
  insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
  select p_view_schema, p_view_name, 'GRANT ' || privilege_type || ' ON ' || table_schema || '.' || table_name || ' TO ' || grantee
  from information_schema.role_table_grants
  where table_schema = v_curr.obj_schema and table_name = v_curr.obj_name;
  
  if v_curr.obj_type = 'v' then
    insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    select p_view_schema, p_view_name, 'CREATE VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name || ' AS ' || view_definition
    from information_schema.views
    where table_schema = v_curr.obj_schema and table_name = v_curr.obj_name;
  elsif v_curr.obj_type = 'm' then
    insert into deps_saved_ddl(deps_view_schema, deps_view_name, deps_ddl_to_run)
    select p_view_schema, p_view_name, 'CREATE MATERIALIZED VIEW ' || v_curr.obj_schema || '.' || v_curr.obj_name || ' AS ' || definition
    from pg_matviews
    where schemaname = v_curr.obj_schema and matviewname = v_curr.obj_name;
  end if;
  
  execute 'DROP ' ||
  case 
    when v_curr.obj_type = 'v' then 'VIEW'
    when v_curr.obj_type = 'm' then 'MATERIALIZED VIEW'
  end
  || ' ' || v_curr.obj_schema || '.' || v_curr.obj_name;
  
end loop;
end;
$$
LANGUAGE plpgsql;

create or replace function deps_restore_dependencies(p_view_schema varchar, p_view_name varchar) returns void as
$$
declare
  v_curr record;
begin
for v_curr in 
(
  select deps_ddl_to_run 
  from deps_saved_ddl
  where deps_view_schema = p_view_schema and deps_view_name = p_view_name
  order by deps_id desc
) loop
  execute v_curr.deps_ddl_to_run;
end loop;
delete from deps_saved_ddl
where deps_view_schema = p_view_schema and deps_view_name = p_view_name;
end;
$$
LANGUAGE plpgsql;

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


SELECT deps_save_and_drop_dependencies('public', 'formview_scheduled_msgs');
DROP VIEW formview_scheduled_msgs;
CREATE OR REPLACE VIEW formview_scheduled_msgs AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id,
        doc #>> '{fields,patient_uuid}'              AS patient_id,
        doc #>> '{fields,patient_name}'              AS patient_name,
        doc #>> '{fields,language_preference}'       AS language_preference,
        doc #>  '{tasks}'                            AS tasks,
        doc #>  '{scheduled_tasks}'                  AS scheduled_tasks
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text IN ('scheduled_msgs'::text, 'enroll'::text);
ALTER VIEW formview_scheduled_msgs OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_scheduled_msgs');


SELECT deps_save_and_drop_dependencies('public', 'formview_client_msg');
DROP VIEW formview_client_msg;
CREATE OR REPLACE VIEW formview_client_msg AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc ->> 'from'                               AS from,
        doc ->> 'form'                               AS form,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id,
        doc #>> '{sms_message,message}'              AS message
    FROM couchdb form
    WHERE
        form.doc ->> 'type'::text = 'data_record'::text
        AND form.doc -> 'sms_message' IS NOT NULL
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_client_msg OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_client_msg');


SELECT deps_save_and_drop_dependencies('public', 'formview_0');
DROP VIEW formview_0;
CREATE OR REPLACE VIEW formview_0 AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{from}'                             AS from,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = '0'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_0 OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_0');


SELECT deps_save_and_drop_dependencies('public', 'formview_1');
DROP VIEW formview_1;
CREATE OR REPLACE VIEW formview_1 AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{from}'                             AS from,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = '1'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_1 OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_1');


SELECT deps_save_and_drop_dependencies('public', 'formview_no_contact');
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
        doc #>> '{fields,patient_uuid}'              AS patient_id,
        doc #>> '{fields,patient_name}'              AS patient_name,
        doc #>> '{fields,phone}'                     AS phone,
        doc #>> '{fields,n,client_ok}'               AS client_ok,
        doc #>> '{fields,n,additional_notes}'        AS additional_notes
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'no_contact'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_no_contact OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_no_contact');


SELECT deps_save_and_drop_dependencies('public', 'formview_referral_for_care');
DROP VIEW formview_referral_for_care;
CREATE OR REPLACE VIEW formview_referral_for_care AS 
    SELECT
        doc ->> '_id'                                AS uuid,
        doc ->> 'reported_date'                      AS reported_date,
        to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision)
                                                     AS reported,
        doc #>> '{contact,_id}'                      AS reported_by_id,
        doc #>> '{contact,parent,_id}'               AS reported_by_parent_id,
        doc #>> '{fields,inputs,source}'             AS source,
        doc #>> '{fields,patient_uuid}'              AS patient_id,
        doc #>> '{fields,patient_name}'              AS patient_name,
        doc #>> '{fields,phone}'                     AS phone,
        doc #>> '{fields,n,symptoms_list}'           AS symptoms_list,
        doc #>> '{fields,n,symptoms_other}'          AS symptoms_other,
        doc #>> '{fields,n,additional_notes}'        AS additional_notes
    FROM couchdb form
    WHERE
        form.doc ->> 'form'::text = 'referral_for_care'::text
        AND doc #>> '{contact, parent, _id}' NOT IN ('b16d3190-843d-415b-b8f1-6e37863cbb3d', '6780a6cc-df51-444b-8772-e9965dd96f15', '8e4e16ee-7b2a-49c4-beb0-e5eefc6ca0a0');  -- Chitungwiza District, Pilot, Test Nurse 1's District
ALTER VIEW formview_referral_for_care OWNER TO full_access;
SELECT deps_restore_dependencies('public', 'formview_referral_for_care');


SELECT deps_save_and_drop_dependencies('public', 'formview_client_review');
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
        doc #>> '{fields,patient_uuid}'                               AS patient_id,
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
SELECT deps_restore_dependencies('public', 'formview_client_review');


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
        WHERE c.doc ->> 'patient_id' IN (SELECT uuid from formview_enrollment)
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


DROP FUNCTION IF EXISTS get_dashboard_data(from_date timestamp without time zone, to_date timestamp without time zone);
CREATE OR REPLACE FUNCTION get_dashboard_data(from_date timestamp without time zone default '2020-01-01 00:00:00', to_date timestamp without time zone default '2020-12-31 23:59:59')
RETURNS TABLE(
    uuid text,
    patient_id text,
    name text,
    reported timestamp with time zone,
    vmmc_no text,
    enrollment_date text,
    site_name text,
    all_msgs_count int,
    period_msgs_count int,
    sms1s_count int,
    sms0s_count int,
    free_texts_count int,
    nurse_free_texts_count int,
    ae_count int,
    ae_mild_count int,
    ae_moderate_count int,
    ae_severe_count int,
    ae_other_count int,
    day0 text, day1 text, day2 text, day3 text, day4 text, day5 text, day6 text, day7 text, day8 text, day9 text, day10 text, day11 text, day12 text, day13 text, day14 text,
    system_sent_texts_count int
) AS
$BODY$
    SELECT
        client.uuid                                                    AS uuid,
        client.uuid                                                    AS patient_id,
        client.name                                                    AS name,
        client.reported                                                AS reported,
        client.vmmc_no                                                 AS vmmc_no,
        client.enrollment_date                                         AS enrollment_date,
        site.name                                                      AS site_name,
        COALESCE(client_msg.all_msgs_count, 0)                         AS all_msgs_count,
        COALESCE(client_msg.period_msgs_count, 0)                      AS period_msgs_count,
        COALESCE(client_msg.sms1s_count, 0)                            AS sms1s_count,
        COALESCE(client_msg.sms0s_count, 0)                            AS sms0s_count,
        COALESCE(client_msg.free_texts_count, 0)                       AS free_texts_count,
        COALESCE(nurse_msg.nurse_free_texts_count, 0)                  AS nurse_free_texts_count,
        COALESCE(ae_counts.ae_count, 0)                                AS ae_count,
        COALESCE(ae_counts.mild_count, 0)                              AS ae_mild_count,
        COALESCE(ae_counts.moderate_count, 0)                          AS ae_moderate_count,
        COALESCE(ae_counts.severe_count, 0)                            AS ae_severe_count,
        COALESCE(ae_counts.severity_other_count, 0)                    AS ae_other_count,
        schedule.day0, schedule.day1, schedule.day2, schedule.day3, schedule.day4, schedule.day5, schedule.day6, schedule.day7, schedule.day8, schedule.day9, schedule.day10, schedule.day11, schedule.day12, schedule.day13, schedule.day14,
        COALESCE(system_sent_msg.system_sent_texts_count, 0)           AS system_sent_texts_count
    FROM formview_enrollment client
        LEFT JOIN (
            SELECT
                reported_by_id,
                COUNT(client_msg.uuid)::int       AS all_msgs_count,
                SUM(CASE WHEN client_msg.reported::date BETWEEN client.reported::date AND (client.reported + interval '14 days')::date THEN 1 ELSE 0 END)::int
                                                  AS period_msgs_count,
                SUM(CASE client_msg.form WHEN '1' THEN 1 ELSE 0 END)::int AS sms1s_count,
                SUM(CASE client_msg.form WHEN '0' THEN 1 ELSE 0 END)::int AS sms0s_count,
                SUM(CASE WHEN client_msg.form IS NULL THEN 1 ELSE 0 END)::int AS free_texts_count
            FROM formview_client_msg client_msg
            LEFT JOIN formview_enrollment client ON client.uuid = client_msg.reported_by_id
            GROUP BY reported_by_id
        ) client_msg ON client.uuid = client_msg.reported_by_id
        LEFT JOIN(
            SELECT
                nurse_msg.patient_id        AS patient_id,
                COUNT(uuid)::int            AS nurse_free_texts_count
            FROM useview_scheduled_msgs nurse_msg
            WHERE nurse_msg.type = 'free_text'
            GROUP BY nurse_msg.patient_id
        ) nurse_msg ON client.uuid = nurse_msg.patient_id
        LEFT JOIN(
            SELECT
                system_sent_msg.patient_id        AS patient_id,
                COUNT(uuid)::int            AS system_sent_texts_count
            FROM useview_scheduled_msgs system_sent_msg
            WHERE system_sent_msg.type = 'scheduled' AND system_sent_msg.state IN ('sent', 'delivered')
            GROUP BY system_sent_msg.patient_id
        ) system_sent_msg ON client.uuid = system_sent_msg.patient_id
        LEFT JOIN (
            SELECT * from CROSSTAB($$
                SELECT foo.patient_id, foo.delta::text, foo.sms_received
                FROM (
                    SELECT
                        client.uuid          AS patient_id,
                        schedule.delta       AS delta,
                        CASE
                            WHEN client_msg.form = '1' THEN 'POTENTIAL AE'
                            WHEN client_msg.form = '0' THEN 'NO AE'
                            WHEN COALESCE(client_msg.uuid) IS NOT NULL THEN 'FREE TEXT'
                            ELSE 'NO SMS'
                        END                  AS sms_received
                        FROM
                            formview_enrollment client
                            CROSS JOIN (SELECT delta FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14)) days(delta)) schedule
                            LEFT JOIN formview_client_msg client_msg ON client_msg.reported_by_id = client.uuid AND (client.reported + (interval '1 day' * schedule.delta))::date = client_msg.reported::date
                        ORDER BY 1, schedule.delta) foo
                    $$) t(patient_id text, day0 text, day1 text, day2 text, day3 text, day4 text, day5 text, day6 text, day7 text, day8 text, day9 text, day10 text, day11 text, day12 text, day13 text, day14 text)

        ) schedule ON client.uuid = schedule.patient_id
        LEFT JOIN contactview_metadata site ON site.uuid = client.parent_uuid
        LEFT JOIN (
            SELECT patient_id,
            SUM(CASE ae_positive WHEN 'yes' THEN 1 ELSE 0 END)::int         AS ae_count,
            SUM(CASE ae_severity WHEN 'mild' THEN 1 ELSE 0 END)::int        AS mild_count,
            SUM(CASE ae_severity WHEN 'moderate' THEN 1 ELSE 0 END)::int    AS moderate_count,
            SUM(CASE ae_severity WHEN 'severe' THEN 1 ELSE 0 END)::int      AS severe_count,
            SUM(CASE ae_severity WHEN 'other' THEN 1 ELSE 0 END)::int       AS severity_other_count
            FROM formview_client_review
            GROUP BY patient_id
        ) ae_counts ON ae_counts.patient_id = client.uuid
        WHERE client.vmmc_no <> '';
$BODY$
LANGUAGE 'sql' STABLE;
ALTER FUNCTION get_dashboard_data(from_date timestamp without time zone, to_date timestamp without time zone) OWNER TO full_access;

