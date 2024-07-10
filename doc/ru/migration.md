# Миграция существующей системы

Большинтсво систем можно разбить на следующие составляющие:
- Ядро MajorDoMo
- База данных (MySQL/MariaDB)
- Пользовательские файлы (медиа, html, svg, итп)
- Плагины, не требующие дополнительный софт на машине (т.е. только php код)
- Плагины требующие дополнительный сетевой софт (например MQTT-плагин требует установки соответсвующего брокера)
- Плагины требующие дополнительный локальный софт/драйвера (например для работы со всевозможными USB/Serial-устройсвами)

Миграцию можно проводить как поэтапно, так и за раз.

Поэтапно - это запустить в докере сначала только контейнер с MajorDoMo, и подключаться к локальной базе данных. Потом докерезировать базу данных и перенастроить MajorDoMo для работы с новой базой. И так далее.

Предлагаю делать всё сразу.

### 1. Ядро, БД, пользовательские файлы, модули

#### 1.1. Подготавливаем рабочую директорию docker-compose 
1. Создаём секреты для базы данных:
```sh
sudo mkdir /root/secrets
sudo echo "rootpassword" > /root/secrets/majordomo_db_root_pw;history -d $(history 1) 
sudo echo "userpassword" > /root/secrets/majordomo_db_pw;history -d $(history 1) 
```
2. Создаём `/var/docker/majoromo`
3. Создаём файл `/var/docker/majoromo/docker-compose.yml` со следующим содержимым:
```yml
version: '3.3'

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

secrets:
  majordomo_db_pw:
    file: /root/secrets/majordomo_db_pw
  majordomo_db_root_pw:
    file: /root/secrets/majordomo_db_root_pw

volumes:
  database: {}

```
Обратите внимание что задан `MAJORDOMO_DONT_RESTORE_FILES: "*"` - в будущем будем использовать [обновления средтсвами MajorDoMo](https://github.com/ai91/majordomo-docker/blob/main/doc/ru/advanced.md#%D0%BE%D0%B1%D0%BD%D0%BE%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5-%D1%81%D1%80%D0%B5%D0%B4%D1%81%D1%82%D0%B2%D0%B0%D0%BC%D0%B8-majordomo).

4. В файле `docker-compose.yml` выше, указаны минимально-необходимые конфигурационные переменные окружения. Туда необходимо перенести все остальные кастомизации из существующего `config.php` рабочей системы. Как работают переменные окружения и `config.php`, смотри [настройку конфигурации](advanced.md#настройка-конфигурации-configphp). Переносим все кастомные константы, кроме базы данных. Например если в `config.php` кастомизировался `PROJECT_TITLE`:
```yml
...
services:
...
  majordomo:
...
    environment:
...
      MAJORDOMO_PROJECT_TITLE: Tiffany Aching
...

```

#### 1.2. На рабоей системе делаем бэкап и распаковываем архив в рабочую директорию докер контейнера.
1. `Панель управления` -> `Система` -> `Проверка обновлений` -> `Создать резервную копию'.
2. Выбираем всё: `дизайн`, `код`, `данные`, `файлы`, после чего создаём архив.
3. Получившийся архив `design_code_data_files_202X-XX-XX__XX-XX-XX.tgz` распаковываем в `/var/docker/majoromo/majordomo`
4. Если чего-то не хватает в архиве, необходимо перенести вручную. Например если был кастомный `favicon.ico`.
> [!CAUTION]
> Не переносите `config.php`! Все необходимые кастомизации конфигурации должны быть сделаны через переменные окружения.

> [!NOTE]
> Обратите внимание на файл с дампом базы данных: `dump.sql`. Именно на него ссылается конфигурация в `docker-compose.yml` выше.
> Он будет замаплен в `/var/www/html/db_terminal.sql`, и запущен для [инициализации БД](https://github.com/ai91/majordomo-docker/blob/main/doc/ru/advanced.md#%D0%B8%D0%BD%D0%B8%D1%86%D0%B8%D0%B0%D0%BB%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D1%8F-%D0%B1%D0%B0%D0%B7%D1%8B-%D0%B4%D0%B0%D0%BD%D0%BD%D1%8B%D1%85).

#### 1.3. Останавливаем рабочую систему
Если новая докеризированая версия устанавливается на ту же машину где работает старая версия, то чтобы не было конфликта портов, надо остановить рабочую версию и веб-сервер.

Тут зависит от того как установлена рабочая версия. Это может быть `sudo systemctl stop majordomo`, может быть `service majordomo stop`, может быть редактирование `crontab`а, или какой-либо иной вариант - в сети ходят разнообразные варианты установки MajorDoMo. Более подробнее см. свою систему и инструкцию по которой она была настроена.

Важно остановить (а после успешной миграции - отключить автоматический запуск) сервис с главным циклом `cycle.php` и веб-сервер (`apache` или `nginx`).

#### 1.4. Запускаем докер
```sh
cd /var/docker/majordomo
sudo docker compose up -d
```

Процесс инициализации и запуска может занять значительное время. Через пару минут новая база данных должна быть проинициализирована и контейнер должен успешно "прогреться".

Все ранее установленные модули и их настройки также должны быть перенесены. Это значит что если использовался, например, MQTT модуль, и он был подключен к локальному брокеру, то после переноса в докер, он по прежнему будет общаться с тем же локальным брокером (вне докера). В целом имеет смысл перенести и этот брокер в докер. Для этого смотри [соответвующий пример](https://github.com/ai91/majordomo-docker/blob/main/doc/ru/advanced.md#mqtt). После докеризации брокера, может понадобиться соответсвенно обновить настройки модуля, и остановить (удалить) старый брокер вне докера. 

Аналогично можно поступить и с другими сетевыми сервисами: Redis, phpMyAdmin, итп. ***TODO: добавить примеры с наиболее часто используемыми***

#### 2. Плагины требующие дополнительный локальный софт/драйвера
 ***TODO: разобраться с use cases и добавить примеры***