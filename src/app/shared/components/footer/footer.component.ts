import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-footer',
  standalone: true,
  imports: [RouterLink],
  template: `
    <footer class="bg-[#071F24] border-t border-emerald-950/80 text-white pt-20 pb-12">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-16">
          
          <!-- Brand -->
          <div class="space-y-6">
            <a routerLink="/" class="flex items-center gap-3 group">
              <div class="w-10 h-10 rounded-xl bg-white shadow-md flex items-center justify-center p-1.5 shrink-0 group-hover:scale-105 transition-transform">
                <svg width="26" height="26" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#13C7A3"/>
                  <path d="M14 20L18 24L26 16" stroke="white" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </div>
              <div class="flex flex-col">
                <div class="flex items-baseline gap-1 leading-none">
                  <span class="font-display text-lg font-bold text-white tracking-tight">Club des</span>
                  <span class="font-display text-lg font-black text-[#13C7A3] tracking-tight">Formateurs</span>
                </div>
                <span class="text-[9px] font-semibold text-emerald-300/70 uppercase tracking-widest mt-1">
                  Plateforme Pédagogique
                </span>
              </div>
            </a>

            <p class="text-slate-300 text-sm leading-relaxed">
              La plateforme d'excellence qui connecte les apprenants aux formateurs et experts pour développer les compétences de haut niveau.
            </p>

            <!-- Reassurance Badges -->
            <div class="flex flex-wrap gap-2 pt-1">
              <span class="px-2.5 py-1 rounded-lg bg-emerald-950/80 border border-emerald-800/50 text-[11px] font-bold text-emerald-300">
                ⚡ Wave & Orange Money
              </span>
              <span class="px-2.5 py-1 rounded-lg bg-emerald-950/80 border border-emerald-800/50 text-[11px] font-bold text-emerald-300">
                🎓 Certificats Vérifiés
              </span>
            </div>
          </div>

          <!-- Links 1 -->
          <div>
            <h4 class="font-bold text-white mb-6 uppercase tracking-widest text-xs border-b border-emerald-900/60 pb-2">
              Formations & Cours
            </h4>
            <ul class="space-y-3.5 text-sm">
              <li><a routerLink="/catalogue" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Catalogue des cours</a></li>
              <li><a routerLink="/formateurs" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Nos Professeurs & Formateurs</a></li>
              <li><a routerLink="/auth/register" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Devenir Formateur Certifié</a></li>
              <li><a routerLink="/auth/login" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Espace Apprenant</a></li>
            </ul>
          </div>

          <!-- Links 2 -->
          <div>
            <h4 class="font-bold text-white mb-6 uppercase tracking-widest text-xs border-b border-emerald-900/60 pb-2">
              Légal & Sécurité
            </h4>
            <ul class="space-y-3.5 text-sm">
              <li><a routerLink="/" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Conditions Générales (CGU)</a></li>
              <li><a routerLink="/" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Politique de Confidentialité</a></li>
              <li><a routerLink="/" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Charte Pédagogique</a></li>
              <li><a routerLink="/" class="text-slate-300 hover:text-[#13C7A3] transition-colors font-medium">Sécurité des Paiements</a></li>
            </ul>
          </div>

          <!-- Newsletter -->
          <div>
            <h4 class="font-bold text-white mb-6 uppercase tracking-widest text-xs border-b border-emerald-900/60 pb-2">
              Restez Informé
            </h4>
            <p class="text-slate-300 text-sm mb-4">
              Recevez les nouvelles formations et les invitations aux masterclasses en direct.
            </p>
            <div class="flex gap-2">
              <input type="email" placeholder="Votre adresse email" 
                     class="flex-1 bg-emerald-950/60 border border-emerald-800/60 text-white rounded-xl px-4 py-2.5 text-xs placeholder:text-slate-400 focus:outline-none focus:border-[#13C7A3] transition-colors">
              <button class="bg-[#13C7A3] text-white px-4 py-2.5 rounded-xl hover:bg-[#12A57A] transition-all font-bold text-xs shadow-md shadow-emerald-500/20">
                S'abonner
              </button>
            </div>
          </div>

        </div>

        <!-- Bottom -->
        <div class="pt-8 border-t border-emerald-900/60 flex flex-col md:flex-row justify-between items-center gap-4 text-xs">
          <p class="text-slate-400 font-medium">
            © 2026 Club des Formateurs. Tous droits réservés. Plateforme certifiée.
          </p>
          <p class="text-slate-400 font-medium flex items-center gap-1.5">
            <span>Conçu avec passion pour l'excellence de la formation</span>
          </p>
        </div>
      </div>
    </footer>
  `,
})
export class FooterComponent {}
