DROP VIEW formview_0.sql;
CREATE OR REPLACE VIEW formview_0.sql AS 
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
        AND doc #>> '{contact, parent, _id}' = '00c7c0bd-f01f-44b2-9fbe-48c4e12c6fc7';  -- Boom Clinic
ALTER VIEW formview_0.sql OWNER TO full_access;
