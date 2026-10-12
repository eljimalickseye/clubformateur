import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ToastrService } from 'ngx-toastr';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, BackButtonComponent],
  template: `
    <div class="min-h-[100dvh] bg-[#F8FAFC] flex flex-col justify-center items-center px-4 py-8 font-body">
      
      <!-- Brand Header -->
      <div class="flex items-center gap-2.5 mb-6">
        <a routerLink="/" class="flex items-center gap-2.5 group">
          <svg width="36" height="36" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
            <circle cx="20" cy="20" r="4" fill="white"/>
          </svg>
          <span class="font-display text-xl font-black text-[#0F172A]">Club des Formateurs</span>
        </a>
      </div>

      <div class="w-full max-w-[440px] bg-white border border-[#EEF2FF] rounded-3xl p-6 sm:p-8 shadow-xl shadow-slate-200/50">
        @if (sent()) {
          <div class="text-center py-4 space-y-4">
            <div class="w-16 h-16 rounded-full bg-emerald-50 border-2 border-emerald-200 flex items-center justify-center text-emerald-600 mx-auto">
              <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            <h2 class="font-display text-xl font-bold text-slate-900">Email envoyé !</h2>
            <p class="text-xs sm:text-sm text-slate-500 leading-relaxed">
              Vérifiez votre boîte de réception et cliquez sur le lien sécurisé pour réinitialiser votre mot de passe.
            </p>
            <div class="pt-2">
              <a routerLink="/auth/login" class="inline-flex items-center justify-center w-full py-3 bg-primary text-white rounded-xl text-xs font-bold hover:bg-primary-600 transition-all shadow-md">
                Retour à la connexion
              </a>
            </div>
          </div>
        } @else {
          <div class="mb-4">
            <app-back-button label="Retour à la connexion" defaultRoute="/auth/login" variant="ghost" />
          </div>

          <div class="mb-6">
            <h1 class="font-display text-2xl font-black text-slate-900">Mot de passe oublié ?</h1>
            <p class="text-xs text-slate-500 mt-1">Entrez votre adresse email pour recevoir le lien de réinitialisation.</p>
          </div>

          <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-slate-800 mb-1.5">Adresse email</label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.255 1.206"/>
                  </svg>
                </div>
                <input type="email" formControlName="email" placeholder="votre.email@exemple.com"
                       class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl text-xs sm:text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all font-medium">
              </div>
            </div>

            <button type="submit" [disabled]="form.invalid || loading()"
                    class="w-full py-3.5 bg-primary hover:bg-primary-600 text-white font-bold rounded-2xl shadow-md disabled:opacity-50 transition-all text-xs sm:text-sm flex items-center justify-center gap-2 cursor-pointer">
              @if (loading()) {
                <svg class="w-4 h-4 animate-spin text-white" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                </svg>
                <span>Envoi en cours...</span>
              } @else {
                <span>Envoyer le lien de réinitialisation</span>
              }
            </button>
          </form>

          <div class="mt-6 text-center">
            <a routerLink="/auth/login" class="text-xs font-bold text-slate-500 hover:text-primary transition-colors">
              ← Retour à la connexion
            </a>
          </div>
        }
      </div>

    </div>
  `,
})
export class ForgotPasswordComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);

  loading = signal(false);
  sent = signal(false);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
  });

  onSubmit(): void {
    if (this.form.invalid) return;
    this.loading.set(true);
    this.authService.resetPassword(this.form.value.email!).subscribe({
      next: () => { this.sent.set(true); this.loading.set(false); },
      error: () => { this.toastr.error('Email introuvable.'); this.loading.set(false); },
    });
  }
}
