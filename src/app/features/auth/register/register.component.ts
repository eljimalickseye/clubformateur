import { Component, inject, signal, OnDestroy } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { Actions, ofType } from '@ngrx/effects';
import { AsyncPipe, CommonModule } from '@angular/common';
import { Subscription } from 'rxjs';
import { authActions } from '../../../store/auth/auth.actions';
import { selectAuthLoading, selectAuthError } from '../../../store/auth/auth.selectors';
import { UserRole } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, RouterLink, AsyncPipe, BackButtonComponent],
  template: `
    <div class="min-h-[100dvh] bg-[#F8FAFC] flex flex-col justify-between font-body text-[#0F172A] selection:bg-primary/20 selection:text-primary">
      
      <!-- ========================================== -->
      <!-- 1. CLEAN SINGLE AUTH HEADER                -->
      <!-- ========================================== -->
      <header class="w-full bg-white/90 backdrop-blur-md border-b border-slate-200/80 sticky top-0 z-30">
        <div class="w-full max-w-6xl mx-auto px-4 sm:px-6 h-14 sm:h-16 flex items-center justify-between">
          
          <!-- Logo & Brand (SVG Logo) -->
          <a routerLink="/" class="flex items-center gap-2.5 group active:scale-95 transition-transform">
            <div class="relative group-hover:scale-105 transition-transform duration-300">
              <svg width="34" height="34" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" class="drop-shadow-xs">
                <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
                <circle cx="20" cy="20" r="4" fill="white"/>
              </svg>
            </div>
            <span class="font-display text-lg sm:text-xl font-black text-[#0F172A] tracking-tight group-hover:text-primary transition-colors">
              Club des Formateurs
            </span>
          </a>

          <!-- Right side: Clean link to Login & Back -->
          <div class="flex items-center gap-2 sm:gap-3">
            <app-back-button label="Accueil" defaultRoute="/" variant="ghost" [showIconOnlyOnMobile]="true" />
            <a routerLink="/auth/login"
               class="px-3.5 py-1.5 sm:px-4 sm:py-2 bg-slate-100 hover:bg-primary/10 text-slate-800 hover:text-primary rounded-xl text-xs font-bold transition-all border border-slate-200/90 active:scale-95">
              Se connecter
            </a>
          </div>

        </div>
      </header>

      <!-- ========================================== -->
      <!-- 2. MAIN CONTAINER & REGISTRATION CARD       -->
      <!-- ========================================== -->
      <main class="flex-1 flex items-center justify-center py-4 sm:py-6 lg:py-8 px-3.5 sm:px-6">
        
        <div class="w-full max-w-[920px] mx-auto">
          
          <!-- STEP 1: Registration Form -->
          @if (currentStep() === 1) {
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-0 bg-white rounded-3xl sm:rounded-[28px] shadow-xl shadow-slate-200/50 border border-slate-200/80 overflow-hidden">
              
              <!-- ─── DESKTOP BRAND SIDEBAR (>= 1024px) ─── -->
              <aside class="hidden lg:flex lg:col-span-5 bg-gradient-to-br from-[#0B132B] via-[#1C2541] to-[#2D5BE3] p-7 flex-col justify-between text-white relative overflow-hidden">
                <!-- Ambient Glow -->
                <div class="absolute -bottom-16 -right-16 w-56 h-56 bg-primary/30 rounded-full blur-3xl pointer-events-none"></div>

                <div class="space-y-5 relative z-10">
                  <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 backdrop-blur-md border border-white/10 text-[11px] font-bold tracking-wider text-blue-200">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                    Plateforme e-Learning & Lives
                  </div>

                  <div class="space-y-1.5">
                    <h2 class="font-display text-2xl font-black text-white leading-tight">
                      Rejoignez la communauté des formateurs & apprenants.
                    </h2>
                    <p class="text-xs text-slate-300 leading-relaxed">
                      Accédez à des cours interactifs, des sessions de Lives et des certifications reconnues.
                    </p>
                  </div>

                  <!-- Value Propositions with Crisp SVGs -->
                  <div class="space-y-3.5 pt-1">
                    <!-- Item 1: Student Cap SVG -->
                    <div class="flex items-start gap-3">
                      <div class="w-8 h-8 rounded-xl bg-white/10 border border-white/15 flex items-center justify-center text-blue-300 shrink-0 shadow-2xs">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 14v7" />
                        </svg>
                      </div>
                      <div>
                        <h4 class="text-xs font-bold text-white">Apprenez à votre rythme</h4>
                        <p class="text-[11px] text-slate-300">Vidéos HD, quiz et replays accessibles 24h/24.</p>
                      </div>
                    </div>

                    <!-- Item 2: Live Video Camera SVG -->
                    <div class="flex items-start gap-3">
                      <div class="w-8 h-8 rounded-xl bg-red-500/20 border border-red-500/30 flex items-center justify-center text-red-400 shrink-0 shadow-2xs">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                        </svg>
                      </div>
                      <div>
                        <h4 class="text-xs font-bold text-white">Lives & Visioconférences</h4>
                        <p class="text-[11px] text-slate-300">Échangez en direct avec formateurs et étudiants.</p>
                      </div>
                    </div>

                    <!-- Item 3: Mobile Money Wallet SVG -->
                    <div class="flex items-start gap-3">
                      <div class="w-8 h-8 rounded-xl bg-emerald-500/20 border border-emerald-500/30 flex items-center justify-center text-emerald-300 shrink-0 shadow-2xs">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                        </svg>
                      </div>
                      <div>
                        <h4 class="text-xs font-bold text-white">Paiement Mobile Money</h4>
                        <p class="text-[11px] text-slate-300">Wave et Orange Money directement intégrés.</p>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Reassurance footer in desktop sidebar -->
                <div class="pt-5 border-t border-white/10 text-[11px] text-slate-300 flex items-center gap-2 relative z-10">
                  <svg class="w-4 h-4 text-emerald-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                  </svg>
                  <span>Connexion chiffrée SSL & Données sécurisées</span>
                </div>
              </aside>

              <!-- ─── FORM CONTENT COLUMN ─── -->
              <section class="lg:col-span-7 p-4 sm:p-6 lg:p-7 flex flex-col justify-center">
                
                <!-- Title Header -->
                <div class="mb-3 sm:mb-4">
                  <h1 class="font-display text-xl sm:text-2xl font-black text-[#0F172A] tracking-tight leading-tight">
                    Créer un compte
                  </h1>
                  <p class="text-xs text-slate-500 mt-0.5">
                    Choisissez votre profil pour commencer dès aujourd'hui.
                  </p>
                </div>

                <!-- 1. Role Selector with Interactive SVG Cards -->
                <div class="mb-3">
                  <div class="grid grid-cols-2 gap-2.5">
                    <!-- Student Option -->
                    <button type="button"
                            (click)="setRole('student')"
                            class="p-2.5 rounded-2xl border-2 text-left transition-all relative cursor-pointer active:scale-[0.98]"
                            [ngClass]="selectedRole() === 'student' 
                              ? 'border-primary bg-primary-50/60 shadow-xs ring-2 ring-primary/10' 
                              : 'border-slate-200 bg-white hover:border-primary/40'">
                      <div class="flex items-center justify-between mb-1">
                        <div class="w-7 h-7 rounded-lg flex items-center justify-center transition-colors"
                             [ngClass]="selectedRole() === 'student' ? 'bg-primary text-white' : 'bg-slate-100 text-slate-600'">
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                          </svg>
                        </div>

                        @if (selectedRole() === 'student') {
                          <span class="w-4 h-4 rounded-full bg-primary text-white flex items-center justify-center text-[9px] font-black">✓</span>
                        }
                      </div>
                      <p class="text-xs sm:text-sm font-bold text-slate-900 leading-tight">Étudiant</p>
                      <p class="text-[10px] sm:text-[11px] text-slate-500 leading-tight truncate">Suivre des cours</p>
                    </button>

                    <!-- Teacher Option -->
                    <button type="button"
                            (click)="setRole('teacher')"
                            class="p-2.5 rounded-2xl border-2 text-left transition-all relative cursor-pointer active:scale-[0.98]"
                            [ngClass]="selectedRole() === 'teacher' 
                              ? 'border-primary bg-primary-50/60 shadow-xs ring-2 ring-primary/10' 
                              : 'border-slate-200 bg-white hover:border-primary/40'">
                      <div class="flex items-center justify-between mb-1">
                        <div class="w-7 h-7 rounded-lg flex items-center justify-center transition-colors"
                             [ngClass]="selectedRole() === 'teacher' ? 'bg-primary text-white' : 'bg-slate-100 text-slate-600'">
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
                          </svg>
                        </div>

                        @if (selectedRole() === 'teacher') {
                          <span class="w-4 h-4 rounded-full bg-primary text-white flex items-center justify-center text-[9px] font-black">✓</span>
                        }
                      </div>
                      <p class="text-xs sm:text-sm font-bold text-slate-900 leading-tight">Formateur</p>
                      <p class="text-[10px] sm:text-[11px] text-slate-500 leading-tight truncate">Créer & enseigner</p>
                    </button>
                  </div>
                </div>

                <!-- 2. Google Social Sign In Button -->
                <div class="mb-3">
                  <button type="button"
                          (click)="signUpWithGoogle()"
                          [disabled]="googleLoading() || submitting() || (loading$ | async)"
                          class="w-full h-10 sm:h-11 px-4 border border-slate-200 hover:border-slate-300 bg-white hover:bg-slate-50 active:scale-[0.99] rounded-xl text-xs sm:text-sm font-bold text-slate-700 shadow-2xs transition-all flex items-center justify-center gap-2.5 cursor-pointer disabled:opacity-60">
                    @if (googleLoading()) {
                      <svg class="w-4 h-4 animate-spin text-primary" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                      </svg>
                      <span>Connexion Google...</span>
                    } @else {
                      <svg class="w-4 h-4 shrink-0" viewBox="0 0 24 24">
                        <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                        <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                        <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                        <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                      </svg>
                      <span>S'inscrire avec Google</span>
                    }
                  </button>
                </div>

                <!-- Separator -->
                <div class="relative my-2.5 text-center">
                  <div class="absolute inset-0 flex items-center"><div class="w-full border-t border-slate-200"></div></div>
                  <span class="relative px-3 py-0.5 bg-white text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                    ou par email
                  </span>
                </div>

                <!-- Error Alert Banner -->
                @if (error$ | async; as error) {
                  <div class="mb-3 p-2.5 rounded-xl bg-red-50 border border-red-200 text-red-700 flex items-start gap-2 text-xs font-semibold animate-fade-in">
                    <svg class="w-4 h-4 text-red-500 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                    </svg>
                    <div class="flex-1 leading-relaxed">{{ error }}</div>
                  </div>
                }

                <!-- 3. Form Inputs -->
                <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-2.5">
                  
                  <!-- Full Name (SVG User Icon) -->
                  <div>
                    <label class="block text-[11px] sm:text-xs font-bold text-slate-800 mb-1">
                      Nom complet <span class="text-primary">*</span>
                    </label>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                        </svg>
                      </div>
                      <input type="text"
                             formControlName="displayName"
                             placeholder="Ex : Malick Ndiaye"
                             autocomplete="name"
                             class="w-full pl-9 pr-8 h-10 sm:h-11 bg-slate-50/80 border rounded-xl text-[14px] sm:text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:ring-2 transition-all font-medium"
                             [ngClass]="getFieldClass('displayName')">
                      @if (isFieldValid('displayName')) {
                        <span class="absolute inset-y-0 right-0 pr-3 flex items-center text-emerald-500">
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
                        </span>
                      }
                    </div>
                    @if (isFieldInvalid('displayName')) {
                      <p class="text-red-500 text-[10px] font-semibold mt-0.5 flex items-center gap-1">
                        <span>●</span> Nom requis (au moins 2 caractères).
                      </p>
                    }
                  </div>

                  <!-- Email (SVG Mail Icon) -->
                  <div>
                    <label class="block text-[11px] sm:text-xs font-bold text-slate-800 mb-1">
                      Adresse email <span class="text-primary">*</span>
                    </label>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.255 1.206"/>
                        </svg>
                      </div>
                      <input type="email"
                             formControlName="email"
                             placeholder="votre.email@exemple.com"
                             autocomplete="email"
                             inputmode="email"
                             class="w-full pl-9 pr-8 h-10 sm:h-11 bg-slate-50/80 border rounded-xl text-[14px] sm:text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:ring-2 transition-all font-medium"
                             [ngClass]="getFieldClass('email')">
                      @if (isFieldValid('email')) {
                        <span class="absolute inset-y-0 right-0 pr-3 flex items-center text-emerald-500">
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
                        </span>
                      }
                    </div>
                    @if (isFieldInvalid('email')) {
                      <p class="text-red-500 text-[10px] font-semibold mt-0.5 flex items-center gap-1">
                        <span>●</span> Adresse email valide requise.
                      </p>
                    }
                  </div>

                  <!-- Phone Number (Flag + Phone Input) -->
                  <div>
                    <label class="block text-[11px] sm:text-xs font-bold text-slate-800 mb-1">
                      Téléphone <span class="text-slate-400 font-normal">(Optionnel)</span>
                    </label>
                    <div class="flex gap-2">
                      <div class="flex items-center gap-1.5 px-2.5 h-10 sm:h-11 bg-slate-100 border border-slate-200 rounded-xl text-xs font-bold text-slate-700 shrink-0 select-none">
                        <svg width="18" height="12" viewBox="0 0 24 16" class="rounded-xs overflow-hidden">
                          <rect width="8" height="16" fill="#00853F"/>
                          <rect x="8" width="8" height="16" fill="#FDEF42"/>
                          <rect x="16" width="8" height="16" fill="#E31B23"/>
                          <path d="M12 8L11.5 9.5H12.5L12 8Z" fill="#00853F"/>
                        </svg>
                        <span>+221</span>
                      </div>
                      <input type="tel"
                             formControlName="phone"
                             placeholder="77 123 45 67"
                             autocomplete="tel-national"
                             inputmode="tel"
                             class="flex-1 px-3.5 h-10 sm:h-11 bg-slate-50/80 border border-slate-200 rounded-xl text-[14px] sm:text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-primary focus:ring-2 focus:ring-primary/10 transition-all font-medium">
                    </div>
                    @if (form.get('phone')?.invalid && form.get('phone')?.touched) {
                      <p class="text-red-500 text-[10px] font-semibold mt-0.5 flex items-center gap-1">
                        <span>●</span> 9 chiffres requis (ex : 77 123 45 67).
                      </p>
                    }
                  </div>

                  <!-- Password Field -->
                  <div>
                    <label class="block text-[11px] sm:text-xs font-bold text-slate-800 mb-1">
                      Mot de passe <span class="text-primary">*</span>
                    </label>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                        </svg>
                      </div>
                      <input [type]="showPassword() ? 'text' : 'password'"
                             formControlName="password"
                             placeholder="8 caractères minimum"
                             autocomplete="new-password"
                             class="w-full pl-9 pr-9 h-10 sm:h-11 bg-slate-50/80 border rounded-xl text-[14px] sm:text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:ring-2 transition-all font-medium"
                             [ngClass]="getFieldClass('password')">
                      
                      <!-- Password eye toggle SVG -->
                      <button type="button"
                              (click)="togglePassword()"
                              class="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-800 active:scale-90 transition-all cursor-pointer"
                              title="Afficher/Masquer">
                        @if (showPassword()) {
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18"/>
                          </svg>
                        } @else {
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                          </svg>
                        }
                      </button>
                    </div>

                    <!-- Password strength compact bar -->
                    @if (form.get('password')?.value) {
                      <div class="mt-1 flex items-center gap-2">
                        <div class="flex-1 flex gap-1">
                          @for (segment of [1, 2, 3, 4]; track segment) {
                            <div class="h-1 flex-1 rounded-full bg-slate-200 overflow-hidden">
                              <div class="h-full transition-all duration-300"
                                   [ngClass]="getStrengthColor(segment)"
                                   [style.width]="passwordStrength() >= segment ? '100%' : '0%'"></div>
                            </div>
                          }
                        </div>
                        <span class="text-[10px] font-bold" [ngClass]="getStrengthTextColor()">{{ getStrengthLabel() }}</span>
                      </div>
                    }

                    @if (isFieldInvalid('password')) {
                      <p class="text-red-500 text-[10px] font-semibold mt-0.5 flex items-center gap-1">
                        <span>●</span> 8 caractères minimum requis.
                      </p>
                    }
                  </div>

                  <!-- Terms note -->
                  <p class="text-[10px] sm:text-[11px] text-slate-500 leading-tight pt-0.5">
                    En créant un compte, vous acceptez nos
                    <a routerLink="/" class="text-primary font-semibold hover:underline">Conditions</a> et
                    <a routerLink="/" class="text-primary font-semibold hover:underline">Politique</a>.
                  </p>

                  <!-- Primary CTA Button (Comfortable touch target) -->
                  <button type="submit"
                          [disabled]="submitting() || (loading$ | async)"
                          class="w-full h-11 sm:h-12 bg-primary hover:bg-primary-600 active:scale-[0.99] text-white font-bold rounded-xl shadow-md shadow-primary/25 disabled:opacity-50 disabled:cursor-not-allowed transition-all text-xs sm:text-sm flex items-center justify-center gap-2 cursor-pointer mt-1">
                    @if (submitting() || (loading$ | async)) {
                      <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                      </svg>
                      <span>Création en cours...</span>
                    } @else {
                      <span>Créer mon compte</span>
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                      </svg>
                    }
                  </button>
                </form>

                <!-- Mobile bottom redirect link (< 1024px) -->
                <div class="mt-3 pt-2.5 border-t border-slate-100 text-center lg:hidden">
                  <p class="text-xs text-slate-500">
                    Déjà inscrit ?
                    <a routerLink="/auth/login" class="font-bold text-primary hover:underline ml-1">
                      Se connecter →
                    </a>
                  </p>
                </div>

              </section>

            </div>
          }

          <!-- STEP 2: Welcome Confirmation Screen -->
          @if (currentStep() === 2) {
            <div class="bg-white rounded-3xl sm:rounded-[28px] shadow-xl shadow-slate-200/50 border border-slate-200 p-6 sm:p-9 text-center space-y-5 max-w-md mx-auto animate-fade-in">
              
              <!-- Celebration icon -->
              <div class="w-16 h-16 mx-auto bg-emerald-50 border-2 border-emerald-200 rounded-full flex items-center justify-center text-emerald-600 shadow-md shadow-emerald-500/10">
                <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                </svg>
              </div>

              <div>
                <h2 class="font-display text-xl sm:text-2xl font-black text-slate-900 tracking-tight">
                  Bienvenue, {{ createdUserName() || 'Apprenant' }} !
                </h2>
                <p class="text-xs sm:text-sm text-slate-600 mt-1 max-w-sm mx-auto">
                  Votre compte <strong class="text-primary">{{ selectedRole() === 'teacher' ? 'Formateur' : 'Étudiant' }}</strong> a été créé avec succès.
                </p>
              </div>

              <!-- Quick Next Steps -->
              <div class="space-y-2.5 text-left">
                <div class="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center gap-3">
                  <div class="w-8 h-8 rounded-lg bg-primary/10 text-primary flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-xs font-bold text-slate-900">Explorez les formations</h3>
                    <p class="text-[10px] text-slate-500">Découvrez des cours interactifs et certifiants.</p>
                  </div>
                </div>

                <div class="p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center gap-3">
                  <div class="w-8 h-8 rounded-lg bg-red-50 text-red-600 flex items-center justify-center shrink-0">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-xs font-bold text-slate-900">Rejoignez les Lives</h3>
                    <p class="text-[10px] text-slate-500">Participez aux cours en direct avec vos professeurs.</p>
                  </div>
                </div>
              </div>

              <!-- CTA Buttons -->
              <div class="pt-1 space-y-2">
                <button (click)="goToDashboard()"
                        class="w-full h-11 bg-primary hover:bg-primary-600 active:scale-[0.98] text-white font-bold rounded-xl shadow-md text-xs sm:text-sm flex items-center justify-center gap-2 cursor-pointer transition-all">
                  <span>Accéder à mon espace</span>
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                  </svg>
                </button>

                <a routerLink="/catalogue"
                   class="block w-full py-2 text-xs font-bold text-slate-600 hover:text-primary transition-colors">
                  Explorer le catalogue
                </a>
              </div>

            </div>
          }

        </div>

      </main>

      <!-- ========================================== -->
      <!-- 3. ULTRA-COMPACT RESPONSIVE FOOTER         -->
      <!-- ========================================== -->
      <footer class="w-full py-2.5 sm:py-3 text-center text-[11px] text-slate-400 border-t border-slate-200/60 bg-white/60 shrink-0">
        <div class="max-w-6xl mx-auto px-4">
          <!-- Mobile Variant (< 640px) -->
          <div class="flex flex-col sm:hidden items-center justify-center gap-1 text-[11px] text-slate-400">
            <div class="flex items-center gap-2 font-medium text-slate-500">
              <a routerLink="/" class="hover:underline">Conditions</a>
              <span>·</span>
              <a routerLink="/" class="hover:underline">Confidentialité</a>
            </div>
            <span>© {{ currentYear }} Club des Formateurs</span>
          </div>

          <!-- Desktop & Tablet Variant (>= 640px) -->
          <div class="hidden sm:flex items-center justify-center gap-3 text-[11px]">
            <span>© {{ currentYear }} Club des Formateurs. Tous droits réservés.</span>
            <span>•</span>
            <div class="flex items-center gap-1.5 text-emerald-600 font-medium">
              <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
              </svg>
              <span>Plateforme certifiée et sécurisée</span>
            </div>
            <span>•</span>
            <a routerLink="/" class="text-slate-500 hover:text-primary transition-colors">Conditions</a>
            <span>·</span>
            <a routerLink="/" class="text-slate-500 hover:text-primary transition-colors">Confidentialité</a>
          </div>
        </div>
      </footer>

    </div>
  `,
})
export class RegisterComponent implements OnDestroy {
  private fb = inject(FormBuilder);
  private store = inject(Store);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private actions$ = inject(Actions);
  private subs = new Subscription();

