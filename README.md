# PHP-Nginx-TCP — учебный стек на Docker (современная замена XAMPP/MAMP/Open Server)

Простая, воспроизводимая и «говорящая» среда для изучения PHP и его экосистемы. Стек собирается из контейнеров Docker и предназначен для локальных экспериментов.

Важное: этот проект предназначен исключительно для обучения, практики и ознакомления. Не используйте его в проде.

## Что внутри (архитектура)

Сервисы docker-compose.yml:
- PHP-FPM 8.4 (контейнер php-nginx-tcp) — выполняет PHP, порт 9000 (внутренний), Xdebug установлен, управляется переменными окружения.
- Nginx (контейнер nginx-tcp) — отдаёт статику и проксирует .php в PHP-FPM; доступен на http://localhost:80.
- MySQL 8.4 (контейнер mysql-nginx-tcp) — база данных на localhost:3306, данные в именованном томе mysql-data.
- phpMyAdmin (контейнер phpmyadmin-nginx-tcp) — веб-интерфейс MySQL на http://localhost:8080.

Здоровье (healthchecks):
- PHP-FPM — проверка fastcgi (cgi-fcgi -connect localhost:9000).
- Nginx — HTTP-запрос к http://localhost/.
- MySQL — mysqladmin ping.
- phpMyAdmin — HTTP-запрос к http://localhost/.

Порядок старта: nginx-tcp ожидает, когда php-nginx-tcp станет healthy.

## Структура репозитория (актуальная)

```
php-nginx-tcp/
├── Makefile
├── README.md
├── .env.example
├── .env                        # Ваши локальные переменные окружения
├── docker/
│   ├── nginx/
│   │   ├── nginx.conf          # Конфиг Nginx (проксирование в PHP-FPM)
│   │   ├── nginx.framework.conf # Альтернативный конфиг (Single Entry Point)
│   │   └── nginx.fastcgi.conf  # Конфиг проксирования (FastCGI)
│   ├── php/
│   │   └── php.ini             # Конфиг PHP (dev-настройки + Xdebug через env)
│   └── php.Dockerfile          # Образ PHP-FPM 8.4 (Alpine) + расширения + Xdebug + Composer
├── docker-compose.yml          # Основной стек: PHP-FPM, Nginx, MySQL, phpMyAdmin
├── docker-compose.xdebug.yml   # Оверлей для включения Xdebug (mode=start)
└── public/                     # DocumentRoot (будет смонтирован в Nginx и PHP-FPM)
    ├── index.html
    ├── index.php
    └── phpinfo.php
```

Обратите внимание: папки src/ и logs/ в данном репозитории отсутствуют. Для обучения достаточно размещать PHP-файлы в public/.

## Быстрый старт

Предпосылки:
- Docker 20.10+
- Docker Compose v2+

Шаги:
1) Клонируйте репозиторий и перейдите в каталог проекта.
2) Скопируйте пример env:
   - cp .env.example .env
   - при необходимости отредактируйте пароли/имена БД.
3) Запустите стек:
   - make up (или docker compose up -d)
4) Проверьте доступность:
   - Web: http://localhost
   - phpMyAdmin: http://localhost:8080 (сервер mysql-nginx-tcp)
   - MySQL: localhost:3306

Полезные команды Makefile:
- make up / make down / make restart — управление стеком
- make logs / make status — логи и статусы контейнеров
- make xdebug-up / make xdebug-down — запуск/остановка стека с включённым Xdebug
- make check-files — проверить, что все нужные файлы на месте

## Конфигурация

PHP (docker/php/php.ini):
- error_reporting=E_ALL, display_errors=On — удобно учиться на ошибках
- memory_limit=256M, upload_max_filesize=20M, post_max_size=20M
- opcache включён, validate_timestamps=1 (код обновляется сразу)
- Xdebug управляется через переменные окружения (см. ниже)

Nginx (docker/nginx/nginx.conf):
- FastCGI проксирует .php в php-nginx-tcp:9000
- try_files для обработки статики и PHP

Альтернативные конфиги Nginx (docker/nginx/):
- nginx.framework.conf — режим Single Entry Point для фреймворков
- nginx.fastcgi.conf — настройки FastCGI параметров

Docker-образ PHP (docker/php.Dockerfile):
- База: php:8.4-fpm-alpine
- Установлены расширения: pdo, pdo_mysql, mysqli, mbstring, xml, gd, bcmath, zip
- Установлен Xdebug (через pecl), Composer, fcgi (для healthcheck)

## Переменные окружения (.env)

Минимальный набор (см. .env.example):
- MYSQL_ROOT_PASSWORD — пароль root для MySQL
- PMA_HOST=mysql-nginx-tcp — хост БД для phpMyAdmin
- NGINX_PORT, MYSQL_PORT, PHPMYADMIN_PORT — порты сервисов
- XDEBUG_MODE, XDEBUG_START, XDEBUG_CLIENT_HOST — опционально для Xdebug

## Xdebug: как включить

По умолчанию Xdebug установлен, но выключен (переменные не заданы). Включить можно двумя способами:

Вариант A: оверлейный compose-файл
- make xdebug-up
  (эквивалент docker compose -f docker-compose.yml -f docker-compose.xdebug.yml up -d)
- Внутри php.ini используются переменные XDEBUG_MODE=debug и XDEBUG_START=yes.

Вариант B: задать переменные в .env и перезапустить php-контейнер
- XDEBUG_MODE=debug
- XDEBUG_START=yes
- XDEBUG_CLIENT_HOST=host.docker.internal
- затем docker compose up -d --no-deps php-nginx-tcp

IDE: подключение по Xdebug 3 на порт 9003, client_host=host.docker.internal.

## Рабочие директории и монтирование

- public/ монтируется в /var/www/html одновременно в PHP-FPM и Nginx — любые изменения видны сразу.
- docker/php/php.ini монтируется в /usr/local/etc/php/conf.d/local.ini (только чтение).
- Для MySQL используется именованный том mysql-data (персистентные данные).

## Подключение к MySQL из PHP (пример)

```
<?php
$host = 'mysql-nginx-tcp';
$dbname = 'your-db-name';
$user = 'your-user';
$pass = 'your-user-password';
$pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
```

## Решение проблем

Порты заняты:
- Измените привязку в docker-compose.yml, например 8081:80 для Nginx.

Контейнеры не стартуют по порядку:
- Проверьте healthchecks командой docker compose ps; nginx-tcp зависит от healthy php-nginx-tcp.

Xdebug не подключается:
- Проверьте, что используете порт 9003 в IDE, и что XDEBUG_MODE/START заданы (compose.xdebug.yml или .env).

Полная очистка и пересборка:
- make clean или make clean-all; затем make rebuild и make up.

## Дисклеймер

Проект создан для обучения и экспериментов с PHP-стеком. Не предназначен для production-использования или оценки производительности.
