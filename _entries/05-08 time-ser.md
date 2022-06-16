---
sectionid: timeser
sectionclass: h2
title: Time-series database on PostgreSQL
parent-id: day2
---

# TimescaleDB -> postgreSQL extention
## What is Timescale-DB

Timescale-DB is an open-source relational database for time-series data. It uses full SQL and is just as easy to use as a traditional relational database, yet scales in ways previously reserved for NoSQL databases. 
Timescale-DB is a category-defining relational database for time-series data. Packaged as a PostgreSQL extension, Timescale-DB is designed to be easy to use, easy to get started, and easy to maintain. All your PostgreSQL knowledge and tools should just work.
In Azure Timescale-DB can be added only to Azure PostgreSQL Single Server.
So, What is really Time Scale DB that we keep talking about, and how and why is it different from other data?
Many applications or databases actually take an overly narrow view, and equate time-series data with something like server metrics of a specific form:

|Date	            | Val|
|-------------------|----|
|2018-01-01 01:01:00| 23 |
|2018-01-01 01:02:00| 34 |
|2018-01-01 01:03:01| 56 |

But in fact, in many monitoring applications, different metrics are often collected together (e.g., CPU, memory, network statistics, battery life). So, it does not always make sense to think of each metric separately. Consider this alternative "wider" data model that maintains the correlation between metrics collected at the same time.

|Date	            |Val#1|Val#2|Val#3|Val#4|
|-------------------|-----|-----|-----|-----|
|2018-01-01 01:01:00|	23| 678	| -63 | 12  |
|2018-01-01 01:02:00|	34| 435	| -98 | 13  |
|2018-01-01 01:03:01|	56| 678	| -90 | 14  |

This type of data belongs in a much **broader** category, whether temperature readings from a sensor, the price of a stock, the status of a machine, or even the number of logins to an app.
**Time-series data is data that collectively represents how a system, process, or behavior changes over time.**

## Time-series data is everywhere
Time-series data is everywhere, but there are environments where it is especially being created in torrents.
* **Monitoring computer systems:** VM, server, container metrics (CPU, free memory, net/disk IOPs), service and application metrics (request rates, request latency).
* **Financial trading systems:** Classic securities, newer cryptocurrencies, payments, transaction events.
* **Internet of Things:** Data from sensors on industrial machines and equipment, wearable devices, vehicles, physical containers, pallets, consumer devices for smart homes, etc.
* **Eventing applications:** User/customer interaction data like clickstreams, pageviews, logins, signups, etc.
* **Business intelligence:** Tracking key metrics and the overall health of the business.
* **Environmental monitoring:** Temperature, humidity, pressure, pH, pollen count, air flow, carbon monoxide (CO), nitrogen dioxide (NO2), particulate matter (PM10).

## Characteristics of time-series data
If you look closely at how it’s produced and ingested, there are important characteristics that time-series databases like TimescaleDB typically leverage:
* **Time-centric:** Data records always have a timestamp.
* **Append-only:** Data is almost solely append-only (INSERTs).
* **Recent:** New data is typically about recent time intervals, and we more rarely make updates or backfill missing data about old intervals.

The frequency or regularity of data is less important though; it can be collected every millisecond or hour. It can also be collected at regular or irregular intervals (e.g., when some event happens, as opposed to at pre-defined times).
But haven't databases long had time fields? A key difference between time-series data (and the databases that support them), compared to other data like standard relational "business" data, is that changes to the data are inserts, not overwrites.

## Installing TimescaleDB Extention

### step #1 (connect to the PostgreSQL and preload the TimescaleDB)
connect to the Azure PostgreSQL with Bash Shell.
check the session IP using the curl command:

``` bash
root@Azure:~$ curl -s checkip.dyndns.org | sed -e 's/.Current IP Address: //' -e 's/<.$//'
```
Add the IP from the output to the fier wall ruls

Output will be in an HTML format, copy the IP address:  
**20.86.166.58**


Preload the time TimescaleDB using the azure portal, 
in the azure portal under servers parameters, check the TimescaleDB in the **shared_preload_libraries** once done seave the change and restrt the server 

