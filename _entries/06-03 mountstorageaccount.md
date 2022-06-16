---

sectionid: mountstorageaccount
sectionclass: h2
parent-id: pgBadger
title: Mounting Storage Account to VM
---

In this section you will mount Storage Account to your dns VM to be able to easier manipulate on log files.

`sudo rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf install blobfuse
sudo mkdir /mnt/ramdisk
sudo mount -t tmpfs -o size=16g tmpfs /mnt/ramdisk
sudo mkdir /mnt/ramdisk/blobfusetmp
sudo chown pgadmin /mnt/ramdisk/blobfusetmp
touch fuse_connection.cfg
vi fuse_connection.cfg
chmod 600 fuse_connection.cfg
mkdir ~/mycontainer

sudo blobfuse ~/mycontainer --tmp-path=/mnt/resource/blobfusetmp  --config-file=/home/pgadmin/fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120

sudo -i`
`
cd /home/pgadmin/mycontainer/
ls
cd resourceId\=/SUBSCRIPTIONS/4DE9CB51-7DBB-474D-B9E8-9571E630BFD5/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM/y\=2022/m\=05/d\=11/h\=1
cd resourceId\=/SUBSCRIPTIONS/4DE9CB51-7DBB-474D-B9E8-9571E630BFD5/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM/y\=2022/m\=05/d\=11/
ls
cd h\=12/
ls
cd m\=00/
ls
less PT1H.json `
