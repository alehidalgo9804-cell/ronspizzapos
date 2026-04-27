<?php

declare(strict_types=1);

namespace App\Models;

abstract class BaseModel
{
    protected string $table;
    protected string $primaryKey = 'id';
    protected array $fillable = [];
    protected array $relations = [];

    public function table(): string
    {
        return $this->table;
    }

    public function primaryKey(): string
    {
        return $this->primaryKey;
    }

    public function fillable(): array
    {
        return $this->fillable;
    }

    public function relations(): array
    {
        return $this->relations;
    }
}
