<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CourseLesson extends Model
{
    protected $fillable = [
        'course_id',
        'lesson_uid',
        'title',
        'duration',
        'video_url',
        'is_free_preview',
        'sort_order',
    ];

    protected $casts = [
        'is_free_preview' => 'boolean',
        'sort_order' => 'integer',
    ];
}
