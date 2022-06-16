---
sectionid: DeepDive
sectionclass: h2
title: Configure PgBadger
parent-id: day2
---

### Configuring Server Parameters
Navigate to Server Parameters page in the Azure Portal and modify the following parameters:
```sh 
log_line_prefix = '%t %p %l-1 db-%d,user-%u,app-%a,client-%h '  #Please mind the space at the end!
log_lock_waits = on
log_temp_files = 0
log_autovacuum_min_duration = 0
log_min_duration_statement=0
```

You can type part of the name in the search field to find them quicker:

![Server Parameters](media/pgbadger-params.png)

After the change hit the "Save":

![Save changed parameters](media/pgbadger-params-save.png)

### Configuring Diagnostic Settings
Navigate to Diagnostic settings page in the Azure Portal and add a new one with Storage Account destination:

![Server Parameters](media/ds-add.png)

Choose a name of your choice for your setting, redirect the logs to the storage account ("Archive to a storage account" checkbox) and choose "PostgreSQLLogs" as a category:

![Server Parameters](media/ds-create.png)

Hit **save** button.

### Mounting Storage Account to VM
In this section you will mount Storage Account to your dns VM to be able to easier manipulate on log files.

First let's download and install necessary packages. Feel free to simply copy and paste the following commands:

```sh
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf -y install blobfuse
sudo mkdir /mnt/ramdisk
sudo mount -t tmpfs -o size=16g tmpfs /mnt/ramdisk
sudo mkdir /mnt/ramdisk/blobfusetmp
sudo chown <your VM admin> /mnt/ramdisk/blobfusetmp
```

#### Authorize access to your storage account
You can authorize access to your storage account by using the account access key, a shared access signature, a managed identity, or a service principal. Authorization information can be provided on the command line, in a config file, or in environment variables. 

For this exercise we will authorize with the account access keys and storing them in a config file. The config file should have the following format:

```shell
accountName myaccount
accountKey storageaccesskey
containerName insights-logs-postgresqllogs
```

Please prepare the following file in editor of your choice. Values for the accountName and accountKey you will find in the Azure Portal. 
Please navigate to your storage account in the portal and then choose Access keys page:

![Server Parameters](media/sa-accesskeys.png)

Copy accountName and accountKey and paste it to the file. Copy the content of your file and paste it to the ***fuse_connection.cfg*** file in your home directory, then mount your storage account container onto the directory in your VM: 

```shell
vi fuse_connection.cfg
chmod 600 fuse_connection.cfg
mkdir ~/mycontainer
sudo blobfuse ~/mycontainer --tmp-path=/mnt/resource/blobfusetmp  --config-file=/home/<your VM admin>/fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120

sudo -i
cd /home/<your VM admin>/mycontainer/
ls # check if you see mounted container
# Please use tab key for directory autocompletion; do not copy and paste!
cd resourceId\=/SUBSCRIPTIONS/<your subscription id>/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM/y\=2022/m\=06/d\=16/h\=09/m\=00/
ls
less PT1H.json 
```

You should see some logs being generated.

### Install PgBadger
As the last step we need to install PgBadger. Feel free to copy and paste the following commands:

```shell
sudo -i
dnf install -y perl perl-devel
wget https://github.com/darold/pgbadger/archive/v11.8.tar.gz
tar xzf v11.8.tar.gz
cd pgbadger-11.8/
perl Makefile.PL
make && make install
```
