---
sectionid: monitoring
sectionclass: h2
parent-id: upandrunning
title: Logical Backup

---
### Plain pg_dump
Make sure you have sourced the file with libpq variables on your current session:
```sh 
source .pg_azure
```

pg_dump like other native postgres utilities is able to use them to connect to your database instance.

Run pg_dump:
```sh 
pg_dump
```

Run pg_dump against quiz database:
```sh 
pg_dump quiz
```

You can redirect the output of pg_dump to another program:
```sh 
pg_dump quiz|less
```

Save the output of pg_dump:
```sh 
pg_dump quiz > /tmp/quiz.plain.dump
```

Check the content of file:
```sh 
less /tmp/quiz.plain.dump
```

Dump only the schema (without any data):
```sh 
pg_dump --schema-only quiz > /tmp/quiz_ddl.plain.dump
```

Check the content of file:
```sh 
less /tmp/quiz_ddl.plain.dump
```

You don't have to each time specify the database name, you can for instance overwrite PGDATABASE variable just for this session:
```sh 
export PGDATABASE=quiz 
```

Let's dump only the data:
```sh 
pg_dump --data-only > /tmp/quiz_data.plain.dump
```

Check the content of file:
```sh 
less /tmp/quiz_data.plain.dump
```

Change the COPY command to INSERT:
```sh 
pg_dump --data-only --inserts > /tmp/quiz_data_insert.plain.dump
```

Check the content of file:
```sh 
less /tmp/quiz_data_insert.plain.dump
```

Dump only one table:
```sh 
pg_dump --table=answers > /tmp/answers.plain.dump
```

Check the content of file:
```sh 
less /tmp/answers.plain.dump
```

Check all the options for pg_dump:
```sh 
pg_dump --help
```

### Restore from plain dump
Drop database quiz:
```sh 
dropdb quiz
```

Recreate it:
```sh 
createdb quiz
```

Restore it from your dump:
```sh 
psql -f /tmp/quiz.plain.dump
```

Watch out for errors!
You might want to redirect errors to a separate file:
```sh 
psql -f /tmp/quiz.plain.dump 2> errors.txt
less errors.txt
```

Log in to psql and check if everything was properly restored.

### Directory format
Create dump using directory format. That is the only format where you can many parallel jobs to dump your database.
```sh 
pg_dump quiz -Fd -f /tmp/directorydump
```

Check the content of files in the directory:
```sh 
zless /tmp/directorydump/*dat.gz
```

### Restore from directory format dump
Drop database quiz:
```sh 
dropdb quiz
```

Recreate it:
```sh 
createdb quiz
```

Restore it from your dump:
```sh 
pg_restore -d quiz /tmp/directorydump
```

Log in to psql and check if everything was properly restored.

### Global objects dump
Dump logically the whole instance:
```sh 
pg_dumpall > /tmp/whole_cluster.plain.dump
less /tmp/whole_cluster.plain.dump
```

Dump only the global objects:
```sh 
pg_dumpall -g > /tmp/globals.plain.dump
less /tmp/globals.plain.dump
```


