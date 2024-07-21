# Быстрая установка с нуля
## Системные требования
 - ОС с установленным docker compose. 

## Установка
> Примеры командной строки для linux системы.

### 0. Устанавливаем docker compose. 
 Для различных ОС процесс установки слегка отличается - см. [соответсвующую документацию](https://docs.docker.com/compose/install/linux/).
### 1. Создаем рабочую директорию
```sh
mkdir -p /var/docker/majordomo
```

### 2. Создаем `docker-compose.yml`:
```sh
nano /var/docker/majordomo/docker-compose.yml
```
со следующим содержимым:
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
Данный файл представляет собой минимальную конфигурацию, состоящую из двух контейнеров: MajorDoMo и базу данных.
Это всё что надо для того чтобы запустить умный дом.

### 3. Запускаем
```sh
cd /var/docker/majordomo
sudo docker compose up -d
```
После того как последняя команда отрапортовала об успешном запуске, необходимо подождать пару минут, т.к. "прогрев" контейнера занимает некоторое время (при старте контейнер некоторое время занят созданием/восстановлением структуры каталогов, инициализацией базы данных). Через пару минут можно открывать сайт в браузере: http://localhost .

# Делаем безопасно
Не рекомендуется указывать пароли в явном виде, как это сделано в примере выше. Изменим конфигурацию для использования т.н. "секретов":

### 1. Создаём "секреты"
 Создаем два секрета - пароли для рута и для пользователя:
```sh
sudo mkdir /root/secrets
sudo echo "rootpassword" > /root/secrets/majordomo_db_root_pw;history -d $(history 1) 
sudo echo "userpassword" > /root/secrets/majordomo_db_pw;history -d $(history 1) 
```
> в конце команд добавлены `;history -d $(history 1)` чтобы пароли не светились в истории - тоже часть концепции безопасности. 
> Другой вариант - использовать редактор.
>```sh
>sudo nano /root/secrets/majordomo_db_root_pw
>sudo nano /root/secrets/majordomo_db_pw
>```
> Файлы должны содержать только пароль, без переноса строки в конце!

### 2. Добавляем секреты в наш `docker-compose.yml`
Добавляем секреты в корень конфигурации:
```yml
...
secrets:
  majordomo_db_pw:
    file: /root/secrets/majordomo_db_pw
  majordomo_db_root_pw:
    file: /root/secrets/majordomo_db_root_pw
```
После чего используем их в параметрах контейнеров:
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

Результирующий файл:
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

### 3. Перестартовываем
```sh
cd /var/docker/majordomo
sudo docker compose up --force-recreate -d
```

Теперь можно настраивать или переходить в [расширеные примеры](advanced.md).