Using the [Azure portal](https://portal.azure.com/):

[The steps to preload load TimeScaleDB](https://docs.microsoft.com/en-us/azure/postgresql/howto-configure-server-parameters-using-portal)
1.	Select your Azure Database for PostgreSQL server.
2.	On the sidebar, select Server Parameters.
3.	Search for the shared_preload_libraries parameter.
4.	Select TimescaleDB.
5.	Select Save to preserve your changes. You get a notification once the change is saved.
6.	After the notification, restart the server to apply these changes.

### step #2
connect to the Postgres Server using the psql command:
```bash
psql "host=singelservuser.postgres.database.azure.com port=5432 dbname=postgres user=user"
Password for user user:
```
Output:

psql (14.2 (Ubuntu 14.2-1.pgdg20.04+1), server 11.12)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

execute the command to validate the the TimescaleDB is available:
```sql
SELECT * FROM pg_available_extensions;
```
|name                 |version | Comment |                                                       
|---------------------|--------|------------------------------------------------------------|
 address_standardizer | 2.5.1  |Used to parse an address into constituent elements.
 fuzzystrmatch        | 1.1    |determine similarities and distance between strings
 ***timescaledb***    | 1.7.4  |Enables scalable inserts and complex queries for time-series data
 .
 .
 uaccent              | 1.1   |text search dictionary that removes accents
 uuid-ossp            | 1.1   |generate universally unique identifiers (UUIDs)
(38 rows)

### step #3
Create the Timescale Extension

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
```

output:

``` 
WELCOME TO
 _____ _                               _     ____________  
|_   _(_)                             | |    |  _  \ ___ \ 
  | |  _ _ __ ___   ___  ___  ___ __ _| | ___| | | | |_/ / 
  | | | |  _ ` _ \ / _ \/ __|/ __/ _` | |/ _ \ | | | ___ \ 
  | | | | | | | | |  __/\__ \ (_| (_| | |  __/ |/ /| |_/ /
  |_| |_|_| |_| |_|\___||___/\___\__,_|_|\___|___/ \____/
               Running version 1.7.4
For more information on TimescaleDB, please visit the following links:

 1. Getting started: https://docs.timescale.com/getting-started
 2. API reference documentation: https://docs.timescale.com/api
 3. How TimescaleDB is designed: https://docs.timescale.com/introduction/architecture

CREATE EXTENSION
postgres=> 
```
---
creating Sensor tables,
populating thuis table and running some Querys on this table

#### Creat the sensors table
```sql
CREATE TABLE sensors(
  id SERIAL PRIMARY KEY,
  type VARCHAR(50),
  location VARCHAR(50)
);
```
#### Create the sensors data table
```sql
CREATE TABLE sensor_data (
  time TIMESTAMPTZ NOT NULL,
  sensor_id INTEGER,
  temperature DOUBLE PRECISION,
  cpu DOUBLE PRECISION,
  FOREIGN KEY (sensor_id) REFERENCES sensors (id)
);
```
Using the create_hypertable function to convert the sensor_data table into a hypertable:

```sql
SELECT create_hypertable('sensor_data', 'time');
```

Inserting data into the Sensors Table
```sql
INSERT INTO sensors (type, location) VALUES
('a','floor'),
('a', 'ceiling'),
('b','floor'),
('b', 'ceiling');

SELECT * FROM sensors;
```
Output:
| id | type | location|
|----|------|---------|
| 1  | a    | floor   |
| 2  | a    | ceiling |
| 3  | b    | floor   |
| 4  | b    | ceiling |
(4 rows)

Generating a dataset for all four sensors and insert into the sensor_data.
```sql
INSERT INTO sensor_data (time, sensor_id, cpu, temperature)
SELECT
  time,
  sensor_id,
  random() AS cpu,
  random()*100 AS temperature
FROM generate_series(now() - interval '24 hour', now(), interval '5 minute') AS g1(time), generate_series(1,4,1) AS g2(sensor_id);


SELECT * FROM sensor_data ORDER BY time limit 8;
```
----- **Limit 8 return the first 8 rows**

Output:
 |    time                      | sensor_id |    temperature     |         cpu        |
 |------------------------------|-----------|--------------------|--------------------|
 |2020-03-31 15:56:25.843575+00 |         1 |   6.86688972637057 |   0.682070567272604|
 |2020-03-31 15:56:40.244287+00 |         2 |    26.589260622859 |   0.229583469685167|
 |2030-03-31 15:56:45.653115+00 |         3 |   79.9925176426768 |   0.457779890391976|
 |2020-03-31 15:56:53.560205+00 |         4 |   24.3201029952615 |   0.641885648947209|
 |2020-03-31 16:01:25.843575+00 |         1 |   33.3203678019345 |  0.0159163917414844|
 |2020-03-31 16:01:40.244287+00 |         2 |   31.2673618085682 |   0.701185956597328|
 |2020-03-31 16:01:45.653115+00 |         3 |   85.2960689924657 |   0.693413889966905|
 |2020-03-31 16:01:53.560205+00 |         4 |   79.4769988860935 |   0.360561791341752|


-- Basic Query Average temperature, average cpu by 30 minute windows:
```sql
SELECT
  time_bucket('30 minutes', time) AS period,
  AVG(temperature) AS avg_temp,
  AVG(cpu) AS avg_cpu
FROM sensor_data
GROUP BY period;
```

-- Query - Average & last temperature, average cpu by 30 minute windows:
```sql
SELECT
  time_bucket('30 minutes', time) AS period,
  AVG(temperature) AS avg_temp,
  last(temperature, time) AS last_temp,
  AVG(cpu) AS avg_cpu
FROM sensor_data
GROUP BY period;
```
--------------
-- Show the Sensor metadata
```sql
SELECT
  sensors.location,
  time_bucket('30 minutes', time) AS period,
  AVG(temperature) AS avg_temp,
  last(temperature, time) AS last_temp,
  AVG(cpu) AS avg_cpu
FROM sensor_data JOIN sensors on sensor_data.sensor_id = sensors.id
GROUP BY period, sensors.location;
```



***If you'd like to experience and test the full extention you can run the New Yort IOT lab***

 [IoT New York City Taxicabs case study](https://docs.timescale.com/timescaledb/latest/tutorials/nyc-taxi-cab/#introduction-to-iot-new-york-city-taxicabs)
