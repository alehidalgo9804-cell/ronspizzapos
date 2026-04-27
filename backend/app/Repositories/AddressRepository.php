<?php

declare(strict_types=1);

namespace App\Repositories;

final class AddressRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct('direcciones_cliente');
    }
}