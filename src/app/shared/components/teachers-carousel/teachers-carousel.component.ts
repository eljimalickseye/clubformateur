import { Component, inject, OnInit, OnDestroy, signal, computed, Output, EventEmitter } from '@angular/core';
import { CommonModule, DecimalPipe, DatePipe } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { CourseService } from '../../../core/services/course.service';
import { LivekitService } from '../../../core/services/livekit.service';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { User, Course, LiveSession, TeacherScheduleSlot } from '../../../core/models';

export interface TeacherCarouselItem {
  teacher: User;
  courses: Course[];
  totalStudents: number;
  avgRating: number;
  introVideoUrl?: string;
  scheduleSlots: TeacherScheduleSlot[];
  upcomingLive?: LiveSession;
  isCurrentlyLive: boolean;
}

@Component({
  selector: 'app-teachers-carousel',
  standalone: true,
  imports: [CommonModule, RouterLink, DecimalPipe, DatePipe],
  template: `
    <div class="relative w-full rounded-3xl bg-gradient-to-br from-slate-900 via-[#0F172A] to-slate-950 p-5 sm:p-8 lg:p-10 shadow-2xl border border-slate-800/80 overflow-hidden font-body text-white"
         (mouseenter)="pauseAutoPlay()" (mouseleave)="resumeAutoPlay()">

      <!-- Ambient Glow Decorators -->
      <div class="absolute -top-24 -left-24 w-72 h-72 bg-primary/20 rounded-full blur-[100px] pointer-events-none"></div>
      <div class="absolute -bottom-24 -right-24 w-80 h-80 bg-sky-500/15 rounded-full blur-[120px] pointer-events-none"></div>

      <!-- Header with Section Title & Carousel Controls -->
      <div class="relative z-10 flex flex-col md:flex-row md:items-end justify-between gap-4 mb-6 sm:mb-8">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/20 border border-primary/30 text-sky-400 text-xs font-bold uppercase tracking-wider mb-2.5">
            <span class="w-2 h-2 rounded-full bg-sky-400 animate-ping"></span>
            <span>Club des Formateurs • Corps Enseignant</span>
          </div>
          <h2 class="font-display text-2xl sm:text-3xl lg:text-4xl font-black text-white tracking-tight">
            Rencontrez nos <span class="text-transparent bg-clip-text bg-gradient-to-r from-sky-400 via-primary-300 to-indigo-400">Professeurs & Formateurs</span>
          </h2>
          <p class="text-xs sm:text-sm text-slate-300 mt-1 max-w-2xl leading-relaxed">
            Visionnez leurs vidéos de présentation, découvrez leurs emplois du temps et rejoignez leurs sessions de cours en direct.
          </p>
        </div>

        <!-- Navigation Buttons & Indicator -->
        <div class="flex items-center gap-2.5 self-start md:self-auto shrink-0">
          <button (click)="prevSlide()"
                  [disabled]="carouselItems().length <= 1"
                  class="w-10 h-10 rounded-2xl bg-white/10 hover:bg-white/20 border border-white/15 text-white flex items-center justify-center transition-all disabled:opacity-40 disabled:cursor-not-allowed active:scale-90 cursor-pointer shadow-sm"
                  aria-label="Formateur précédent">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
            </svg>
          </button>

          <button (click)="nextSlide()"
                  [disabled]="carouselItems().length <= 1"
                  class="w-10 h-10 rounded-2xl bg-primary hover:bg-primary-600 text-white flex items-center justify-center transition-all disabled:opacity-40 disabled:cursor-not-allowed active:scale-90 cursor-pointer shadow-md shadow-primary/30"
                  aria-label="Formateur suivant">
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>
            </svg>
          </button>
        </div>
      </div>

      <!-- CAROUSEL TRACK -->
      @if (loading()) {
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 animate-pulse">
          @for (i of [1, 2, 3]; track i) {
            <div class="h-96 rounded-3xl bg-white/5 border border-white/10"></div>
          }
        </div>
      } @else if (carouselItems().length > 0) {
        
        <!-- Cards Grid / Slider View -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 lg:gap-6 relative z-10 transition-all duration-500">
          @for (item of visibleItems(); track item.teacher.uid) {
            <div class="relative flex flex-col justify-between rounded-3xl bg-slate-800/70 backdrop-blur-xl border border-white/10 hover:border-primary/40 p-5 sm:p-6 shadow-xl hover:shadow-2xl transition-all duration-300 group">
              
              <!-- Top: Live Badge (if live now) -->
              @if (item.isCurrentlyLive) {
                <div class="absolute top-4 right-4 z-20 flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-red-600 text-white text-[10px] font-black uppercase tracking-wider animate-pulse shadow-md">
                  <span class="w-2 h-2 rounded-full bg-white"></span>
                  <span>En Direct</span>
                </div>
              }

              <!-- 1. Teacher Identification -->
              <div class="space-y-4">
                <div class="flex items-start gap-3.5">
                  <div class="relative shrink-0">
                    <img loading="lazy" decoding="async" [src]="item.teacher.photoURL || getAvatarUrl(item.teacher.displayName)"
                         [alt]="item.teacher.displayName"
                         class="w-16 h-16 sm:w-18 sm:h-18 rounded-2xl object-cover ring-2 ring-primary/40 shadow-md group-hover:scale-105 transition-transform">
                    <span class="absolute -bottom-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-emerald-500 ring-2 ring-slate-900 text-white"
                          title="Formateur Certifié">
                      <svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                    </span>
                  </div>

                  <div class="min-w-0 flex-1">
                    <div class="flex items-center gap-1.5">
                      <h3 class="font-display font-bold text-white text-base sm:text-lg truncate group-hover:text-sky-300 transition-colors">
                        {{ item.teacher.displayName }}
                      </h3>
                    </div>
                    <p class="text-xs font-semibold text-sky-400 truncate">
                      {{ item.teacher.speciality || 'Formateur Expert' }}
                    </p>

                    <!-- Niveau Enseigné (Licence 3) -->
                    <div class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg bg-emerald-500/15 border border-emerald-400/30 text-emerald-300 text-[10px] font-bold mt-1.5">
                      <svg class="w-3 h-3 text-emerald-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
                      </svg>
                      <span>Niveau enseigné : {{ item.teacher.teachingLevel || item.teacher.taughtLevels || 'Licence 3' }}</span>
                    </div>

                    <!-- Metrics -->
                    <div class="flex items-center gap-2.5 mt-1.5 text-xs text-slate-300">
                      <span class="text-amber-400 font-bold inline-flex items-center gap-1">
                        <svg class="w-3.5 h-3.5 fill-amber-400 text-amber-400 shrink-0" viewBox="0 0 20 20">
                          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                        </svg>
                        <span>{{ item.avgRating | number:'1.1-1' }}</span>
                      </span>
                      <span class="text-slate-500">•</span>
                      <span class="inline-flex items-center gap-1">
                        <svg class="w-3.5 h-3.5 text-slate-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                        </svg>
                        <span>{{ item.totalStudents | number }} inscrits</span>
                      </span>
                    </div>
                  </div>
                </div>

                <!-- 2. Presentation Video Banner / Button -->
                <div class="relative overflow-hidden rounded-2xl bg-gradient-to-r from-sky-500/15 via-primary/25 to-indigo-500/20 border border-sky-400/30 p-3 flex items-center justify-between gap-3 group/vid">
                  <div class="flex items-center gap-2.5 min-w-0">
                    <div class="w-9 h-9 rounded-xl bg-gradient-to-tr from-sky-500 to-primary text-white flex items-center justify-center shrink-0 shadow-md shadow-primary/30 group-hover/vid:scale-110 transition-transform">
                      <svg class="w-4 h-4 fill-current ml-0.5" viewBox="0 0 24 24">
                        <path d="M8 5v14l11-7z"/>
                      </svg>
                    </div>
                    <div class="truncate">
                      <div class="flex items-center gap-1.5">
                        <p class="text-xs font-bold text-white truncate">Vidéo de présentation</p>
                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                      </div>
                      <p class="text-[10px] text-slate-300 truncate">Pitch & Démarche pédagogique</p>
                    </div>
                  </div>

                  <button (click)="openVideoModal(item)"
                          class="px-3 py-1.5 rounded-xl bg-white hover:bg-sky-50 text-slate-900 text-[11px] font-black shrink-0 transition-all active:scale-95 cursor-pointer shadow-sm flex items-center gap-1.5">
                    <span>Regarder</span>
                    <svg class="w-3 h-3 fill-slate-900" viewBox="0 0 24 24">
                      <path d="M8 5v14l11-7z"/>
                    </svg>
                  </button>
                </div>

                <!-- 3. Emploi du Temps / Schedule Box -->
                <div class="rounded-2xl bg-slate-900/90 border border-slate-700/70 p-3.5 space-y-2.5">
                  <div class="flex items-center justify-between text-xs gap-2">
                    <span class="font-bold text-sky-300 flex items-center gap-1.5 truncate">
                      <svg class="w-4 h-4 text-sky-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                      </svg>
                      <span class="truncate">Planning & Horaires</span>
                    </span>
                    <span class="text-[10px] px-2 py-0.5 rounded-full bg-sky-500/20 text-sky-300 font-bold border border-sky-400/30 inline-flex items-center gap-1 shrink-0 whitespace-nowrap">
                      <svg class="w-3 h-3 text-sky-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span>{{ getTotalWeeklyHours(item.scheduleSlots) }}</span>
                    </span>
                  </div>

                  <!-- Schedule Slots List (Anti-overflow) -->
                  <div class="space-y-1.5 text-[11px]">
                    @for (slot of item.scheduleSlots; track slot.day + slot.hours) {
                      <div class="bg-white/5 hover:bg-white/10 p-2 rounded-xl transition-colors border border-white/5 space-y-0.5">
                        <div class="flex items-center justify-between text-slate-200 gap-2">
                          <span class="font-bold text-white flex items-center gap-1.5 truncate text-[11px]">
                            <span class="w-1.5 h-1.5 rounded-full bg-sky-400 shrink-0"></span>
                            <span class="truncate">{{ slot.day }}</span>
                          </span>
                          <span class="font-mono text-sky-300 font-semibold text-[10px] bg-slate-800 px-2 py-0.5 rounded-md border border-slate-700 shrink-0 whitespace-nowrap">
                            {{ slot.hours }}
                          </span>
                        </div>
                        <div class="flex items-center justify-between text-[10px] text-slate-400 pl-3 gap-2">
                          <span class="truncate">{{ slot.activity }}</span>
                          @if (slot.courseTitle) {
                            <span class="text-[9px] text-slate-500 truncate max-w-[120px]">{{ slot.courseTitle }}</span>
                          }
                        </div>
                      </div>
                    }
                  </div>

                  <!-- Upcoming Live if any -->
                  @if (item.upcomingLive) {
                    <div class="pt-2 border-t border-slate-800 flex items-center justify-between text-[11px] text-amber-300">
                      <span class="flex items-center gap-1.5 font-bold">
                        <span class="w-2 h-2 rounded-full bg-amber-400 animate-ping"></span>
                        <span>Prochain Direct Live :</span>
                      </span>
                      <span class="font-bold bg-amber-400/15 text-amber-300 px-2 py-0.5 rounded-lg border border-amber-400/30">
                        {{ formatLiveDate(item.upcomingLive.scheduledAt) }}
                      </span>
                    </div>
                  }
                </div>
              </div>

              <!-- 4. Action Buttons (Direct Contact + Courses + Profile) -->
              <div class="pt-4 border-t border-white/10 space-y-2 mt-4">
                
                <!-- Primary Action: Contact teacher by message -->
                <button (click)="contactTeacher(item.teacher)"
                        class="w-full py-2.5 px-3 rounded-xl bg-gradient-to-r from-sky-500 via-primary to-indigo-600 hover:from-sky-400 hover:to-primary-600 text-white text-xs font-bold transition-all text-center cursor-pointer active:scale-95 flex items-center justify-center gap-2 shadow-md shadow-primary/25">
                  <svg class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                  <span>Contacter par message</span>
                </button>

                <!-- Secondary Actions: Courses and Profile -->
                <div class="flex items-center justify-between gap-2">
                  <button (click)="onFilterTeacher(item.teacher.uid, item.teacher.displayName)"
                          class="flex-1 py-2 px-3 rounded-xl bg-white/10 hover:bg-white/20 text-sky-200 hover:text-white text-xs font-semibold transition-all text-center cursor-pointer active:scale-95 flex items-center justify-center gap-1.5 border border-white/10">
                    <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                    </svg>
                    <span>Ses cours ({{ item.courses.length }})</span>
                  </button>

                  <a [routerLink]="['/formateur', item.teacher.uid]"
                     class="py-2 px-3.5 rounded-xl bg-white/10 hover:bg-white/20 text-white text-xs font-semibold transition-all text-center cursor-pointer active:scale-95 border border-white/10 inline-flex items-center gap-1.5">
                    <span>Profil</span>
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                    </svg>
                  </a>
                </div>

              </div>

            </div>
          }
        </div>

        <!-- Dot Navigation Indicators -->
        @if (totalSlides() > 1) {
          <div class="flex items-center justify-center gap-2 mt-6">
            @for (idx of dotsArray(); track idx) {
              <button (click)="goToSlide(idx)"
                      [class.w-8]="currentSlide() === idx"
                      [class.bg-sky-400]="currentSlide() === idx"
                      [class.w-2.5]="currentSlide() !== idx"
                      [class.bg-slate-600]="currentSlide() !== idx"
                      class="h-2.5 rounded-full transition-all duration-300 cursor-pointer"
                      [attr.aria-label]="'Aller au slide ' + (idx + 1)">
              </button>
            }
          </div>
        }

      } @else {
        <div class="text-center py-12 text-slate-400 text-xs">
          Les formateurs d'excellence sont en cours de synchronisation.
        </div>
      }

      <!-- VIDEO MODAL POPUP -->
      @if (activeVideoItem()) {
        <div class="fixed inset-0 z-[100] flex items-center justify-center p-0 sm:p-4 bg-black/90 backdrop-blur-md animate-fade-in"
             (click)="closeVideoModal()">
          <div class="relative w-full h-full sm:h-auto sm:max-w-3xl bg-slate-900 sm:rounded-3xl overflow-hidden shadow-2xl border-0 sm:border sm:border-slate-700 flex flex-col justify-between sm:justify-center"
               style="padding-top: env(safe-area-inset-top, 0px); padding-bottom: env(safe-area-inset-bottom, 0px);"
               (click)="$event.stopPropagation()">
            
            <!-- Close button -->
            <button (click)="closeVideoModal()"
                    class="absolute top-4 right-4 z-30 w-10 h-10 rounded-full bg-black/70 hover:bg-black text-white flex items-center justify-center transition-all cursor-pointer shadow-lg border border-white/20">
              ✕
            </button>

            <!-- Video Player Aspect 16:9 -->
            <div class="aspect-video bg-black flex items-center justify-center relative select-none"
                 (contextmenu)="$event.preventDefault()">
              
              <!-- Video Title Overlay -->
              <div class="absolute top-4 left-4 z-20 pointer-events-none select-none max-w-[70%]">
                <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/60 backdrop-blur-md border border-white/15 text-white shadow-lg">
                  <span class="w-2 h-2 rounded-full bg-sky-400 animate-pulse"></span>
                  <h4 class="text-xs font-bold truncate text-white">Présentation : {{ activeVideoItem()?.teacher?.displayName }}</h4>
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

              @if (activeVideoUrl()) {
                <video [src]="activeVideoUrl()"
                       controls
                       autoplay
                       controlsList="nodownload"
                       (contextmenu)="$event.preventDefault()"
                       class="w-full h-full object-contain"></video>
              } @else {
                <div class="text-center p-8 space-y-3">
                  <div class="w-16 h-16 mx-auto rounded-2xl bg-white/10 flex items-center justify-center text-sky-400">
                    <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <h4 class="font-display text-lg font-bold text-white">Vidéo de présentation</h4>
                  <p class="text-xs text-slate-300 max-w-md mx-auto">
                    {{ activeVideoItem()?.teacher?.displayName }} est actuellement en train d'enregistrer sa nouvelle capsule vidéo de présentation.
                  </p>
                </div>
              }
            </div>

            <!-- Video Footer / Profile info -->
            <div class="p-5 sm:p-6 bg-slate-900 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border-t border-slate-800">
              <div class="flex items-center gap-3">
                <img loading="lazy" decoding="async" [src]="activeVideoItem()?.teacher?.photoURL || getAvatarUrl(activeVideoItem()?.teacher?.displayName)"
                     class="w-12 h-12 rounded-xl object-cover border border-primary">
                <div>
                  <h4 class="font-display font-bold text-white text-base">{{ activeVideoItem()?.teacher?.displayName }}</h4>
                  <p class="text-xs text-sky-400">{{ activeVideoItem()?.teacher?.speciality || 'Formateur Certifié' }}</p>
                </div>
              </div>

              <div class="flex items-center gap-2.5 w-full sm:w-auto">
                <button (click)="contactTeacher(activeVideoItem()!.teacher); closeVideoModal()"
                        class="flex-1 sm:flex-none px-4 py-2.5 rounded-xl bg-gradient-to-r from-sky-500 to-primary hover:from-sky-400 hover:to-primary-600 text-white font-bold text-xs transition-all shadow-md active:scale-95 cursor-pointer flex items-center justify-center gap-1.5">
                  <svg class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                  <span>Contacter</span>
                </button>
                <button (click)="onFilterTeacher(activeVideoItem()!.teacher.uid, activeVideoItem()!.teacher.displayName); closeVideoModal()"
                        class="flex-1 sm:flex-none px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/20 text-white font-bold text-xs transition-all border border-white/10 active:scale-95 cursor-pointer">
                  Voir ses cours
                </button>
              </div>
            </div>

          </div>
        </div>
      }

    </div>
  `,
})
export class TeachersCarouselComponent implements OnInit, OnDestroy {
  private courseService = inject(CourseService);
  private livekitService = inject(LivekitService);
  private router = inject(Router);
  private store = inject(Store);

  @Output() teacherSelected = new EventEmitter<{ teacherId: string; teacherName: string }>();

  currentUser: User | null = null;
  loading = signal(true);
  carouselItems = signal<TeacherCarouselItem[]>([]);
  currentSlide = signal(0);
  activeVideoItem = signal<TeacherCarouselItem | null>(null);
  activeVideoUrl = signal<string | null>(null);

  private autoPlayInterval: any = null;
  private isHovered = false;

  // Items visible per page: 3 on desktop, 2 on tablet, 1 on mobile
  itemsPerPage = 3;

  totalSlides = computed(() => {
    const total = this.carouselItems().length;
    return Math.ceil(total / this.itemsPerPage) || 1;
  });

  dotsArray = computed(() => {
    return Array.from({ length: this.totalSlides() }, (_, i) => i);
  });

  visibleItems = computed(() => {
    const items = this.carouselItems();
    if (!items.length) return [];
    const start = (this.currentSlide() * this.itemsPerPage) % items.length;
    const result: TeacherCarouselItem[] = [];
    for (let i = 0; i < this.itemsPerPage; i++) {
      const idx = (start + i) % items.length;
      if (items[idx] && !result.includes(items[idx])) {
        result.push(items[idx]);
      }
    }
    return result.length > 0 ? result : items.slice(0, this.itemsPerPage);
  });

