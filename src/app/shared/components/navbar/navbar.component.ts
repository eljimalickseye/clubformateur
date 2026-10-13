import { Component, inject, signal } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { Store } from '@ngrx/store';
import { AsyncPipe, CommonModule } from '@angular/common';
import { authActions } from '../../../store/auth/auth.actions';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { PwaService } from '../../../core/services/pwa.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive, AsyncPipe],
  template: `
    <nav class="fixed top-0 left-0 right-0 z-50 bg-[#062C32]/95 backdrop-blur-xl border-b border-emerald-900/40 text-white shadow-lg transition-all duration-300">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-20">

          <!-- Logo Brand -->
          <a routerLink="/" class="flex items-center gap-3 group">
            <div class="w-10 h-10 rounded-xl bg-white shadow-md flex items-center justify-center p-1.5 group-hover:scale-105 transition-transform shrink-0">
              <svg width="26" height="26" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#13C7A3"/>
                <path d="M14 20L18 24L26 16" stroke="white" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            </div>
            <div class="flex flex-col">
              <div class="flex items-baseline gap-1 leading-none">
                <span class="font-display text-base sm:text-lg font-bold text-white tracking-tight">Club des</span>
                <span class="font-display text-base sm:text-lg font-black text-[#13C7A3] tracking-tight">Formateurs</span>
              </div>
              <span class="text-[9px] font-semibold text-emerald-200/70 uppercase tracking-widest mt-1">
                Plateforme Pédagogique
              </span>
            </div>
          </a>

          <!-- Desktop Nav (Clean, Contextual & Role-Based) -->
          <div class="hidden md:flex items-center gap-8">
            @if (user$ | async; as user) {
              <!-- ─── ETUDIANT CONNECTE ─── -->
              @if (user.role === 'student') {
                <a routerLink="/catalogue" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Catalogue
                </a>
                <a routerLink="/student/my-courses" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Mes Cours
                </a>
                <a routerLink="/student/assignments" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Devoirs
                </a>
                <a routerLink="/student/lives" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider flex items-center gap-1.5">
                  <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                  <span>Lives</span>
                </a>
                <a routerLink="/formateurs" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Formateurs
                </a>
              }

              <!-- ─── PROFESSEUR CONNECTE ─── -->
              @if (user.role === 'teacher') {
                <a routerLink="/teacher/dashboard" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Tableau de bord
                </a>
                <a routerLink="/teacher/courses" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Mes Cours
                </a>
                <a routerLink="/teacher/assignments" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Devoirs
                </a>
                <a routerLink="/teacher/lives" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider flex items-center gap-1.5">
                  <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                  <span>Studio Live</span>
                </a>
                <a routerLink="/catalogue" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Catalogue
                </a>
              }

              <!-- ─── ADMIN CONNECTE ─── -->
              @if (user.role === 'admin') {
                <a routerLink="/admin/dashboard" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Administration
                </a>
                <a routerLink="/admin/users" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Utilisateurs
                </a>
                <a routerLink="/admin/courses" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Validation Cours
                </a>
                <a routerLink="/catalogue" routerLinkActive="text-[#13C7A3] !font-bold"
                   class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                  Catalogue
                </a>
              }
            } @else {
              <!-- ─── VISITEUR NON CONNECTE (Épuré & Normal) ─── -->
              <a routerLink="/catalogue" routerLinkActive="text-[#13C7A3] !font-bold"
                 class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                Catalogue
              </a>
              <a routerLink="/formateurs" routerLinkActive="text-[#13C7A3] !font-bold"
                 class="text-slate-200 hover:text-[#13C7A3] transition-all text-xs font-bold uppercase tracking-wider">
                Nos Formateurs
              </a>
            }
          </div>

          <!-- Right side -->
          <div class="flex items-center gap-3 sm:gap-5">
            @if (user$ | async; as user) {
              <!-- Avatar & Dropdown -->
              <div class="relative">
                <button (click)="toggleMenu()"
                        class="flex items-center gap-2.5 p-1.5 rounded-2xl hover:bg-white/10 transition-all border border-transparent hover:border-white/15 cursor-pointer">
                  <img decoding="async" [src]="user.photoURL || 'assets/default-avatar.png'" [alt]="user.displayName"
                       class="w-9 h-9 rounded-xl object-cover ring-2 ring-[#13C7A3]/40">
                  <div class="hidden lg:flex flex-col text-left">
                    <span class="text-xs font-bold text-white leading-tight">{{ user.displayName }}</span>
                    <span class="text-[10px] text-[#13C7A3] font-semibold uppercase tracking-wider">
                      {{ user.role === 'teacher' ? 'Formateur' : user.role === 'admin' ? 'Admin' : 'Étudiant' }}
                    </span>
                  </div>
                  <svg class="w-4 h-4 text-slate-300 transition-transform duration-300" [class.rotate-180]="menuOpen()" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                  </svg>
                </button>

                @if (menuOpen()) {
                  <div class="absolute right-0 mt-3 w-60 bg-white border border-slate-200 rounded-2xl shadow-2xl py-2 animate-slide-up z-[100] text-slate-800">
                    <div class="px-4 py-3 border-b border-slate-100 mb-1">
                      <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Connecté en tant que</p>
                      <p class="text-xs font-black text-slate-800 truncate">{{ user.email }}</p>
                    </div>

                    <a [routerLink]="'/' + user.role + '/dashboard'" (click)="menuOpen.set(false)"
                       class="flex items-center gap-3 px-4 py-2.5 text-xs font-bold text-slate-700 hover:bg-[#13C7A3]/10 hover:text-[#0D6B4D] transition-all">
                      <svg class="w-4 h-4 text-[#13C7A3]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1-1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                      </svg>
                      <span>Tableau de bord</span>
                    </a>

                    @if (user.role === 'student') {
                      <a routerLink="/student/my-courses" (click)="menuOpen.set(false)"
                         class="flex items-center gap-3 px-4 py-2.5 text-xs font-bold text-slate-700 hover:bg-[#13C7A3]/10 hover:text-[#0D6B4D] transition-all">
                        <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                        </svg>
                        <span>Mes Cours & Formations</span>
                      </a>
                      <a routerLink="/student/assignments" (click)="menuOpen.set(false)"
                         class="flex items-center gap-3 px-4 py-2.5 text-xs font-bold text-slate-700 hover:bg-[#13C7A3]/10 hover:text-[#0D6B4D] transition-all">
                        <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                        </svg>
                        <span>Mes Devoirs & Examens</span>
                      </a>
                    }

                    <hr class="border-slate-100 my-1">
                    <button (click)="logout()"
                            class="flex items-center gap-3 w-full px-4 py-2.5 text-xs font-bold text-red-600 hover:bg-red-50 transition-all cursor-pointer">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                      </svg>
                      <span>Déconnexion</span>
                    </button>
                  </div>
                }
              </div>
            } @else {
              <!-- Actions Visiteur (Connexion & Inscription) -->
              <div class="flex items-center gap-3 sm:gap-4">
                <a routerLink="/auth/login"
                   class="text-xs font-bold text-slate-200 hover:text-white transition-all uppercase tracking-wider py-2 px-2.5">
                  Connexion
                </a>
                <a routerLink="/auth/register"
                   class="px-4 sm:px-5 py-2.5 text-xs font-extrabold bg-[#13C7A3] text-white rounded-xl hover:bg-[#12A57A] hover:shadow-lg hover:shadow-emerald-500/25 transition-all shadow-sm active:scale-95">
                  S'inscrire
                </a>
              </div>
            }

            @if (pwaService.isInstallable() && !pwaService.isInstalled()) {
              <button (click)="pwaService.installPwa()"
                      class="hidden sm:flex items-center gap-1.5 px-3 py-1.5 bg-emerald-950/60 text-emerald-300 border border-emerald-600/40 rounded-xl text-xs font-bold hover:bg-emerald-900/80 transition-all shadow-2xs cursor-pointer"
                      title="Installer l'application Club des Formateurs sur votre appareil">
                <svg class="w-3.5 h-3.5 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                <span>Installer l'App</span>
              </button>
            }

            <!-- Mobile menu toggle -->
            <button (click)="toggleMobileMenu()"
                    class="p-2 rounded-xl text-slate-200 hover:bg-white/10 transition-all md:hidden cursor-pointer"
                    aria-label="Menu">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5"
                      [attr.d]="mobileMenuOpen() ? 'M6 18L18 6M6 6l12 12' : 'M4 6h16M4 12h16M4 18h16'" />
              </svg>
            </button>
          </div>

        </div>
      </div>

      <!-- Mobile nav drawer -->
      @if (mobileMenuOpen()) {
        <div class="md:hidden border-t border-emerald-900/60 bg-[#062C32] px-4 py-5 space-y-2 animate-fade-in shadow-2xl">
          @if (pwaService.isInstallable() && !pwaService.isInstalled()) {
            <button (click)="pwaService.installPwa(); closeMobileMenu()"
                    class="w-full flex items-center justify-center gap-2 px-4 py-3 bg-[#13C7A3] text-white rounded-xl font-bold text-xs shadow-md shadow-emerald-600/20 mb-3 cursor-pointer">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              <span>Installer l'application Club des Formateurs</span>
            </button>
          }

          @if (user$ | async; as user) {
            <!-- Connected Mobile Links -->
            <div class="px-3 py-2 bg-emerald-950/60 border border-emerald-800/40 rounded-xl mb-2 flex items-center gap-3">
              <img decoding="async" [src]="user.photoURL || 'assets/default-avatar.png'" class="w-8 h-8 rounded-lg object-cover">
              <div class="min-w-0">
                <p class="text-xs font-bold text-white truncate">{{ user.displayName }}</p>
                <p class="text-[10px] text-emerald-300 truncate">{{ user.email }}</p>
              </div>
            </div>

            <a [routerLink]="'/' + user.role + '/dashboard'" (click)="closeMobileMenu()"
               class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
              <svg class="w-4 h-4 text-[#13C7A3] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1-1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
              </svg>
              <span>Tableau de bord</span>
            </a>

            <a routerLink="/catalogue" (click)="closeMobileMenu()"
               class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
              <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
              </svg>
              <span>Catalogue de formations</span>
            </a>

            @if (user.role === 'student') {
              <a routerLink="/student/my-courses" (click)="closeMobileMenu()"
                 class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
                <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                </svg>
                <span>Mes cours</span>
              </a>
              <a routerLink="/student/assignments" (click)="closeMobileMenu()"
                 class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
                <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                </svg>
                <span>Mes devoirs & examens</span>
              </a>
              <a routerLink="/student/lives" (click)="closeMobileMenu()"
                 class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-red-400 hover:bg-red-500/10 transition-all">
                <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                <svg class="w-4 h-4 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                <span>Lives & Directs</span>
              </a>
            }

            @if (user.role === 'teacher') {
              <a routerLink="/teacher/courses" (click)="closeMobileMenu()"
                 class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
                <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <span>Gérer mes cours</span>
              </a>
              <a routerLink="/teacher/assignments" (click)="closeMobileMenu()"
                 class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
                <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                <span>Corriger les devoirs</span>
              </a>
              <a routerLink="/teacher/lives" (click)="closeMobileMenu()"
                 class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-red-400 hover:bg-red-500/10 transition-all">
                <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                <svg class="w-4 h-4 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                <span>Studio Live</span>
              </a>
            }

            <a routerLink="/formateurs" (click)="closeMobileMenu()"
               class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
              <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span>Les Formateurs</span>
            </a>

            <button (click)="logout()"
                    class="w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-red-400 hover:bg-red-500/10 transition-all cursor-pointer">
              <svg class="w-4 h-4 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
              </svg>
              <span>Déconnexion</span>
            </button>
          } @else {
            <!-- Guest Mobile Links -->
            <a routerLink="/catalogue" (click)="closeMobileMenu()"
               class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
              <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
              </svg>
              <span>Catalogue des cours</span>
            </a>
            <a routerLink="/formateurs" (click)="closeMobileMenu()"
               class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold text-slate-200 hover:bg-white/10 hover:text-[#13C7A3] transition-all">
              <svg class="w-4 h-4 text-emerald-300 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span>Nos Formateurs</span>
            </a>

            <div class="grid grid-cols-2 gap-2 pt-2">
              <a routerLink="/auth/login" (click)="closeMobileMenu()"
                 class="flex items-center justify-center px-3 py-2.5 rounded-xl text-xs font-bold text-slate-200 border border-emerald-800/60 hover:bg-white/5">
                Connexion
              </a>
              <a routerLink="/auth/register" (click)="closeMobileMenu()"
                 class="flex items-center justify-center px-3 py-2.5 rounded-xl text-xs font-bold bg-[#13C7A3] text-white hover:bg-[#12A57A] shadow-sm">
                S'inscrire
              </a>
            </div>
          }
        </div>
      }
    </nav>
    <!-- Spacer -->
    <div class="h-20"></div>
  `,
})
export class NavbarComponent {
  private store = inject(Store);
  pwaService = inject(PwaService);

  user$ = this.store.select(selectCurrentUser);
  menuOpen = signal(false);
  mobileMenuOpen = signal(false);

  toggleMenu(): void {
    this.menuOpen.update(v => !v);
  }

  toggleMobileMenu(): void {
    this.mobileMenuOpen.update(v => !v);
  }

  closeMobileMenu(): void {
    this.mobileMenuOpen.set(false);
  }

  logout(): void {
    this.store.dispatch(authActions.logout());
    this.menuOpen.set(false);
    this.mobileMenuOpen.set(false);
  }
}
