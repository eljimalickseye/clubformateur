import { Component, OnInit, inject, signal } from '@angular/core';
import { Title, Meta } from '@angular/platform-browser';
import { DecimalPipe, CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { Store } from '@ngrx/store';
import { Firestore, doc, getDoc } from '@angular/fire/firestore';
import { CourseService } from '../../core/services/course.service';
import { PaymentService } from '../../core/services/payment.service';
import { RequestService } from '../../core/services/request.service';
import { LivekitService } from '../../core/services/livekit.service';
import { selectCurrentUser } from '../../store/auth/auth.selectors';
import { Course, Lesson, User, EnrollmentRequest, LiveSession } from '../../core/models';
import { ToastrService } from 'ngx-toastr';

import { BackButtonComponent } from '../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-course-detail',
  standalone: true,
  imports: [RouterLink, DecimalPipe, CommonModule, FormsModule, BackButtonComponent],
  template: `
    <div class="max-w-6xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-8 space-y-6 sm:space-y-8 font-body">
      
      <!-- Standardized Sticky Responsive Back button -->
      <div class="sticky top-0 z-30 -mx-3 sm:-mx-6 lg:-mx-8 px-3 sm:px-6 lg:px-8 py-3 bg-white/95 backdrop-blur-md border-b border-slate-200/80 shadow-2xs flex items-center justify-between mb-4">
        <app-back-button label="Retour au catalogue" defaultRoute="/catalogue" />
      </div>

      @if (loading()) {
        <div class="bg-white border border-dark-border rounded-3xl p-8 animate-pulse shadow-xs">
          <div class="h-8 bg-dark-surface2 rounded w-2/3 mb-4"></div>
          <div class="h-4 bg-dark-surface2 rounded w-full mb-2"></div>
          <div class="h-4 bg-dark-surface2 rounded w-5/6"></div>
        </div>
      } @else if (course()) {
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          <!-- Left Main Column (Course Details, Syllabus, Teacher) -->
          <section class="lg:col-span-2 space-y-6">
            
            <!-- Video / Thumbnail Hero -->
            <div class="rounded-3xl border border-dark-border bg-white overflow-hidden shadow-xs">
              <div class="relative aspect-video bg-dark-surface2 overflow-hidden select-none"
                   (contextmenu)="$event.preventDefault()">
                <!-- Watermark Logo Club des Formateurs at Bottom -->
                <div class="absolute bottom-12 right-4 z-20 pointer-events-none select-none flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/55 backdrop-blur-md border border-white/15 shadow-lg">
                  <svg width="20" height="20" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" class="shrink-0">
                    <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
                    <circle cx="20" cy="20" r="4" fill="white"/>
                  </svg>
                  <span class="font-display text-[10px] font-black text-white tracking-tight drop-shadow-sm">
                    Club des Formateurs
                  </span>
                </div>

                @if (course()!.promoVideoUrl) {
                  <video [src]="course()!.promoVideoUrl"
                         controls
                         controlsList="nodownload"
                         (contextmenu)="$event.preventDefault()"
                         class="w-full h-full object-cover"></video>
                } @else if (course()!.thumbnailUrl) {
                  <img loading="lazy" decoding="async" [src]="course()!.thumbnailUrl" [alt]="course()!.title" class="w-full h-full object-cover">
                } @else {
                  <div class="w-full h-full flex items-center justify-center text-primary/30">
                    <svg class="w-20 h-20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                    </svg>
                  </div>
                }
              </div>

              <div class="p-6 sm:p-8 space-y-6">
                <!-- Badges -->
                <div class="flex flex-wrap items-center gap-2">
                  <span class="px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider">
                    {{ course()!.categoryName || 'Formation' }}
                  </span>
                  <span class="px-3 py-1 rounded-full bg-dark-surface2 text-light text-xs font-bold capitalize">
                    Niveau {{ course()!.level }}
                  </span>
                  <span class="px-3 py-1 rounded-full bg-dark-surface2 text-light text-xs font-bold uppercase">
                    Langue : {{ course()!.language }}
                  </span>
                  @if (course()!.hasLiveClasses) {
                    <span class="px-3 py-1 rounded-full bg-red-50 text-red-600 border border-red-200 text-xs font-bold flex items-center gap-1">
                      <span class="w-1.5 h-1.5 rounded-full bg-red-500 animate-ping"></span>
                      Live Direct Inclus
                    </span>
                  }
                </div>

                <div>
                  <h1 class="font-display text-3xl sm:text-4xl font-black text-light tracking-tight mb-3">
                    {{ course()!.title }}
                  </h1>
                  <p class="text-sm sm:text-base text-light-muted leading-relaxed">
                    {{ course()!.shortDescription }}
                  </p>
                </div>

                <!-- Teacher Card (Requirement 4 & 11) -->
                <div class="p-5 rounded-2xl bg-dark-surface2/50 border border-dark-border/60 flex items-center justify-between gap-4">
                  <div class="flex items-center gap-4">
                    <img loading="lazy" decoding="async" [src]="course()!.teacherPhotoURL || getAvatarUrl(course()!.teacherName)"
                         [alt]="course()!.teacherName"
                         class="w-12 h-12 rounded-2xl object-cover border border-dark-border shadow-xs">
                    <div>
                      <p class="text-[10px] font-bold text-light-muted uppercase tracking-wider">Dispensé par</p>
                      <h3 class="font-bold text-light text-sm">{{ course()!.teacherName }}</h3>
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <button (click)="contactTeacher()"
                            class="px-3.5 py-1.5 rounded-xl bg-gradient-to-r from-sky-500 to-primary text-white text-xs font-bold shadow-xs hover:from-sky-400 hover:to-primary-600 transition-all flex items-center gap-1.5 active:scale-95 cursor-pointer">
                      <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                      </svg>
                      <span>Message</span>
                    </button>
                    <a [routerLink]="['/formateur', course()!.teacherId]"
                       class="px-3.5 py-1.5 rounded-xl border border-dark-border bg-white text-xs font-bold text-primary hover:bg-primary/5 transition-all shadow-xs inline-flex items-center gap-1">
                      <span>Voir le profil</span>
                      <svg class="w-3.5 h-3.5 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                      </svg>
                    </a>
                  </div>
                </div>

                <!-- Description -->
                <div class="space-y-3 pt-2">
                  <h2 class="font-display text-lg font-bold text-light">À propos de cette formation</h2>
                  <p class="text-xs sm:text-sm text-light-muted leading-relaxed whitespace-pre-line">
                    {{ course()!.description }}
                  </p>
                </div>

                <!-- Curriculum / Syllabus -->
                <div class="space-y-3 pt-4 border-t border-dark-border/60">
                  <div class="flex items-center justify-between">
                    <div>
                      <h2 class="font-display text-lg font-bold text-light">Programme de la formation</h2>
                      <p class="text-xs text-light-muted mt-0.5">
                        {{ lessons().length }} leçons structurées
                        @if (meetReplays().length > 0) {
                          <span>• {{ meetReplays().length }} séance{{ meetReplays().length > 1 ? 's' : '' }} Meet & Replay</span>
                        }
                      </p>
                    </div>
                    <span class="text-xs font-bold text-primary bg-primary/10 px-3 py-1 rounded-xl">
                      {{ lessons().length + meetReplays().length }} vidéos au total
                    </span>
                  </div>

                  <!-- Standard Lessons List -->
                  <div class="space-y-2">
                    @for (lesson of lessons(); track lesson.id; let idx = $index) {
                      <div class="p-3.5 rounded-xl border border-dark-border/60 bg-dark-surface2/30 flex items-center justify-between gap-3 text-xs">
                        <div class="flex items-center gap-3 min-w-0">
                          <span class="w-6 h-6 rounded-lg bg-primary/10 text-primary font-bold flex items-center justify-center text-[10px]">
                            {{ idx + 1 }}
                          </span>
                          <span class="font-bold text-light truncate">{{ lesson.title }}</span>
                        </div>
                        <div class="flex items-center gap-2 shrink-0">
                          @if (lesson.isFree) {
                            <span class="px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 text-[9px] font-black uppercase">Aperçu Gratuit</span>
                          }
                          <span class="text-light-muted capitalize text-[11px]">{{ lesson.type }}</span>
                        </div>
                      </div>
                    } @empty {
                      <p class="text-xs text-light-muted py-4 text-center italic">Le programme complet sera accessible dès votre inscription.</p>
                    }
                  </div>

                  <!-- Séances Meet & Replays -->
                  @if (meetReplays().length > 0) {
                    <div class="mt-5 pt-4 border-t border-dark-border/40 space-y-2.5">
                      <div class="flex items-center justify-between">
                        <h3 class="text-xs font-bold text-red-500 flex items-center gap-1.5">
                          <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                          <span>Séances Meet & Replays en direct ({{ meetReplays().length }})</span>
                        </h3>
                        <span class="text-[10px] text-light-muted font-medium">Inclus dans la formation</span>
                      </div>
                      <div class="space-y-2">
                        @for (meet of meetReplays(); track meet.id) {
                          <div class="p-3.5 rounded-xl border border-red-500/20 bg-red-500/5 flex items-center justify-between gap-3 text-xs">
                            <div class="flex items-center gap-3 truncate min-w-0">
                              <span class="w-6 h-6 rounded-lg bg-red-500/20 text-red-400 font-bold flex items-center justify-center text-[11px]">
                                📹
                              </span>
                              <div class="truncate">
                                <p class="font-bold text-light truncate">{{ meet.title }}</p>
                                <p class="text-[10px] text-light-muted">
                                  {{ meet.durationMinutes ? meet.durationMinutes + ' min' : 'Session complète' }} • Enregistrement & notes disponibles
                                </p>
                              </div>
                            </div>
                            <span class="px-2.5 py-0.5 rounded-full bg-red-500/20 text-red-400 text-[10px] font-bold shrink-0">
                              Replay Meet
                            </span>
                          </div>
                        }
                      </div>
                    </div>
                  }
                </div>

              </div>
            </div>
          </section>

          <!-- Right Sidebar (Pricing & Action - Requirement 11) -->
          <aside class="space-y-6">
            <div class="rounded-3xl border border-dark-border bg-white p-6 shadow-xs h-fit lg:sticky lg:top-24 space-y-6">
              
              <div>
                @if (course()!.isFree) {
                  <span class="text-xs text-light-muted font-bold uppercase tracking-wider">Tarification</span>
                  <p class="font-display text-3xl font-black text-emerald-600 mt-1">Gratuit</p>
                } @else {
                  <span class="text-xs text-light-muted font-bold uppercase tracking-wider">Tarif de la formation</span>
                  <div class="flex items-baseline gap-2 mt-1">
                    <p class="font-display text-3xl sm:text-4xl font-black text-primary">
                      {{ course()!.price | number }} <span class="text-sm font-bold">F CFA</span>
                    </p>
                    @if (course()!.originalPrice && course()!.originalPrice! > course()!.price) {
                      <p class="text-sm text-light-muted line-through">{{ course()!.originalPrice | number }} F</p>
                    }
                  </div>
                }
                <p class="text-[11px] text-light-muted mt-1">
                  {{ course()!.pricingType === 'monthly' ? 'Accès mensuel renouvelable' : 'Paiement unique • Accès à vie' }}
                </p>
              </div>

              <!-- Action Buttons -->
              <div class="space-y-3 pt-2">
                @if (hasAccess() && lessons().length > 0) {
                  <a [routerLink]="['/learn', course()!.id, firstLessonId()]"
                     class="w-full py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold text-center block shadow-md shadow-emerald-600/20 transition-all">
                    Accéder au cours (Formats Vidéo & PDF) →
                  </a>
                } @else if (existingRequest()) {
                  <div class="p-4 rounded-2xl bg-amber-50 border border-amber-200 text-center space-y-1">
                    <p class="text-xs font-bold text-amber-800">Demande d'inscription en cours</p>
                    <p class="text-[11px] text-amber-700">Le professeur examine actuellement votre dossier.</p>
                  </div>
                } @else if (course()!.isFree) {
                  <button (click)="enrollFree()"
                          [disabled]="actionLoading()"
                          class="w-full py-3.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold shadow-md shadow-emerald-600/20 transition-all disabled:opacity-50">
                    {{ actionLoading() ? 'Inscription en cours...' : 'S’inscrire gratuitement' }}
                  </button>
                } @else {
                  <!-- S'inscrire & Payer avec Wave ou Orange Money -->
                  <button (click)="openCheckoutModal()"
                          class="w-full py-4 rounded-2xl bg-gradient-to-r from-primary via-indigo-600 to-primary hover:from-primary-600 hover:to-primary text-white text-xs font-black shadow-lg shadow-primary/25 transition-all flex items-center justify-center gap-2 active:scale-95 cursor-pointer">
                    <span>S’inscrire & Payer (Wave / Orange Money)</span>
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                    </svg>
                  </button>

                  <!-- Faire une demande d'inscription (Dossier / Candidature) -->
                  <button (click)="openRequestModal = true"
                          class="w-full py-3 rounded-2xl border border-dark-border bg-white hover:bg-dark-surface2 text-light text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer">
                    <span>Faire une demande de bourse / candidature</span>
                    <span>→</span>
                  </button>
                }
              </div>

              <div class="text-[11px] text-light-muted space-y-2.5 pt-4 border-t border-dark-border/60">
                <div class="flex items-center justify-between">
                  <span class="flex items-center gap-1.5">
                    <svg class="w-3.5 h-3.5 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span>Formats de cours</span>
                  </span>
                  <span class="font-bold text-primary">Vidéo HD & PDF inclus</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="flex items-center gap-1.5">
                    <svg class="w-3.5 h-3.5 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                    <span>Étudiants inscrits</span>
                  </span>
                  <span class="font-bold text-light">{{ course()!.enrolledCount | number }}</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="flex items-center gap-1.5">
                    <svg class="w-3.5 h-3.5 text-amber-500" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                    </svg>
                    <span>Évaluation moyenne</span>
                  </span>
                  <span class="font-bold text-amber-500">{{ course()!.rating || '5.0' }} / 5</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="flex items-center gap-1.5">
                    <svg class="w-3.5 h-3.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                    </svg>
                    <span>Certificat de réussite</span>
                  </span>
                  <span class="font-bold text-emerald-600">Inclus</span>
                </div>
              </div>

            </div>
          </aside>

        </div>
      }

      <!-- Enrollment Request Modal (Requirement 7 & 11) -->
      @if (openRequestModal) {
        <div class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in"
             (click)="openRequestModal = false">
          <div class="bg-white sm:rounded-3xl p-5 sm:p-8 w-full max-w-lg h-full sm:h-auto max-sm:max-h-[100dvh] overflow-y-auto shadow-2xl border-0 sm:border sm:border-dark-border space-y-6 max-sm:flex max-sm:flex-col max-sm:justify-between"
               style="padding-top: max(1.25rem, env(safe-area-inset-top, 1.25rem)); padding-bottom: max(1.5rem, env(safe-area-inset-bottom, 1.5rem));"
               (click)="$event.stopPropagation()">
            
            <div class="space-y-6">
              <div class="flex items-center justify-between border-b border-dark-border pb-3">
                <div>
                  <span class="text-[10px] font-bold text-primary uppercase tracking-wider">Candidature</span>
                  <h3 class="font-display text-lg font-bold text-light">Demande d'inscription au cours</h3>
                </div>
                <button (click)="openRequestModal = false" class="p-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors">✕</button>
              </div>

              <div class="p-4 rounded-2xl bg-dark-surface2/60 border border-dark-border/40 space-y-1">
                <p class="text-xs font-bold text-light">{{ course()?.title }}</p>
                <p class="text-[11px] text-light-muted">Professeur : {{ course()?.teacherName }}</p>
              </div>

              <div class="space-y-4">
                <div>
                  <label class="block text-xs font-bold text-light mb-1.5">
                    Message pour le formateur (Motivation, attentes, niveau actuel) :
                  </label>
                  <textarea [(ngModel)]="requestMotivation" rows="4"
                            placeholder="Bonjour professeur, je souhaite rejoindre votre formation car..."
                            class="w-full px-4 py-3 bg-dark-surface2 border border-dark-border rounded-xl text-base sm:text-xs text-light placeholder-light-muted focus:border-primary outline-none resize-none"></textarea>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-2">
              <button (click)="openRequestModal = false" class="px-4 py-2.5 text-xs font-bold text-light-muted hover:bg-dark-surface2 rounded-xl">
                Annuler
              </button>
              <button (click)="submitEnrollmentRequest()"
                      [disabled]="actionLoading()"
                      class="px-6 py-2.5 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 transition-all disabled:opacity-50">
                {{ actionLoading() ? 'Envoi...' : 'Envoyer ma candidature' }}
              </button>
            </div>

          </div>
        </div>
      }

      <!-- Direct Mobile Money Checkout Modal (Wave & Orange Money) -->
      @if (openPaymentModal) {
        <div class="fixed inset-0 bg-black/75 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in"
             (click)="openPaymentModal = false">
          <div class="bg-white sm:rounded-3xl p-5 sm:p-8 w-full max-w-lg h-full sm:h-auto max-sm:max-h-[100dvh] overflow-y-auto shadow-2xl border-0 sm:border sm:border-dark-border space-y-5"
               style="padding-top: max(1.25rem, env(safe-area-inset-top, 1.25rem)); padding-bottom: max(1.5rem, env(safe-area-inset-bottom, 1.5rem));"
               (click)="$event.stopPropagation()">
            
            <!-- Modal Header -->
            <div class="flex items-center justify-between border-b border-slate-200 pb-3">
              <div>
                <span class="text-[10px] font-black text-primary uppercase tracking-wider flex items-center gap-1.5">
                  <svg class="w-3.5 h-3.5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                  <span>Paiement Sécurisé • Club des Formateurs</span>
                </span>
                <h3 class="font-display text-lg font-bold text-slate-900">Inscription au Cours</h3>
              </div>
              <button (click)="openPaymentModal = false" class="p-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition-colors cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </div>

            <!-- Course / Teacher Summary Card -->
            <div class="p-4 rounded-2xl bg-slate-50 border border-slate-200 flex items-center justify-between gap-3">
              <div class="min-w-0">
                <span class="px-2 py-0.5 rounded-md bg-primary/10 text-primary text-[10px] font-bold uppercase">
                  {{ course()?.categoryName || 'Formation' }}
                </span>
                <h4 class="font-display text-sm font-bold text-slate-900 mt-1 truncate">{{ course()?.title }}</h4>
                <p class="text-xs text-slate-500 flex items-center gap-1.5 mt-0.5">
                  <svg class="w-3.5 h-3.5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                  <span>Formateur :</span>
                  <span class="font-bold text-slate-800">{{ course()?.teacherName }}</span>
                </p>
              </div>

              <div class="text-right shrink-0">
                <span class="text-[10px] text-slate-500 block uppercase font-bold">Total à payer</span>
                <span class="font-display text-lg font-black text-primary">{{ course()?.price | number }} F CFA</span>
              </div>
            </div>

            <!-- Payment Method Selector -->
            <div class="space-y-2">
              <label class="block text-xs font-bold text-slate-800">Choisissez votre moyen de paiement :</label>
              <div class="grid grid-cols-2 gap-3">
                <!-- Wave Card -->
                <button type="button"
                        (click)="selectedPaymentMethod = 'wave'"
                        [class.border-blue-500]="selectedPaymentMethod === 'wave'"
                        [class.bg-blue-50]="selectedPaymentMethod === 'wave'"
                        [class.border-slate-200]="selectedPaymentMethod !== 'wave'"
                        class="p-4 rounded-2xl border-2 text-left transition-all relative flex flex-col justify-between h-24 group cursor-pointer">
                  <div class="flex items-center justify-between w-full">
                    <div class="w-8 h-8 rounded-xl bg-blue-500 text-white flex items-center justify-center font-black text-xs shadow-xs">
                      W
                    </div>
                    @if (selectedPaymentMethod === 'wave') {
                      <span class="w-4 h-4 rounded-full bg-blue-500 text-white flex items-center justify-center text-[10px] font-bold">✓</span>
                    }
                  </div>
                  <div>
                    <span class="font-display text-xs font-bold text-slate-900 block">Wave Sénégal</span>
                    <span class="text-[10px] text-slate-500">Paiement instantané</span>
                  </div>
                </button>

                <!-- Orange Money Card -->
                <button type="button"
                        (click)="selectedPaymentMethod = 'orange_money'"
                        [class.border-orange-500]="selectedPaymentMethod === 'orange_money'"
                        [class.bg-orange-50]="selectedPaymentMethod === 'orange_money'"
                        [class.border-slate-200]="selectedPaymentMethod !== 'orange_money'"
                        class="p-4 rounded-2xl border-2 text-left transition-all relative flex flex-col justify-between h-24 group cursor-pointer">
                  <div class="flex items-center justify-between w-full">
                    <div class="w-8 h-8 rounded-xl bg-orange-500 text-white flex items-center justify-center font-black text-xs shadow-xs">
                      OM
                    </div>
                    @if (selectedPaymentMethod === 'orange_money') {
                      <span class="w-4 h-4 rounded-full bg-orange-500 text-white flex items-center justify-center text-[10px] font-bold">✓</span>
                    }
                  </div>
                  <div>
                    <span class="font-display text-xs font-bold text-slate-900 block">Orange Money</span>
                    <span class="text-[10px] text-slate-500">Validation mobile</span>
                  </div>
                </button>
              </div>
            </div>

            <!-- Phone Input with Senegal Indicator -->
            <div class="space-y-1.5">
              <label class="block text-xs font-bold text-slate-800">
                Numéro de téléphone {{ selectedPaymentMethod === 'wave' ? 'Wave' : 'Orange Money' }} (Sénégal) :
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-xs font-bold text-slate-600 gap-1">
                  <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                  <span>+221</span>
                </div>
                <input type="tel"
                       [(ngModel)]="paymentPhone"
                       placeholder="77 123 45 67"
                       class="w-full pl-16 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl text-xs font-bold text-slate-900 placeholder-slate-400 focus:outline-none focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all">
              </div>
              <p class="text-[11px] text-slate-500">
                Exemple : 77XXXXXXX, 78XXXXXXX, 76XXXXXXX, 70XXXXXXX, 75XXXXXXX
              </p>
            </div>

            <!-- Validation Button -->
            <div class="pt-2">
              <button (click)="submitDirectPayment()"
                      [disabled]="actionLoading() || !paymentPhone.trim()"
                      [class.bg-blue-600]="selectedPaymentMethod === 'wave'"
                      [class.bg-orange-500]="selectedPaymentMethod === 'orange_money'"
                      class="w-full py-4 text-white text-xs font-black rounded-2xl shadow-xl disabled:opacity-50 disabled:cursor-not-allowed active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer">
                @if (actionLoading()) {
                  <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                  </svg>
                  <span>Traitement du paiement en cours...</span>
                } @else {
                  <span>Valider le paiement de {{ course()?.price | number }} F CFA</span>
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                  </svg>
                }
              </button>
            </div>

            <!-- Security Footer -->
            <p class="text-center text-[10px] text-slate-500 flex items-center justify-center gap-1.5">
              <svg class="w-3.5 h-3.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
              <span>Paiement direct sécurisé • Accès immédiat au cours & directs</span>
            </p>

          </div>
        </div>
      }

    </div>
  `,
})
export class CourseDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private store = inject(Store);
  private firestore = inject(Firestore);
  private courseService = inject(CourseService);
  private paymentService = inject(PaymentService);
  private requestService = inject(RequestService);
  private livekitService = inject(LivekitService);
  private toastr = inject(ToastrService);
  private titleService = inject(Title);
  private metaService = inject(Meta);

  loading = signal(true);
  actionLoading = signal(false);
  course = signal<Course | null>(null);
  lessons = signal<Lesson[]>([]);
  meetReplays = signal<LiveSession[]>([]);
  currentUser = signal<User | null>(null);
  hasAccess = signal(false);
  existingRequest = signal<EnrollmentRequest | null>(null);

  firstLessonId = signal<string>('intro');
  openRequestModal = false;
  requestMotivation = '';

  // Direct Mobile Money Checkout Modal State
  openPaymentModal = false;
  selectedPaymentMethod: 'wave' | 'orange_money' = 'wave';
  paymentPhone = '';

  goBack(): void { this.router.navigate(['/catalogue']); }

  contactTeacher(): void {
    const c = this.course();
    if (!c) return;
    const teacherId = c.teacherId;
    const teacherName = c.teacherName || 'Formateur';
    const teacherPhoto = c.teacherPhotoURL || '';
    const speciality = c.categoryName || 'Formation';

    if (!this.currentUser()) {
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

  ngOnInit(): void {
    const courseId = this.route.snapshot.params['id'];
    if (!courseId) {
      this.loading.set(false);
      return;
    }

    // Increment views count on visit (Requirement 1 & 6)
    this.courseService.incrementViews(courseId);

    this.store.select(selectCurrentUser).subscribe(async user => {
      this.currentUser.set(user);
      if (user && courseId) {
        const req = await this.requestService.checkExistingRequest(user.uid, courseId);
        this.existingRequest.set(req);
      }
      await this.refreshAccess();
    });

    this.courseService.getCourseById(courseId).subscribe(async (course: Course | undefined) => {
      this.course.set(course ?? null);
      if (course) this.updateMetadata(course);
      await this.refreshAccess();
      this.loading.set(false);
    });

    this.courseService.getLessons(courseId).subscribe(lessons => {
      this.lessons.set(lessons);
      this.firstLessonId.set(lessons[0]?.id ?? 'intro');
    });

    this.livekitService.getCourseReplays(courseId).subscribe(replays => {
      this.meetReplays.set(replays);
    });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Formateur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  private updateMetadata(course: Course): void {
    const title = `${course.title} – Club des Formateurs`;
    this.titleService.setTitle(title);
    this.metaService.updateTag({ name: 'description', content: course.shortDescription });
  }

  private async refreshAccess(): Promise<void> {
    const currentCourse = this.course();
    const user = this.currentUser();
    if (!currentCourse) return;

    if (!user) {
      this.hasAccess.set(false);
      return;
    }

    if (user.role === 'admin' || (user.role === 'teacher' && currentCourse.teacherId === user.uid)) {
      this.hasAccess.set(true);
      return;
    }

    if (currentCourse.isFree) {
      this.hasAccess.set(true);
      return;
    }

    const enrollmentSnap = await getDoc(doc(this.firestore, `enrollments/${user.uid}_${currentCourse.id}`));
    this.hasAccess.set(enrollmentSnap.exists());
  }

  openCheckoutModal(): void {
    const user = this.currentUser();
    const currentCourse = this.course();
    if (!currentCourse) return;

    if (!user) {
      this.router.navigate(['/auth/login'], { queryParams: { redirectTo: `/course/${currentCourse.id}` } });
      return;
    }

    if (user.phone) {
      this.paymentPhone = user.phone;
    }
    this.openPaymentModal = true;
  }

  async submitDirectPayment(): Promise<void> {
    const currentCourse = this.course();
    const user = this.currentUser();
    if (!currentCourse || !user) return;

    const phone = this.paymentPhone.trim();
    if (!phone) {
      this.toastr.warning('Veuillez renseigner un numéro de téléphone valide.');
      return;
    }

    try {
      this.actionLoading.set(true);
      await this.paymentService.processDirectPaymentAndEnroll({
        userId: user.uid,
        userName: user.displayName || 'Apprenant',
        userEmail: user.email || '',
        courseId: currentCourse.id,
        courseTitle: currentCourse.title,
        teacherId: currentCourse.teacherId,
        teacherName: currentCourse.teacherName,
        amount: currentCourse.price,
        method: this.selectedPaymentMethod,
        phone: phone,
      });

      this.openPaymentModal = false;
      this.toastr.success(`Inscription confirmée ! Paiement validé par ${this.selectedPaymentMethod === 'wave' ? 'Wave' : 'Orange Money'}.`);
      await this.refreshAccess();

      // Navigation vers le cours si leçons disponibles
      const firstId = this.firstLessonId();
      if (firstId && firstId !== 'intro') {
        this.router.navigate(['/learn', currentCourse.id, firstId]);
      }
    } catch (e) {
      this.toastr.error('Erreur lors de la validation du paiement.');
    } finally {
      this.actionLoading.set(false);
    }
  }

  async payWithWave(): Promise<void> {
    this.selectedPaymentMethod = 'wave';
    this.openCheckoutModal();
  }

  async payWithOrangeMoney(): Promise<void> {
    this.selectedPaymentMethod = 'orange_money';
    this.openCheckoutModal();
  }

  async submitEnrollmentRequest(): Promise<void> {
    const currentCourse = this.course();
    const user = this.currentUser();
    if (!currentCourse) return;

    if (!user) {
      this.router.navigate(['/auth/login'], { queryParams: { redirectTo: `/course/${currentCourse.id}` } });
      return;
    }

    this.actionLoading.set(true);
    try {
      await this.requestService.createRequest({
        studentId: user.uid,
        studentName: user.displayName,
        studentEmail: user.email,
        studentPhotoURL: user.photoURL,
        courseId: currentCourse.id,
        courseTitle: currentCourse.title,
        teacherId: currentCourse.teacherId,
        teacherName: currentCourse.teacherName,
        message: this.requestMotivation,
      });

      this.toastr.success('Votre demande d\'inscription a été envoyée au professeur !');
      this.openRequestModal = false;
      const req = await this.requestService.checkExistingRequest(user.uid, currentCourse.id);
      this.existingRequest.set(req);
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors de l\'envoi de la demande.');
    } finally {
      this.actionLoading.set(false);
    }
  }

  async enrollFree(): Promise<void> {
    const currentCourse = this.course();
    const user = this.currentUser();
    if (!currentCourse) return;
    if (!user) {
      this.router.navigate(['/auth/login']);
      return;
    }

    try {
      this.actionLoading.set(true);
      await this.paymentService.enrollFree(currentCourse.id, user.uid, user.displayName);
      this.toastr.success('Inscription gratuite confirmée !');
      await this.refreshAccess();
    } catch {
      this.toastr.error('Impossible de finaliser l\'inscription.');
    } finally {
      this.actionLoading.set(false);
    }
  }
}
