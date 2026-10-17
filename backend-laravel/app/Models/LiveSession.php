<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LiveSession extends Model
{
    protected $fillable = [
        'session_uid',
        'course_id',
        'course_name',
        'title',
        'teacher_id',
        'teacher_name',
        'teacher_photo_url',
        'status',
        'room_name',
        'session_type',
        'host_role',
        'phase',
        'participant_count',
        'connected_participants',
        'raised_hands',
        'has_replay',
        'replay_url',
        'replay_duration',
        'scheduled_at',
        'started_at',
        'ended_at',
    ];

    protected $casts = [
        'participant_count' => 'integer',
        'connected_participants' => 'array',
        'raised_hands' => 'array',
        'has_replay' => 'boolean',
        'scheduled_at' => 'datetime',
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];
}
