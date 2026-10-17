<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Enrollment extends Model
{
    protected $fillable = [
        'enrollment_uid',
        'student_id',
        'student_name',
        'course_id',
        'course_title',
        'course_image',
        'trainer_name',
        'category',
        'price_cfa',
        'payment_method',
        'status',
        'progress_percent',
        'completed_lessons',
    ];

    protected $casts = [
        'price_cfa' => 'integer',
        'progress_percent' => 'integer',
        'completed_lessons' => 'array',
    ];
}
