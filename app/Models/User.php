<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;

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
        'api_token', // empreinte SHA-256 uniquement, jamais alimente par une requete
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'api_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_verified' => 'boolean',
            'onboarding_step' => 'integer',
            'balance_fcfa' => 'integer',
            'api_token_expires_at' => 'datetime',
        ];
    }

    /** Duree de validite d'un jeton d'API, en jours. */
    public const TOKEN_TTL_DAYS = 30;

    /**
     * Genere un nouveau jeton, ne conserve que son empreinte SHA-256 et
     * retourne la valeur en clair, qui ne sera plus jamais relisible.
     */
    public function issueToken(): string
    {
        $plain = Str::random(80);
        $this->forceFill([
            'api_token' => hash('sha256', $plain),
            'api_token_expires_at' => now()->addDays(self::TOKEN_TTL_DAYS),
        ])->save();

        return $plain;
    }

    public function revokeToken(): void
    {
        $this->forceFill(['api_token' => null, 'api_token_expires_at' => null])->save();
    }

    public static function findByToken(?string $plain): ?self
    {
        if (!$plain) {
            return null;
        }

        return static::where('api_token', hash('sha256', $plain))
            ->where(function ($q) {
                $q->whereNull('api_token_expires_at')->orWhere('api_token_expires_at', '>', now());
            })
            ->first();
    }
}
