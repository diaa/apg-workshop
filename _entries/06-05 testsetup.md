---
sectionid: testsetup
sectionclass: h2
title: Generating pgBadger report
parent-id: pgBadger

---
Choose the file you want to generate pgBadger from and go to the directory where the chosen **PT1H.json** file is stored, for instance:

```shell
cd /home/pgadmin/mycontainer/resourceId=/SUBSCRIPTIONS/***/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM/y=2022/m=05/d=23/h=09/m=00
```

and run the following commands to extract the message value from json:

```shell
cut -f9- -d\: PT1H.json | cut -f1 -d\} | sed -e 's/^."//' -e 's/"$//' > 01
cat 01| sed 's/\\n/\n/g'>02
cat 02| sed 's/\\"/"/g'>03
```

You are ready to generate your first pgBadger report:

```shell
/usr/local/bin/pgbadger --prefix='%t %p %l-1 db-%d,user-%u,app-%a,client-%h ' 03 -o pgbadgerReport.html
```

Now you can download your report either from Azure Portal or by using scp command:


