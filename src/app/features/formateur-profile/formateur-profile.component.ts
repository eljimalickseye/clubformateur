import { Component, inject, OnInit, signal, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink, Router } from '@angular/router';
import { Store } from '@ngrx/store';
import { AuthService } from '../../core/services/auth.service';
import { CourseService } from '../../core/services/course.service';
import { selectCurrentUser } from '../../store/auth/auth.selectors';
import { User, Course, TeacherScheduleSlot } from '../../core/models';
import { CourseCardComponent } from '../../shared/components/course-card/course-card.component';

import { BackButtonComponent } from '../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-formateur-profile',
  standalone: true,
  imports: [CommonModule, RouterLink, CourseCardComponent, BackButtonComponent],
  template: `
    <div class="max-w-6xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-8 font-body space-y-6">
      
      <!-- Back button -->
      <div class="flex items-center justify-between">
        <app-back-button label="Retour aux formateurs" defaultRoute="/formateurs" />
        
        <!-- Quick contact button top right on mobile/tablet -->
        @if (formateur()) {
          <button (click)="contactTeacher()"
                  class="md:hidden px-3.5 py-1.5 rounded-xl bg-gradient-to-r from-sky-500 to-primary text-white text-xs font-bold shadow-sm flex items-center gap-1.5 active:scale-95 cursor-pointer">
            <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span>Message</span>
          </button>
        }
      </div>

      @if (loading()) {
        <div class="flex justify-center py-20">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
        </div>
      } @else if (formateur()) {
        <!-- Profile Header -->
        <div class="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 flex flex-col md:flex-row gap-6 sm:gap-8 items-center md:items-start text-center md:text-left shadow-sm">
          <div class="relative shrink-0">
            <img loading="lazy" decoding="async" [src]="formateur()?.photoURL || 'assets/images/default-avatar.png'" alt="Avatar" class="w-32 h-32 rounded-3xl object-cover border-4 border-primary/20 shadow-xl" onerror="this.src='https://ui-avatars.com/api/?name=' + formateur()?.displayName + '&background=2D5BE3&color=fff'">
            <span class="absolute -bottom-2 -right-2 flex h-7 w-7 items-center justify-center rounded-full bg-emerald-500 ring-4 ring-white text-white"
                  title="Formateur Certifié">
              <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            </span>
          </div>
          
          <div class="flex-1">
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-4">
              <div>
                <h1 class="font-display text-2xl sm:text-3xl font-extrabold text-slate-900 mb-1">{{ formateur()?.displayName }}</h1>
                <p class="text-primary font-bold text-sm">{{ formateur()?.speciality || 'Formateur Expert' }}</p>
                
                <!-- Niveau Enseigné (Licence 3) -->
                <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-700 text-xs font-bold mt-2">
                  <svg class="w-3.5 h-3.5 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z"/>
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
                  </svg>
                  <span>Niveau enseigné : {{ formateur()?.teachingLevel || formateur()?.taughtLevels || 'Licence 3' }}</span>
                </div>
              </div>
              
              <!-- Direct Contact Button & Socials -->
              <div class="flex items-center gap-2.5 justify-center md:justify-start flex-wrap">
                <button (click)="contactTeacher()"
                        class="px-4 py-2.5 rounded-2xl bg-gradient-to-r from-sky-500 via-primary to-indigo-600 hover:from-sky-400 hover:to-primary-600 text-white font-bold text-xs sm:text-sm shadow-md shadow-primary/25 transition-all flex items-center gap-2 cursor-pointer active:scale-95">
                  <svg class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                  <span>Contacter par message</span>
                </button>

                @if (formateur()?.socialLinks?.linkedin) {
                  <a [href]="formateur()?.socialLinks?.linkedin" target="_blank" class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700 hover:text-primary hover:bg-primary/10 transition-colors" title="LinkedIn">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/></svg>
                  </a>
                }
                @if (formateur()?.socialLinks?.youtube) {
                  <a [href]="formateur()?.socialLinks?.youtube" target="_blank" class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700 hover:text-red-500 hover:bg-red-500/10 transition-colors" title="YouTube">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>
                  </a>
                }
                @if (formateur()?.socialLinks?.twitter) {
                  <a [href]="formateur()?.socialLinks?.twitter" target="_blank" class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700 hover:text-blue-400 hover:bg-blue-400/10 transition-colors" title="Twitter">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z"/></svg>
                  </a>
                }
              </div>
            </div>
            
            <p class="text-slate-600 text-xs sm:text-sm leading-relaxed mb-5 whitespace-pre-line">{{ formateur()?.bio || 'Ce formateur n’a pas encore ajouté de description.' }}</p>
            
            <!-- Credentials & Badges -->
            <div class="flex flex-wrap gap-2 mb-6">
              @if (formateur()?.experience) {
                <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-primary/10 text-primary border border-primary/20 rounded-xl text-xs font-bold">
                  <svg class="w-3.5 h-3.5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                  <span>{{ formateur()?.experience }}</span>
                </span>
              }
              @for (dip of formateur()?.diplomas || []; track dip) {
                <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-slate-100 text-slate-800 border border-slate-200 rounded-xl text-xs font-bold">
                  <svg class="w-3.5 h-3.5 text-slate-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                  <span>{{ dip }}</span>
                </span>
              }
              @for (lang of formateur()?.languages || []; track lang) {
                <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-500/10 text-emerald-700 border border-emerald-500/20 rounded-xl text-xs font-bold uppercase">
                  <svg class="w-3.5 h-3.5 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
                  </svg>
                  <span>{{ lang }}</span>
                </span>
              }
            </div>

            <div class="flex items-center justify-center md:justify-start gap-6 sm:gap-8 text-sm border-t border-slate-100 pt-4">
              <div class="text-center md:text-left">
                <p class="font-bold text-xl text-slate-900">{{ courses().length }}</p>
                <p class="text-slate-500 uppercase tracking-wider text-[11px] font-semibold">Cours</p>
              </div>
              <div class="w-px h-8 bg-slate-200"></div>
              <div class="text-center md:text-left">
                <p class="font-bold text-xl text-amber-500 inline-flex items-center justify-center md:justify-start gap-1">
                  <span>{{ averageRating() | number:'1.1-1' }}</span>
                  <svg class="w-4 h-4 fill-amber-500 text-amber-500 shrink-0" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                  </svg>
                </p>
                <p class="text-slate-500 uppercase tracking-wider text-[11px] font-semibold">Avis moyen</p>
              </div>
              <div class="w-px h-8 bg-slate-200"></div>
              <div class="text-center md:text-left">
                <p class="font-bold text-xl text-slate-900">{{ totalStudents() }}</p>
                <p class="text-slate-500 uppercase tracking-wider text-[11px] font-semibold">Étudiants</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Weekly Schedule & Course Hours -->
        <div class="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-sm space-y-4">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100">
            <div>
              <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-1">
                <svg class="w-3.5 h-3.5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                </svg>
                <span>Emploi du Temps & Directs</span>
              </div>
              <h2 class="font-display text-xl sm:text-2xl font-bold text-slate-900">Planning & Horaires de cours</h2>
              <p class="text-xs sm:text-sm text-slate-500">Heures de cours en direct, travaux pratiques et permanences de tutorat du formateur.</p>
            </div>
            <div class="flex items-center gap-2">
              <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-slate-100 text-slate-700 text-xs font-bold">
                <svg class="w-3.5 h-3.5 text-slate-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>~6h de cours / semaine</span>
              </span>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            @for (slot of scheduleSlots(); track slot.day + slot.hours) {
              <div class="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 space-y-2 hover:border-primary/40 transition-colors">
                <div class="flex items-center justify-between gap-2">
                  <span class="font-bold text-slate-900 text-sm flex items-center gap-1.5 truncate">
                    <span class="w-2 h-2 rounded-full bg-primary shrink-0"></span>
                    <span class="truncate">{{ slot.day }}</span>
                  </span>
                  <span class="px-2.5 py-0.5 rounded-lg bg-white border border-slate-200 text-primary font-mono text-xs font-bold shrink-0 whitespace-nowrap">
                    {{ slot.hours }}
                  </span>
                </div>
                <p class="text-xs font-semibold text-slate-700 truncate">{{ slot.activity }}</p>
                @if (slot.courseTitle) {
                  <p class="text-[11px] text-slate-400 truncate">Module : {{ slot.courseTitle }}</p>
                }
              </div>
            }
          </div>
        </div>

        <!-- Teacher Intro / Presentation Video -->
        @if (introVideoUrl()) {
          <div class="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-xl text-white space-y-4">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/20 text-sky-400 text-xs font-bold uppercase tracking-wider mb-1">
                  <svg class="w-3.5 h-3.5 text-sky-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                  <span>Démarche Pédagogique</span>
                </span>
                <h2 class="font-display text-xl sm:text-2xl font-bold text-white">Vidéo de présentation du formateur</h2>
                <p class="text-xs sm:text-sm text-slate-400">Faites connaissance avec votre formateur et découvrez ses méthodes d'apprentissage.</p>
              </div>
              <button (click)="contactTeacher()"
                      class="px-4 py-2 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs font-bold transition-all self-start sm:self-auto cursor-pointer inline-flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
                <span>Écrire au formateur</span>
              </button>
            </div>

            <div class="aspect-video w-full max-w-4xl mx-auto rounded-2xl overflow-hidden bg-black relative shadow-2xl select-none"
                 (contextmenu)="$event.preventDefault()">
              <!-- Watermark -->
              <div class="absolute bottom-12 right-4 sm:bottom-14 sm:right-6 z-20 pointer-events-none select-none flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/55 backdrop-blur-md border border-white/15 shadow-lg">
                <svg width="20" height="20" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" class="shrink-0">
                  <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
                  <circle cx="20" cy="20" r="4" fill="white"/>
                </svg>
                <span class="font-display text-[10px] font-black text-white tracking-tight drop-shadow-sm">
                  Club des Formateurs
                </span>
              </div>

              <video [src]="introVideoUrl()"
                     controls
                     controlsList="nodownload"
                     (contextmenu)="$event.preventDefault()"
                     class="w-full h-full object-contain"></video>
            </div>
          </div>
        }

        <!-- Course Catalog -->
        <div>
          <h2 class="font-display text-xl sm:text-2xl font-bold text-slate-900 mb-5">Catalogue de formations du professeur</h2>
          
          @if (courses().length > 0) {
            <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
              @for (course of courses(); track course.id) {
                <app-course-card [course]="course" (playVideo)="openVideoModal($event)" />
              }
            </div>
          } @else {
            <div class="text-center py-12 bg-white border border-dashed border-slate-200 rounded-3xl p-6">
              <div class="w-12 h-12 mx-auto mb-3 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400">
                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <p class="text-slate-500 text-sm">Ce formateur n'a pas encore publié de cours.</p>
            </div>
          }
        </div>
      } @else {
        <div class="text-center py-16 bg-white border border-slate-200 rounded-3xl p-8 max-w-lg mx-auto">
          <div class="w-14 h-14 mx-auto mb-4 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400">
            <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 class="font-display text-xl sm:text-2xl font-bold text-slate-900 mb-2">Formateur introuvable</h2>
          <p class="text-slate-500 text-xs sm:text-sm mb-6">Le formateur que vous recherchez n'existe pas ou a été retiré.</p>
          <a routerLink="/formateurs" class="btn-primary inline-flex">Retour aux formateurs</a>
        </div>
      }
    </div>

    <!-- Video Modal -->
    @if (selectedCourse()) {
      <div class="fixed inset-0 z-50 flex items-center justify-center p-0 sm:p-4 bg-black/85 backdrop-blur-sm animate-in fade-in duration-200" (click)="closeVideoModal()">
        <div class="relative w-full h-full sm:h-auto max-w-4xl bg-dark-surface sm:rounded-2xl overflow-hidden shadow-2xl border-0 sm:border sm:border-dark-border flex flex-col justify-between sm:justify-center"
             style="padding-top: env(safe-area-inset-top, 0px); padding-bottom: env(safe-area-inset-bottom, 0px);"
             (click)="$event.stopPropagation()">
          <div class="absolute top-4 right-4 z-30">
            <button (click)="closeVideoModal()" class="w-10 h-10 flex items-center justify-center rounded-full bg-black/70 text-white hover:bg-black transition-colors shadow-lg border border-white/20 cursor-pointer">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            </button>
          </div>
          
          <div class="aspect-video bg-black flex items-center justify-center relative select-none"
               (contextmenu)="$event.preventDefault()">
            
            <!-- Video Title Overlay -->
            <div class="absolute top-4 left-4 z-20 pointer-events-none select-none max-w-[70%]">
              <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/60 backdrop-blur-md border border-white/15 text-white shadow-lg">
                <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
                <h4 class="text-xs font-bold truncate text-white">{{ selectedCourse()?.title }}</h4>
              </div>
            </div>

            <!-- Watermark Logo Club des Formateurs at Bottom -->
            <div class="absolute bottom-12 right-4 sm:bottom-14 sm:right-6 z-20 pointer-events-none select-none flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/55 backdrop-blur-md border border-white/15 shadow-lg">
              <svg width="22" height="22" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" class="shrink-0">
                <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
                <circle cx="20" cy="20" r="4" fill="white"/>
              </svg>
              <span class="font-display text-[11px] font-black text-white tracking-tight drop-shadow-sm">
                Club des Formateurs
              </span>
            </div>

            @if (selectedCourse()?.promoVideoUrl) {
              <video [src]="selectedCourse()!.promoVideoUrl"
                     controls
                     autoplay
                     controlsList="nodownload"
                     (contextmenu)="$event.preventDefault()"
                     class="w-full h-full object-contain"></video>
            } @else {
              <div class="text-center p-8">
                <div class="w-12 h-12 mx-auto mb-4 rounded-2xl bg-white/10 flex items-center justify-center text-slate-400">
                  <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold text-light mb-2">Présentation du cours</h3>
                <p class="text-light-muted">La vidéo de présentation n'est pas encore disponible pour ce cours.</p>
              </div>
            }
          </div>
          <div class="p-5">
            <h3 class="font-display text-xl font-bold text-light mb-1">{{ selectedCourse()?.title }}</h3>
            <p class="text-sm text-light-muted flex items-center gap-2">
              <img loading="lazy" decoding="async" [src]="formateur()?.photoURL || 'assets/images/default-avatar.png'" alt="avatar" class="w-5 h-5 rounded-full object-cover">
              Présenté par <span class="text-light">{{ formateur()?.displayName }}</span>
            </p>
          </div>
        </div>
      </div>
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class FormateurProfileComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private store = inject(Store);
  private authService = inject(AuthService);
  private courseService = inject(CourseService);

  currentUser: User | null = null;
  loading = signal(true);
  formateur = signal<User | null>(null);
  courses = signal<Course[]>([]);
  selectedCourse = signal<Course | null>(null);
  scheduleSlots = signal<TeacherScheduleSlot[]>([]);
  introVideoUrl = signal<string | null>(null);

  averageRating = signal(0);
  totalStudents = signal(0);

  ngOnInit() {
    this.store.select(selectCurrentUser).subscribe(u => this.currentUser = u);

    this.route.paramMap.subscribe(params => {
      const id = params.get('id');
      if (id) {
        this.loadFormateur(id);
      } else {
        this.loading.set(false);
      }
    });
  }

  private loadFormateur(id: string) {
    this.loading.set(true);
    
    // Fetch user profile
    this.authService.getUserById(id).subscribe(user => {
      if (user && user.role === 'teacher') {
        this.formateur.set(user);
        
        // Fetch teacher's published courses
        this.courseService.getTeacherCourses(id).subscribe(allCourses => {
          const published = allCourses.filter(c => c.isPublished);
          this.courses.set(published);
          
          // Calculate stats
          let totalRating = 0;
          let students = 0;
          let coursesWithRatings = 0;
          
          published.forEach(c => {
            students += c.enrolledCount || 0;
            if (c.rating > 0) {
              totalRating += c.rating;
              coursesWithRatings++;
            }
          });
          
          this.totalStudents.set(students);
          this.averageRating.set(coursesWithRatings > 0 ? totalRating / coursesWithRatings : 0);

          // Video & schedule
          let introVideo = user.introVideoUrl;
          if (!introVideo && published.length > 0) {
            introVideo = published.find(c => !!c.promoVideoUrl)?.promoVideoUrl;
          }
          this.introVideoUrl.set(introVideo || null);

          const slots = (user.scheduleSlots && user.scheduleSlots.length > 0)
            ? user.scheduleSlots
            : this.generateDefaultSchedule(user.speciality, published);
          this.scheduleSlots.set(slots);
          
          this.loading.set(false);
        });
      } else {
        this.formateur.set(null);
        this.loading.set(false);
      }
    });
  }

  private generateDefaultSchedule(speciality?: string, published?: Course[]): TeacherScheduleSlot[] {
    const primaryCourse = published && published.length > 0 ? published[0].title : undefined;
    const spec = (speciality || '').toLowerCase();

    if (spec.includes('développement') || spec.includes('code') || spec.includes('informatique') || spec.includes('web') || spec.includes('python')) {
      return [
        { day: 'Lundi & Mercredi', hours: '18h00 - 19h30', activity: 'Cours Magistral & Code Live', courseTitle: primaryCourse || 'Développement & Algorithmique' },
        { day: 'Vendredi', hours: '19h00 - 20h30', activity: 'Projets & Travaux Pratiques', courseTitle: primaryCourse },
        { day: 'Samedi', hours: '10h00 - 12h00', activity: 'Permanence & Tutorat Q/R' }
      ];
    }

    if (spec.includes('business') || spec.includes('gestion') || spec.includes('marketing') || spec.includes('finance')) {
      return [
        { day: 'Mardi & Jeudi', hours: '18h30 - 20h00', activity: 'Stratégie & Études de cas', courseTitle: primaryCourse || 'Management & Business' },
        { day: 'Vendredi', hours: '18h00 - 19h30', activity: 'Atelier Pratique & Pitchs' },
        { day: 'Samedi', hours: '10h30 - 12h30', activity: 'Mentorat & Tutorat individuel' }
      ];
    }

    if (spec.includes('design') || spec.includes('ui') || spec.includes('ux') || spec.includes('graph')) {
      return [
        { day: 'Lundi & Jeudi', hours: '18h30 - 20h00', activity: 'Workshop Figma & Création', courseTitle: primaryCourse || 'Design Graphique' },
        { day: 'Mercredi', hours: '19h00 - 20h15', activity: 'Critiques & Revues de projets' },
        { day: 'Samedi', hours: '11h00 - 13h00', activity: 'Mentorat & Suivi de portfolio' }
      ];
    }

    return [
      { day: 'Mardi & Jeudi', hours: '18h30 - 20h00', activity: 'Cours Interactif & Direct', courseTitle: primaryCourse || 'Cours Fondamental' },
      { day: 'Vendredi', hours: '19h00 - 20h15', activity: 'Atelier Pratique & Travaux de groupe' },
      { day: 'Samedi', hours: '10h00 - 12h00', activity: 'Permanence Tutorat Étudiants' }
    ];
  }

  contactTeacher(): void {
    const t = this.formateur();
    if (!t) return;
    const teacherId = t.uid;
    const teacherName = t.displayName || 'Formateur';
    const teacherPhoto = t.photoURL || '';
    const speciality = t.speciality || 'Formation';

    if (!this.currentUser) {
      const returnUrl = `/student/chat?teacherId=${teacherId}&teacherName=${encodeURIComponent(teacherName)}&teacherPhoto=${encodeURIComponent(teacherPhoto)}&speciality=${encodeURIComponent(speciality)}`;
      this.router.navigate(['/auth/login'], { queryParams: { returnUrl } });
      return;
    }

    this.router.navigate(['/student/chat'], {
      queryParams: {
        teacherId,
        teacherName,
        teacherPhoto,
        speciality
      }
    });
  }

  openVideoModal(course: Course): void {
    this.selectedCourse.set(course);
  }

  closeVideoModal(): void {
    this.selectedCourse.set(null);
  }
}
