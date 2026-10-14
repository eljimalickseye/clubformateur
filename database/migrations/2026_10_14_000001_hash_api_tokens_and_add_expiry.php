<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('api_token_expires_at')->nullable()->after('api_token');
        });

        // Les jetons existants deviennent des empreintes : les sessions en cours
        // restent valides cote client (qui detient la valeur en clair) et
        // expirent dans 30 jours.
        DB::table('users')->whereNotNull('api_token')->orderBy('id')->each(function ($user) {
            DB::table('users')->where('id', $user->id)->update([
                'api_token' => hash('sha256', $user->api_token),
                'api_token_expires_at' => now()->addDays(30),
            ]);
        });
    }

    public function down(): void
    {
        // Les empreintes ne sont pas reversibles : les jetons sont invalides.
        DB::table('users')->update(['api_token' => null]);
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('api_token_expires_at');
        });
    }
};
