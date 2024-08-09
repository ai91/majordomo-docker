# Configuration (`config.php`)
In the quick start examples, you may see the following block in the `docker-compose.yml` file:
```yml
...
    environment:
      MAJORDOMO_DB_HOST: majordomo_db
      MAJORDOMO_DB_NAME: db_terminal
      MAJORDOMO_DB_USER: root
      MAJORDOMO_DB_PASSWORD: rootpassword
...
```
This block creates the appropriate configuration constants in [config.php](https://github.com/sergejey/majordomo/blob/master/config.php.sample):
```php
...
Define('DB_HOST', 'majordomo_db');
Define('DB_NAME', 'db_terminal');
Define('DB_USER', 'root');
Define('DB_PASSWORD', 'rootpassword');
...
```

To create any configuration constant, it is enough to add a corresponding variable with the prefix `MAJORDOMO_` to the environment variables. 
I.e. to add a constant `XXX` to the configuration, it is necessary to set the environment variable `MAJORDOMOMO_XXX`.

See the list of supported constants and their values in the original [config.php](https://github.com/sergejey/majordomo/blob/master/config.php.sample).

# Secrets and constants from external files
In some situations, the value of a configuration constant needs to be passed via an external file. A typical example is a secret.
To do this, add a variable with the prefix `MAJORDOMO_` and the suffix `_FILE` to the environment variables. For example, setting `MAJORDOMO_XXX_FILE: /var/xxx.txt` will create the configuration constant `XXX` with the value from the file `/var/xxx.txt`.
> [!NOTE]
> The file referenced by the environment variable must be accessible *inside the container*.

#### Example with a secret:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DB_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw
    secrets:
      - majordomo_db_root_pw
...
secrets:
  majordomo_db_root_pw:
    file: /root/secrets/majordomo_db_root_pw
...
```
Where `/root/secrets/majordomo_db_root_pw` is the location of the file on the host,  `/run/secrets/majordomo_db_root_pw` is the location of the file inside the container. The result is a configuration constant:
```php
Define ('DB_PASSWORD', 'содержимое файла');
```

#### Example with a value from an external file:
```yml
services:
  majordomo:
...
    volumes:
      - ./git.url:/var/www/html/git.url
    environment:
      MAJORDOMO_GIT_URL_FILE: /var/www/html/git.url
...
```
Where `/var/docker/majordomo/git.url` is the location of the file on the host, and `/var/www/html/git.url` is the location of the file inside the container. The result is a configuration constant:
```php
Define ('GIT_URL', 'содержимое файла');
```

# Restore files from base image and protect against recovery
The `majordomo-docker` image contains a copy of MajorDoMo. On the first start it does not download anything from the Internet, but restores a snapshot of the project as it was when the image was created.
Technically it is done as follows.

Container structure:
```
/
├─ var/
│  └─ www/
│     ├─ majordomo/
│     │  └─ ...          <-- r/o snapshot of the project
│     └─ html/
│        └─ ...          <-- r/w working copyof the project, also known as the web server directory. 
└─ usr/
   └─ local/
      └─ bin/
         └─ majordomo.sh <-- startup script
```
The container startup script (`/usr/local/bin/majordomo.sh`) copies the contents of `/var/www/majordomo` to `/var/www/html`.
As shown in [quickstart](firststart.md), the `/var/www/html` directory inside the container is mapped from the host machine (in the examples it is `/var/docker/majordomo/majordomo/`).

Thus, when the container is first started, the host machine's `/var/docker/majordomo/majordomo/` directory will obtain a copy of MajorDoMo as it was when the `majordomo-docker` image was created.
If the contents of `/var/docker/majordomo/majordomo/` are modified for any reason, all modified and deleted files will be restored the next time the container is restarted.

Important note: only files contained in the base image will be restored. Files that are not in the base image (created in custom subdirectories, or new plugins installed) will not be deleted.

This behavior allows you to restore a damaged installation and "freeze" a working copy. At the same time, it prevents you from making desired changes to the base files, and also prevents you from updating the system using MajorDoMo's own update module.

### MAJORDOMO_DONT_RESTORE_FILES
If you need to modify a system file and prevent it to be restored on container restart, you should use the `MAJORDOMO_DONT_RESTORE_FILES` environment variable (or  `MAJORDOMO_DONT_RESTORE_FILES_FILE` if you want to specify a large list of exceptions).
This variable contains a list of files relative to the working directory that the startup script should skip.


> [!NOTE]
> The `MAJORDOMO_DONT_RESTORE_FILES` variable (and the `MAJORDOMO_DONT_RESTORE_FILES_FILE` file) can contain files, directories, masks in the format of the `rsync` utility (see format of [`--exclude-from`](https://linuxize.com/post/how-to-exclude-files-and-directories-with-rsync/) ).

Example `docker-compose.yml`:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: scripts/cycle_connect.php,modules/connect
...
```
This configuration specifies that the file `scripts/cycle_connect.php` and the entire directory `modules/connect` should not be restored. This way the `Connect` module can be removed by MajorDoMo, and it will not be restored on container restart.

The problem of MajorDoMo auto updates is solved in a similar way: to allow updates through the control panel - it is enough to specify all files in `MAJORDOMO_DONT_RESTORE_FILES`:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: "*"
...
```
> [!CAUTION]
> Updating a "frozen" configuration can be misleading: when updating via the control panel, the files in the working directory are updated, and update-records are created in the database. When the container is restarted, the working directory is restored to its original state, but the database records remain untouched.
> As a result, after the container is restarted, the interface will show a wrong system state - "latest updates installed", even though the files are out of date.
> I.e., if the environment variable `MAJORDOMO_DONT_RESTORE_FILES:"*"` is not specified, it is not recommended to apply updates via the control panel.

### MAJORDOMO_SOFT_RESTORE
If you only need to add files from the base image that are missing in the working directory, you can use the `MAJORDOMO_SOFT_RESTORE` environment variable. The value can be any. If the variable is set, the files will be copied without overwriting the existing files. 
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_SOFT_RESTORE: true
...
```

> [!NOTE]
> The `MAJORDOMO_DONT_RESTORE_FILES` and `MAJORDOMO_SOFT_RESTORE` variables can be combined.

# Database initialization
When starting the container, besides creating (restoring) the working directory structure, the database integrity is checked. If the database could be connected, but is empty, the database is initialized with the contents of [db_terminal.sql](https://github.com/sergejey/majordomo/blob/master/db_terminal.sql) from the base image.

This behavior can also be used to initialize the database with your dump, e.g. for migration or restore from backup. 

Example configuration:
```yml
...
services:
  majordomo:
...
    volumes:
      - ./backup/dump.sql:/var/www/html/db_terminal.sql
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: db_terminal.sql
```
If the database is cleaned up (for example, if you use the configuration from [quickstart](firststart.md), you can simply delete the `/var/docker/majordomo/database` directory). In this case the database will be initialized at startup with the contents of `/var/docker/majordomo/majordomo/backup/dump.sql`.

# Custom startup script
If there is a need to run a custom shell script when the container starts, you can mount any script from the host machine and specify the path to it using the `MAJORDOMO_STARTUP_SCRIPT` environment variable:
```yml
services:
  majordomo:
...
    volumes:
      - ./startup.sh:/root/startup.sh
    environment:
      MAJORDOMO_STARTUP_SCRIPT: /root/startup.sh
```
This script is executed after the working directory and database structure are initialized, but before the majordomo service (`cycle.php`) is started.

# Updates
As described above, the `majordomo-docker` container contains the operating system, php, apache web server, and a snapshot of the MajorDoMo project. Each time the container image is built, a tag is created with the current version of the master branch, and the MajorDoMo master branch is copied into image. In addition, the same container replaces the `:latest' tag.

There are two ways to update MajorDoMo:
1. Update the docker container.
2. Update using the MajorDoMo auto update module.

Each approach has its advantages and disadvantages.
### Updating the Docker Container
No special configuration changes are required to enable this mode. To upgrade, you need to change the `docker-compose.yml` file to the desired tag:
```yml
services:
  majordomo:
    image: ai91/majordomo-docker:master_E2B3099_php7.4.25
```

Or use `:latest` - it will always have the latest available version:
```yml
services:
  majordomo:
    image: ai91/majordomo-docker:latest
```
However, it is necessary to force the `:latest` container to be updated, because docker does not download the image on every startup, but uses its own storage:
```sh
sudo docker pull ai91/majordomo-docker:latest
sudo docker compose up --force-recreate -d
```

#### Pros
- The system is resistant to changes in the base files: hacker attacks, experiments with code - to roll back to the original state, it is enough to restart the container.
- You can easily roll back to a previous or any other version stored on [docker-hub](https://hub.docker.com/r/ai91/majordomo-docker/tags).
- You can also switch between alpha and master.
#### Cons
- You can't use the standard control panel update modue. If you use control panel updates, the system will be updated only temporary, till the next container restart. When the container is restarted, all updated files will be rolled back to the initial state of the tag, but the records in the database will remain, and the system will think that it has been updated, when in fact it is outdated.
- Because of the way the `saverestore` module works, it always warns that "the system is out of date". *(TODO: in future versions of majordomo-docker try to fix this by manipulating the `saverestore` entry in the `project_modules` table)*.

### Updating via MajorDoMo update module
To take full advantage of updating via the control panel, you need to disable restoring the working directory:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: "*"
...
```
Or prevent existing files from being updated:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_SOFT_RESTORE: true
...
```
With this approach, the docker container will only be used as a stable environment with php runtime and apache. Though periodic tag updates also make sense - OS, php, apache, packages will be updated.
#### Pros
- All the power of the control panel without restrictions.
#### Cons
- When corrupted, you have to find out and fix the working directory yourself.

# Additional services
Docker philosophy - one container for one task. That's why in [quickstart](firststart.md) there are two services in the configuration: database and php-environment with MajorDoMo.

When it's possible, the same is to be done if any other service needs to be added. This way you can isolate services from each other and avoid package conflicts.

## MQTT
Example configuration with MQTT broker running: 
```yml
services:
  majordomo:
    image: ai91/majordomo-docker:latest
    container_name: majordomo
    depends_on:
      - majordomo_db
      - majordomo_mqtt
    ports:
      - 80:80
      - 8001:8001
    restart: always
    volumes:
      - ./majordomo:/var/www/html
    environment:
      MAJORDOMO_DB_HOST: majordomo_db
      MAJORDOMO_DB_NAME: db_terminal
      MAJORDOMO_DB_USER: root
      MAJORDOMO_DB_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw
      MAJORDOMO_DONT_RESTORE_FILES: "*"
    secrets:
      - majordomo_db_root_pw

  majordomo_db:
    image: mariadb:10.8.2
    container_name: majordomo_db
    volumes:
      - ./database:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw
      MYSQL_DATABASE: db_terminal
      MYSQL_USER: user
      MYSQL_PASSWORD_FILE: /run/secrets/majordomo_db_pw
      MARIADB_AUTO_UPGRADE: "1"
      MARIADB_INITDB_SKIP_TZINFO: "1"
    secrets:
      - majordomo_db_root_pw
      - majordomo_db_pw

  majordomo_mqtt:
    image: eclipse-mosquitto
    container_name: majordomo_mqtt
    restart: always
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto:/etc/mosquitto
      - ./mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf

secrets:
  majordomo_db_pw:
    file: /root/secrets/majordomo_db_pw
  majordomo_db_root_pw:
    file: /root/secrets/majordomo_db_root_pw

volumes:
  database: {}

```

You also need to prepare the configuration:

`/var/docker/majordomo/mosquitto/mosquitto.conf` file:
```conf
allow_anonymous false
password_file /etc/mosquitto/passwd
listener 1883
```

And the password file `/var/docker/majordomo/mosquitto/passwd`:
```
username:password
```
The username and password are stored in clear text. To encrypt the password, you need to run the utility that comes with the `eclipse-mosquitto` container.
To do this, run the containers:
```sh
sudo docker compose up --force-recreate -d
```

When they start, we can execute the `mosquitto_passwd` utility from a running `majordomo_mqtt` container (aka `eclipse-mosquitto`):
```sh
sudo docker exec majordomo_mqtt mosquitto_passwd -U /etc/mosquitto/passwd
```
After executing this utility, the password in `/etc/mosquitto/passwd` (aka `/var/docker/majordomo/mosquitto/passwd` on the host) will be encrypted.

Now you can install and configure the MQTT module in MajorDoMo. Open the control panel, install the module and configure it to work with the broker: it is available on localhost on port `1883`.

# phpMyAdmin
Install phpMyAdmin in the same way.
```yml
services:
...
  majordomo_db:
...
  majordomo_phpmyadmin:
    image: phpmyadmin
    depends_on:
      - majordomo_db
    restart: always
    ports:
      - 8080:80
    environment:
      PMA_HOST: majordomo_db
```
In the example above, to access phpMyAdmin, you need to open port 8080: http://localhost:8080.