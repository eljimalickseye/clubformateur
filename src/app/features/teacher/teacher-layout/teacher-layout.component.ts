import { Component, inject, OnInit, signal } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive, Router, NavigationEnd } from '@angular/router';
import { Store } from '@ngrx/store';
import { AsyncPipe, CommonModule } from '@angular/common';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { authActions } from '../../../store/auth/auth.actions';
import { ChatService } from '../../../core/services/chat.service';
import { CourseService } from '../../../core/services/course.service';
import { RequestService } from '../../../core/services/request.service';
import { NotificationService } from '../../../core/services/notification.service';
import { filter, switchMap, of } from 'rxjs';

@Component({
  selector: 'app-teacher-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, AsyncPipe, CommonModule],
  template: `
    <div class="flex h-screen overflow-hidden bg-dark text-light font-body">

      <!-- Mobile Backdrop -->
      @if (mobileSidebarOpen()) {
        <div class="fixed inset-0 z-40 bg-black/40 backdrop-blur-sm lg:hidden"
             (click)="mobileSidebarOpen.set(false)"></div>
      }

      <!-- Left Sidebar -->
      <aside class="fixed inset-y-0 left-0 z-50 flex w-72 flex-col border-r border-dark-border bg-white transition-transform duration-300 ease-in-out lg:static lg:translate-x-0"
             [class.translate-x-0]="mobileSidebarOpen()"
             [class.-translate-x-full]="!mobileSidebarOpen()">

        <!-- Brand / Header -->
        <div class="flex h-20 items-center justify-between border-b border-dark-border/60 px-6">
          <a routerLink="/" class="flex items-center gap-3 group">
            <div class="relative group-hover:rotate-[30deg] transition-transform duration-500 shrink-0">
              <svg width="36" height="36" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
                <circle cx="20" cy="20" r="4" fill="white"/>
              </svg>
            </div>
            <div>
              <span class="font-display text-lg font-black text-light tracking-tight group-hover:text-primary transition-colors block leading-tight">
                Club des Formateurs
              </span>
              <span class="block text-[10px] font-bold uppercase tracking-widest text-primary">
                Espace Formateur
              </span>
            </div>
          </a>

          <!-- Close button on mobile -->
          <button (click)="mobileSidebarOpen.set(false)"
                  class="rounded-lg p-2 text-light-muted hover:bg-dark-surface2 lg:hidden"
                  aria-label="Fermer le menu">
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <!-- Sidebar Navigation -->
        <nav class="flex-1 overflow-y-auto px-4 py-5 space-y-6">

          <!-- Section: GESTION & COURS -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-light-muted/70 mb-2">
              Formation & Cours
            </p>
            <div class="space-y-1">
              <a routerLink="/teacher/dashboard"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 [routerLinkActiveOptions]="{ exact: true }"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
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

              <a routerLink="/teacher/courses"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                  </svg>
                  <span>Mes cours</span>
                </div>
                @if (courseCount() > 0) {
                  <span class="rounded-full bg-dark-surface2 px-2 py-0.5 text-[10px] font-bold text-light group-[.shadow-md]:bg-white/20 group-[.shadow-md]:text-white">
                    {{ courseCount() }}
                  </span>
                }
              </a>

              <a routerLink="/teacher/course/new"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                  </svg>
                  <span>Créer un cours</span>
                </div>
                <span class="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded group-[.shadow-md]:bg-white/20 group-[.shadow-md]:text-white">+ Nouveau</span>
              </a>

              <a routerLink="/teacher/requests"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"/>
                  </svg>
                  <span>Demandes d'inscription</span>
                </div>
                @if (pendingRequestsCount() > 0) {
                  <span class="rounded-full bg-amber-500 px-2 py-0.5 text-[10px] font-black text-white group-[.shadow-md]:bg-white group-[.shadow-md]:text-amber-600">
                    {{ pendingRequestsCount() }}
                  </span>
                }
              </a>

              <a routerLink="/teacher/assignments"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                  </svg>
                  <span>Devoirs & Exercices</span>
                </div>
                <span class="text-[10px] font-bold text-purple-600 bg-purple-50 px-1.5 py-0.5 rounded group-[.shadow-md]:bg-white/20 group-[.shadow-md]:text-white">Vocaux</span>
              </a>

              <a routerLink="/teacher/students"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                  </svg>
                  <span>Mes étudiants</span>
                </div>
              </a>
            </div>
          </div>

          <!-- Section: COMMUNICATION & DIRECT -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-light-muted/70 mb-2">
              Communication & Direct
            </p>
            <div class="space-y-1">
              <a routerLink="/teacher/chat"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                  </svg>
                  <span>Messagerie & Chat</span>
                </div>
                @if (unreadChatCount() > 0) {
                  <span class="rounded-full bg-primary px-2 py-0.5 text-[10px] font-black text-white group-[.shadow-md]:bg-white group-[.shadow-md]:text-primary">
                    {{ unreadChatCount() }}
                  </span>
                }
              </a>

              <a routerLink="/teacher/notifications"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                  </svg>
                  <span>Notifications</span>
                </div>
                @if (unreadNotifCount() > 0) {
                  <span class="rounded-full bg-red-500 px-2 py-0.5 text-[10px] font-black text-white group-[.shadow-md]:bg-white group-[.shadow-md]:text-red-500">
                    {{ unreadNotifCount() }}
                  </span>
                }
              </a>

              <a routerLink="/teacher/live"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                  </svg>
                  <span>Live Classes / Directs</span>
                </div>
                <span class="flex items-center gap-1 rounded bg-red-500/10 px-1.5 py-0.5 text-[10px] font-bold text-red-500 group-[.shadow-md]:bg-white/20 group-[.shadow-md]:text-white">
                  <span class="h-1.5 w-1.5 rounded-full bg-red-500 animate-ping"></span>
                  HD
                </span>
              </a>
            </div>
          </div>

          <!-- Section: FINANCES & MON PROFIL -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-light-muted/70 mb-2">
              Finances & Mon Compte
            </p>
            <div class="space-y-1">
              <a routerLink="/teacher/earnings"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                  <span>Revenus & Paiements</span>
                </div>
              </a>

              <a routerLink="/teacher/profile"
                 routerLinkActive="!bg-primary !text-white shadow-md shadow-primary/25 font-semibold"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                  </svg>
                  <span>Mon Profil Professionnel</span>
                </div>
              </a>
            </div>
          </div>

          <!-- Section: ACCÈS PUBLIC -->
          <div>
            <p class="px-3 text-[11px] font-bold uppercase tracking-wider text-light-muted/70 mb-2">
              Navigation
            </p>
            <div class="space-y-1">
              <a routerLink="/catalogue"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                  </svg>
                  <span>Voir le Catalogue</span>
                </div>
              </a>
              <a routerLink="/formateurs"
                 (click)="mobileSidebarOpen.set(false)"
                 class="group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-sm font-medium text-light-muted hover:bg-dark-surface2 hover:text-light transition-all">
                <div class="flex items-center gap-3">
                  <svg class="h-4 w-4 shrink-0 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>
                  </svg>
                  <span>Annuaire Professeurs</span>
                </div>
              </a>
            </div>
          </div>
        </nav>

        <!-- User Profile Card in Sidebar Bottom -->
        @if (user$ | async; as user) {
          <div class="border-t border-dark-border/60 p-4 bg-white">
            <div class="flex items-center justify-between rounded-2xl bg-dark-surface2/60 p-3 border border-dark-border/40">
              <div class="flex items-center gap-3 min-w-0">
                <img loading="lazy" decoding="async" [src]="user.photoURL || 'assets/default-avatar.png'"
                     [alt]="user.displayName"
                     class="h-10 w-10 rounded-xl object-cover border border-dark-border shrink-0 shadow-sm">
                <div class="min-w-0 flex-1">
                  <p class="truncate text-xs font-bold text-light">{{ user.displayName }}</p>
                  <p class="truncate text-[10px] font-medium text-light-muted">{{ user.email }}</p>
                </div>
              </div>
              <button (click)="logout()"
                      title="Déconnexion"
                      class="rounded-xl p-2 text-light-muted hover:bg-red-50 hover:text-red-500 transition-colors">
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
              </button>
            </div>
          </div>
        }
      </aside>

      <!-- Main Workspace Container -->
      <div class="flex flex-1 flex-col overflow-hidden">

        <!-- Top Header Bar -->
        <header class="flex h-20 shrink-0 items-center justify-between border-b border-dark-border/60 bg-white/80 px-6 backdrop-blur-md">

          <!-- Left: Mobile Menu Trigger + Title / Breadcrumb -->
          <div class="flex items-center gap-4">
            <button (click)="mobileSidebarOpen.set(true)"
                    class="rounded-xl p-2 text-light hover:bg-dark-surface2 lg:hidden"
                    aria-label="Ouvrir le menu">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>
              </svg>
            </button>

            <div>
              <h1 class="font-display text-lg font-bold text-light">{{ currentTitle() }}</h1>
              <p class="hidden text-xs text-light-muted sm:block">Tableau de bord enseignant & outils pédagogiques</p>
            </div>
          </div>

          <!-- Right: Actions & Tools (like reference image) -->
          <div class="flex items-center gap-3 sm:gap-4">

            <!-- Quick Status Pill -->
            <div class="hidden md:flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200/60 text-emerald-700 text-xs font-semibold">
              <span class="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span>Enseignant Actif</span>
            </div>

            <!-- Notification Bell -->
            <button routerLink="/teacher/chat"
                    class="relative rounded-xl p-2.5 text-light-muted hover:bg-dark-surface2 hover:text-primary transition-all">
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
              </svg>
              @if (unreadChatCount() > 0) {
                <span class="absolute top-1.5 right-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[9px] font-black text-white">
                  {{ unreadChatCount() }}
                </span>
              }
            </button>

            <!-- Language / Theme indicator (Like in Screenshot) -->
            <div class="hidden sm:flex items-center rounded-xl bg-dark-surface2 p-1 border border-dark-border">
              <span class="px-2.5 py-1 text-xs font-bold text-primary bg-white rounded-lg shadow-sm">FR</span>
              <span class="px-2.5 py-1 text-xs font-bold text-light-muted">EN</span>
            </div>

            <div class="h-6 w-px bg-dark-border hidden sm:block"></div>

            <!-- Logout Button (Top Right CTA) -->
            <button (click)="logout()"
                    class="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50/50 px-3.5 py-2 text-xs font-bold text-red-600 hover:bg-red-100 hover:border-red-300 transition-all">
              <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
              </svg>
              <span class="hidden sm:inline">Déconnexion</span>
            </button>
          </div>
        </header>

        <!-- Routed Page Content -->
        <main class="flex-1 overflow-y-auto">
          <router-outlet />
        </main>

      </div>
    </div>
  `,
})
export class TeacherLayoutComponent implements OnInit {
  private store = inject(Store);
  private router = inject(Router);
  private chatService = inject(ChatService);
  private courseService = inject(CourseService);
  private requestService = inject(RequestService);
  private notificationService = inject(NotificationService);

