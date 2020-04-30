 -- GENERATED 2020-03-19T13:01:42.388175967


-- confirm_clinic_visit.sql
CREATE OR REPLACE VIEW public.confirm_clinic_visit
AS SELECT c.doc ->> '_id'::text AS uuid,
    replace((c.doc #> '{fields,patient_id}'::text[])::text, '"'::text, ''::text) AS patient_id,
    replace((c.doc #> '{fields,return}'::text[])::text, '"'::text, ''::text) AS return,
    replace((c.doc #> '{fields,visit_date}'::text[])::text, '"'::text, ''::text) AS visit_date,
    replace((c.doc #> '{fields,trace}'::text[])::text, '"'::text, ''::text) AS followup_method,
    replace((c.doc #> '{fields,explanation}'::text[])::text, '"'::text, ''::text) AS client_return,
    replace((c.doc #> '{fields,comments}'::text[])::text, '"'::text, ''::text) AS comments,
    to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), 'yyyy-MM-dd'::text) AS reported_date
   FROM couchdb c
  WHERE (c.doc ->> 'form'::text) = 'referral_confirmation'::text AND (replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text) = 'b16d3190-843d-415b-b8f1-6e37863cbb3d'::text OR replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text) = '6780a6cc-df51-444b-8772-e9965dd96f15'::text) AND lower(replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text)) !~~ '%fake%'::text;

-- Permissions

ALTER TABLE public.confirm_clinic_visit OWNER TO full_access;
GRANT ALL ON TABLE public.confirm_clinic_visit TO full_access;


-- get_dashboard_data_active.sql
/* ###########################################*/
/* ########## Nepas Zazic - SMS ENGAGEMENT ########*/
/* ###########################################*/

/*
Steps included in this script
- create function get_dashboard_data_active
*/


/* Notes:

Modified - disagg. by district hospital

*/


DROP FUNCTION IF EXISTS get_dashboard_data_active(param_facility_group_by text, param_num_units text, param_interval_unit text, param_include_current boolean);
CREATE FUNCTION get_dashboard_data_active(param_facility_group_by text, param_num_units text default '12', param_interval_unit text default 'month', param_include_current boolean default 'true')

	RETURNS TABLE(
				district_hospital_uuid text,
				district_hospital_name text,
				health_center_uuid text,
				health_center_name text,
				clinic_uuid text,
				clinic_name text,
				period_start date,
				period_start_epoch numeric,
				facility_join_field text,	
				count_reported_by numeric,
				count_any_interaction numeric,
				count_total_forms numeric,
				count_error_forms numeric		
	) AS
	
$BODY$

	WITH period_CTE AS
		(
			SELECT generate_series(date_trunc(param_interval_unit,
				now() - (param_num_units||' '||param_interval_unit)::interval), 
									
				CASE
					WHEN param_include_current 
					THEN now() 
					ELSE now() - ('1 ' || param_interval_unit)::interval
				END, 
									
				('1 '||param_interval_unit)::interval
		)::date AS start
		)
	
--######################
--MAIN QUERY STARTS HERE
--######################

SELECT

	CASE
		WHEN param_facility_group_by = 'clinic' OR param_facility_group_by = 'health_center' OR param_facility_group_by = 'district_hospital'
		THEN place_period.district_hospital_uuid
		ELSE 'All'
	END AS _district_hospital_uuid,	
	CASE
		WHEN param_facility_group_by = 'clinic' OR param_facility_group_by = 'health_center' OR param_facility_group_by = 'district_hospital'
		THEN place_period.district_hospital_name
		ELSE 'All'
	END AS _district_hospital_name,
	
	CASE
		WHEN param_facility_group_by = 'clinic' OR param_facility_group_by = 'health_center'
		THEN 'All'
		ELSE 'All'
	END AS _health_center_uuid,			
	CASE
		WHEN param_facility_group_by = 'clinic' OR param_facility_group_by = 'health_center'
		THEN 'All'
		ELSE 'All'
	END AS _health_center_name,
		
	CASE
		WHEN param_facility_group_by = 'clinic'
		THEN 'All'
		ELSE 'All'
	END AS _clinic_uuid,
	CASE
		WHEN param_facility_group_by = 'clinic'
		THEN 'All'
		ELSE 'All'
	END AS _clinic_name,

	place_period.period_start AS _period_start,
	date_part('epoch',place_period.period_start)::numeric AS _period_start_epoch,
	
	CASE
		WHEN param_facility_group_by = 'district_hospital'
			THEN place_period.district_hospital_uuid
		ELSE
			'All'
	END AS _facility_join_field,
	SUM(COALESCE(district_hospital.count_reported_by,0)) AS count_reported_by,
	SUM(COALESCE(district_hospital.count_any_interaction,0)) AS count_any_interaction,
	SUM(COALESCE(district_hospital.count_total_forms,0)) AS count_total_forms,
	SUM(COALESCE(district_hospital.count_error_forms,0)) AS count_error_forms
	
	
FROM
	(
		SELECT
			district_hospital.uuid AS district_hospital_uuid,
			district_hospital.name AS district_hospital_name,
			--health_center.uuid AS health_center_uuid,
			--health_center.name AS health_center_name
			--chw.uuid AS chw_uuid,
			--chw.name AS chw_name
			period_CTE.start AS period_start
			
		FROM
			period_CTE,	
			--contactview_metadata AS chw 
			--INNER JOIN 
			contactview_metadata AS district_hospital 
			--ON (chw.parent_uuid = district_hospital.uuid)
					
		WHERE
			district_hospital.type ='district_hospital' 
			AND district_hospital.parent_uuid IS NULL
						 	
	) AS place_period
	
	
LEFT JOIN /* CHWs Engagement */
	
	(
SELECT
			doc#>>'{contact,parent,_id}' AS reported_by_parent,
			--doc #>> '{contact,_id}' AS reported_by,
			date_trunc(param_interval_unit,to_timestamp((NULLIF(doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision))::date AS period_reported,
			count(distinct(doc#>>'{contact,_id}')) AS count_reported_by,
			count(*) AS count_any_interaction,
			
				SUM(
					CASE
						WHEN doc ? 'form' AND (doc->>'form') IS NOT NULL 
						THEN 1
						ELSE 0
					END
				) AS count_total_forms,
				
				SUM(
					CASE
						WHEN doc ? 'form' AND (doc->>'form') IS NOT NULL AND (doc->>'errors') = '[]'
						THEN 1
						ELSE 0
					END
				) AS count_valid_forms,
				
				SUM(
					CASE
						WHEN doc ? 'form' AND (doc->>'form') IS NOT NULL AND (doc->>'errors') <> '[]'
						THEN 1
						ELSE 0
					END
				) AS count_error_forms
		
		FROM
			couchdb
			--INNER JOIN contactview_metadata AS contact ON (contact.uuid = doc#>>'{contact,_id}')
			--INNER JOIN contactview_metadata AS parent ON (parent.uuid = doc#>>'{contact,parent,_id}')
	
			
		WHERE
			doc->>'type' = 'data_record'
			AND (doc#>>'{contact,_id}') IS NOT NULL
			AND (doc#>>'{contact,parent,_id}') IS NOT NULL
			--AND parent.type = 'district_hospital'
			
		GROUP BY
			period_reported,
			reported_by_parent

				
		) AS district_hospital ON (place_period.period_start = district_hospital.period_reported AND place_period.district_hospital_uuid = district_hospital.reported_by_parent)
																												
		
GROUP BY
		
	_district_hospital_uuid,
	_district_hospital_name,
	_health_center_uuid,
	_health_center_name,
	_clinic_uuid,
	_clinic_name,
	_period_start,
	_period_start_epoch,
	_facility_join_field
		
ORDER BY
	
	_district_hospital_name,
	_health_center_name,
	_clinic_name,
	_period_start	
			
$BODY$
LANGUAGE 'sql' STABLE;
ALTER FUNCTION get_dashboard_data_active(text,text,text,boolean) OWNER TO full_access;


-- zazic_useviews.sql
DROP MATERIALIZED VIEW IF EXISTS people;
CREATE MATERIALIZED VIEW people
AS SELECT c.doc ->> '_id'::text AS uuid,
    initcap(replace(c.doc ->> 'name'::text, '"'::text, ''::text)) AS name,
    initcap(replace(c.doc ->> 'patient_id'::text, '"'::text, ''::text)) AS patient_id,
    replace((c.doc #> '{parent,_id}'::text[])::text, '"'::text, ''::text) AS parent,
    initcap(replace(c.doc ->> 'phone'::text, '"'::text, ''::text)) AS phone,
    to_timestamp((NULLIF(c.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision) AS enrollment_date,
    to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), 'dd-MM-yyyy'::text) AS enrollment_date_format1,
    to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), 'yyyy-MM-dd'::text) AS enrollment_date_format2,
    initcap(replace(c.doc ->> 'language_preference'::text, '"'::text, ''::text)) AS language_p,
    initcap(replace(c.doc ->> 'vmmc_no'::text, '"'::text, ''::text)) AS vmmc_no,
    initcap(replace(c.doc ->> 'study_no'::text, '"'::text, ''::text)) AS study_no,
    initcap(replace(c.doc ->> 'randomization'::text, '"'::text, ''::text)) AS randomization,
    initcap(replace(c.doc ->> 'mobile_company'::text, '"'::text, ''::text)) AS mobile_company
   FROM couchdb c
  WHERE (c.doc ->> 'type'::text) = 'person'::text
  and (replace((c.doc #> '{parent,_id}'::text[])::text, '"'::text, ''::text) = 'b16d3190-843d-415b-b8f1-6e37863cbb3d'
  			OR
  	    replace((c.doc #> '{parent,_id}'::text[])::text, '"'::text, ''::text) = '6780a6cc-df51-444b-8772-e9965dd96f15'
    	)
       and LOWER(initcap(replace(c.doc ->> 'name'::text, '"'::text, ''::text))) NOT LIKE '%fake%'
  ;

CREATE UNIQUE INDEX people_uuid ON people USING btree (uuid);
ALTER MATERIALIZED VIEW public.people OWNER TO full_access;
GRANT ALL ON MATERIALIZED VIEW public.people TO full_access;


-- zazic_analytics_improved.sql
DROP MATERIALIZED VIEW vmmc_clients_data;
CREATE MATERIALIZED VIEW vmmc_clients_data AS
select a.uuid,a.name,a.randomization,a.phone,a.enrollment_date,a.enrollment_date_format1,a.enrollment_date_format2,a.language_p, 
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN j.formname = '1' THEN 'Potential AE' WHEN j.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_1,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  v.formname = '1' THEN 'Potential AE' WHEN v.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_2,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN b.patient_id IS NULL THEN 'No' ELSE 'Yes' END AS day_2_sms_received,
  date_part('day',age(b.reported_date::date, a.enrollment_date_format2::date))::INT -2 as day_2_sms_after_x_days,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  k.formname = '1' THEN 'Potential AE' WHEN k.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_3,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  l.formname = '1' THEN 'Potential AE' WHEN l.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_4,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  m.formname = '1' THEN 'Potential AE' WHEN m.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_5,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  n.formname = '1' THEN 'Potential AE' WHEN n.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_6,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  w.formname = '1' THEN 'Potential AE' WHEN w.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_7,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  d.patient_id IS NULL THEN 'No' ELSE 'Yes' END AS day_7_sms_received,
  date_part('day',age(d.reported_date::date, a.enrollment_date_format2::date))::INT -7 as day_7_sms_after_x_days,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  p.formname = '1' THEN 'Potential AE' WHEN p.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_8,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  q.formname = '1' THEN 'Potential AE' WHEN q.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_9,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  r.formname = '1' THEN 'Potential AE' WHEN r.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_10,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  s.formname = '1' THEN 'Potential AE' WHEN s.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_11,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  t.formname = '1' THEN 'Potential AE' WHEN t.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_12,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  u.formname = '1' THEN 'Potential AE' WHEN u.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_13,
  CASE WHEN a.randomization = 'Routine' THEN 'N/A' WHEN  x.formname = '1' THEN 'Potential AE' WHEN x.formname = '0' THEN 'NO AE' ELSE 'NO SMS' END AS day_14,
  CASE WHEN e.patient_id IS NULL THEN 'No' ELSE 'Yes' END AS day_14_client_visit,
  CASE WHEN f.ae_reported_forms IS NULL THEN 0 ELSE f.ae_reported_forms END AS sms_suspected_ae,
  CASE WHEN g.all_submitted_reports IS NULL THEN 0 ELSE g.all_submitted_reports END AS total_number_of_responses_per_person,
  CASE WHEN a.parent = 'b16d3190-843d-415b-b8f1-6e37863cbb3d' THEN 'Main Study' WHEN a.parent = '6780a6cc-df51-444b-8772-e9965dd96f15' THEN 'Pilot Study' ELSE 'Test People' END AS which_study
from (SELECT 
    p.uuid,p.name,p.phone,p.enrollment_date_format1,p.enrollment_date_format2,p.enrollment_date,p.language_p,p.randomization,p.parent
  FROM people p
    WHERE 
      p.uuid != '06f2b862-5b10-464e-ad7f-a162c8da1e2c'
) a
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')	
) j
ON a.uuid = j.patient_id AND to_char((a.enrollment_date + interval '1 day'), 'dd-MM-yyyy') = j.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) v
ON a.uuid = v.patient_id AND to_char((a.enrollment_date + interval '2 day'), 'dd-MM-yyyy') = v.reported_date
LEFT JOIN 
(
  SELECT 
replace((doc #> '{fields, patient_id}')::text, '"', '') AS "patient_id",
to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date', '')::BIGINT)/1000), 'yyyy-MM-dd') as reported_date
 FROM couchdb c
    WHERE 
    doc ->> 'form' = 'day2_sms'
      AND doc ->> 'type' = 'data_record'
) b
ON a.uuid = b.patient_id
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) k
ON a.uuid = k.patient_id AND to_char((a.enrollment_date + interval '3 day'), 'dd-MM-yyyy') = k.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) l
ON a.uuid = l.patient_id AND to_char((a.enrollment_date + interval '4 day'), 'dd-MM-yyyy') = l.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) m
ON a.uuid = m.patient_id AND to_char((a.enrollment_date + interval '5 day'), 'dd-MM-yyyy') = m.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) n
ON a.uuid = n.patient_id AND to_char((a.enrollment_date + interval '6 day'), 'dd-MM-yyyy') = n.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) w
ON a.uuid = w.patient_id AND to_char((a.enrollment_date + interval '7 day'), 'dd-MM-yyyy') = w.reported_date
LEFT JOIN
(
  SELECT 
  replace((doc #> '{fields, patient_id}')::text, '"', '') AS "patient_id",
  to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date', '')::BIGINT)/1000), 'yyyy-MM-dd') as reported_date
  FROM couchdb c
    WHERE 
    doc ->> 'form' = 'day7_sms'
      AND doc ->> 'type' = 'data_record'
) d

ON a.uuid = d.patient_id
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) p
ON a.uuid = p.patient_id AND to_char((a.enrollment_date + interval '8 day'), 'dd-MM-yyyy') = p.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) q
ON a.uuid = q.patient_id AND to_char((a.enrollment_date + interval '9 day'), 'dd-MM-yyyy') = q.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) r
ON a.uuid =r.patient_id AND to_char((a.enrollment_date + interval '10 day'), 'dd-MM-yyyy') = r.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) s
ON a.uuid =s.patient_id AND to_char((a.enrollment_date + interval '11 day'), 'dd-MM-yyyy') = s.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) t
ON a.uuid =t.patient_id AND to_char((a.enrollment_date + interval '12 day'), 'dd-MM-yyyy') = t.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) u
ON a.uuid =u.patient_id AND to_char((a.enrollment_date + interval '13 day'), 'dd-MM-yyyy') = u.reported_date
LEFT JOIN
(
   SELECT 
    fm.chw AS patient_id,
    to_char(fm.reported, 'dd-MM-yyyy') as reported_date,
    fm.formname as formname
    FROM form_metadata fm
    WHERE 
        (fm.formname = '1'
        OR
        fm.formname = '0')
) x
ON a.uuid = x.patient_id AND to_char((a.enrollment_date + interval '14 day'), 'dd-MM-yyyy') = x.reported_date
LEFT JOIN
(
    SELECT 
  replace((doc #> '{fields, patient_id}')::text, '"', '') AS "patient_id"
  FROM couchdb c
    WHERE 
    doc ->> 'form' = 'day14_client_visit'
      AND doc ->> 'type' = 'data_record'
) e

ON a.uuid = e.patient_id
LEFT JOIN
(
  SELECT
  fm.chw AS patient_id,
  count(*) as ae_reported_forms
    FROM form_metadata fm
    WHERE 
        fm.formname = '1'
    GROUP BY fm.chw
) f
ON a.uuid = f.patient_id
LEFT JOIN
(
 SELECT
  fm.chw AS patient_id,
  count(*) as all_submitted_reports
    FROM form_metadata fm
    WHERE 
        fm.formname = '1'
        OR 
         fm.formname = '0'
    GROUP BY fm.chw
) g
ON a.uuid = g.patient_id
GROUP BY uuid,name,randomization,phone,enrollment_date,enrollment_date_format1,enrollment_date_format2,language_p, day_1, day_2, day_2_sms_received, day_2_sms_after_x_days, day_3, day_4, day_5, day_6, day_7, day_7_sms_received, day_7_sms_after_x_days, day_8, day_9, day_10, day_11, day_12, day_13, day_14, day_14_client_visit, sms_suspected_ae, total_number_of_responses_per_person, which_study
;

DROP INDEX IF EXISTS vmmc_clients_data_uuid;
CREATE UNIQUE INDEX vmmc_clients_data_uuid ON vmmc_clients_data USING btree (uuid,name,randomization,phone,enrollment_date,enrollment_date_format1,enrollment_date_format2,language_p, day_1, day_2, day_2_sms_received, day_2_sms_after_x_days, day_3, day_4, day_5, day_6, day_7, day_7_sms_received, day_7_sms_after_x_days, day_8, day_9, day_10, day_11, day_12, day_13, day_14, day_14_client_visit, sms_suspected_ae, total_number_of_responses_per_person, which_study);
ALTER MATERIALIZED VIEW public.vmmc_clients_data OWNER TO full_access;
GRANT ALL ON TABLE public.vmmc_clients_data TO full_access;


DROP VIEW IF EXISTS client_visit;
CREATE VIEW client_visit AS
SELECT 
c.doc ->> '_id' as uuid,
replace((c.doc #> '{fields,patient_id}'::text[])::text, '"'::text, ''::text) AS patient_id,
    replace((c.doc #> '{fields,visit}'::text[])::text, '"'::text, ''::text) AS visit,
    replace((c.doc #> '{fields,ae_severity}'::text[])::text, '"'::text, ''::text) AS ae_severity,
      replace((c.doc #> '{fields,patient_name}'::text[])::text, '"'::text, ''::text) AS client_name,
    replace((c.doc #> '{fields,phone}'::text[])::text, '"'::text, ''::text) AS client_phone_no,
    replace((c.doc #> '{fields,phone_credit}'::text[])::text, '"'::text, ''::text) AS phone_credit,
    replace((c.doc #> '{fields,explanation}'::text[])::text, '"'::text, ''::text) AS why_no_phone_credit,
    replace((c.doc #> '{fields,comments}'::text[])::text, '"'::text, ''::text) AS comments,
    replace((c.doc #> '{fields,visit_date}'::text[])::text, '"'::text, ''::text) AS visit_date_filled,
    to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), 'yyyy-MM-dd'::text) AS reported_date
   FROM couchdb c
  WHERE (c.doc ->> 'form'::text) = 'client_visit'::text 
  AND 
  (replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text) = 'b16d3190-843d-415b-b8f1-6e37863cbb3d'::text 
  OR 
  replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text) = '6780a6cc-df51-444b-8772-e9965dd96f15'::text) 
  AND 
  lower(replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text)) !~~ '%fake%'::text
  AND
  replace((c.doc #> '{fields,patient_id}'::text[])::text, '"'::text, ''::text) != ''
UNION

SELECT 
c.doc ->> '_id' as uuid,
replace((c.doc #> '{fields,patient_id}'::text[])::text, '"'::text, ''::text) AS patient_id,
    'day14'::text AS visit,
    replace((c.doc #> '{fields,ae_severity}'::text[])::text, '"'::text, ''::text) AS ae_severity,
      replace((c.doc #> '{fields,patient_name}'::text[])::text, '"'::text, ''::text) AS client_name,
    	replace((c.doc #> '{fields,phone}'::text[])::text, '"'::text, ''::text) AS client_phone_no,
     replace((c.doc #> '{fields,phone_credit}'::text[])::text, '"'::text, ''::text) AS phone_credit,
      replace((c.doc #> '{fields,explanation}'::text[])::text, '"'::text, ''::text) AS why_no_phone_credit,
      replace((c.doc #> '{fields,comments}'::text[])::text, '"'::text, ''::text) AS comments,
        replace((c.doc #> '{fields,visit_date}'::text[])::text, '"'::text, ''::text) AS visit_date_filled,
    to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date'::text, ''::text)::bigint / 1000)::double precision), 'yyyy-MM-dd'::text) AS reported_date
   FROM couchdb c
  WHERE (c.doc ->> 'form'::text) = 'day14_client_visit'::text 
  AND 
  (replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text) = 'b16d3190-843d-415b-b8f1-6e37863cbb3d'::text  
  OR replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text) = '6780a6cc-df51-444b-8772-e9965dd96f15'::text) 
  AND 
  lower(replace((c.doc #> '{contact,parent,_id}'::text[])::text, '"'::text, ''::text)) !~~ '%fake%'::text
  AND
  replace((c.doc #> '{fields,patient_id}'::text[])::text, '"'::text, ''::text) != ''
;
ALTER TABLE public.client_visit OWNER TO full_access;
GRANT ALL ON TABLE public.client_visit TO full_access;
GRANT ALL ON TABLE public.client_visit TO full_access;


DROP VIEW IF EXISTS potential_ae;
CREATE VIEW potential_ae AS
SELECT 
doc ->>'_id' as uuid,
replace((doc #> '{fields, patient_id}')::text, '"', '') AS "patient_id",
replace((doc #> '{fields, n, days_post_mc}')::text, '"', '') AS "days_post_mc",
replace((doc #> '{fields, n, symptoms}')::text, '"', '') AS "symptoms",
  replace((doc #> '{fields, n, followup_request}')::text, '"', '') AS "followup_request",
    replace((doc #> '{fields, n,followup_method}')::text, '"', '') AS "followup_method",
      replace((doc #> '{fields, n,ae}')::text, '"', '') AS "ae",
        replace((doc #> '{fields, n,info}')::text, '"', '') AS "info",
      replace((doc #> '{fields, n,client_return}')::text, '"', '') AS "client_return",
        replace((doc #> '{fields, n,explanation}')::text, '"', '') AS "explanation",
to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date', '')::BIGINT)/1000), 'yyyy-MM-dd') as reported_date
 FROM couchdb c
    WHERE 
    doc ->> 'form' = 'potential_ae'
    AND 
    (
      replace((doc #> '{contact, parent, _id}')::text, '"', '') = 'b16d3190-843d-415b-b8f1-6e37863cbb3d' 
        OR
      replace((doc #> '{contact, parent, _id}')::text, '"', '') = '6780a6cc-df51-444b-8772-e9965dd96f15' 
    ) 
    AND LOWER(replace((doc #> '{contact, parent, _id}')::text, '"', '')) NOT LIKE '%fake%'
    ;

DROP VIEW IF EXISTS clients_free_text;
CREATE VIEW clients_free_text AS
SELECT 
doc ->>'_id' as uuid,
replace((doc #> '{contact, _id}')::text, '"', '') AS patient_id,
to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date', '')::BIGINT)/1000), 'yyyy-MM-dd') as reported_date,
replace((doc #> '{sms_message, message}')::text, '"', '') as message_contents
 FROM couchdb c
    WHERE 
    doc ->>'form' IS NULL
    AND (doc #> '{sms_message, from}')::text IS NOT NULL
    AND  doc ->> 'type' = 'data_record'
    AND doc ->> 'errors' = '[]'
    AND (doc #> '{contact, _id}')::text IS NOT NULL
    AND 
      (
        replace((doc #> '{contact, parent, _id}')::text, '"', '') = 'b16d3190-843d-415b-b8f1-6e37863cbb3d' 
        OR
        replace((doc #> '{contact, parent, _id}')::text, '"', '') = '6780a6cc-df51-444b-8772-e9965dd96f15'
      )
    AND LOWER(replace((doc #> '{contact, parent, _id}')::text, '"', '')) NOT LIKE '%fake%'
    ;

DROP VIEW IF EXISTS nurses_free_text;
CREATE VIEW nurses_free_text AS
SELECT 
doc ->>'_id' as uuid,
replace((doc->>'sent_by'::text)  , '"', '') AS nurse_username,
replace((doc #> '{tasks, 0, messages, 0, contact, _id}')::text, '"', '') as patient_id,
to_char(to_timestamp((NULLIF(c.doc ->> 'reported_date', '')::BIGINT)/1000), 'yyyy-MM-dd') as reported_date
 FROM couchdb c
    WHERE 
    doc ->>'form' IS NULL
    AND doc->>'sent_by'  IS NOT NULL
    AND  doc ->> 'type' = 'data_record'
    AND doc ->> 'errors' = '[]'
    AND  doc ->> 'kujua_message' IS NOT NULL
    AND 
      (
        replace((doc #> '{tasks, 0, messages, 0, contact, parent,_id}')::text, '"', '') = 'b16d3190-843d-415b-b8f1-6e37863cbb3d' 
        OR
        replace((doc #> '{contact, parent, _id}')::text, '"', '') = '6780a6cc-df51-444b-8772-e9965dd96f15'
      ) 
    AND 
    EXISTS(SELECT name FROM people WHERE uuid = (replace((doc #> '{tasks, 0, messages, 0, contact, _id}')::text, '"', '')) LIMIT 1)
    ;

