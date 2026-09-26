<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Certificate extends Model
{
    protected $fillable = [
        'certificate_code',
        'student_id',
        'student_name',
        'course_id',
        'course_title',
        'teacher_name',
        'issued_at',
    ];

    protected $casts = [
        'issued_at' => 'datetime',
    ];
}
