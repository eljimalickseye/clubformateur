<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LegalDocument extends Model
{
    protected $fillable = [
        'doc_uid',
        'title',
        'category',
        'version',
        'content',
        'accepted_by',
    ];

    protected $casts = [
        'accepted_by' => 'array',
    ];
}