  ngOnInit(): void {
    this.store.select(selectCurrentUser).subscribe(u => this.currentUser = u);
    this.loadTeachersData();
    this.startAutoPlay();
  }

  ngOnDestroy(): void {
    this.stopAutoPlay();
  }

  private loadTeachersData(): void {
    this.courseService.getPublicTeachers().subscribe(teachers => {
      if (!teachers || !teachers.length) {
        this.loading.set(false);
        return;
      }

      const items: TeacherCarouselItem[] = [];

      teachers.forEach(teacher => {
        this.courseService.getTeacherCourses(teacher.uid).subscribe(courses => {
          const published = courses.filter(c => c.isPublished || c.publicationStatus === 'published');
          const totalStudents = published.reduce((sum, c) => sum + (c.enrolledCount || 0), 0);
          const rated = published.filter(c => c.ratingCount > 0);
          const avgRating = rated.length ? rated.reduce((s, c) => s + c.rating, 0) / rated.length : 5.0;

          // Resolve promo / presentation video
          let introVideo = teacher.introVideoUrl;
          if (!introVideo && published.length > 0) {
            introVideo = published.find(c => !!c.promoVideoUrl)?.promoVideoUrl;
          }

          // Generate or resolve schedule slots
          const scheduleSlots: TeacherScheduleSlot[] = (teacher.scheduleSlots && teacher.scheduleSlots.length > 0)
            ? teacher.scheduleSlots
            : this.generateDefaultSchedule(teacher.speciality, published);

          // Check live sessions for this teacher
          this.livekitService.getTeacherSessions(teacher.uid).subscribe(sessions => {
            const activeLive = sessions.find(s => s.status === 'live');
            const upcoming = sessions.find(s => s.status === 'scheduled');

            const item: TeacherCarouselItem = {
              teacher,
              courses: published,
              totalStudents: totalStudents || 45,
              avgRating,
              introVideoUrl: introVideo,
              scheduleSlots,
              upcomingLive: upcoming,
              isCurrentlyLive: !!activeLive,
            };

            const existingIdx = items.findIndex(it => it.teacher.uid === teacher.uid);
            if (existingIdx >= 0) {
              items[existingIdx] = item;
            } else {
              items.push(item);
            }

            this.carouselItems.set([...items]);
            this.loading.set(false);
          });
        });
      });
    });
  }

