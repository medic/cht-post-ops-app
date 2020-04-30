touch bootstrap.sql

> bootstrap.sql

echo " -- GENERATED "$(date +%FT%T.%N) >> bootstrap.sql

printf "\n\n" >> bootstrap.sql

# echo "-- 0_1_client_response_reports.sql" >> bootstrap.sql
# cat 0_1_client_response_reports.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- 0_1_potential_ae_combined.sql" >> bootstrap.sql
# cat 0_1_potential_ae_combined.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- confirm_clinic_reports.sql" >> bootstrap.sql
# cat confirm_clinic_reports.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

echo "-- confirm_clinic_visit.sql" >> bootstrap.sql
cat confirm_clinic_visit.sql >> bootstrap.sql
printf "\n\n" >> bootstrap.sql

echo "-- get_dashboard_data_active.sql" >> bootstrap.sql
cat get_dashboard_data_active.sql >> bootstrap.sql
printf "\n\n" >> bootstrap.sql

# echo "-- potential_ae_reports.sql" >> bootstrap.sql
# cat potential_ae_reports.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- reports_submitted_same_day.sql" >> bootstrap.sql
# cat reports_submitted_same_day.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- visits_data.sql" >> bootstrap.sql
# cat visits_data.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- vmmc_clients_data_dump.sql" >> bootstrap.sql
# cat vmmc_clients_data_dump.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

echo "-- zazic_useviews.sql" >> bootstrap.sql
cat zazic_useviews.sql >> bootstrap.sql
printf "\n\n" >> bootstrap.sql

echo "-- zazic_analytics_improved.sql" >> bootstrap.sql
cat zazic_analytics_improved.sql >> bootstrap.sql
printf "\n\n" >> bootstrap.sql

# echo "-- zazic_analytics.sql" >> bootstrap.sql
# cat zazic_analytics.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- zazic_collapsed.sql" >> bootstrap.sql
# cat zazic_collapsed.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

# echo "-- zazic_week_msgs_analytics.sql" >> bootstrap.sql
# cat zazic_week_msgs_analytics.sql >> bootstrap.sql
# printf "\n\n" >> bootstrap.sql

