<?php

declare(strict_types=1);

namespace App\Controllers\V1;

use App\Core\Controller;
use App\Core\Database;
use App\Core\Request;
use PDO;

final class AdminCustomerController extends Controller
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function index(Request $request): void
    {
        $busqueda = trim((string) ($request->query['busqueda'] ?? ''));
        $page = max(1, (int) ($request->query['page'] ?? 1));
        $limit = 50;
        $offset = ($page - 1) * $limit;

        $where = ['c.deleted_at IS NULL'];
        $params = [];

        if ($busqueda !== '') {
            $where[] = '(c.nombre LIKE :q OR c.apellidos LIKE :q OR c.telefono LIKE :q OR c.telefono_alterno LIKE :q OR c.email LIKE :q)';
            $params['q'] = '%' . $busqueda . '%';
        }

        $sqlCount = 'SELECT COUNT(*) FROM clientes c WHERE ' . implode(' AND ', $where);
        $countStmt = $this->db->prepare($sqlCount);
        $countStmt->execute($params);
        $total = (int) $countStmt->fetchColumn();

        $sql = 'SELECT c.id, c.nombre, c.apellidos, c.telefono, c.telefono_alterno, c.email, c.notas, c.activo, c.created_at,
                       COUNT(d.id) as total_direcciones
                FROM clientes c
                LEFT JOIN direcciones_cliente d ON d.cliente_id = c.id AND d.deleted_at IS NULL
                WHERE ' . implode(' AND ', $where) . '
                GROUP BY c.id
                ORDER BY c.id DESC
                LIMIT ' . $limit . ' OFFSET ' . $offset;

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $this->ok([
            'data' => $rows,
            'meta' => ['page' => $page, 'limit' => $limit, 'total' => $total, 'pages' => (int) ceil($total / $limit)],
        ]);
    }

    public function show(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);

        $cliente = $this->db->prepare('SELECT * FROM clientes WHERE id = :id AND deleted_at IS NULL LIMIT 1');
        $cliente->execute(['id' => $id]);
        $row = $cliente->fetch(PDO::FETCH_ASSOC);

        if (!$row) {
            $this->fail('Cliente no encontrado', 404);
            return;
        }

        $direcciones = $this->db->prepare('SELECT * FROM direcciones_cliente WHERE cliente_id = :id AND deleted_at IS NULL ORDER BY id DESC');
        $direcciones->execute(['id' => $id]);
        $row['direcciones'] = $direcciones->fetchAll(PDO::FETCH_ASSOC);

        $this->ok($row);
    }

    public function store(Request $request): void
    {
        $data = $this->validate($request->body);
        if (!$data['valid']) {
            $this->fail($data['errors'], 422);
            return;
        }

        $stmt = $this->db->prepare(
            'INSERT INTO clientes (nombre, apellidos, telefono, telefono_alterno, email, notas, activo, created_at, updated_at)
             VALUES (:nombre, :apellidos, :telefono, :telefono_alt, :email, :notas, 1, NOW(), NOW())'
        );
        $stmt->execute([
            'nombre' => $data['nombre'],
            'apellidos' => $data['apellidos'] ?? '',
            'telefono' => $data['telefono'] ?? '',
            'telefono_alt' => $data['telefono_alterno'] ?? '',
            'email' => $data['email'] ?? '',
            'notas' => $data['notas'] ?? '',
        ]);

        $id = (int) $this->db->lastInsertId();

        // Crear direccion si viene
        if (!empty($data['direccion']) && is_array($data['direccion'])) {
            $this->insertDireccion($id, $data['direccion']);
        }

        $this->ok(['id' => $id], 'Cliente creado', 201);
    }

    public function update(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $data = $this->validate($request->body, $id);
        if (!$data['valid']) {
            $this->fail($data['errors'], 422);
            return;
        }

        $stmt = $this->db->prepare(
            'UPDATE clientes SET nombre = :nombre, apellidos = :apellidos, telefono = :telefono,
             telefono_alterno = :telefono_alt, email = :email, notas = :notas, updated_at = NOW()
             WHERE id = :id'
        );
        $stmt->execute([
            'id' => $id,
            'nombre' => $data['nombre'],
            'apellidos' => $data['apellidos'] ?? '',
            'telefono' => $data['telefono'] ?? '',
            'telefono_alt' => $data['telefono_alterno'] ?? '',
            'email' => $data['email'] ?? '',
            'notas' => $data['notas'] ?? '',
        ]);

        $this->ok([], 'Cliente actualizado');
    }

    public function destroy(Request $request): void
    {
        $id = (int) ($request->params['id'] ?? 0);
        $this->db->prepare('UPDATE clientes SET deleted_at = NOW(), activo = 0 WHERE id = :id')->execute(['id' => $id]);
        $this->ok([], 'Cliente eliminado');
    }

    public function addAddress(Request $request): void
    {
        $clienteId = (int) ($request->params['id'] ?? 0);
        $dir = $request->body;
        $this->insertDireccion($clienteId, $dir);
        $this->ok([], 'Direccion agregada');
    }

    public function removeAddress(Request $request): void
    {
        $dirId = (int) ($request->params['dirId'] ?? 0);
        $this->db->prepare('UPDATE direcciones_cliente SET deleted_at = NOW() WHERE id = :id')->execute(['id' => $dirId]);
        $this->ok([], 'Direccion eliminada');
    }

    private function insertDireccion(int $clienteId, array $dir): void
    {
        $stmt = $this->db->prepare(
            'INSERT INTO direcciones_cliente (cliente_id, alias, calle, numero_exterior, numero_interior, colonia, ciudad, estado, codigo_postal, referencia, instrucciones_entrega, costo_envio, activa, created_at, updated_at)
             VALUES (:cliente_id, :alias, :calle, :num_ext, :num_int, :colonia, :ciudad, :estado, :cp, :referencia, :instrucciones, :costo_envio, 1, NOW(), NOW())'
        );
        $stmt->execute([
            'cliente_id' => $clienteId,
            'alias' => $dir['alias'] ?? 'Principal',
            'calle' => $dir['calle'] ?? '',
            'num_ext' => $dir['numero_exterior'] ?? '',
            'num_int' => $dir['numero_interior'] ?? '',
            'colonia' => $dir['colonia'] ?? '',
            'ciudad' => $dir['ciudad'] ?? '',
            'estado' => $dir['estado'] ?? '',
            'cp' => $dir['codigo_postal'] ?? '',
            'referencia' => $dir['referencia'] ?? '',
            'instrucciones' => $dir['instrucciones_entrega'] ?? '',
            'costo_envio' => isset($dir['costo_envio']) && is_numeric($dir['costo_envio']) ? (float) $dir['costo_envio'] : 0,
        ]);
    }

    private function validate(array $body, ?int $excludeId = null): array
    {
        $nombre = trim((string) ($body['nombre'] ?? ''));
        $telefono = trim((string) ($body['telefono'] ?? ''));

        $errors = [];
        if ($nombre === '') $errors['nombre'] = 'El nombre es obligatorio';
        if ($telefono === '') $errors['telefono'] = 'El telefono es obligatorio';

        if (!empty($errors)) return ['valid' => false, 'errors' => $errors];

        return array_merge(['valid' => true], $body, ['nombre' => $nombre, 'telefono' => $telefono]);
    }
}
