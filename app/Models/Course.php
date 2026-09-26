<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Course extends Model
{
    protected $fillable = [
        'course_uid',
        'title',
        'category',
        'description',
        'price_cfa',
        'level',
        'duration',
        'lessons_count',
        'rating',
        'students_count',
        'image_url',
        'presentation_video_url',
        'teacher_id',
        'teacher_name',
        'status',
        'is_published',
    ];

    protected $casts = [
        'price_cfa' => 'integer',
        'lessons_count' => 'integer',
        'rating' => 'float',
        'students_count' => 'integer',
        'is_published' => 'boolean',
    ];

    public function lessons(): HasMany
    {
        return $this->hasMany(CourseLesson::class, 'course_id', 'course_uid')->orderBy('sort_order');
    }

    public function replays(): HasMany
    {
        return $this->hasMany(CourseReplay::class, 'course_id', 'course_uid');
    }
}
