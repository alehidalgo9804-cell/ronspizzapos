<?php

declare(strict_types=1);

namespace App\Core;

use Throwable;

final class Router
{
    private array $routes = [];
    private string $groupPrefix = '';
    private array $groupMiddleware = [];

    public function group(string $prefix, array $middleware, callable $callback): void
    {
        $previousPrefix = $this->groupPrefix;
        $previousMiddleware = $this->groupMiddleware;

        $this->groupPrefix .= rtrim($prefix, '/');
        $this->groupMiddleware = array_merge($this->groupMiddleware, $middleware);

        $callback($this);

        $this->groupPrefix = $previousPrefix;
        $this->groupMiddleware = $previousMiddleware;
    }

    public function get(string $path, callable|array $handler, array $middleware = []): void
    {
        $this->add('GET', $path, $handler, $middleware);
    }

    public function post(string $path, callable|array $handler, array $middleware = []): void
    {
        $this->add('POST', $path, $handler, $middleware);
    }

    public function put(string $path, callable|array $handler, array $middleware = []): void
    {
        $this->add('PUT', $path, $handler, $middleware);
    }

    public function delete(string $path, callable|array $handler, array $middleware = []): void
    {
        $this->add('DELETE', $path, $handler, $middleware);
    }

    public function add(string $method, string $path, callable|array $handler, array $middleware = []): void
    {
        $fullPath = $this->normalizePath($this->groupPrefix . '/' . ltrim($path, '/'));
        $routeMiddleware = array_merge($this->groupMiddleware, $middleware);
        [$pattern, $params] = $this->compilePath($fullPath);

        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $fullPath,
            'pattern' => $pattern,
            'params' => $params,
            'handler' => $handler,
            'middleware' => $routeMiddleware,
        ];
    }

    public function dispatch(Request $request): void
    {
        foreach ($this->routes as $route) {
            if ($route['method'] !== $request->method) {
                continue;
            }

            if (!preg_match($route['pattern'], $request->uri, $matches)) {
                continue;
            }

            foreach ($route['params'] as $param) {
                $request->params[$param] = $matches[$param] ?? null;
            }

            $this->runMiddleware(0, $route['middleware'], $request, function (Request $request) use ($route) {
                $this->executeHandler($route['handler'], $request);
            });
            return;
        }

        Response::json(['success' => false, 'message' => 'Not found'], 404);
    }

    private function runMiddleware(int $index, array $middleware, Request $request, callable $destination): mixed
    {
        if (!isset($middleware[$index])) {
            return $destination($request);
        }

        $current = $middleware[$index];

        $next = function (Request $request) use ($index, $middleware, $destination) {
            return $this->runMiddleware($index + 1, $middleware, $request, $destination);
        };

        if ($current instanceof MiddlewareInterface) {
            return $current->handle($request, $next);
        }

        if (is_callable($current)) {
            return $current($request, $next);
        }

        if (is_string($current) && class_exists($current)) {
            $instance = new $current();
            if ($instance instanceof MiddlewareInterface) {
                return $instance->handle($request, $next);
            }
        }

        return $next($request);
    }

    private function executeHandler(callable|array $handler, Request $request): void
    {
        try {
            if (is_array($handler)) {
                [$class, $method] = $handler;
                $instance = new $class();
                $instance->{$method}($request);
                return;
            }

            $handler($request);
        } catch (Throwable $throwable) {
            Response::json([
                'success' => false,
                'message' => 'Internal server error',
                'error' => $throwable->getMessage(),
            ], 500);
        }
    }

    private function compilePath(string $path): array
    {
        $params = [];
        $pattern = preg_replace_callback('/\{([a-zA-Z0-9_]+)\}/', function (array $matches) use (&$params) {
            $params[] = $matches[1];
            return '(?<' . $matches[1] . '>[^/]+)';
        }, $path);

        return ['#^' . $pattern . '$#', $params];
    }

    private function normalizePath(string $path): string
    {
        $path = preg_replace('#/+#', '/', $path) ?? $path;
        $path = rtrim($path, '/');
        return $path === '' ? '/' : $path;
    }
}