  currentYear = new Date().getFullYear();

  loading$ = this.store.select(selectAuthLoading);
  error$ = this.store.select(selectAuthError);

  currentStep = signal<1 | 2>(1);
  selectedRole = signal<UserRole>('student');
  showPassword = signal(false);
  passwordStrength = signal(0);
  googleLoading = signal(false);
  submitting = signal(false);
  createdUserName = signal('');

  form = this.fb.group({
    displayName: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    phone: ['', [Validators.pattern(/^[0-9]{9}$/)]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  constructor() {
    const roleParam = this.route.snapshot.queryParamMap.get('role');
    if (roleParam === 'teacher' || roleParam === 'student') {
      this.selectedRole.set(roleParam as UserRole);
    }
    this.form.get('password')?.valueChanges.subscribe(val => {
      this.passwordStrength.set(this.calculateStrength(val || ''));
    });

    this.subs.add(
      this.actions$.pipe(ofType(authActions.registerSuccess)).subscribe(({ user }) => {
        this.submitting.set(false);
        this.createdUserName.set(user.displayName || '');
        this.currentStep.set(2);
      })
    );

    this.subs.add(
      this.actions$.pipe(ofType(authActions.registerFailure)).subscribe(() => {
        this.submitting.set(false);
      })
    );

    this.subs.add(
      this.actions$.pipe(ofType(authActions.loginSuccess)).subscribe(() => {
        this.googleLoading.set(false);
      })
    );

    this.subs.add(
      this.actions$.pipe(ofType(authActions.loginFailure)).subscribe(() => {
        this.googleLoading.set(false);
      })
    );
  }

  ngOnDestroy() { 
    this.subs.unsubscribe(); 
  }

  setRole(role: UserRole): void {
    this.selectedRole.set(role);
  }

  togglePassword(): void {
    this.showPassword.update(v => !v);
  }

  calculateStrength(password: string): number {
    if (!password) return 0;
    let strength = 0;
    if (password.length >= 8) strength++;
    if (/[A-Z]/.test(password) || /[a-z]/.test(password)) strength++;
    if (/[0-9]/.test(password)) strength++;
    if (/[^A-Za-z0-9]/.test(password) || password.length >= 10) strength++;
    return strength;
  }

  getStrengthLabel(): string {
    const s = this.passwordStrength();
    if (s <= 1) return 'Faible';
    if (s === 2) return 'Moyen';
    if (s === 3) return 'Bon';
    return 'Robuste';
  }

  getStrengthTextColor(): string {
    const s = this.passwordStrength();
    if (s <= 1) return 'text-red-500';
    if (s === 2) return 'text-amber-500';
    if (s === 3) return 'text-blue-600';
    return 'text-emerald-600';
  }

  getStrengthColor(segment: number): string {
    const strength = this.passwordStrength();
    if (strength < segment) return 'bg-slate-200';
    if (strength === 1) return 'bg-red-500';
    if (strength === 2) return 'bg-amber-500';
    if (strength === 3) return 'bg-blue-600';
    return 'bg-emerald-500';
  }

  isFieldValid(name: string): boolean {
    const control = this.form.get(name);
    return !!(control && control.valid && control.touched);
  }

  isFieldInvalid(name: string): boolean {
    const control = this.form.get(name);
    return !!(control && control.invalid && control.touched);
  }

  getFieldClass(name: string): Record<string, boolean> {
    const control = this.form.get(name);
    if (!control || !control.touched) {
      return {
        'border-slate-200': true,
        'focus:border-primary': true,
        'focus:ring-primary/10': true
      };
    }
    if (control.invalid) {
      return {
        'border-red-400': true,
        'bg-red-50/30': true,
        'focus:border-red-500': true,
        'focus:ring-red-500/15': true
      };
    }
    return {
      'border-emerald-400': true,
      'bg-emerald-50/20': true,
      'focus:border-emerald-500': true,
      'focus:ring-emerald-500/15': true
    };
  }

  signUpWithGoogle(): void {
    this.googleLoading.set(true);
    try {
      this.store.dispatch(authActions.loginWithGoogle({ role: this.selectedRole() }));
    } catch (e) {
      this.googleLoading.set(false);
    }
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    
    this.submitting.set(true);
    try {
      const { displayName, email, password, phone } = this.form.value;
      
      this.store.dispatch(authActions.register({
        displayName: displayName!.trim(),
        email: email!.trim().toLowerCase(),
        password: password!,
        role: this.selectedRole(),
        phone: phone?.trim() ? '+221' + phone.trim() : undefined,
      }));
    } catch (e) {
      this.submitting.set(false);
    }
  }

  goToDashboard(): void {
    this.router.navigate([`/${this.selectedRole()}/dashboard`]);
  }
}
