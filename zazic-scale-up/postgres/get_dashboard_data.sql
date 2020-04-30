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
    day0 text, day1 text, day2 text, day3 text, day4 text, day5 text, day6 text, day7 text, day8 text, day9 text, day10 text, day11 text, day12 text, day13 text, day14 text
) AS
$BODY$
    SELECT
        client.uuid                                                    AS uuid,
        client.patient_id                                              AS patient_id,
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
        schedule.day0, schedule.day1, schedule.day2, schedule.day3, schedule.day4, schedule.day5, schedule.day6, schedule.day7, schedule.day8, schedule.day9, schedule.day10, schedule.day11, schedule.day12, schedule.day13, schedule.day14
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
        ) nurse_msg ON client.patient_id = nurse_msg.patient_id
        LEFT JOIN (
            SELECT * from CROSSTAB($$
                SELECT foo.patient_id, foo.delta::text, foo.sms_received
                FROM (
                    SELECT
                        client.patient_id    AS patient_id,
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

        ) schedule ON client.patient_id = schedule.patient_id
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
        ) ae_counts ON ae_counts.patient_id = client.uuid;
$BODY$
LANGUAGE 'sql' STABLE;
ALTER FUNCTION get_dashboard_data(from_date timestamp without time zone, to_date timestamp without time zone) OWNER TO full_access;

