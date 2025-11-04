<?php
// Простая страница для проверки работы в runtime
// - Проверяет, что PHP-FPM обрабатывает запросы через Nginx FastCGI по TCP
// - Показывает минимальную информацию и пример DSN для подключения к PostgreSQL

echo "<h1>PHP-Nginx-TCP — PHP работает ✅</h1>";
echo "<p>Время сервера: " . date('Y-m-d H:i:s') . " (UTC)</p>";

$dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', 'postgres-nginx-tcp', 5432, getenv('POSTGRES_DB') ?: 'app');
echo "<p>DSN для PostgreSQL: <code>{$dsn}</code></p>";

echo '<p><a href="phpinfo.php">phpinfo()</a></p>';
