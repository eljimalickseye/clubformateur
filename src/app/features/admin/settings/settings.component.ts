import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-admin-settings',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div class="mb-6 rounded-2xl border border-dark-border bg-dark-surface p-6 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <p class="text-xs uppercase tracking-wider text-light-muted mb-2">Settings & Profile</p>
          <h1 class="font-display text-2xl font-bold text-light">Parametres administrateur</h1>
          <p class="text-sm text-light-muted mt-1">Configuration plateforme, securite et profil.</p>
        </div>
        <a routerLink="/admin/dashboard" class="btn-secondary w-fit">Retour dashboard</a>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-[320px_1fr] gap-6">
        <aside class="card p-5">
          <div class="flex items-center gap-3 mb-4">
            <div class="h-14 w-14 rounded-full bg-primary/15 text-primary flex items-center justify-center font-bold text-lg">
              A
            </div>
            <div>
              <p class="text-sm font-semibold text-light">Admin Anour</p>
              <p class="text-xs text-light-muted">admin&#64;anour.app</p>
            </div>
          </div>
          <div class="space-y-2 text-sm">
            <button class="w-full text-left px-3 py-2 rounded-lg bg-primary/10 text-primary">Profil</button>
            <button class="w-full text-left px-3 py-2 rounded-lg hover:bg-dark-surface2 text-light-muted hover:text-light">Notifications</button>
            <button class="w-full text-left px-3 py-2 rounded-lg hover:bg-dark-surface2 text-light-muted hover:text-light">Securite</button>
            <button class="w-full text-left px-3 py-2 rounded-lg hover:bg-dark-surface2 text-light-muted hover:text-light">Facturation</button>
          </div>
        </aside>

        <section class="space-y-6">
          <div class="card p-6">
            <h2 class="font-display text-xl font-semibold text-light mb-4">Profil</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <label class="block">
                <span class="input-label">Nom complet</span>
                <input class="input" value="Administrateur Anour" />
              </label>
              <label class="block">
                <span class="input-label">Email</span>
                <input class="input" value="admin&#64;anour.app" />
              </label>
              <label class="block">
                <span class="input-label">Telephone</span>
                <input class="input" value="+221 77 000 00 00" />
              </label>
              <label class="block">
                <span class="input-label">Role</span>
                <input class="input" value="Super Admin" />
              </label>
            </div>
            <div class="mt-4">
              <button class="btn-primary">Enregistrer les modifications</button>
            </div>
          </div>

          <div class="card p-6">
            <h2 class="font-display text-xl font-semibold text-light mb-4">Securite</h2>
            <div class="space-y-3 text-sm">
              <label class="flex items-center justify-between p-3 rounded-lg border border-dark-border">
                <span class="text-light">Double authentification (2FA)</span>
                <input type="checkbox" class="accent-primary" checked />
              </label>
              <label class="flex items-center justify-between p-3 rounded-lg border border-dark-border">
                <span class="text-light">Alertes connexion suspecte</span>
                <input type="checkbox" class="accent-primary" checked />
              </label>
            </div>
          </div>
        </section>
      </div>
    </div>
  `,
})
export class AdminSettingsComponent {}
