
# General

## Connect to a MySQL instance and basic commands

```bash
MYSQL_HOST="localhost"
MYSQL_USER="user_name"

# this will launch the option to enter your user password
mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p
```

See the databases.
```bash
show databases;
use your_database_name;
```

# Setting up MySQL Google Cloud (GC) instance

The advantage of a MySQL GC instance is that it will automatically scale to your needs.

Below are the steps to set up a GC instance.

1. Navigate to GC console
2. Create new instance
3. Select MySQL and configure the settings
4. After it has been made, click on the instance in the GC console
5. Select database > create database
6. Select users > create user account
7. Select connections > add your network to "Authorized networks" (you may need to speak to your systems administrator to set this up).

After these steps you should be able to connect using the "Public IP address" as `${MYSQL_HOST}` with `${MYSQL_USER}` set to the user you created and using the password you set up.
