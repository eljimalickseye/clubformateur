<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudyGroup extends Model
{
    protected $fillable = [
        'group_uid',
        'name',
        'category',
        'description',
        'creator_id',
        'creator_name',
        'members_count',
        'member_ids',
    ];

    protected $casts = [
        'members_count' => 'integer',
        'member_ids' => 'array',
    ];
}
