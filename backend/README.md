# Ron's Pizza POS Backend

## Requisitos

- PHP 8.1+
- MySQL 8+

## Configuracion

1. Copiar `.env.example` a `.env`.
2. Configurar credenciales de MySQL.

## Migraciones y seeders

```bash
php scripts/migrate.php
php scripts/seed.php
```

## Ejecutar API local

```bash
php -S localhost:8080 -t public
```

Base URL:

`http://localhost:8080/api/v1`

## Endpoints principales

- `POST /api/v1/auth/login`
- `GET /api/v1/customers/by-phone/{phone}`
- `POST /api/v1/orders/quick-phone`
- `POST /api/v1/deliveries/assign`
- `POST /api/v1/cash/open`
- `POST /api/v1/payments`