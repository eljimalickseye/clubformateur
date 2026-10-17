<?php

namespace App\Support;

use Closure;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

/**
 * Cache du catalogue et des lecons.
 *
 * Les cles portent un numero de version : invalider revient a changer ce
 * numero, ce qui fonctionne avec tous les pilotes (database, redis, array)
 * sans dependre des tags.
 */
class CourseCache
{
    private const VERSION_KEY = 'courses:version';

    /** Duree de vie, en secondes. L'invalidation explicite prime sur ce delai. */
    public const TTL = 600;

    public static function remember(string $key, Closure $callback): mixed
    {
        return Cache::remember('courses:' . self::version() . ':' . $key, self::TTL, $callback);
    }

    /** A appeler apres toute ecriture touchant une formation, une lecon, un replay ou un compteur. */
    public static function flush(): void
    {
        Cache::forever(self::VERSION_KEY, (string) Str::uuid());
    }

    private static function version(): string
    {
        return Cache::rememberForever(self::VERSION_KEY, fn () => (string) Str::uuid());
    }
}