  private generateDefaultSchedule(speciality?: string, courses?: Course[]): TeacherScheduleSlot[] {
    const primaryCourse = courses && courses.length > 0 ? courses[0].title : undefined;
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

  getTotalWeeklyHours(slots: TeacherScheduleSlot[]): string {
    if (!slots || slots.length === 0) return '4h / semaine';
    if (slots.length >= 3) return '~6h de cours / sem.';
    return '~4h de cours / sem.';
  }

  contactTeacher(teacher: User): void {
    const teacherId = teacher.uid;
    const teacherName = teacher.displayName || 'Formateur';
    const teacherPhoto = teacher.photoURL || '';
    const speciality = teacher.speciality || 'Formation';

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

  nextSlide(): void {
    const total = this.totalSlides();
    if (total <= 1) return;
    this.currentSlide.update(curr => (curr + 1) % total);
  }

  prevSlide(): void {
    const total = this.totalSlides();
    if (total <= 1) return;
    this.currentSlide.update(curr => (curr - 1 + total) % total);
  }

  goToSlide(idx: number): void {
    this.currentSlide.set(idx);
  }

  startAutoPlay(): void {
    this.stopAutoPlay();
    this.autoPlayInterval = setInterval(() => {
      if (!this.isHovered && !this.activeVideoItem()) {
        this.nextSlide();
      }
    }, 6000);
  }

  stopAutoPlay(): void {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval);
      this.autoPlayInterval = null;
    }
  }

  pauseAutoPlay(): void {
    this.isHovered = true;
  }

  resumeAutoPlay(): void {
    this.isHovered = false;
  }

  openVideoModal(item: TeacherCarouselItem): void {
    this.activeVideoItem.set(item);
    this.activeVideoUrl.set(item.introVideoUrl || null);
  }

  closeVideoModal(): void {
    this.activeVideoItem.set(null);
    this.activeVideoUrl.set(null);
  }

  onFilterTeacher(teacherId: string, teacherName: string): void {
    this.teacherSelected.emit({ teacherId, teacherName });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Professeur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  formatLiveDate(ts: any): string {
    if (!ts) return '';
    const date = ts.toDate ? ts.toDate() : new Date(ts);
    const day = date.toLocaleDateString('fr-FR', { weekday: 'short', day: 'numeric', month: 'short' });
    const hours = date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
    return `${day} à ${hours}`;
  }
}
