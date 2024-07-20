# Настройка конфигурации (`config.php`)
В примерах быстрого старта, в файле `docker-compose.yml` можно увидеть следующий блок:
```yml
...
    environment:
      MAJORDOMO_DB_HOST: majordomo_db
      MAJORDOMO_DB_NAME: db_terminal
      MAJORDOMO_DB_USER: root
      MAJORDOMO_DB_PASSWORD: rootpassword
...
```
Данный блок создает соответсвующие конфигурационные константы в [config.php](https://github.com/sergejey/majordomo/blob/master/config.php.sample):
```php
...
Define('DB_HOST', 'majordomo_db');
Define('DB_NAME', 'db_terminal');
Define('DB_USER', 'root');
Define('DB_PASSWORD', 'rootpassword');
...
```

Для создания любой конфигурационной константы, достаточно добавить в переменные окружения соответсвующую переменную, с префиксом `MAJORDOMO_`. 
Т.е. чтобы в конфигурацию добавилась константа `XXX`, надо задать переменную окружения `MAJORDOMO_XXX`.

Список поддерживаемых констант и их значения смотри в оригинальном [config.php](https://github.com/sergejey/majordomo/blob/master/config.php.sample).

# Секреты и константы из внешних файлов
В некоторых ситуациях значение конфигурационной константы необходимо передать через внешний файл. Типичный пример - секрет.
Для этого необходимо добавить в переменные окружения переменную с префиксом `MAJORDOMO_` и суффиком `_FILE`. Например задание `MAJORDOMO_XXX_FILE: /var/xxx.txt` приведет к созданию конфигурационной константы `XXX` со значением из файла `/var/xxx.txt`.
> [!NOTE]
> Файл на который ссылается переменная окружения должен быть доступен *внутри контейнера*.

#### Пример с секретом:
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
Здесь `/root/secrets/majordomo_db_root_pw` - расположение файла на хост-машине, `/run/secrets/majordomo_db_root_pw` - расположение файла внутри контейнера. В результаре создастся конфигурационная константа:
```php
Define ('DB_PASSWORD', 'содержимое файла');
```

#### Пример с переменной во внешнем файле:
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
Здесь `/var/docker/majordomo/git.url` - расположение файла на хост-машине, `/var/www/html/git.url` - расположение файла внутри контейнера. В результаре создастся конфигурационная константа:
```php
Define ('GIT_URL', 'содержимое файла');
```

# Восстановление файлов из базового образа и защита от восстановления
Образ `majordomo-docker` содержит в себе копию MajorDoMo. При первом запуске он ничего не скачивает из интернета, а разворачивает слепок проекта в том виде, каким он был при создании образа.
Технически это реализовано следующим образом.

Структура контейнера:
```
/
├─ var/
│  └─ www/
│     ├─ majordomo/
│     │  └─ ...          <-- r/o слепок проекта, на момент создания докер-контейнера
│     └─ html/
│        └─ ...          <-- r/w рабочая копия проекта, она же директория вебсервера.
└─ usr/
   └─ local/
      └─ bin/
         └─ majordomo.sh <-- стартовый скрипт

```
Стартовый скрипт контейнера (`/usr/local/bin/majordomo.sh`) копирует содержимое из `/var/www/majordomo` в `/var/www/html`.
Как показывалось в [быстром старте](firststart.md), директория `/var/www/html` внутри контейнера - маунтится из хост-машины (в примерах это `/var/docker/majordomo/majordomo/`).

Таким образом, после первого запуска контейнера, в директории `/var/docker/majordomo/majordomo/` хост-машины окажется копия MajorDoMo в том виде, в каком она была на момент создания `majordomo-docker` образа.
Если по какой-либо причине содержимое `/var/docker/majordomo/majordomo/` окажется изменено, то при следующем старте контейнера все изменённые и удалённые файлы будут восстановлены.

Важное замечание: восстанавливаются только те файлы, которые содержатся в базовом образе. Файлы которые не существуют в базовом образе (были созданы в пользовательских поддиректориях, или установлены новые плагины) - не удаляются.

Данное поведение позволяет восстанавливать поврежденную инсталяцию и "замораживать" рабочую копию. В то же время, это препятсвует внесению желаемых изменений в базовые файлы, а также не позволяет обновлять систему средствами самого MajorDoMo.

### MAJORDOMO_DONT_RESTORE_FILES
В случае если необходимо изменить какой-либо системный файл таким образом, чтобы он не откатывался при перезапуске, необходимо использовать переменную окружения `MAJORDOMO_DONT_RESTORE_FILES` (и соответсвенно `MAJORDOMO_DONT_RESTORE_FILES_FILE`, если надо указать большой список исключений).
Данная переменная содержит список файлов относительно рабочей директории, которые стартовый скрипт должен пропустить.

> [!NOTE]
> Переменная `MAJORDOMO_DONT_RESTORE_FILES` (и файл `MAJORDOMO_DONT_RESTORE_FILES_FILE`) могут содержать файлы, директории, маски в формате утилиты `rsync` (см. формат [`--exclude-from`](https://linuxize.com/post/how-to-exclude-files-and-directories-with-rsync/) ) .

Пример `docker-compose.yml`:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: scripts/cycle_connect.php,modules/connect
...
```
Данная конфигурация указывает что файл `scripts/cycle_connect.php` и вся директория `modules/connect` не должны восстанавливаться. Таким образом можно удалить модуль `Connect` средствами MajorDoMo, и он не будет самовосстанавливаться при перезапуске контейнера.

Аналогичным образом решается проблема обновлений средствами самого MajorDoMo: чтобы позволить обновления через панель управления - достаточно в MAJORDOMO_DONT_RESTORE_FILES указать все файлы:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: "*"
...
```
> [!CAUTION]
> Обновления на "замороженой" конфигурации могут ввести в заблуждение: при обновлении через панель управления, обновляются файлы в рабочей директории и в базе данных создаются записи об обновлении. При перезапуске контейнера, рабочая директория восстанавливается к исходному состоянию, однако записи в БД остаются.
> Таким образом после перезапуска контейнера в интерфейсе будет отображаться неверное состояние системы - "последние обновления установлены", хотя фактически сами файлы будут устаревшими.
> Т.е. если не указана переменная окружения `MAJORDOMO_DONT_RESTORE_FILES: "*"`, то пользоваться обновлением системы через панель управления не рекомендуется.

### MAJORDOMO_SOFT_RESTORE
В случае если надо только добавить файлы из базового образа которые отсутсвуют в рабочей директории, можно использовать переменную окружения `MAJORDOMO_SOFT_RESTORE`. Значение может быть любым. Если переменная установлена, то будут копироваться файлы без перезаписи существующих. 
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_SOFT_RESTORE: true
...
```

> [!NOTE]
> Переменные `MAJORDOMO_DONT_RESTORE_FILES` и `MAJORDOMO_SOFT_RESTORE` можно комбинировать.

# Инициализация базы данных
При старте контейнера, кроме создания (восстановления) структуры рабочей директории, производится проверка целостности базы данных. Если к БД удалось подключиться, но она пустая, то БД инициализируется содержимым [db_terminal.sql](https://github.com/sergejey/majordomo/blob/master/db_terminal.sql) из базового образа.

Данное поведение также можно использовать для инициализации БД собственным дампом, т.е. использовать для миграции или восстановления из бекапа. 

Пример конфигурации:
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
Если БД очистить любым из способов (например если используется конфигурация из [Быстрого старта](firststart.md), то можно просто удалить директорию `/var/docker/majordomo/database`), то при запуске данной конфигурации, база данных будет проинициализирована содержимым файла `/var/docker/majordomo/majordomo/backup/dump.sql`.

# Пользовательский стартовый скрипт
Если есть необходимость запускать пользовательский shell скрипт при старте контейнера, то можно замаунтить из хост машины произвольный скрипт и указать путь к нему с помощью переменной окружения `MAJORDOMO_STARTUP_SCRIPT`:
```yml
services:
  majordomo:
...
    volumes:
      - ./startup.sh:/root/startup.sh
    environment:
      MAJORDOMO_STARTUP_SCRIPT: /root/startup.sh

```
Данный скрипт запустится после инициализации структуры рабочего каталога и базы данных, но перед запуском сервиса majordomo (`cycle.php`).

# Обновления
Как описывалось выше, контейнер `majordomo-docker` содержит операционную систему, php, вебсервер apache, а также слепок проекта MajorDoMo. При каждом билде контейнера, создается тег с текущей датой, и в него помещается master бранч MajorDoMo на момент билда. Кроме того, этот же контейнер заменяет собой `:latest` тег.

Обновления MajorDoMo возможны двумя способами:
1. Обновление докер контейнера.
2. Обновление средствами MajorDoMo.

Каждый из подходов имеет свои плюсы и минусы.
### Обновление докер контейнера
Для активации этого режима, никаких специальных изменений конфигурации не надо делать. Для обновления надо изменить `docker-compose.yml` файл на желаемый тег:
```yml
services:
  majordomo:
    image: ai91/majordomo-docker:202407062324
```

Либо использовать `:latest` - он всегда будет иметь последнюю доступную версию:
```yml
services:
  majordomo:
    image: ai91/majordomo-docker:latest
```
Однако при этом надо принудительно обновлять `:latest` контейнер, т.к. докер не скачивает образ при каждом запуске, а использует собтвенное хранилище:
```sh
sudo docker pull ai91/majordomo-docker:latest
sudo docker compose up --force-recreate -d
```
#### Плюсы
- Система устойчива к изменениям базовых файлов: хакерская атака, эксперименты с кодом - чтобы откатить к исходному состоянию, достаточно перезапустить контейнер.
- Можно легко откатиться к предыдущей или любой другой версии, которые хранятся на [докер-хабе](https://hub.docker.com/r/ai91/majordomo-docker/tags).
- Аналогично можно переключаться между альфой и мастером.
#### Минусы
- Штатным механизмом обновлений, из панели управления, пользоваться нельзя. Если воспользоваться обновлением из панели управления - система обновится, однако до следующего рестарта контейнера. При старте контейнера, все обновлённые файлы откатятся к исходному состоянию тега, однако записи в базе данных останутся, и система будет считать что она обновлена, хотя фактически она будет устаревшей.
- Из-за особеностей работы модуля `saverestore`, он всегда ругается что "система сильно устарела". *(TODO: в будущих версиях majordomo-docker можно попытаться исправить манипулируя записью `saverestore` в таблице `project_modules`)*

### Обновление средствами MajorDoMo
Чтобы полноценно воспользоваться обновлениями через панель управления, надо запретить восстановление рабочей директории:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_DONT_RESTORE_FILES: "*"
...
```
либо запретить обновлять существующие файлы:
```yml
services:
  majordomo:
...
    environment:
      MAJORDOMO_SOFT_RESTORE: true
...
```
При таком подходе докер-контейнер будет использоваться только как стабильная среда с php и apache. При этом периодические обновления тега также имеют смысл - будет обновлятся ОС, php, apache, пакеты.
#### Плюсы
- Вся мощь панели управления без ограничений.
#### Минусы
- В случае "поломки", надо самостоятельно разбираться и чинить рабочую директорию.

# MQTT
Философия докера - один контейнер ответсвеннен за одну задачу. Именно поэтому в [Быстром старте](firststart.md) в конфигурации есть два сервиса: база данных и php-окружение с MajorDoMo.

Аналогичным образом необходимо поступать если надо подключить какой-то сервис. Если, конечно, его архитектура позволяет. Такой подход позволяет изолировать сервисы друг от друга, избавляя от конфликтов пакетов.

Пример конфигурации с запуском MQTT брокера: 
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
Так же необходимо подготовить конфигурацию:

файл `/var/docker/majordomo/mosquitto/mosquitto.conf`:
```conf
allow_anonymous false
password_file /etc/mosquitto/passwd
listener 1883
```

а также файл с паролем `/var/docker/majordomo/mosquitto/passwd`:
```
username:password
```
Здесь задается логин и пароль в открытом виде. Чтобы зашифровать пароль - необходимо запустить утилиту которая поставляется с контейнером `eclipse-mosquitto`.
Для этого запускаем контейнеры:
```sh
sudo docker compose up --force-recreate -d
```

Когда они успешно стартуют, можем запустить утилиту `mosquitto_passwd` из работающего контейнера `majordomo_mqtt` (он же `eclipse-mosquitto`):
```sh
sudo docker exec majordomo_mqtt mosquitto_passwd -U /etc/mosquitto/passwd
```
После вызова данной утилиты, пароль внутри файла `/etc/mosquitto/passwd` (он же `/var/docker/majordomo/mosquitto/passwd` на хост-машине) станет зашифрованым.

Теперь можно установить и настроить модуль MQTT в MajorDoMo. Для этого открываем панель управления, устанавливаем модуль и настраиваем его для работы с брокером: он доступен на этой же машине по порту `1883`.

# phpMyAdmin
Аналогичным образом ставится phpMyAdmin.
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
В примере выше для доступа к phpMyAdmin надо открывать порт 8080: http://localhost:8080