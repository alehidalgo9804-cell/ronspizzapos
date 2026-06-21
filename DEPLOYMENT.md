# Ron's Pizza POS - Configuración de Despliegue

## Base de Datos (HostGator MySQL)

| Campo | Valor |
|-------|-------|
| Host | `www.ronspizza.net` |
| Base de datos | `alexishi_ronspizza_pos` |
| Usuario DB | `alexishi_pos_user` |
| Contraseña DB | `LC6Cz5VRNMFO` |
| Puerto | 3306 |
| Charset | `utf8mb4` |

### Archivo de configuración PHP
`backend/config/database.php`

```php
<?php

declare(strict_types=1);

use App\Core\Env;

return [
    'host' => Env::get('DB_HOST', 'www.ronspizza.net'),
    'port' => (int) Env::get('DB_PORT', 3306),
    'name' => Env::get('DB_NAME', 'alexishi_ronspizza_pos'),
    'user' => Env::get('DB_USER', 'alexishi_pos_user'),
    'pass' => Env::get('DB_PASS', 'LC6Cz5VRNMFO'),
    'charset' => Env::get('DB_CHARSET', 'utf8mb4'),
];
```

### Archivo `.env` de producción (`backend/.env` a subir a HostGator)
```
APP_ENV=production
APP_DEBUG=false
APP_URL=https://ronspizza.net/ronspizzapos/backend/public

DB_HOST=www.ronspizza.net
DB_PORT=3306
DB_NAME=alexishi_ronspizza_pos
DB_USER=alexishi_pos_user
DB_PASS=LC6Cz5VRNMFO
DB_CHARSET=utf8mb4

GOOGLE_MAPS_API_KEY=
```

> **Nota:** El `.env` local de desarrollo en tu máquina sigue usando `127.0.0.1` y `root`. No lo modifiques.

---

## API - URLs

| Entorno | URL Base |
|---------|----------|
| Producción (HostGator) | `https://ronspizza.net/ronspizzapos/backend/public` |
| API endpoint | `https://ronspizza.net/ronspizzapos/backend/public/api/v1` |

---

## Acceso SSH/SCP (HostGator)

| Campo | Valor |
|-------|-------|
| Servidor | `www.ronspizza.net` |
| Puerto SSH | `22` |
| Usuario SSH | `alexishi` |
| Método auth | Clave SSH (sin contraseña) |
| Clave privada local | `C:\Users\alehi\.ssh\ronspizza_deploy` |
| Clave pública | `C:\Users\alehi\.ssh\ronspizza_deploy.pub` |
| Shell en servidor | **Deshabilitada** (solo SCP funciona) |

### Directorio de despliegue en servidor
```
public_html/ronspizzapos/backend/
├── app/
│   ├── Controllers/V1/
│   ├── Core/
│   ├── DTOs/
│   ├── Middleware/
│   ├── Models/
│   ├── Repositories/
│   └── Services/
├── bootstrap/
│   └── app.php
├── config/
│   └── database.php
├── public/
│   ├── .htaccess
│   ├── backoffice/
│   ├── index.php
│   ├── setup_mesas.php
│   └── verificar_pedido.php
├── routes/
│   └── api_v1.php
├── .env
└── .env.example
```

### Comando SCP para subir archivos
```bash
# Subir un controller
scp -i C:\Users\alehi\.ssh\ronspizza_deploy \
  backend/app/Controllers/V1/NombreController.php \
  alexishi@www.ronspizza.net:public_html/ronspizzapos/backend/app/Controllers/V1/NombreController.php

# Subir un modelo
scp -i C:\Users\alehi\.ssh\ronspizza_deploy \
  backend/app/Models/NombreModel.php \
  alexishi@www.ronspizza.net:public_html/ronspizzapos/backend/app/Models/NombreModel.php

# Subir rutas
scp -i C:\Users\alehi\.ssh\ronspizza_deploy \
  backend/routes/api_v1.php \
  alexishi@www.ronspizza.net:public_html/ronspizzapos/backend/routes/api_v1.php

# Subir archivo .env de producción
scp -i C:\Users\alehi\.ssh\ronspizza_deploy \
  backend/.env.production \
  alexishi@www.ronspizza.net:public_html/ronspizzapos/backend/.env

# Subir archivos del backoffice
scp -i C:\Users\alehi\.ssh\ronspizza_deploy \
  -r backend/public/backoffice/* \
  alexishi@www.ronspizza.net:public_html/ronspizzapos/backend/public/backoffice/
```

---

## Compilación APK Flutter

```bash
cd flutter_pos
flutter build apk --release
```

Salida: `flutter_pos/build/app/outputs/flutter-apk/app-release.apk`

---

## Notas importantes

1. **Shell deshabilitada en HostGator**: No se pueden ejecutar comandos SSH directamente. Solo funciona SCP para subir archivos.
2. **Base de datos online**: La app es 100% online, no usa SQLite local.
3. **API Base URL en Flutter**: Configurada en `flutter_pos/lib/core/config/app_config.dart` → apunta a `https://ronspizza.net/ronspizzapos/backend/public` por defecto.
4. **CORS**: Ya está configurado en `backend/public/index.php` para permitir peticiones desde cualquier origen.
5. **Backoffice**: Disponible en `https://ronspizza.net/ronspizzapos/backend/public/backoffice/`
