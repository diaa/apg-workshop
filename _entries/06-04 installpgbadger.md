---
sectionid: installpgbadger
sectionclass: h2
title: pgBadger Installation
parent-id: pgBadger
---


`sudo -i
dnf install -y perl perl-devel
wget https://github.com/darold/pgbadger/archive/v11.8.tar.gz
tar xzf v11.8.tar.gz
cd pgbadger-11.8/
perl Makefile.PL
make && make install`