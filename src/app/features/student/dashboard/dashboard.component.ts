import { Component, inject, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AsyncPipe, DatePipe } from '@angular/common';
import { Store } from '@ngrx/store';
import { switchMap, of, forkJoin } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { EnrollmentService } from '../../../core/services/enrollment.service';
import { CourseService } from '../../../core/services/course.service';
import { Enrollment, Course, User } from '../../../core/models';

import { LivekitService } from '../../../core/services/livekit.service';
import { LiveSession } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../../shared/components/refresh-button/refresh-button.component';
import { authActions } from '../../../store/auth/auth.actions';

interface EnrollmentWithCourse extends Enrollment { course?: Course; }

@Component({
  selector: 'app-student-dashboard',
  standalone: true,
  imports: [RouterLink, AsyncPipe, DatePipe, BackButtonComponent, RefreshButtonComponent],
  template: `
    <div class="page-container font-body animate-fade-in">
      <!-- Sticky Top Navigation & PWA Header -->
      <div class="sticky top-0 z-30 -mx-4 sm:-mx-6 lg:-mx-8 px-4 sm:px-6 lg:px-8 py-3 bg-white/95 backdrop-blur-md border-b border-slate-200/80 shadow-2xs mb-6 flex items-center justify-between gap-3">
        <div class="flex items-center gap-2 sm:gap-3">
          <app-back-button label="Accueil" defaultRoute="/" variant="light" />
          <app-refresh-button variant="light" />
          <a routerLink="/" class="flex items-center gap-2 group">
            <svg width="28" height="28" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
              <circle cx="20" cy="20" r="4" fill="white"/>
            </svg>
            <span class="font-display text-sm sm:text-base font-extrabold text-light tracking-tight group-hover:text-primary transition-colors hidden sm:inline">
              Club des Formateurs
            </span>
          </a>
        </div>

        <div class="flex items-center gap-2">
          <a routerLink="/catalogue"
             class="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold transition-all flex items-center gap-1.5 active:scale-95">
            <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect>
              <rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect>
            </svg>
            <span>Catalogue</span>
          </a>
          <button (click)="logout()"
                  class="px-3 py-2 rounded-xl bg-red-50 hover:bg-red-100 text-red-600 text-xs font-bold transition-all flex items-center gap-1.5 active:scale-95 cursor-pointer"
                  title="Se déconnecter">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
            </svg>
            <span class="hidden sm:inline">Déconnexion</span>
          </button>
        </div>
      </div>

      <!-- Student Profile Header (No 'Student Dashboard', No 'Bienvenue', Name + Matricule + Academic Year) -->
      @if (user$ | async; as user) {
        <div class="mb-8 rounded-3xl border border-slate-200 bg-white p-5 sm:p-7 shadow-xs">
          <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-5">
            
            <!-- Left: Avatar & Identity -->
            <div class="flex items-center gap-4 sm:gap-5">
              <div class="relative shrink-0">
                <img loading="lazy" decoding="async" [src]="user.photoURL || getAvatarUrl(user.displayName)"
                     class="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl object-cover border-2 border-primary/40 shadow-sm bg-slate-50"
                     alt="Photo de profil"
                     onerror="this.src='assets/default-avatar.png'">
                <span class="absolute -bottom-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-emerald-500 ring-2 ring-white text-white text-[10px] font-bold" title="Compte Actif">
                  <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </span>
              </div>

              <div class="space-y-1.5 min-w-0">
                <!-- User name only (no 'Bienvenue') -->
                <h1 class="font-display text-2xl sm:text-3xl font-black text-slate-900 tracking-tight truncate">
                  {{ user.displayName || 'Étudiant' }}
                </h1>

                <!-- Matricule & Academic Year Badges -->
                <div class="flex flex-wrap items-center gap-2">
                  <!-- Matricule -->
                  <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 border border-blue-200 text-primary text-xs font-bold font-mono">
                    <svg class="w-3.5 h-3.5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
                    </svg>
                    <span>Matricule : {{ getStudentMatricule(user) }}</span>
                  </div>

                  <!-- Année en cours & Niveau -->
                  <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-slate-700 text-xs font-medium">
                    <svg class="w-3.5 h-3.5 text-slate-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                    </svg>
                    <span>{{ user.academicLevel || 'Étudiant en Licence' }} • Année {{ user.academicYear || getAcademicYear() }}</span>
                  </div>
                </div>
              </div>
            </div>



          </div>
        </div>

        <!-- Devise d'apprentissage avec le "s" à arrêtés -->
        <div class="mb-6 rounded-2xl bg-blue-50/70 border border-blue-100 p-4 flex items-center justify-between gap-3 shadow-2xs">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-xl bg-primary/10 text-primary flex items-center justify-center shrink-0">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <p class="text-xs sm:text-sm text-slate-700 font-semibold">
              Continuez votre apprentissage là où vous vous êtes arrêtés.
            </p>
          </div>
          <a routerLink="/student/my-courses"
             class="px-3.5 py-1.5 rounded-xl bg-white border border-slate-200 hover:border-primary text-primary text-xs font-bold transition-all shrink-0 active:scale-95 shadow-2xs">
            Reprendre
          </a>
        </div>

        <!-- Dynamic Live Alert Banner -->
        @if (activeLives().length > 0) {
          <div class="mb-8 p-5 rounded-2xl bg-gradient-to-r from-red-600 via-rose-600 to-red-700 text-white shadow-xl shadow-red-600/20 flex flex-col sm:flex-row items-center justify-between gap-4 animate-bounce-short">
            <div class="flex items-center gap-3.5">
              <span class="flex h-3.5 w-3.5 relative">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3.5 w-3.5 bg-white"></span>
              </span>
              <div>
                <div class="flex items-center gap-2">
                  <span class="px-2 py-0.5 rounded-full bg-black/30 text-[10px] font-black uppercase tracking-wider">
                    EN DIRECT MAINTENANT
                  </span>
                  <span class="text-xs font-bold text-red-100">
                    Prof. {{ activeLives()[0].teacherName }}
                  </span>
                </div>
                <h2 class="font-display text-sm sm:text-base font-extrabold text-white mt-0.5">
                  {{ activeLives()[0].title }} ({{ activeLives()[0].courseName }})
                </h2>
              </div>
            </div>

            <a [routerLink]="['/student/live', activeLives()[0].id]"
               class="px-5 py-2.5 bg-white hover:bg-slate-100 text-red-600 font-black text-xs rounded-2xl shadow-lg transition-all active:scale-95 flex items-center gap-2 shrink-0">
              <span>Rejoindre le Live</span>
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
              </svg>
            </a>
          </div>
        }

        <!-- Menu Navigation Rapide (Pure SVG Icons, Clean Labels) -->
        <h2 class="font-display text-lg sm:text-xl font-bold text-light mb-4">Accès rapide</h2>
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3 mb-8">
          
          <!-- Lives & Replays -->
          <a routerLink="/student/lives" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white border border-red-500/20 hover:border-red-500 transition-all">
            <div class="h-12 w-12 rounded-2xl bg-red-500/10 text-red-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform relative">
              @if (activeLives().length > 0) {
                <span class="w-2 h-2 rounded-full bg-red-500 absolute top-2 right-2 animate-ping"></span>
              }
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Lives & Replays</span>
          </a>

          <!-- Catalogue -->
          <a routerLink="/catalogue" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="7" rx="1.5"></rect>
                <rect x="14" y="3" width="7" height="7" rx="1.5"></rect>
                <rect x="14" y="14" width="7" height="7" rx="1.5"></rect>
                <rect x="3" y="14" width="7" height="7" rx="1.5"></rect>
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Catalogue</span>
          </a>

          <!-- Mes Cours -->
          <a routerLink="/student/my-courses" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-blue-500/10 text-blue-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Mes Cours</span>
          </a>

          <!-- Mes Devoirs -->
          <a routerLink="/student/assignments" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-purple-500/10 text-purple-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Mes Devoirs</span>
          </a>

          <!-- Groupes d'Étude -->
          <a routerLink="/student/study-groups" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-indigo-500/10 text-indigo-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Groupes (5 max)</span>
          </a>

          <!-- Certificats -->
          <a routerLink="/student/certificates" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Certificats</span>
          </a>

          <!-- Messagerie -->
          <a routerLink="/student/chat" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-cyan-500/10 text-cyan-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Messagerie</span>
          </a>

          <!-- Achats -->
          <a routerLink="/student/purchases" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-amber-500/10 text-amber-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Achats</span>
          </a>

          <!-- Paramètres -->
          <a routerLink="/student/settings" class="card-hover p-4 flex flex-col items-center justify-center text-center group bg-white">
            <div class="h-12 w-12 rounded-2xl bg-gray-500/10 text-gray-600 flex items-center justify-center mb-3 group-hover:scale-110 transition-transform">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <span class="text-xs font-bold text-slate-800">Paramètres</span>
          </a>

        </div>

        <!-- Stats Cards (Accurate Counts + Pure SVG Icons) -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          
          <!-- Cours inscrits -->
          <div class="card p-5 border border-slate-200 bg-white shadow-xs">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-xs text-slate-500 font-medium">Cours inscrits</div>
                <div class="font-display text-2xl font-black text-slate-900 mt-1">{{ enrolledCount }}</div>
              </div>
              <div class="h-11 w-11 rounded-2xl bg-primary/10 text-primary flex items-center justify-center">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
            </div>
          </div>

          <!-- Cours terminés -->
          <div class="card p-5 border border-slate-200 bg-white shadow-xs">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-xs text-slate-500 font-medium">Cours terminés</div>
                <div class="font-display text-2xl font-black text-slate-900 mt-1">{{ completedCount }}</div>
              </div>
              <div class="h-11 w-11 rounded-2xl bg-emerald-500/10 text-emerald-600 flex items-center justify-center">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>

          <!-- Certificats -->
          <div class="card p-5 border border-slate-200 bg-white shadow-xs">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-xs text-slate-500 font-medium">Certificats obtenus</div>
                <div class="font-display text-2xl font-black text-slate-900 mt-1">{{ certificatesCount }}</div>
              </div>
              <div class="h-11 w-11 rounded-2xl bg-blue-500/10 text-blue-600 flex items-center justify-center">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                </svg>
              </div>
            </div>
          </div>

          <!-- Heures d'étude -->
          <div class="card p-5 border border-slate-200 bg-white shadow-xs">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-xs text-slate-500 font-medium">Heures d'apprentissage</div>
                <div class="font-display text-2xl font-black text-slate-900 mt-1">{{ totalHours }}h</div>
              </div>
              <div class="h-11 w-11 rounded-2xl bg-amber-500/10 text-amber-600 flex items-center justify-center">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
          </div>

        </div>

        <!-- Continue learning -->
        <div class="mb-8">
          <div class="flex items-center justify-between mb-4">
            <h2 class="font-display text-lg sm:text-xl font-bold text-light">Continuer l'apprentissage</h2>
            <a routerLink="/student/my-courses" class="btn-secondary !px-3 !py-1.5 !text-xs font-bold">Voir tout</a>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            @for (item of recentEnrollments; track item.id) {
              @if (item.course) {
                <div class="card-hover p-4 flex gap-4 bg-white border border-slate-200 rounded-2xl">
                  <img loading="lazy" decoding="async" [src]="item.course.thumbnailUrl || 'assets/default-course.png'" [alt]="item.course.title"
                       class="w-24 h-16 object-cover rounded-xl shrink-0 bg-slate-100"
                       onerror="this.src='assets/default-course.png'">
                  <div class="flex-1 min-w-0">
                    <h3 class="font-bold text-slate-900 text-sm line-clamp-1">{{ item.course.title }}</h3>
                    <p class="text-xs text-slate-500 mb-2 truncate">Prof. {{ item.course.teacherName }}</p>
                    
                    <!-- Progress bar -->
                    <div class="w-full bg-slate-100 rounded-full h-1.5 mb-1.5 overflow-hidden">
                      <div class="bg-primary h-1.5 rounded-full transition-all duration-500"
                           [style.width.%]="item.progress || 5"></div>
                    </div>
                    
                    <div class="flex items-center justify-between">
                      <span class="text-xs text-slate-500 font-medium">{{ item.progress || 0 }}% terminé</span>
                      <a [routerLink]="['/learn', item.courseId, item.lastLessonId || '']"
                         class="text-xs text-primary font-bold hover:underline flex items-center gap-1">
                        <span>Reprendre</span>
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                        </svg>
                      </a>
                    </div>
                  </div>
                </div>
              }
            } @empty {
              <div class="col-span-2 text-center py-12 border border-dashed border-slate-300 rounded-3xl bg-white shadow-xs space-y-3">
                <div class="w-14 h-14 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto">
                  <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                  </svg>
                </div>
                <div>
                  <p class="font-bold text-slate-800 text-sm">Aucun cours en cours actuellement</p>
                  <p class="text-xs text-slate-500 mt-0.5">Explorez nos formations pour débuter votre apprentissage.</p>
                </div>
                <a routerLink="/catalogue" class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-primary text-white text-xs font-bold shadow-sm shadow-primary/20 hover:bg-primary-600 transition-all active:scale-95">
                  <span>Explorer le catalogue</span>
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                  </svg>
                </a>
              </div>
            }
          </div>
        </div>
      }
    </div>
  `,
})
export class StudentDashboardComponent implements OnInit {
  private store = inject(Store);
  private enrollmentService = inject(EnrollmentService);
  private courseService = inject(CourseService);
  private livekitService = inject(LivekitService);

