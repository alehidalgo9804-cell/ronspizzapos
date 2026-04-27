<?php

declare(strict_types=1);

namespace App\Core;

final class Validator
{
    public static function require(array $data, array $fields): array
    {
        $errors = [];
        foreach ($fields as $field) {
            if (!array_key_exists($field, $data) || $data[$field] === null || $data[$field] === '') {
                $errors[$field][] = 'required';
            }
        }

        return $errors;
    }
}
