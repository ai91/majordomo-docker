# Migrating an Existing System

Most systems consist of the following components:
- MajorDoMo Core
- Database (MySQL/MariaDB)
- User files (media, html, svg, etc.)
- Plugins that require no additional software on the machine (i.e. only php code)
- Plugins that require additional network software (e.g. MQTT plugin requires installation of a broker)
- Plugins that require additional local software/drivers (e.g. to work with all kinds of USB/serial devices).

Migration can be done step-by-step or all at once.

Step-by-step is to first run only the container with MajorDoMo in the docker and connect to the local database. Then dockerize the database and reconfigure MajorDoMo to work with the new database. And so on.

I suggest to do everything at once.

### 1. Core, Database, User Files, Modules

#### 1.1. Prepare a working docker-compose directory 
1. Create secrets for the new database:
```sh
sudo mkdir /root/secrets
sudo echo "rootpassword" > /root/secrets/majordomo_db_root_pw;history -d $(history 1) 
sudo echo "userpassword" > /root/secrets/majordomo_db_pw;history -d $(history 1) 
```
2. Create `/var/docker/majoromo`.
3. Create a file `/var/docker/majoromo/docker-compose.yml` with the following content:
```yml
services:
  majordomo:
    image: ai91/majordomo-docker:latest
    container_name: majordomo
    depends_on:
      - majordomo_db
    ports:
      - 80:80
      - 8001:8001
    restart: always
    volumes:
      - ./majordomo:/var/www/html
      - ./majordomo/dump.sql:/var/www/html/db_terminal.sql
    environment:
      MAJORDOMO_DB_HOST: majordomo_db
      MAJORDOMO_DB_NAME: db_terminal
      MAJORDOMO_DB_USER: root
      MAJORDOMO_DB_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw
      MAJORDOMO_SOFT_RESTORE: true
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

secrets:
  majordomo_db_pw:
    file: /root/secrets/majordomo_db_pw
  majordomo_db_root_pw:
    file: /root/secrets/majordomo_db_root_pw

volumes:
  database: {}
```
Note that `MAJORDOMO_SOFT_RESTORE: true` is set - in the future we will use [MajorDoMo updates](advanced.md#updating-via-majordomo-update-module).

4. The above `docker-compose.yml` file specifies the minimum necessary configuration environment variables. Any other customizations from the existing `config.php` on working system should be moved there. See [Configuration customization](advanced.md#configuration-configphp) for more info. Migrate all custom constants except for the database. If, for example, the `PROJECT_TITLE` was previously customized in `config.php`:
```yml
services:
...
  majordomo:
...
    environment:
...
      MAJORDOMO_PROJECT_TITLE: Tiffany Aching
...

```

#### 1.2. On a working system, create a backup and extract the archive to the working directory of the Docker container.
1. `Control Panel -> System -> Check for Updates -> Create Backup`.
2. Select everything: `design`, `code`, `data`, `files` and then create an archive.
3. Extract the resulting archive `design_code_data_files_202X-XX-XX__XX-XX-XX.tgz` to `/var/docker/majordomo/majordomo`.
4. If anything is missing in the archive, you will need to copy it manually. For example custom `favicon.ico` or `templates_old`. Final polishing can be done after migration.

> [!NOTE]
> When backup is created, many core directories and files from an existing installation are not added to the archive. For example `3rdparty`, `css`, `.htaccess`, etc. To restore most of them automatically, the [`MAJORDOMO_SOFT_RESTORE`](advanced.md#majordomo_soft_restore) variable can be used. However, missing files can be copied manually. We assume that the standard files have not been copied manually.

> [!CAUTION]
> Do not move `config.php`! Any necessary configuration changes should be done via environment variables in `docker-compose.yml`.

> [!NOTE]
> Note the database dump file: `dump.sql`. This is the one referenced by the configuration in `docker-compose.yml` above.
> It will be mounted to `/var/www/html/db_terminal.sql` and used to [initialize the database](advanced.md#%database-initialization).


#### 1.3. Stop the existing system
If a new dockerised instance is going to be running on the same machine where the old instance is running, you should stop the working instance and the web server to avoid port conflicts.

It depends on how the working system is installed. It can be `sudo systemctl stop majordomo`, it can be `sudo service majordomo stop`, it can be editing `crontab`, or some other variant - there are several variants of MajorDoMo installations instructions in the internet. For more details, refer your system and the manual based on which it was configured.

It is important to stop the service with the main `cycle.php` loop and the web server (`apache` or `nginx`) (and disable the automatic startup after successful migration).

#### 1.4. Start Docker container
```sh
cd /var/docker/majordomo
sudo docker compose up -d
```

The initialization and startup process can take a considerable amount of time. After a few minutes, the new database should be initialized and the container should have successfully "warmed up".

Any previously installed modules and their settings should also be migrated.
> [!CAUTION]
> However, some modules install additional files in the `3rdparty` directory which are not included in the backup. Therefore, if you only used the backup archive in step 1.2. without manually copying directories from the old instance, some modules may not work. For example, `3rdparty/highcharts` is not included in the base image (because it is not part of the core project), nor is included in the backup. 
> 
> To solve this problem, you can either copy the missing files manually or use the optional restore procedure via the built-in update feature: `Control Panel -> System -> Check for Updates -> Update -> Update all installed add-ons`.


After a successful start it is recommended to use the system and check the logs: either via X-Ray or in `/var/docker/majordomo/majordomo/cms/debmes/`. An example of what can go wrong: the path to the backups may point to a non-existent directory on the old instance (this can be fixed by pointing to `/var/www/html/backup/`, which would correspond to `/var/docker/majordomo/majordomo/backup/` on the host machine). 

If, for example, an MQTT module was used, and it was connected to a local broker, then after migrating to Docker, it will still communicate with the same local broker (outside of Docker). In general, it makes sense to dockerize this broker as well. See [related example](advanced.md#mqtt). After dockerizing the broker, you may need to update the module settings accordingly and stop (delete) the old broker outside the docker. 

You can do the same for other network services: Redis, [phpMyAdmin](advanced.md#phpmyadmin), etc. 

*TODO: add examples with the most used ones*

#### 2. Plugins that require additional local software/drivers
*TODO: Address use cases and add examples*