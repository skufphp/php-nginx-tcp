# ==========================================
# PHP-Nginx-TCP — среда разработки
# ==========================================
# Современная замена XAMPP/MAMP/OpenServer
# 
# Основные команды:
# make up        - Запуск всех сервисов
# make down      - Остановка всех сервисов
# make restart   - Перезапуск сервисов
# make logs      - Просмотр логов всех сервисов
# make status    - Статус контейнеров
# make clean     - Полная очистка
# ==========================================

.PHONY: help up down restart build rebuild logs logs-php logs-nginx logs-postgres logs-pgadmin status shell-php shell-nginx shell-postgres clean clean-all setup info test check-files xdebug-up xdebug-down permissions composer-install composer-update composer-require dev-reset

# Цвета для вывода
YELLOW=\033[0;33m
GREEN=\033[0;32m
RED=\033[0;31m
NC=\033[0m # No Color

# По умолчанию показываем справку
help: ## Показать справку по командам
	@echo "$(YELLOW)PHP-Nginx-TCP Development Environment$(NC)"
	@echo "======================================"
	@echo "Современная замена XAMPP/MAMP/OpenServer для изучения PHP"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)URL сервисов после запуска:$(NC)"
	@echo "  Web Server:  http://localhost"
	@echo "  pgAdmin:     http://localhost:8080"
	@echo "  PostgreSQL:  localhost:5432"

check-files: ## Проверить наличие всех необходимых файлов
	@echo "$(YELLOW)Проверка файлов конфигурации...$(NC)"
	@test -f docker-compose.yml || (echo "$(RED)✗ docker-compose.yml не найден$(NC)" && exit 1)
	@test -f docker-compose.xdebug.yml || (echo "$(RED)✗ docker-compose.xdebug.yml не найден$(NC)" && exit 1)
	@test -f env/.env || (echo "$(RED)✗ env/.env не найден$(NC)" && exit 1)
	@test -f docker/php.Dockerfile || (echo "$(RED)✗ docker/php.Dockerfile не найден$(NC)" && exit 1)
	@test -f config/nginx/conf.d/default.conf || (echo "$(RED)✗ config/nginx/conf.d/default.conf не найден$(NC)" && exit 1)
	@test -f config/php/php.ini || (echo "$(RED)✗ config/php/php.ini не найден$(NC)" && exit 1)
	@test -d public/ || (echo "$(RED)✗ директория public/ не найдена$(NC)" && exit 1)
	@echo "$(GREEN)✓ Все файлы на месте$(NC)"

up: check-files ## Запуск всех сервисов
	@echo "$(YELLOW)Запуск сервисов...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✓ Сервисы запущены$(NC)"
	@echo "$(YELLOW)Доступные URL:$(NC)"
	@echo "  Web Server:  http://localhost"
	@echo "  pgAdmin:     http://localhost:8080"

down: ## Остановка всех сервисов
	@echo "$(YELLOW)Остановка сервисов...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Сервисы остановлены$(NC)"

restart: ## Перезапуск всех сервисов
	@echo "$(YELLOW)Перезапуск сервисов...$(NC)"
	docker-compose restart
	@echo "$(GREEN)✓ Сервисы перезапущены$(NC)"

build: ## Сборка образов
	@echo "$(YELLOW)Сборка образов...$(NC)"
	docker-compose build
	@echo "$(GREEN)✓ Образы собраны$(NC)"

rebuild: ## Пересборка образов с очисткой кэша
	@echo "$(YELLOW)Пересборка образов...$(NC)"
	docker-compose build --no-cache
	@echo "$(GREEN)✓ Образы пересобраны$(NC)"

xdebug-up: check-files ## Запуск с включенным Xdebug (через docker-compose.xdebug.yml)
	@echo "$(YELLOW)Запуск с Xdebug...$(NC)"
	docker-compose -f docker-compose.yml -f docker-compose.xdebug.yml up -d
	@echo "$(GREEN)✓ Сервисы с Xdebug запущены$(NC)"
	@echo "$(YELLOW)Доступные URL:$(NC)"
	@echo "  Web Server:  http://localhost"
	@echo "  pgAdmin:     http://localhost:8080"

xdebug-down: ## Остановить стек, запущенный с Xdebug
	@echo "$(YELLOW)Остановка сервисов с Xdebug...$(NC)"
	docker-compose -f docker-compose.yml -f docker-compose.xdebug.yml down
	@echo "$(GREEN)✓ Сервисы с Xdebug остановлены$(NC)"

logs: ## Просмотр логов всех сервисов
	docker-compose logs -f

logs-php: ## Просмотр логов PHP-FPM
	docker-compose logs -f php-nginx-tcp

logs-nginx: ## Просмотр логов Nginx
	docker-compose logs -f nginx-tcp

logs-postgres: ## Просмотр логов PostgreSQL
	docker-compose logs -f postgres-nginx-tcp

logs-pgadmin: ## Просмотр логов pgAdmin
	docker-compose logs -f pgadmin-nginx-tcp

status: ## Показать статус контейнеров
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker-compose ps

shell-php: ## Подключиться к контейнеру PHP
	docker-compose exec php-nginx-tcp sh

shell-nginx: ## Подключиться к контейнеру Nginx
	docker-compose exec nginx-tcp sh

shell-postgres: ## Подключиться к PostgreSQL CLI
	docker-compose exec postgres-nginx-tcp psql -U $$POSTGRES_USER -d $$POSTGRES_DB

info: ## Показать информацию о проекте
	@echo "$(YELLOW)PHP-Nginx-TCP Development Environment$(NC)"
	@echo "======================================"
	@echo "$(GREEN)Сервисы:$(NC)"
	@echo "  • PHP-FPM 8.4 (Alpine)"
	@echo "  • Nginx"
	@echo "  • PostgreSQL 17"
	@echo "  • pgAdmin 4"
	@echo ""
	@echo "$(GREEN)Структура:$(NC)"
	@echo "  • public/           - публичные файлы (DocumentRoot)"
	@echo "  • config/nginx/     - конфигурация Nginx"
	@echo "  • config/php/       - конфигурация PHP (php.ini)"
	@echo "  • env/.env          - переменные окружения"
	@echo ""
	@echo "$(GREEN)Порты:$(NC)"
	@echo "  • 80   - Nginx"
	@echo "  • 5432 - PostgreSQL"
	@echo "  • 8080 - pgAdmin"
	@echo "  • 9000 - PHP-FPM (внутренний)"

test: ## Проверить работу сервисов
	@echo "$(YELLOW)Проверка работы сервисов...$(NC)"
	@echo -n "Nginx (http://localhost): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo -n "pgAdmin (http://localhost:8080): "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo "$(YELLOW)Статус контейнеров:$(NC)"
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

clean: ## Остановка и удаление контейнеров
	@echo "$(YELLOW)Очистка контейнеров...$(NC)"
	docker-compose down -v
	@echo "$(GREEN)✓ Контейнеры и тома удалены$(NC)"

clean-all: ## Полная очистка (контейнеры, образы, тома)
	@echo "$(YELLOW)Полная очистка...$(NC)"
	docker-compose down -v
	docker-compose down --rmi all
	@echo "$(GREEN)✓ Выполнена полная очистка$(NC)"

dev-reset: clean-all build up ## Сброс среды разработки
	@echo "$(GREEN)✓ Среда разработки сброшена и перезапущена!$(NC)"

# Утилиты для работы с файлами
permissions: ## Исправить права доступа к файлам проекта
	@echo "$(YELLOW)Исправление прав доступа...$(NC)"
	chmod -R 755 public/
	@echo "$(GREEN)✓ Права доступа исправлены$(NC)"

# Composer команды
composer-install: ## Установить зависимости через Composer
	docker-compose exec php-nginx-tcp composer install

composer-update: ## Обновить зависимости через Composer
	docker-compose exec php-nginx-tcp composer update

composer-require: ## Установить пакет через Composer (make composer-require PACKAGE=vendor/package)
	docker-compose exec php-nginx-tcp composer require $(PACKAGE)

# Команда по умолчанию
.DEFAULT_GOAL := help
