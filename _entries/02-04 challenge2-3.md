---

sectionid: frontend
sectionclass: h2
parent-id: upandrunning
title: psql — PostgreSQL interactive terminal
hide: true
published: false
---

psql is a terminal-based front-end to PostgreSQL. It enables you to type in queries interactively, issue them to PostgreSQL, and see the query results. Alternatively, input can be from a file or from command line arguments. In addition, psql provides a number of meta-commands and various shell-like features to facilitate writing scripts and automating a wide variety of tasks.
Anything you enter in psql that begins with an **unquoted backslash** (\\) is a psql meta-command that is processed by psql itself. These commands make psql more useful for administration or scripting. Meta-commands are often called slash or backslash commands. The format of a psql command is the backslash, followed immediately by a command verb, then any arguments. The arguments are separated from the command verb and each other by any number of whitespace characters.

List the databases in the cluster:

```sh 
postgres=> \l
```

List the databases in the cluster with their sizes:
```sh 
postgres=> \l+
```

Copy and paste following statements:
```sql
CREATE DATABASE quiz;
\connect quiz

CREATE TABLE public.answers (
    question_id serial NOT NULL,
    answer text NOT NULL,
    is_correct boolean NOT NULL DEFAULT FALSE
);

CREATE TABLE public.questions (
    question_id integer NOT NULL,
    question text NOT NULL
);

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT answers_pkey PRIMARY KEY (question_id, answer);

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (question_id);

ALTER TABLE ONLY public.answers
    ADD CONSTRAINT question_id_answers_fk FOREIGN KEY (question_id) REFERENCES public.questions(question_id);

CREATE SCHEMA calc;
CREATE OR REPLACE FUNCTION calc.increment(i integer) RETURNS integer AS $$
        BEGIN
                RETURN i + 1;
        END;
$$ LANGUAGE plpgsql;

CREATE VIEW calc.vista AS SELECT $$I'm in calc$$;

CREATE VIEW public.vista AS SELECT $$I'm in public$$;

INSERT INTO public.questions (question_id, question) VALUES (1, 'Jaki symbol chemiczny ma tlen?');

INSERT INTO public.answers (question_id, answer, is_correct) VALUES (1, 'Au', false);
INSERT INTO public.answers (question_id, answer, is_correct) VALUES (1, 'O', true);
INSERT INTO public.answers (question_id, answer, is_correct) VALUES (1, 'Oxy', false);
INSERT INTO public.answers (question_id, answer, is_correct) VALUES (1, 'Tl', false);
```

List the databases in the cluster:
```sh 

```

Lists schemas (namespaces) in the current database:
```sh 
quiz=> \dn
     List of schemas
  Name  |     Owner
--------+----------------
 calc   | gustaw
 public | azure_pg_admin
(2 rows)
```

Check your current conection:
```sh 
quiz=> \conninfo
You are connected to database "quiz" as user "gustaw" on host "demo.postgres.database.azure.com" (address "20.67.160.95") at port "5432".
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
```

Check what's going on on your database:
```sh
quiz=> TABLE pg_stat_activity;
```

It's unreadable, isn't it? Change the display format:
```sh 
quiz=> \x auto
```

And try to display the same view again:
```sh
quiz=> SELECT * FROM pg_stat_activity;
```

Display all relations (including tables, views, materialized views, indexes, sequences, or foreign tables) in your database:
```sh
quiz=> \d
                   List of relations
 Schema |          Name           |   Type   |  Owner
--------+-------------------------+----------+----------
 public | answers                 | table    | postgres
 public | answers_question_id_seq | sequence | postgres
 public | questions               | table    | postgres
 public | vista                   | view     | postgres
(4 rows)
```

Display all relations with their size and description:
```sh
quiz=> \d+
                                 List of relations
 Schema |          Name           |   Type   |  Owner   |    Size    | Description
--------+-------------------------+----------+----------+------------+-------------
 public | answers                 | table    | postgres | 16 kB      |
 public | answers_question_id_seq | sequence | postgres | 8192 bytes |
 public | questions               | table    | postgres | 16 kB      |
 public | vista                   | view     | postgres | 0 bytes    |
(4 rows)
```

Display information about one, specific table:
```sh
quiz=> \dt+ pg_class
```

Display tables, which names start with "pg_c[...]"
```sh
quiz=> \dt pg_c*
```

Check out help information:

```sh
quiz=> \?
```

Display the number of total connections to your database:
```sh
quiz=> SELECT count(*) FROM pg_stat_activity;
```

Watch the change of the number over time:
```sh
quiz=> \watch
```

Stop the process:
```sh
quiz=> [Ctrl+c]
```

Write the output of a query to a file:
```sh
quiz=> \! cat /tmp/pg_stat_activity.txt
```

List all system views:
```sh 
quiz=> \dvS
```

Turns displaying of how long each SQL statement takes on:
```sh 
quiz=> \timing
```

List the system functions:
```sh 
quiz=> \dfS
```

Fetch and display the definition of the chosen function, in the form of a CREATE OR REPLACE FUNCTION command:
```sh 
quiz=> \sf abs(bigint)
```

Print psql's command line history:
```sh 
quiz=> \s
```

Search for a specific command in the history:
```sh 
quiz=> [Ctrl+r + part of the command string]
```




