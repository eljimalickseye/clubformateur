import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-admin-analytics',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div class="mb-6 rounded-2xl border border-dark-border bg-dark-surface p-6 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <p class="text-xs uppercase tracking-wider text-light-muted mb-2">Platform Analytics</p>
          <h1 class="font-display text-2xl font-bold text-light">Analytics</h1>
          <p class="text-sm text-light-muted mt-1">Vue globale des performances business et pedagogiques.</p>
        </div>
        <div class="flex items-center gap-2">
          <button class="btn-secondary">7 jours</button>
          <button class="btn-secondary">30 jours</button>
          <button class="btn-primary">90 jours</button>
        </div>
      </div>

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="card p-5"><p class="text-xs text-light-muted">Utilisateurs actifs</p><p class="font-display text-3xl font-bold text-light mt-1">8 420</p></div>
        <div class="card p-5"><p class="text-xs text-light-muted">Nouveaux inscrits</p><p class="font-display text-3xl font-bold text-light mt-1">1 120</p></div>
        <div class="card p-5"><p class="text-xs text-light-muted">Taux completion</p><p class="font-display text-3xl font-bold text-emerald-500 mt-1">68%</p></div>
        <div class="card p-5"><p class="text-xs text-light-muted">MRR</p><p class="font-display text-3xl font-bold text-primary mt-1">12.4M F</p></div>
      </div>

      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <section class="xl:col-span-2 card p-5">
          <h2 class="font-display text-lg font-semibold text-light mb-4">Revenus mensuels</h2>
          <div class="h-72 rounded-xl border border-dark-border bg-dark p-4 flex items-end gap-2">
            @for (v of [35,42,51,48,65,72,70,82,78,88,91,95]; track v) {
              <div class="flex-1 bg-primary/20 rounded-t relative">
                <div class="absolute bottom-0 left-0 right-0 bg-primary rounded-t" [style.height.%]="v"></div>
              </div>
            }
          </div>
        </section>

        <section class="card p-5">
          <h2 class="font-display text-lg font-semibold text-light mb-4">Top categories</h2>
          <div class="space-y-3">
            @for (cat of ['Informatique', 'Business', 'Design', 'Marketing', 'Langues']; track cat; let i = $index) {
              <div>
                <div class="flex items-center justify-between text-sm mb-1">
                  <span class="text-light">{{ cat }}</span>
                  <span class="text-light-muted">{{ 90 - (i * 12) }}%</span>
                </div>
                <div class="h-2 rounded-full bg-dark-surface2">
                  <div class="h-2 rounded-full bg-primary" [style.width.%]="90 - (i * 12)"></div>
                </div>
              </div>
            }
          </div>
          <a routerLink="/admin/payments" class="inline-block mt-5 text-sm text-primary font-medium hover:underline">Voir les paiements</a>
        </section>
      </div>
    </div>
  `,
})
export class AdminAnalyticsComponent {}
