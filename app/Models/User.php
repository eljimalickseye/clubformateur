<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'uid',
        'name',
        'email',
        'password',
        'role',
        'phone',
        'specialite',
        'bio',
        'photo_url',
        'is_verified',
        'onboarding_step',
        'balance_fcfa',
        'linked_teacher_id',
        'api_token',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_verified' => 'boolean',
            'onboarding_step' => 'integer',
            'balance_fcfa' => 'integer',
        ];
    }
}
