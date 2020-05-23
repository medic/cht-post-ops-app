touch bootstrap.sql

> bootstrap.sql

echo " -- GENERATED "$(date +%FT%T.%N) >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat object_dependecy_delete_and_restore.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_enrollment.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_scheduled_msgs.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_client_msg.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_0.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_1.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_no_contact.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_referral_for_care.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat formview_client_review.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat useview_scheduled_msgs.sql >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

cat get_dashboard_data.sql >> bootstrap.sql