  user$ = this.store.select(selectCurrentUser);
  mobileSidebarOpen = signal(false);
  unreadChatCount = signal(0);
  unreadNotifCount = signal(0);
  pendingRequestsCount = signal(0);
  courseCount = signal(0);
  currentTitle = signal('Tableau de bord');

  ngOnInit(): void {
    this.updateTitle(this.router.url);

    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe((event: any) => {
      this.updateTitle(event.urlAfterRedirects || event.url);
    });

    this.user$.subscribe(user => {
      if (!user) return;

      // Subscribe to teacher's courses
      this.courseService.getTeacherCourses(user.uid).subscribe(courses => {
        this.courseCount.set(courses.length);
      });

      // Subscribe to chat conversations
      this.chatService.getUserConversations(user.uid).subscribe(convs => {
        const unread = convs.reduce((acc, c) => {
          const u = c.unreadCount ? Object.values(c.unreadCount).reduce((a, b) => a + b, 0) : 0;
          return acc + u;
        }, 0);
        this.unreadChatCount.set(unread);
      });

      // Subscribe to pending requests
      this.requestService.getTeacherRequests(user.uid).subscribe(reqs => {
        const pending = reqs.filter(r => r.status === 'pending').length;
        this.pendingRequestsCount.set(pending);
      });

      // Subscribe to notifications
      this.notificationService.getNotifications(user.uid).subscribe(notifs => {
        const unread = notifs.filter(n => !n.isRead).length;
        this.unreadNotifCount.set(unread);
      });
    });
  }

  logout(): void {
    this.store.dispatch(authActions.logout());
  }

  private updateTitle(url: string): void {
    if (url.includes('/teacher/courses')) {
      this.currentTitle.set('Mes Cours');
    } else if (url.includes('/teacher/course/new')) {
      this.currentTitle.set('Création de Cours');
    } else if (url.includes('/teacher/course/edit')) {
      this.currentTitle.set('Édition de Cours');
    } else if (url.includes('/teacher/requests')) {
      this.currentTitle.set('Demandes d\'inscription');
    } else if (url.includes('/teacher/chat')) {
      this.currentTitle.set('Messagerie & Chat');
    } else if (url.includes('/teacher/notifications')) {
      this.currentTitle.set('Centre de Notifications');
    } else if (url.includes('/teacher/live')) {
      this.currentTitle.set('Gestion des Lives & Plannings');
    } else if (url.includes('/teacher/earnings')) {
      this.currentTitle.set('Revenus & Paiements');
    } else if (url.includes('/teacher/students')) {
      this.currentTitle.set('Gestion des Étudiants');
    } else if (url.includes('/teacher/profile')) {
      this.currentTitle.set('Mon Profil Professionnel');
    } else {
      this.currentTitle.set('Tableau de bord Formateur');
    }
  }
}
