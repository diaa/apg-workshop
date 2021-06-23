---

sectionid: api
sectionclass: h2
parent-id: upandrunning
title: Connecting to PostgreSQL
---

In order to connect to a database you need to know the name of your target database, the host name and port number of the server, and what user name you want to connect as. **psql** can be told about those parameters via command line options, namely -d, -h, -p, and -U respectively. If an argument is found that does not belong to any option it will be interpreted as the database name (or the user name, if the database name is already given). Not all of these options are required; there are useful defaults. If you omit the host name, psql will connect via a Unix-domain socket to a server on the local host, or via TCP/IP to localhost on machines that don't have Unix-domain sockets. The default port number is determined at compile time. Since the database server uses the same default, you will not have to specify the port in most cases. The default user name is your operating-system user name, as is the default database name.
When the defaults aren't quite right, you can save yourself some typing by setting the environment variables PGDATABASE, PGHOST, PGPORT and/or PGUSER to appropriate values. It is also convenient to have a ~/.pgpass file to avoid regularly having to type in passwords.

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

Example (Please change these values to match with your setup)
```sh   
psql -U adminuser@postgresql-db -W -h postgresql-db.postgres.database.azure.com "dbname=postgres sslmode=require"
```

### Getting the connection string from Azure Portal
In this task, we will create a file in our Cloud Shell containing [libpq environment variables](https://www.postgresql.org/docs/current/libpq-envars.html) that will be used to select default connection parameter values to PostgreSQL PaaS instance. These are useful to be able to connect to postgres in a fast and convenient way without hard-coding connection string.

Go to the "Connection Strings" tab on the left hand side of the Azure Portal and find **psql** connection string:

<a href="media/connectionString.png" target="_blank"><img src="media/connectionString.png" style="width:800px"></a>

Open Cloud Shell and create a new *.pg_azure* file:

```sh
vi .pg_azure
```
Add the following parameters:

```sh
export PGDATABASE=ora2pg
export PGHOST=HOSTNAME.postgres.database.azure.com
export PGUSER=your_user@hostname
export PGPASSWORD=your_password
export PGSSLMODE=require
```
Read the content of the file in the current session:

```sh
source .pg_azure
```

Let's connect to our Azure database with psql client:

```sh
psql
```

<a href="media/ex03_libpq.gif" target="_blank"><img src="media/ex03_libpq.gif" style="width:800px"></a>



**Task Hints**
You can also use the connection string shown in the Azure Portal in the Connection String tab. Using libpq variables is another option to ease your work with Postgres. 


