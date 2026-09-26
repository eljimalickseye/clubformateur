<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudyGroupMessage extends Model
{
    protected $fillable = [
        'group_id',
        'sender_id',
        'sender_name',
        'content',
        'message_type',
        'file_url',
        'audio_duration',
    ];

    protected $casts = [
        'audio_duration' => 'integer',
    ];
}
