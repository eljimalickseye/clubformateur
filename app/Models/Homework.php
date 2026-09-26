<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Homework extends Model
{
    protected $table = 'homeworks';

    protected $fillable = [
        'homework_uid',
        'course_id',
        'course_title',
        'lesson_id',
        'student_id',
        'student_name',
        'teacher_id',
        'corrector_id',
        'title',
        'instructions',
        'submission_text',
        'attachment_url',
        'status',
        'grade',
        'feedback',
    ];

    protected $casts = [
        'grade' => 'float',
    ];
}
