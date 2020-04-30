WITH schedule_report AS (
    SELECT
    uuid, tasks, scheduled_tasks
    FROM formview_scheduled_msgs
),
task AS (
    SELECT
    jsonb_array_elements(tasks) AS task
    FROM schedule_report
),
scheduled_task AS (
    SELECT
    jsonb_array_elements(scheduled_tasks) AS task
    FROM schedule_report
),
auto_response as (
    SELECT
        a.task -> 'due' as due,
        a.task -> 'type' as schedule,
        a.task -> 'messages' -> 0 -> 'to' as recipient,
        a.task -> 'messages' -> 0 -> 'uuid' as message_uuid,
        a.task -> 'messages' -> 0 -> 'message' as message,
        a.task -> 'state_history' -> -1 -> 'state' as state,
        a.task -> 'state_history' -> -1 -> 'timestamp' as timestamp,
        'auto_response'::text as type
    FROM task a
),
scheduled_msg AS (
    SELECT
        a.task -> 'due' as due,
        a.task -> 'type' as schedule,
        a.task -> 'messages' -> 0 -> 'to' as recipient,
        a.task -> 'messages' -> 0 -> 'uuid' as message_uuid,
        a.task -> 'messages' -> 0 -> 'message' as message,
        a.task -> 'state_history' -> -1 -> 'state' as state,
        a.task -> 'state_history' -> -1 -> 'timestamp' as timestamp,
        'scheduled'::text as type
    FROM scheduled_task a
)
SELECT * FROM auto_response
UNION
SELECT * FROM scheduled_msg;