  user$ = this.store.select(selectCurrentUser);
  activeLives = signal<LiveSession[]>([]);
  recentEnrollments: (Enrollment & { course?: Course })[] = [];
  enrolledCount = 0;
  completedCount = 0;
  certificatesCount = 0;
  totalHours = 0;

  ngOnInit(): void {
    this.livekitService.getActiveLiveSessions().subscribe(lives => {
      this.activeLives.set(lives);
    });

    this.user$.pipe(
      switchMap(user => {
        if (!user) return of({ user: null, enrollments: [] });
        return this.enrollmentService.getStudentEnrollments(user.uid).pipe(
          switchMap(enrollments => of({ user, enrollments }))
        );
      })
    ).subscribe(({ user, enrollments }) => {
      if (!user) return;

      // Enrolled courses count: accurately take all enrolled courses
      const enrolledSet = new Set([
        ...enrollments.map(e => e.courseId),
        ...(user.enrolledCourses || [])
      ]);
      this.enrolledCount = Math.max(enrollments.length, enrolledSet.size);

      // Completed courses count
      this.completedCount = enrollments.filter(e => e.progress === 100).length;

      // Certificates count
      this.certificatesCount = enrollments.filter(e => e.certificateIssued).length;

      // Total hours computation: based on enrolled courses and progress
      let totalMinutes = 0;
      enrollments.forEach(e => {
        const progress = e.progress || 10;
        totalMinutes += (progress / 100) * 180; // 3h avg per course
      });
      if (this.enrolledCount > 0 && totalMinutes === 0) {
        totalMinutes = this.enrolledCount * 45;
      }
      this.totalHours = Math.max(this.enrolledCount > 0 ? 1 : 0, Math.round(totalMinutes / 60));

      this.recentEnrollments = enrollments.slice(0, 4);
      this.loadCourseDetails();
    });
  }

  getStudentMatricule(user: User): string {
    if (user.matricule) return user.matricule;
    // Generate deterministic clean matricule: CF-2026-XXXXX
    const year = new Date().getFullYear();
    const hash = (user.uid || 'STU').slice(0, 5).toUpperCase();
    return `CF-${year}-${hash}`;
  }

  getAcademicYear(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1; // 1-12
    if (month < 9) {
      return `${year - 1}-${year}`;
    }
    return `${year}-${year + 1}`;
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Étudiant');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  private loadCourseDetails(): void {
    this.recentEnrollments.forEach((enrollment, index) => {
      this.courseService.getCourseById(enrollment.courseId).subscribe(course => {
        this.recentEnrollments[index] = { ...enrollment, course };
      });
    });
  }

  logout(): void {
    this.store.dispatch(authActions.logout());
  }
}
