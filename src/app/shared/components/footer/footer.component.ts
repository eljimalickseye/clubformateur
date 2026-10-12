import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-footer',
  standalone: true,
  imports: [RouterLink],
  template: `
    <footer class="bg-white border-t border-dark-border pt-20 pb-10">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-16">
          
          <!-- Brand -->
          <div class="space-y-6">
            <a routerLink="/" class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-primary flex items-center justify-center shadow-lg shadow-primary/20">
                <span class="text-white font-display font-black text-xl">C</span>
              </div>
              <span class="font-display text-2xl font-black text-light tracking-tighter">
                Club des Formateurs
              </span>
            </a>
            <p class="text-light-muted leading-relaxed">
              La plateforme de formation nouvelle génération. Apprenez, enseignez et grandissez avec une communauté passionnée.
            </p>
            <div class="flex gap-4">
              <a href="#" class="w-10 h-10 rounded-xl bg-dark-surface2 flex items-center justify-center text-light-muted hover:bg-primary hover:text-white transition-all">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z"/></svg>
              </a>
              <a href="#" class="w-10 h-10 rounded-xl bg-dark-surface2 flex items-center justify-center text-light-muted hover:bg-primary hover:text-white transition-all">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
              </a>
            </div>
          </div>

          <!-- Links 1 -->
          <div>
            <h4 class="font-bold text-light mb-6 uppercase tracking-widest text-xs">Plateforme</h4>
            <ul class="space-y-4">
              <li><a routerLink="/catalogue" class="text-light-muted hover:text-primary transition-colors font-medium">Catalogue des cours</a></li>
              <li><a routerLink="/auth/register" class="text-light-muted hover:text-primary transition-colors font-medium">Devenir formateur</a></li>
              <li><a href="#" class="text-light-muted hover:text-primary transition-colors font-medium">Tarifications</a></li>
              <li><a href="#" class="text-light-muted hover:text-primary transition-colors font-medium">Aide & Support</a></li>
            </ul>
          </div>

          <!-- Links 2 -->
          <div>
            <h4 class="font-bold text-light mb-6 uppercase tracking-widest text-xs">Légal</h4>
            <ul class="space-y-4">
              <li><a href="#" class="text-light-muted hover:text-primary transition-colors font-medium">Conditions d'utilisation</a></li>
              <li><a href="#" class="text-light-muted hover:text-primary transition-colors font-medium">Politique de confidentialité</a></li>
              <li><a href="#" class="text-light-muted hover:text-primary transition-colors font-medium">Mentions légales</a></li>
              <li><a href="#" class="text-light-muted hover:text-primary transition-colors font-medium">Cookies</a></li>
            </ul>
          </div>

          <!-- Newsletter -->
          <div>
            <h4 class="font-bold text-light mb-6 uppercase tracking-widest text-xs">Newsletter</h4>
            <p class="text-light-muted mb-4">Recevez les dernières nouveautés et offres exclusives.</p>
            <div class="flex gap-2">
              <input type="email" placeholder="Votre email" class="flex-1 bg-dark-surface2 border border-dark-border rounded-xl px-4 py-2 text-sm focus:outline-none focus:border-primary transition-colors">
              <button class="bg-primary text-white p-2.5 rounded-xl hover:bg-primary-600 transition-all">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3"/></svg>
              </button>
            </div>
          </div>

        </div>

        <!-- Bottom -->
        <div class="pt-8 border-t border-dark-border flex flex-col md:flex-row justify-between items-center gap-4">
          <p class="text-light-muted text-sm font-medium">
            © 2026 Club des Formateurs. Tous droits réservés.
          </p>
          <p class="text-light-muted text-sm font-medium flex items-center gap-1">
            Fait avec <span class="text-red-500 text-lg">♥</span> par l'équipe Club des Formateurs
          </p>
        </div>
      </div>
    </footer>
  `,
})
export class FooterComponent {}
