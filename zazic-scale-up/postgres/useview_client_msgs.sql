SELECT
    doc -> ''
FROM formview_enrollment client
LEFT JOIN formview_0 no_ae ON client.uuid = no_ae.reported_by_id
LEFT JOIN formview_1 potential_ae ON clietn.uuid = potential_ae.reported_by_id;
