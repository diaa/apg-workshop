---
sectionid: logicalbackup
sectionclass: h2
parent-id: businesscont-sec
title: Logical Backup
---

### Plain pg_dump

First, source the file with libpq variables in your current session:

```sh
source .pg_azure
```

Native PostgreSQL utilities like `pg_dump` use these variables to connect to your database instance.

To dump the `quiz` database:

```sh
pg_dump quiz
```

You can redirect the output to another program:

```sh
pg_dump quiz | less
```

Or save the output to a file:

```sh
pg_dump quiz > /tmp/quiz.plain.dump
```

Check the contents of the file:

```sh
less /tmp/quiz.plain.dump
```

To dump only the schema (no data):

```sh
pg_dump --schema-only quiz > /tmp/quiz_ddl.plain.dump
```

Check the contents:

```sh
less /tmp/quiz_ddl.plain.dump
```

You don't need to specify the database name every time. You can overwrite the `PGDATABASE` variable for the session:

```sh
export PGDATABASE=quiz
```

To dump only the data:

```sh
pg_dump --data-only > /tmp/quiz_data.plain.dump
```

Check the contents:

```sh
less /tmp/quiz_data.plain.dump
```

To use `INSERT` statements instead of `COPY`:

```sh
pg_dump --data-only --inserts > /tmp/quiz_data_insert.plain.dump
```

Check the contents:

```sh
less /tmp/quiz_data_insert.plain.dump
```

To dump a single table:

```sh
pg_dump --table=answers > /tmp/answers.plain.dump
```

Check the contents:

```sh
less /tmp/answers.plain.dump
```

To see all options for `pg_dump`:

```sh
pg_dump --help
```

---

### Restore from Plain Dump

Drop the `quiz` database:

```sh
dropdb quiz
```

Recreate it:

```sh
createdb quiz
```

Restore from your dump file:

```sh
psql -f /tmp/quiz.plain.dump
```

Watch out for errors!  
You may want to redirect errors to a separate file:

```sh
psql -f /tmp/quiz.plain.dump 2> errors.txt
less errors.txt
```

Log in to `psql` and check if everything was restored properly.

---

### Directory Format

Create a dump using the directory format. This is the only format that allows multiple parallel jobs:

```sh
pg_dump quiz -Fd -f /tmp/directorydump
```

Check the contents of the directory files:

```sh
zless /tmp/directorydump/*dat.gz
```

---

### Restore from Directory Format Dump

Drop the `quiz` database:

```sh
dropdb quiz
```

Recreate it:

```sh
createdb quiz
```

Restore from your directory dump:

```sh
pg_restore -d quiz /tmp/directorydump
```

Log in to `psql` and verify the restoration.

---

### Global Objects Dump

To logically dump the whole instance:

```sh
pg_dumpall > /tmp/whole_cluster.plain.dump
less /tmp/whole_cluster.plain.dump
```

To dump only global objects:

```sh
pg_dumpall -g > /tmp/globals.plain.dump
less /tmp/globals.plain.dump
```

You may encounter errors because you cannot export passwords.  
To avoid these errors, use:

```sh
pg_dumpall -g --no-role-passwords > /tmp/globals.plain.dump
```