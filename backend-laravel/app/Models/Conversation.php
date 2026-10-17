<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    protected $fillable = [
        'conversation_uid',
        'student_id',
        'student_name',
        'student_photo_url',
        'teacher_id',
        'teacher_name',
        'teacher_photo_url',
        'course_id',
        'course_title',
        'last_message',
        'last_message_at',
        'unread_count',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
        'unread_count' => 'integer',
    ];
}
