import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="min-h-screen bg-dark flex items-center justify-center px-4">
      <div class="text-center">
        <div class="font-display text-9xl font-bold text-primary/20 mb-4">404</div>
        <h1 class="font-display text-3xl font-bold text-light mb-3">Page introuvable</h1>
        <p class="text-light-muted mb-8">La page que vous cherchez n'existe pas ou a été déplacée.</p>
        <a routerLink="/" class="px-6 py-3 bg-primary text-white font-semibold rounded-lg hover:bg-primary-400 transition-colors">
          Retour à l'accueil
        </a>
      </div>
    </div>
  `,
})
export class NotFoundComponent {}
