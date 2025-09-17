---

sectionid: connecting-db
sectionclass: h2
parent-id: upandrunning
title: Connecting to PostgreSQL
---

In order to connect to a database you need to know the name of your target database, the host name and port number of the server, and what user name you want to connect as. 

You can save yourself some typing by setting the environment variables PGDATABASE, PGHOST, PGPORT and/or PGUSER to appropriate values. It is also convenient to have a **~/.pgpass** file to avoid regularly having to type in passwords.

### Basic psql options

    -d dbname
    --dbname=dbname
        Specifies the name of the database to connect to. This is equivalent to specifying dbname as the first non-option argument on the command line.

    -h hostname
    --host=hostname
        Specifies the host name of the machine on which the server is running.

    -p port
    --port=port
        Specifies the TCP port or the local Unix-domain socket file extension on which the server is listening for connections. Defaults to the value of the PGPORT environment variable or, if not set, to the port specified at compile time, usually **5432**.

    -U username
    --username=username
        Connect to the database as the user username instead of the default. (You must have permission to do so, of course.)
    -W
       --password
        Force psql to prompt for a password before connecting to a database.


**Using Azure Cloud Shell**

Example (please change these values to match with your setup) from the cloudshell

```sh
ssh username@<jumpbox-ip> # the DNS VM IP Address, and the username that you selected in deployment
```
![ssh access](media/ssh-access.png)


The first time you access the jumpbox, make sure that you have psql installed. Use the following commands once you log in:
```
sudo dnf module enable -y postgresql:13
sudo dnf install -y postgresql

```
You should see output like this

![Install PG client](media/dnf-install-pg.png)

Then connect to the database

```sh   
psql -U adminuser -h postgresql-db.postgres.database.azure.com postgres

```
![Install PG client](media/pg-access.png)

### Getting the connection string from Azure Portal
In this task, we will create a file in our Cloud Shell containing [libpq environment variables](https://www.postgresql.org/docs/current/libpq-envars.html) that will be used to select default connection parameter values to PostgreSQL PaaS instance. These are useful to be able to connect to postgres in a fast and convenient way without hard-coding connection string.

Go to the "Connection Strings" tab on the left hand side of the Azure Portal and find **psql** connection string:

<a href="media/connectionString.png" target="_blank"><img src="media/connectionString.png" style="width:800px"></a>

Open Cloud Shell and create a new *.pg_azure* file using your favourite editor (if you are not comfortable with Vim you can use VSCode):

**Using VIM**
```sh
vi .pg_azure
```

Add the following parameters or use the below **wget** command to download the file:

```sh
export PGDATABASE=postgres
export PGHOST=HOSTNAME.postgres.database.azure.com
export PGUSER=adminuser
export PGPASSWORD=your_password
export PGSSLMODE=require
```

**Using Wget**

```sh
wget https://pg.azure-workshops.cloud/scripts/pg_azure -O .pg_azure
```

Read the content of the file in the current session:

```sh
source .pg_azure
```

If you closed this bash session, you won't be able to login again to psql without reading .pg_azure.

Let's connect to our Azure database with psql client:

```sh
psql
```

You should be able to connect to PostgreSQL without specifying any parameters.


**Task Hints**
You can also use the connection string shown in the Azure Portal in the Connection String tab. Using libpq variables is another option to ease your work with Postgres. 


While you have the psql connected to the database, Let's run some queries:

```sql
SELECT version();
```
You should be able to read the PostgreSQL version.

Create a table with some random data:

```sql
DROP TABLE IF EXISTS random_data;

CREATE TABLE random_data AS
SELECT s                    AS first_column,
   md5(random()::TEXT)      AS second_column,
   md5((random()/2)::TEXT)  AS third_column
FROM generate_series(1,500000) s;
```

Let's select some of the records that we generated:

```sql
SELECT * FROM random_data LIMIT 10;

SELECT count(*) FROM random_data;

```