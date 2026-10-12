import { Component, inject, OnInit, signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { Store } from '@ngrx/store';
import { AsyncPipe, CommonModule } from '@angular/common';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { authActions } from '../../../store/auth/auth.actions';
import { AdminService } from '../../../core/services/admin.service';
import { filter } from 'rxjs';

@Component({
  selector: 'app-admin-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, AsyncPipe, CommonModule],
  template: `
    <div class="flex h-screen overflow-hidden bg-slate-900 text-light font-body">

      <!-- Mobile Backdrop -->
      @if (mobileSidebarOpen()) {
        <div class="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
             (click)="mobileSidebarOpen.set(false)"></div>
      }

      <!-- Admin Left Sidebar (Requirement 14) -->
      <aside class="fixed inset-y-0 left-0 z-50 flex w-72 flex-col border-r border-slate-800 bg-slate-950 transition-transform duration-300 ease-in-out lg:static lg:translate-x-0"
             [class.translate-x-0]="mobileSidebarOpen()"
             [class.-translate-x-full]="!mobileSidebarOpen()">

        <!-- Brand / Header -->
        <div class="flex h-20 items-center justify-between border-b border-slate-800 px-6">
          <a routerLink="/admin/dashboard" class="flex items-center gap-3 group">
            <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-red-600 text-white shadow-md shadow-red-600/30">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
              </svg>
            </div>
            <div>
              <span class="font-display text-xl font-black text-white tracking-tight">
                Administration
              </span>
              <span class="block text-[10px] font-bold uppercase tracking-widest text-red-400">
                Supervision Centrale
              </span>
            </div>
          </a>

          <!-- Close button on mobile -->
          <button (click)="mobileSidebarOpen.set(false)"
                  class="rounded-lg p-2 text-slate-400 hover:bg-slate-800 lg:hidden"
                  aria-label="Fermer le menu">
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <!-- Sidebar Navigation -->
        <nav class="flex-1 overflow-y-auto px-4 py-5 space-y-6">

          <!-- Section: SUPERVISION -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Vue Globale
            </p>
            <div class="space-y-1">
              <a routerLink="/admin/dashboard"
                 routerLinkActive="!bg-red-600 !text-white shadow-md shadow-red-600/30 font-semibold"
                 [routerLinkActiveOptions]="{ exact: true }"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                    <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                    <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                    <rect x="3" y="14" width="7" height="7" rx="1.5"/>
                  </svg>
                  <span>Tableau de bord</span>
                </div>
              </a>
            </div>
          </div>

          <!-- Section: GESTION PLATEFORME -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Gestion des Utilisateurs
            </p>
            <div class="space-y-1">
              <a routerLink="/admin/users"
                 routerLinkActive="!bg-red-600 !text-white shadow-md shadow-red-600/30 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                  </svg>
                  <span>Tous les Utilisateurs</span>
                </div>
              </a>
            </div>
          </div>

          <!-- Section: VALIDATION & COURS -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Pédagogie & Contenus
            </p>
            <div class="space-y-1">
              <a routerLink="/admin/courses"
                 routerLinkActive="!bg-red-600 !text-white shadow-md shadow-red-600/30 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                  <span>Validation des Cours</span>
                </div>
                @if (pendingCoursesCount() > 0) {
                  <span class="rounded-full bg-amber-500 px-2 py-0.5 text-[10px] font-black text-white">
                    {{ pendingCoursesCount() }}
                  </span>
                }
              </a>
            </div>
          </div>

          <!-- Section: FINANCES GLOBALES -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Finances & Commissions
            </p>
            <div class="space-y-1">
              <a routerLink="/admin/payments"
                 routerLinkActive="!bg-red-600 !text-white shadow-md shadow-red-600/30 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                  <span>Transactions & Revenus</span>
                </div>
              </a>
            </div>
          </div>

          <!-- Section: PARAMÈTRES & RETOUR -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400 mb-2">
              Accès Rapide
            </p>
            <div class="space-y-1">
              <a routerLink="/teacher/dashboard"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                  </svg>
                  <span>Vue Espace Professeur</span>
                </div>
              </a>
              <a routerLink="/catalogue"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                  </svg>
                  <span>Catalogue Public</span>
                </div>
              </a>
            </div>
          </div>

        </nav>

        <!-- User Profile Card in Sidebar Bottom -->
        @if (user$ | async; as user) {
          <div class="border-t border-slate-800 p-4 bg-slate-950">
            <div class="flex items-center justify-between rounded-2xl bg-slate-900 p-3 border border-slate-800">
              <div class="flex items-center gap-3 min-w-0">
                <img loading="lazy" decoding="async" [src]="user.photoURL || 'assets/default-avatar.png'"
                     [alt]="user.displayName"
                     class="h-10 w-10 rounded-xl object-cover border border-slate-700 shrink-0 shadow-sm">
                <div class="min-w-0 flex-1">
                  <p class="truncate text-xs font-bold text-white">{{ user.displayName }}</p>
                  <span class="inline-block px-1.5 py-0.5 rounded bg-red-500/20 text-red-400 text-[9px] font-bold uppercase">
                    Administrateur
                  </span>
                </div>
              </div>
              <button (click)="logout()"
                      title="Déconnexion"
                      class="rounded-xl p-2 text-slate-400 hover:bg-red-950 hover:text-red-400 transition-colors">
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
              </button>
            </div>
          </div>
        }
      </aside>

      <!-- Main Workspace Container -->
      <div class="flex flex-1 flex-col overflow-hidden bg-slate-900">

        <!-- Top Header Bar -->
        <header class="flex h-20 shrink-0 items-center justify-between border-b border-slate-800 bg-slate-950/80 px-6 backdrop-blur-md">

          <!-- Left: Title -->
          <div class="flex items-center gap-4">
            <button (click)="mobileSidebarOpen.set(true)"
                    class="rounded-xl p-2 text-slate-300 hover:bg-slate-800 lg:hidden"
                    aria-label="Ouvrir le menu">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
              </svg>
            </button>
            <div class="min-w-0">
              <h1 class="font-display text-base sm:text-lg font-bold text-white tracking-tight truncate">
                {{ currentTitle() }}
              </h1>
              <p class="text-[11px] text-slate-400 hidden sm:block">Panneau d'administration globale Club des Formateurs</p>
            </div>
          </div>

          <!-- Right: Status Badge & Logout -->
          <div class="flex items-center gap-3">
            <span class="inline-flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-3 py-1 text-xs font-bold text-emerald-400">
              <span class="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
              Plateforme Opérationnelle
            </span>

            <button (click)="logout()"
                    class="flex items-center gap-2 rounded-xl border border-red-500/30 bg-red-500/10 px-3.5 py-2 text-xs font-bold text-red-400 hover:bg-red-500/20 transition-all">
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
              </svg>
              <span class="hidden sm:inline">Déconnexion</span>
            </button>
          </div>
        </header>

        <!-- Main Content -->
        <main class="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <router-outlet />
        </main>

      </div>
    </div>
  `,
})
export class AdminLayoutComponent implements OnInit {
  private store = inject(Store);
  private router = inject(Router);
  private adminService = inject(AdminService);

  user$ = this.store.select(selectCurrentUser);
  mobileSidebarOpen = signal(false);
  pendingCoursesCount = signal(0);
  currentTitle = signal('Supervision Centrale');

  ngOnInit(): void {
    this.updateTitle(this.router.url);

    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe((event: any) => {
      this.updateTitle(event.urlAfterRedirects || event.url);
    });

    this.adminService.getAllCourses('pending_approval').subscribe(courses => {
      this.pendingCoursesCount.set(courses.length);
    });
  }

  logout(): void {
    this.store.dispatch(authActions.logout());
  }

  private updateTitle(url: string): void {
    if (url.includes('/admin/users')) {
      this.currentTitle.set('Gestion des Utilisateurs');
    } else if (url.includes('/admin/courses')) {
      this.currentTitle.set('Modération & Validation des Cours');
    } else if (url.includes('/admin/payments')) {
      this.currentTitle.set('Transactions & Supervision Financière');
    } else {
      this.currentTitle.set('Supervision Centrale & KPIs');
    }
  }
}
