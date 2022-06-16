---
sectionid: testsetup
sectionclass: h2
title: Test setup
parent-id: pgBadger
---


`CREATE TABLE status (status int);
INSERT INTO status SELECT 1;`
CREATE FUNCTION dummy(out a int)
    AS $$
SELECT count(*) FROM (
SELECT rates.description, COUNT(vendor_id) AS num_trips,
   AVG(dropoff_datetime - pickup_datetime) AS avg_trip_duration, AVG(total_amount) AS avg_total,
   AVG(tip_amount) AS avg_tip, MIN(trip_distance) AS min_distance, AVG (trip_distance) AS avg_distance, MAX(trip_distance) AS max_distance,
   AVG(passenger_count) AS avg_passengers
 FROM rides
 JOIN rates ON rides.rate_code = rates.rate_code
 WHERE rides.rate_code IN (2,3) AND pickup_datetime < '2016-02-01'
 GROUP BY rates.description
 ORDER BY rates.description) k
 $$
    LANGUAGE SQL;


for i in {1..10000}; do psql -f 01.sql nyc>/dev/null; done

for i in {1..10000}; do psql -f 02.sql nyc>/dev/null; done
cut -f9- -d\: PT1H.json | cut -f1 -d\} | sed -e 's/^."//' -e 's/"$//' > 01
cat 01| sed 's/\\n/\n/g'>02
cat 02| sed 's/\\"/"/g'>03


/usr/local/bin/pgbadger --prefix='%t %p %l-1 db-%d,user-%u,app-%a,client-%h ' 03