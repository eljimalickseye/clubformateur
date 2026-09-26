<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'user_id',
        'external_transaction_id',
        'type',
        'provider_code',
        'provider_name',
        'phone',
        'amount_fcfa',
        'status',
    ];

    protected $casts = [
        'amount_fcfa' => 'integer',
    ];
}
