<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $fillable = [
        'conversation_id',
        'sender_id',
        'sender_name',
        'sender_role',
        'content',
        'message_type',
        'file_url',
        'file_name',
        'audio_duration',
    ];

    protected $casts = [
        'audio_duration' => 'integer',
    ];
}
