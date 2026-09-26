<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CourseReplay extends Model
{
    protected $fillable = [
        'course_id',
        'replay_uid',
        'title',
        'replay_url',
        'duration',
        'recorded_at',
    ];

    protected $casts = [
        'recorded_at' => 'datetime',
    ];
}
