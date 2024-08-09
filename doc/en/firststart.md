# Quick installation from scratch
## System Requirements
 - OS with docker compose installed. 

## Installation
> Command line examples for Linux systems.

### 0. Install docker compose. 
 The installation process is slightly different for different operating systems - see the [appropriate documentation](https://docs.docker.com/compose/install/linux/).
### 1. Create a working directory
```sh
mkdir -p /var/docker/majordomo
```

### 2. Create `docker-compose.yml`:
```sh
nano /var/docker/majordomo/docker-compose.yml
```
with the following content:
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
    environment:
      MAJORDOMO_DB_HOST: majordomo_db
      MAJORDOMO_DB_NAME: db_terminal
      MAJORDOMO_DB_USER: root
      MAJORDOMO_DB_PASSWORD: rootpassword

  majordomo_db:
    image: mariadb:10.8.2
    container_name: majordomo_db
    volumes:
      - ./database:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: db_terminal
      MYSQL_USER: user
      MYSQL_PASSWORD: userpassword
      MARIADB_AUTO_UPGRADE: "1"
      MARIADB_INITDB_SKIP_TZINFO: "1"

volumes:
  database: {}
```
This file is a minimal configuration, consisting of two containers: MajorDoMo and the database.
This is all you need to start your smart home.

### 3. Run
```sh
cd /var/docker/majordomo
sudo docker compose up -d
```
After the last command reports a successful start, you should wait a few minutes because the container needs some time to "warm up" (at startup, the container takes some time to create/restore the directory structure and initialize the database). After a few minutes you can open the site in your browser: http://localhost .

# Make it safe
It is not recommended to specify passwords explicitly, as in the example above. Let's change the configuration to use "secrets":

### 1. Create "secrets
 Create two secrets - root and user passwords:
```sh
sudo mkdir /root/secrets
sudo echo "rootpassword" > /root/secrets/majordomo_db_root_pw;history -d $(history 1) 
sudo echo "userpassword" > /root/secrets/majordomo_db_pw;history -d $(history 1) 
```
> `;history -d $(history 1)` is added at the end of the commands to prevent passwords from appearing in the history, also part of the security concept. 
> Another way is to use the editor.
>```sh
>sudo nano /root/secrets/majordomo_db_root_pw
>sudo nano /root/secrets/majordomo_db_pw
>```
> Files must contain only the password, no line breaks at the end!

### 2. Add the secrets to our `docker-compose.yml`.
Add secrets to the root of the configuration file:
```yml
...
secrets:
  majordomo_db_pw:
    file: /root/secrets/majordomo_db_pw
  majordomo_db_root_pw:
    file: /root/secrets/majordomo_db_root_pw
```
Then we use it in the container parameters:
```yml
...
services:
  majordomo:
...
    environment:
...
      MAJORDOMO_DB_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw
    secrets:
      - majordomo_db_root_pw
...

  majordomo_db:
...
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw
      MYSQL_PASSWORD_FILE: /run/secrets/majordomo_db_pw
    secrets:
      - majordomo_db_root_pw
      - majordomo_db_pw

```

Resulting file:
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
    environment:
      MAJORDOMO_DB_HOST: majordomo_db
      MAJORDOMO_DB_NAME: db_terminal
      MAJORDOMO_DB_USER: root
      MAJORDOMO_DB_PASSWORD_FILE: /run/secrets/majordomo_db_root_pw

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

### 3. Restart
```sh
cd /var/docker/majordomo
sudo docker compose up --force-recreate -d
```

Now you can customize or go to [advanced examples](advanced.md).