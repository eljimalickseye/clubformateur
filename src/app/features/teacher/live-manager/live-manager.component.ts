import { Component, inject, OnInit, OnDestroy, signal, computed, ElementRef, ViewChild, AfterViewInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { switchMap, of, combineLatest, catchError, timeout } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { LivekitService } from '../../../core/services/livekit.service';
import { CourseService } from '../../../core/services/course.service';
import { NotificationService } from '../../../core/services/notification.service';
import { LiveSession, Course, User } from '../../../core/models';

interface LiveChatMessage {
  id: string;
  sender: string;
  avatar?: string;
  text: string;
  time: string;
  isTeacher?: boolean;
}

@Component({
  selector: 'app-live-manager',
  standalone: true,
  imports: [CommonModule, RouterLink, ReactiveFormsModule, FormsModule, DatePipe],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8 font-body animate-fade-in">
      
      <!-- Top Banner with Instant Start Meeting Button -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-6 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-500/10 text-red-600 text-xs font-bold uppercase tracking-wider mb-2">
            <span class="h-2 w-2 rounded-full bg-red-500 animate-ping"></span>
            Directs & Visioconférences HD
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">Gestion des Réunions & Lives</h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">
            Démarrez une réunion instantanée ou planifiez un cours en direct avec caméra, micro, partage d'écran et tableau blanc interactif.
          </p>
        </div>

        <div class="flex flex-wrap items-center gap-3 shrink-0">
          <button (click)="openCapsuleModal()"
                  class="px-5 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 active:scale-95 text-white text-xs font-black rounded-2xl shadow-lg shadow-purple-600/25 flex items-center gap-2 transition-all cursor-pointer">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>Capsule Vidéo 5 Min (Partage & Tableau)</span>
          </button>

          <button (click)="startInstantMeeting()"
                  class="px-5 py-3 bg-emerald-600 hover:bg-emerald-700 active:scale-95 text-white text-xs font-black rounded-2xl shadow-lg shadow-emerald-600/25 flex items-center gap-2 transition-all cursor-pointer">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
            </svg>
            <span>Démarrer une réunion maintenant</span>
          </button>

          <button (click)="scrollToSchedule()"
                  class="px-4 py-3 bg-dark-surface2 hover:bg-dark-border active:scale-95 text-light text-xs font-bold rounded-2xl transition-all border border-dark-border flex items-center gap-1.5 cursor-pointer">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
            <span>Programmer un direct</span>
          </button>
        </div>
      </div>

      <!-- Quick KPI Counters -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Total Sessions</p>
          <p class="font-display text-3xl font-black text-light mt-1">{{ sessions().length }}</p>
          <p class="text-[10px] text-primary font-bold mt-1">Sessions créées</p>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Prochain Direct</p>
          <p class="font-display text-base sm:text-lg font-black text-primary mt-1 truncate">{{ getNextLiveTime() }}</p>
          <p class="text-[10px] text-emerald-600 font-bold mt-1">● Planifié</p>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Sessions Terminées</p>
          <p class="font-display text-3xl font-black text-emerald-600 mt-1">{{ getEndedCount() }}</p>
          <p class="text-[10px] text-light-muted mt-1">Diffusées avec succès</p>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Tableau Blanc HD</p>
          <p class="font-display text-base font-black text-light mt-1">Interactif & Notes</p>
          <p class="text-[10px] text-emerald-600 font-bold mt-1">✓ Dessin / Formules / Export</p>
        </div>
      </div>

      <!-- Main Section: Scheduled Sessions + Creator Form -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        <!-- Left: Sessions Table -->
        <section class="xl:col-span-2 rounded-3xl border border-dark-border bg-white p-6 shadow-xs space-y-4">
          <div class="flex items-center justify-between border-b border-dark-border/60 pb-4">
            <div>
              <h2 class="font-display text-lg font-bold text-light">Sessions & Réunions</h2>
              <p class="text-xs text-light-muted">Historique et sessions en direct programmées</p>
            </div>
            <span class="text-xs font-bold text-primary bg-primary/10 px-3 py-1 rounded-full">
              {{ sessions().length }} session(s)
            </span>
          </div>

          @if (loading()) {
            <div class="flex flex-col items-center justify-center py-16">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mb-3"></div>
              <p class="text-xs text-light-muted">Chargement des sessions en direct...</p>
            </div>
          } @else if (sessions().length === 0) {
            <div class="text-center py-12 text-light-muted space-y-3">
              <div class="text-3xl">📹</div>
              <p class="text-sm font-bold text-light">Aucune session programmée</p>
              <p class="text-xs">Utilisez le bouton "Démarrer une réunion" ou planifiez un cours à droite.</p>
            </div>
          } @else {
            <div class="space-y-3">
              @for (session of sessions(); track session.id) {
                <div class="p-4 rounded-2xl border border-dark-border bg-dark-surface2/30 hover:bg-white hover:border-primary/40 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  
                  <div class="space-y-1 min-w-0">
                    <div class="flex items-center gap-2">
                      <span class="px-2 py-0.5 rounded-full text-[10px] font-bold"
                            [class.bg-emerald-100]="session.status === 'live'"
                            [class.text-emerald-700]="session.status === 'live'"
                            [class.bg-blue-100]="session.status === 'scheduled'"
                            [class.text-blue-700]="session.status === 'scheduled'"
                            [class.bg-slate-100]="session.status === 'ended'"
                            [class.text-slate-600]="session.status === 'ended'">
                        {{ session.status === 'live' ? '● En Direct' : session.status === 'scheduled' ? 'Planifié' : 'Terminé' }}
                      </span>
                      <span class="text-xs text-light-muted">
                        {{ session.scheduledAt ? (session.scheduledAt.toMillis() | date:'dd/MM/yyyy à HH:mm') : 'Immédiat' }}
                      </span>
                    </div>
                    
                    <h3 class="font-bold text-light text-sm truncate">{{ session.title }}</h3>
                    <p class="text-xs text-primary font-semibold truncate">{{ session.courseName || 'Salle Générale' }}</p>
                  </div>

                  <div class="flex items-center gap-2 shrink-0">
                    @if (session.status !== 'ended') {
                      <button (click)="joinVirtualStudio(session)"
                              class="px-4 py-2 bg-primary hover:bg-primary-600 active:scale-95 text-white text-xs font-bold rounded-xl shadow-xs transition-all flex items-center gap-1.5 cursor-pointer">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                        </svg>
                        <span>Rejoindre le Studio</span>
                      </button>
                    }
                  </div>

                </div>
              }
            </div>
          }
        </section>

        <!-- Right: Schedule a Live Form -->
        <aside #scheduleSection class="rounded-3xl border border-dark-border bg-white p-6 shadow-xs space-y-4">
          <div class="border-b border-dark-border/60 pb-3">
            <h2 class="font-display text-base font-bold text-light">Programmer un Direct</h2>
            <p class="text-xs text-light-muted">Fixez une date et prévenez vos élèves</p>
          </div>

          <form [formGroup]="liveForm" (ngSubmit)="scheduleLive()" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-light mb-1">Titre de la session *</label>
              <input type="text" formControlName="title" placeholder="Ex: Correction des devoirs & Q&A"
                     class="w-full px-3.5 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none" />
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Formation associée</label>
              <select formControlName="courseId"
                      class="w-full px-3.5 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
                <option value="general">✦ Visioconférence ouverte (Tous les étudiants)</option>
                @for (course of courses(); track course.id) {
                  <option [value]="course.id">{{ course.title }}</option>
                }
              </select>
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Date et Heure du direct</label>
              <input type="datetime-local" formControlName="scheduledAt"
                     class="w-full px-3.5 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none" />
            </div>

            <button type="submit"
                    class="w-full py-3.5 bg-primary hover:bg-primary-600 active:scale-95 text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 transition-all cursor-pointer">
              {{ scheduling() ? 'Enregistrement en cours...' : '✓ Enregistrer la programmation' }}
            </button>
          </form>
        </aside>

      </div>

      <!-- ======================================================== -->
      <!-- MODALE CONFIGURATION CAPSULE VIDÉO 5 MINUTES              -->
      <!-- ======================================================== -->
      @if (showCapsuleConfigModal()) {
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-xs p-4 animate-fade-in">
          <div class="bg-white rounded-3xl border border-dark-border max-w-lg w-full p-6 sm:p-8 space-y-6 shadow-2xl font-body">
            
            <div class="flex items-center justify-between border-b border-dark-border pb-4">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-2xl bg-purple-600/10 text-purple-600 flex items-center justify-center">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <div>
                  <h3 class="font-display font-black text-lg text-light">Studio Capsule Vidéo (5 min)</h3>
                  <p class="text-xs text-light-muted">Partage d'écran, tableau d'illustrations, notes & PDF</p>
                </div>
              </div>
              <button (click)="showCapsuleConfigModal.set(false)" class="text-light-muted hover:text-light cursor-pointer text-sm">✕</button>
            </div>

            <div class="space-y-4">
              <div>
                <label class="block text-xs font-bold text-light mb-1.5">Titre de la capsule vidéo</label>
                <input type="text" [(ngModel)]="capsuleTitle"
                       placeholder="Ex: Démonstration et Synthèse en 5 minutes..."
                       class="w-full px-3.5 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none" />
              </div>

              <div>
                <label class="block text-xs font-bold text-light mb-1.5">Rattacher au cours (les inscrits y auront accès)</label>
                <select [(ngModel)]="capsuleCourseId"
                        class="w-full px-3.5 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
                  <option value="general">Général (Tous les étudiants)</option>
                  @for (course of courses(); track course.id) {
                    <option [value]="course.id">{{ course.title }}</option>
                  }
                </select>
              </div>

              <div>
                <label class="block text-xs font-bold text-light mb-1.5">Document PDF d'appui (Support)</label>
                <input type="file" accept="application/pdf" (change)="onPdfFileSelected($event)" class="hidden" #modalPdfInput />
                @if (capsulePdfName) {
                  <div class="flex items-center justify-between p-2.5 bg-primary/10 border border-primary/20 rounded-xl text-xs">
                    <span class="text-primary font-bold truncate">📄 {{ capsulePdfName }}</span>
                    <button (click)="capsulePdfName = ''; capsulePdfUrl = ''" class="text-red-500 font-bold">✕</button>
                  </div>
                } @else {
                  <button (click)="modalPdfInput.click()"
                          class="w-full py-2.5 border border-dashed border-dark-border rounded-xl text-xs text-light-muted hover:text-light flex items-center justify-center gap-2 cursor-pointer">
                    <span>📎 Sélectionner un document PDF de cours</span>
                  </button>
                }
              </div>

              <div class="p-3.5 bg-purple-500/10 border border-purple-500/20 rounded-2xl text-[11px] text-purple-900 leading-relaxed space-y-1">
                <p class="font-bold flex items-center gap-1.5">
                  <span>⏱️ Caractéristiques de la capsule express :</span>
                </p>
                <ul class="list-disc list-inside space-y-0.5 text-purple-800">
                  <li>Durée limitée à <strong>5 minutes chrono</strong> avec compte à rebours.</li>
                  <li>Partage d'écran et tableau d'illustration interactif.</li>
                  <li><strong>L'étudiant ne peut répondre que par message textuel</strong>.</li>
                  <li>Les inscrits au cours accèdent aux <strong>formats Vidéo ET PDF</strong>.</li>
                </ul>
              </div>
            </div>

            <div class="flex items-center justify-end gap-3 pt-2">
              <button (click)="showCapsuleConfigModal.set(false)"
                      class="px-4 py-2.5 rounded-xl border border-dark-border text-xs font-bold text-light hover:bg-dark-surface2 cursor-pointer">
                Annuler
              </button>
              <button (click)="start5MinCapsule()"
                      class="px-6 py-2.5 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white text-xs font-black shadow-lg shadow-purple-600/25 flex items-center gap-2 cursor-pointer">
                <span>🔴 Démarrer l'enregistrement 5 Min</span>
              </button>
            </div>

          </div>
        </div>
      }

      <!-- ======================================================== -->
      <!-- VIRTUAL LIVE STUDIO MODAL WITH WHITEBOARD & SVG ICONS    -->
      <!-- ======================================================== -->
      @if (activeStudioSession()) {
        <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/90 backdrop-blur-md p-2 sm:p-4 overflow-hidden animate-fade-in">
          <div class="relative w-full h-full max-w-7xl max-h-[95vh] bg-slate-950 rounded-3xl border border-slate-800 shadow-2xl flex flex-col overflow-hidden">
            
            <!-- Studio Top Header -->
            <div class="flex items-center justify-between border-b border-slate-800 px-6 py-4 bg-slate-900/90 shrink-0">
              <div class="flex items-center gap-3">
                @if (isCapsule5Min()) {
                  <span class="flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-600 text-white text-[10px] font-black uppercase tracking-wider shadow-sm">
                    <span class="w-2 h-2 rounded-full bg-white animate-ping"></span>
                    CAPSULE 5 MIN
                  </span>
                } @else {
                  <span class="flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-600 text-white text-[10px] font-black uppercase tracking-wider shadow-sm">
                    <span class="w-2 h-2 rounded-full bg-white animate-ping"></span>
                    EN DIRECT
                  </span>
                }
                <div>
                  <h2 class="font-display text-sm sm:text-base font-bold text-white truncate max-w-md">
                    {{ activeStudioSession()?.title }}
                  </h2>
                  <p class="text-[11px] text-slate-400">
                    Formation : {{ activeStudioSession()?.courseName || 'Salle Générale' }}
                  </p>
                </div>
              </div>

              <div class="flex items-center gap-3">
                <!-- View Mode Switcher: Video vs Tableau Blanc -->
                <div class="flex bg-slate-800 p-1 rounded-xl border border-slate-700">
                  <button (click)="viewMode.set('video')"
                          [class.bg-primary]="viewMode() === 'video'"
                          [class.text-white]="viewMode() === 'video'"
                          [class.text-slate-400]="viewMode() !== 'video'"
                          class="px-3 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                    <span>Caméra</span>
                  </button>
                  <button (click)="switchToWhiteboard()"
                          [class.bg-purple-600]="viewMode() === 'whiteboard'"
                          [class.text-white]="viewMode() === 'whiteboard'"
                          [class.text-slate-400]="viewMode() !== 'whiteboard'"
                          class="px-3 py-1 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                    </svg>
                    <span>Tableau Blanc 🎨</span>
                  </button>
                </div>

                <!-- Timer (Countdown if Capsule 5 min, Elapsed if standard live) -->
                @if (isCapsule5Min()) {
                  <span class="font-mono text-xs font-black px-3 py-1.5 rounded-xl border flex items-center gap-1.5"
                        [class.bg-emerald-950]="capsuleSecondsLeft() > 120"
                        [class.border-emerald-500]="capsuleSecondsLeft() > 120"
                        [class.text-emerald-400]="capsuleSecondsLeft() > 120"
                        [class.bg-amber-950]="capsuleSecondsLeft() <= 120 && capsuleSecondsLeft() > 30"
                        [class.border-amber-500]="capsuleSecondsLeft() <= 120 && capsuleSecondsLeft() > 30"
                        [class.text-amber-400]="capsuleSecondsLeft() <= 120 && capsuleSecondsLeft() > 30"
                        [class.bg-red-950]="capsuleSecondsLeft() <= 30"
                        [class.border-red-500]="capsuleSecondsLeft() <= 30"
                        [class.text-red-400]="capsuleSecondsLeft() <= 30">
                    ⏱️ {{ capsuleTimerFormatted() }}
                  </span>
                } @else {
                  <span class="font-mono text-xs text-white font-bold bg-slate-800 px-3 py-1.5 rounded-xl border border-slate-700">
                    ⏱️ {{ liveTimerFormatted() }}
                  </span>
                }

                <!-- End Live / Save Capsule Button -->
                <button (click)="endStudioLive()"
                        class="px-4 py-2 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-xl shadow-md transition-all flex items-center gap-1.5 active:scale-95 cursor-pointer">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                  </svg>
                  <span>{{ isCapsule5Min() ? 'Terminer & Sauvegarder' : 'Terminer le live' }}</span>
                </button>
              </div>
            </div>

            <!-- Capsule 5 Min Progress Bar & Banner -->
            @if (isCapsule5Min()) {
              <div class="w-full bg-slate-800 h-1 overflow-hidden shrink-0">
                <div class="h-full transition-all duration-1000"
                     [class.bg-emerald-500]="capsuleSecondsLeft() > 120"
                     [class.bg-amber-500]="capsuleSecondsLeft() <= 120 && capsuleSecondsLeft() > 30"
                     [class.bg-red-500]="capsuleSecondsLeft() <= 30"
                     [style.width.%]="(capsuleSecondsLeft() / 300) * 100"></div>
              </div>

              <div class="bg-indigo-950/80 border-b border-indigo-500/30 px-6 py-2 flex items-center justify-between text-xs text-indigo-200 shrink-0">
                <div class="flex items-center gap-2">
                  <span class="w-2 h-2 rounded-full bg-indigo-400 animate-pulse"></span>
                  <span><strong>Capsule 5 Minutes</strong> • Partage d'écran & Tableau blanc • Micro apprenants verrouillé</span>
                </div>
                <span class="text-[11px] bg-indigo-500/20 px-2 py-0.5 rounded-full text-indigo-300 font-bold">
                  Les étudiants répondent uniquement par message
                </span>
              </div>
            }

            <!-- Studio Main Center (Video / Whiteboard & Sidebar) -->
            <div class="flex-1 grid grid-cols-1 lg:grid-cols-4 gap-4 p-4 min-h-0 overflow-hidden">
              
              <!-- Left 3 Cols: Video OR Interactive Whiteboard -->
              <div class="lg:col-span-3 bg-slate-900 rounded-2xl border border-slate-800 relative flex flex-col overflow-hidden shadow-inner">
                
                @if (viewMode() === 'video') {
                  <!-- Video Viewport -->
                  <div class="w-full h-full relative flex items-center justify-center overflow-hidden">
                    <video #localVideoElement autoplay playsinline muted
                           class="w-full h-full object-cover rounded-2xl"
                           [class.hidden]="isCameraOff()"></video>

                    @if (isCameraOff()) {
                      <div class="flex flex-col items-center justify-center text-center p-8 space-y-4">
                        <div class="w-24 h-24 rounded-full bg-slate-800 border-4 border-slate-700 flex items-center justify-center text-4xl shadow-xl">
                          🎙️
                        </div>
                        <div>
                          <p class="font-bold text-white text-base">{{ currentUser?.displayName || 'Professeur' }}</p>
                          <p class="text-xs text-slate-400">Caméra désactivée • Micro actif</p>
                        </div>
                      </div>
                    }

                    <div class="absolute top-4 left-4 flex items-center gap-2 bg-slate-950/80 backdrop-blur-md px-3 py-1.5 rounded-xl border border-slate-800 text-white text-xs">
                      <span class="w-2 h-2 rounded-full" [class.bg-emerald-400]="!isMuted()" [class.bg-red-400]="isMuted()"></span>
                      <span class="font-bold">{{ currentUser?.displayName || 'Professeur' }} (Vous)</span>
                    </div>

                    @if (isScreenSharing()) {
                      <div class="absolute top-4 right-4 bg-primary px-3 py-1 rounded-xl text-white text-xs font-bold shadow-md">
                        🖥️ Partage d'écran actif
                      </div>
                    }
                  </div>
                } @else {
                  <!-- INTERACTIVE WHITEBOARD (TABLEAU BLANC) -->
                  <div class="w-full h-full flex flex-col bg-slate-950 relative">
                    
                    <!-- Whiteboard Tools Bar -->
                    <div class="h-12 bg-slate-900 border-b border-slate-800 px-4 flex items-center justify-between shrink-0 gap-2 overflow-x-auto">
                      
                      <!-- Drawing Tool Selectors -->
                      <div class="flex items-center gap-1">
                        <button (click)="wbTool = 'pen'" title="Stylo / Pinceau"
                                [class.bg-purple-600]="wbTool === 'pen'"
                                [class.text-white]="wbTool === 'pen'"
                                [class.text-slate-400]="wbTool !== 'pen'"
                                class="p-1.5 rounded-lg hover:bg-slate-800 transition-all cursor-pointer">
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                          </svg>
                        </button>

                        <button (click)="wbTool = 'highlighter'" title="Surligneur"
                                [class.bg-purple-600]="wbTool === 'highlighter'"
                                [class.text-white]="wbTool === 'highlighter'"
                                [class.text-slate-400]="wbTool !== 'highlighter'"
                                class="p-1.5 rounded-lg hover:bg-slate-800 transition-all cursor-pointer">
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                          </svg>
                        </button>

                        <button (click)="wbTool = 'eraser'" title="Gomme"
                                [class.bg-purple-600]="wbTool === 'eraser'"
                                [class.text-white]="wbTool === 'eraser'"
                                [class.text-slate-400]="wbTool !== 'eraser'"
                                class="p-1.5 rounded-lg hover:bg-slate-800 transition-all cursor-pointer">
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                          </svg>
                        </button>

                        <button (click)="wbTool = 'rect'" title="Rectangle"
                                [class.bg-purple-600]="wbTool === 'rect'"
                                [class.text-white]="wbTool === 'rect'"
                                [class.text-slate-400]="wbTool !== 'rect'"
                                class="p-1.5 rounded-lg hover:bg-slate-800 transition-all cursor-pointer">
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                          </svg>
                        </button>
                      </div>

                      <!-- Colors Palette -->
                      <div class="flex items-center gap-1.5">
                        @for (color of wbColors; track color) {
                          <button (click)="wbColor = color"
                                  [style.backgroundColor]="color"
                                  [class.ring-2]="wbColor === color"
                                  [class.ring-white]="wbColor === color"
                                  class="w-5 h-5 rounded-full border border-slate-700 transition-all cursor-pointer hover:scale-110"></button>
                        }
                      </div>

                      <!-- Brush Size -->
                      <div class="flex items-center gap-1">
                        <button (click)="wbLineWidth = 2" [class.bg-slate-800]="wbLineWidth === 2" class="px-2 py-0.5 rounded text-[10px] text-slate-300 font-bold">Fin</button>
                        <button (click)="wbLineWidth = 6" [class.bg-slate-800]="wbLineWidth === 6" class="px-2 py-0.5 rounded text-[10px] text-slate-300 font-bold">Moyen</button>
                        <button (click)="wbLineWidth = 14" [class.bg-slate-800]="wbLineWidth === 14" class="px-2 py-0.5 rounded text-[10px] text-slate-300 font-bold">Épais</button>
                      </div>

                      <!-- Actions: Clear & Export -->
                      <div class="flex items-center gap-2">
                        <button (click)="clearWhiteboard()" title="Effacer tout le tableau"
                                class="p-1.5 bg-red-950/60 hover:bg-red-900 text-red-300 text-xs font-bold rounded-lg border border-red-800/40 cursor-pointer">
                          Effacer 🗑️
                        </button>
                        <button (click)="exportWhiteboardImage()" title="Télécharger l'image PNG du tableau"
                                class="px-2.5 py-1 bg-emerald-700 hover:bg-emerald-600 text-white text-xs font-bold rounded-lg shadow-xs cursor-pointer">
                          Enregistrer 📸
                        </button>
                      </div>

                    </div>

                    <!-- Canvas -->
                    <div class="flex-1 relative bg-white cursor-crosshair overflow-hidden">
                      <canvas #whiteboardCanvas
                              (mousedown)="startDrawing($event)"
                              (mousemove)="draw($event)"
                              (mouseup)="stopDrawing()"
                              (mouseleave)="stopDrawing()"
                              (touchstart)="startDrawingTouch($event)"
                              (touchmove)="drawTouch($event)"
                              (touchend)="stopDrawing()"
                              class="w-full h-full block"></canvas>
                    </div>

                  </div>
                }

              </div>

              <!-- Sidebar: Chat & Participants (1 col) -->
              <div class="bg-slate-900 rounded-2xl border border-slate-800 flex flex-col min-h-0 overflow-hidden">
                
                <!-- Raised Hands Realtime Banner -->
                @if ((activeStudioSession()?.raisedHands?.length || 0) > 0) {
                  <div class="p-3 bg-amber-500/15 border-b border-amber-500/30 shrink-0">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-xs font-black text-amber-400 flex items-center gap-1.5">
                        <svg class="w-4 h-4 text-amber-400 animate-bounce" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11" />
                        </svg>
                        <span>{{ activeStudioSession()?.raisedHands?.length }} main(s) levée(s)</span>
                      </span>
                    </div>
                    <div class="space-y-1.5 max-h-36 overflow-y-auto">
                      @for (hand of activeStudioSession()?.raisedHands; track hand.uid) {
                        <div class="flex items-center justify-between p-2 rounded-xl bg-slate-900 border border-slate-800 text-xs">
                          <div class="flex items-center gap-2 min-w-0">
                            <span class="w-2 h-2 rounded-full bg-amber-400 animate-ping shrink-0"></span>
                            <span class="text-white font-bold truncate">{{ hand.displayName }}</span>
                          </div>
                          <div class="flex items-center gap-1 shrink-0">
                            <button (click)="grantSpeaking(hand.uid, hand.displayName)"
                                    class="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-[10px] font-bold flex items-center gap-1 cursor-pointer shadow-xs">
                              <span>🎙️ Autoriser</span>
                            </button>
                            <button (click)="lowerHand(hand.uid)"
                                    class="p-1 bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white rounded-lg text-[10px] cursor-pointer"
                                    title="Baisser la main">
                              ✕
                            </button>
                          </div>
                        </div>
                      }
                    </div>
                  </div>
                }

                <div class="flex border-b border-slate-800 bg-slate-950/60 p-1 shrink-0">
                  <button (click)="studioTab.set('chat')"
                          [class.bg-slate-800]="studioTab() === 'chat'"
                          [class.text-white]="studioTab() === 'chat'"
                          [class.text-slate-400]="studioTab() !== 'chat'"
                          class="flex-1 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer">
                    Discussion ({{ chatMessages().length }})
                  </button>
                  <button (click)="studioTab.set('notes_pdf')"
                          [class.bg-slate-800]="studioTab() === 'notes_pdf'"
                          [class.text-white]="studioTab() === 'notes_pdf'"
                          [class.text-slate-400]="studioTab() !== 'notes_pdf'"
                          class="flex-1 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer">
                    Notes & PDF 📄
                  </button>
                  <button (click)="studioTab.set('participants')"
                          [class.bg-slate-800]="studioTab() === 'participants'"
                          [class.text-white]="studioTab() === 'participants'"
                          [class.text-slate-400]="studioTab() !== 'participants'"
                          class="flex-1 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer">
                    Audience
                  </button>
                </div>

                <!-- Tab 1: Chat Stream -->
                @if (studioTab() === 'chat') {
                  <div class="flex-1 p-3 overflow-y-auto space-y-2.5 text-xs">
                    @for (msg of chatMessages(); track msg.id) {
                      <div class="space-y-0.5 p-2 rounded-xl" [class.bg-slate-800]="msg.isTeacher" [class.bg-slate-950]="!msg.isTeacher">
                        <div class="flex items-center justify-between text-[10px]">
                          <span class="font-bold" [class.text-primary]="msg.isTeacher" [class.text-slate-300]="!msg.isTeacher">
                            {{ msg.sender }} {{ msg.isTeacher ? '(Enseignant)' : '' }}
                          </span>
                          <span class="text-slate-500">{{ msg.time }}</span>
                        </div>
                        <p class="text-white text-xs leading-relaxed">{{ msg.text }}</p>
                      </div>
                    }
                  </div>

                  <!-- Chat Input -->
                  <form (ngSubmit)="sendChatMessage()" class="p-2 border-t border-slate-800 flex gap-2 shrink-0">
                    <input type="text" [(ngModel)]="newChatMessage" name="newChatMessage"
                           placeholder="Poser une question en direct..."
                           class="flex-1 px-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-primary">
                    <button type="submit" [disabled]="!newChatMessage.trim()"
                            class="px-3 py-2 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-xs disabled:opacity-50 cursor-pointer">
                      Envoyer
                    </button>
                  </form>
                }

                <!-- Tab 2: Notes & Document PDF Support -->
                @if (studioTab() === 'notes_pdf') {
                  <div class="flex-1 p-3 overflow-y-auto space-y-3 text-xs">
                    <div class="p-3 bg-slate-950 border border-slate-800 rounded-xl space-y-2">
                      <label class="font-bold text-white flex items-center gap-1.5">
                        <span>📝 Notes de synthèse du professeur :</span>
                      </label>
                      <textarea [(ngModel)]="capsuleNotes" rows="4"
                                placeholder="Rédigez les points essentiels, formules ou synthèses liés à cette capsule vidéo..."
                                class="w-full p-2 bg-slate-900 border border-slate-800 rounded-lg text-white text-xs placeholder-slate-500 focus:outline-none focus:border-primary resize-none"></textarea>
                    </div>

                    <div class="p-3 bg-slate-950 border border-slate-800 rounded-xl space-y-2">
                      <label class="font-bold text-white flex items-center gap-1.5">
                        <span>📎 Document PDF d'appui :</span>
                      </label>
                      <input type="file" accept="application/pdf" (change)="onPdfFileSelected($event)" class="hidden" #pdfFileInput />
                      
                      @if (capsulePdfName) {
                        <div class="flex items-center justify-between p-2 rounded-lg bg-primary/10 border border-primary/30">
                          <div class="flex items-center gap-2 truncate">
                            <span class="text-primary text-base">📄</span>
                            <span class="text-white font-bold truncate text-[11px]">{{ capsulePdfName }}</span>
                          </div>
                          <button (click)="capsulePdfName = ''; capsulePdfUrl = ''" class="text-red-400 hover:text-red-300 text-xs cursor-pointer">✕</button>
                        </div>
                      } @else {
                        <button (click)="pdfFileInput.click()"
                                class="w-full py-2.5 px-3 border border-dashed border-slate-700 hover:border-primary rounded-xl text-slate-400 hover:text-white flex items-center justify-center gap-2 cursor-pointer transition-colors">
                          <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                          </svg>
                          <span>Joindre un document PDF de cours</span>
                        </button>
                      }
                    </div>

                    <button (click)="publishNotesAndPdf()"
                            class="w-full py-2.5 bg-primary hover:bg-primary-600 active:scale-95 text-white font-bold rounded-xl shadow-xs transition-all flex items-center justify-center gap-1.5 cursor-pointer">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"/>
                      </svg>
                      <span>Diffuser Notes & PDF aux apprenants</span>
                    </button>

                    @if (recordedVideoUrl()) {
                      <div class="p-3 bg-emerald-950/40 border border-emerald-500/30 rounded-xl space-y-2">
                        <p class="text-[11px] text-emerald-400 font-bold flex items-center gap-1">
                          <span>✓ Vidéo de la capsule prête</span>
                        </p>
                        <button (click)="downloadRecordedVideo()"
                                class="w-full py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-bold text-xs flex items-center justify-center gap-1.5 cursor-pointer">
                          📥 Télécharger la capsule vidéo (.webm)
                        </button>
                      </div>
                    }
                  </div>
                }

                <!-- Tab 2: Participants List -->
                @if (studioTab() === 'participants') {
                  <div class="flex-1 p-3 overflow-y-auto space-y-2 text-xs">
                    <div class="flex items-center justify-between p-2 rounded-xl bg-primary/10 border border-primary/20">
                      <div class="flex items-center gap-2">
                        <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
                        <span class="font-bold text-white">{{ currentUser?.displayName || 'Professeur' }}</span>
                      </div>
                      <span class="text-[10px] text-primary font-bold">Hôte (Micro Maître)</span>
                    </div>

                    <!-- Students permitted to speak -->
                    @for (spkId of activeStudioSession()?.allowedSpeakers; track spkId) {
                      <div class="flex items-center justify-between p-2 rounded-xl bg-emerald-950/40 border border-emerald-500/30">
                        <div class="flex items-center gap-2">
                          <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                          <span class="text-white font-bold">{{ getStudentDisplayName(spkId) }}</span>
                        </div>
                        <button (click)="revokeSpeaking(spkId, getStudentDisplayName(spkId))"
                                class="px-2 py-0.5 rounded-lg bg-red-600/80 hover:bg-red-600 text-white text-[10px] font-bold cursor-pointer">
                          Couper la parole
                        </button>
                      </div>
                    }

                    @for (student of mockLiveStudents; track student.id) {
                      <div class="flex items-center justify-between p-2 rounded-xl bg-slate-950 border border-slate-800">
                        <div class="flex items-center gap-2">
                          <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
                          <span class="text-slate-200">{{ student.name }}</span>
                        </div>
                        <div class="flex items-center gap-1.5">
                          @if (isHandRaisedByUid(student.id)) {
                            <button (click)="grantSpeaking(student.id, student.name)"
                                    class="px-2 py-0.5 rounded-lg bg-amber-500 hover:bg-amber-400 text-black text-[10px] font-bold flex items-center gap-1 cursor-pointer">
                              <span>✋ Donner parole</span>
                            </button>
                          } @else {
                            <button (click)="grantSpeaking(student.id, student.name)"
                                    class="px-2 py-0.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 text-[10px] font-bold cursor-pointer"
                                    title="Autoriser la parole">
                              Débloquer micro
                            </button>
                          }
                        </div>
                      </div>
                    }
                  </div>
                }

              </div>

            </div>

            <!-- Studio Bottom Control Bar (100% SVG Icons) -->
            <div class="flex items-center justify-center gap-4 py-4 px-6 border-t border-slate-800 bg-slate-900/90 shrink-0">
              
              <!-- Toggle Mic -->
              <button (click)="toggleMicrophone()"
                      [class.bg-slate-800]="!isMuted()"
                      [class.text-white]="!isMuted()"
                      [class.bg-red-600]="isMuted()"
                      [class.text-white]="isMuted()"
                      class="p-3.5 rounded-2xl border border-slate-700 hover:scale-105 active:scale-95 transition-all shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"/>
                </svg>
                <span>{{ isMuted() ? 'Micro Coupé' : 'Micro Actif' }}</span>
              </button>

              <!-- Toggle Camera -->
              <button (click)="toggleCamera()"
                      [class.bg-slate-800]="!isCameraOff()"
                      [class.text-white]="!isCameraOff()"
                      [class.bg-red-600]="isCameraOff()"
                      [class.text-white]="isCameraOff()"
                      class="p-3.5 rounded-2xl border border-slate-700 hover:scale-105 active:scale-95 transition-all shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                </svg>
                <span>{{ isCameraOff() ? 'Caméra Off' : 'Caméra On' }}</span>
              </button>

              <!-- Screen Share -->
              <button (click)="toggleScreenShare()"
                      [class.bg-primary]="isScreenSharing()"
                      [class.bg-slate-800]="!isScreenSharing()"
                      class="p-3.5 rounded-2xl border border-slate-700 text-white hover:scale-105 active:scale-95 transition-all shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                </svg>
                <span>{{ isScreenSharing() ? 'Arrêter Partage' : 'Partager Écran' }}</span>
              </button>

              <!-- Whiteboard Switch -->
              <button (click)="switchToWhiteboard()"
                      [class.bg-purple-600]="viewMode() === 'whiteboard'"
                      [class.bg-slate-800]="viewMode() !== 'whiteboard'"
                      class="p-3.5 rounded-2xl border border-slate-700 text-white hover:scale-105 active:scale-95 transition-all shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                </svg>
                <span>Tableau Blanc</span>
              </button>

              <!-- Mute All Students -->
              <button (click)="muteAll()"
                      class="p-3.5 rounded-2xl bg-amber-500/20 border border-amber-500/40 text-amber-300 hover:bg-amber-500 hover:text-slate-950 active:scale-95 transition-all shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer"
                      title="Couper immédiatement tous les micros des étudiants">
                <svg class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"/>
                  <line x1="1" y1="1" x2="23" y2="23" stroke="currentColor" stroke-width="2" />
                </svg>
                <span class="hidden sm:inline">Couper tous les micros</span>
              </button>

            </div>

          </div>
        </div>
      }

    </div>
  `,
})
export class LiveManagerComponent implements OnInit, OnDestroy {
  @ViewChild('localVideoElement') localVideoRef?: ElementRef<HTMLVideoElement>;
  @ViewChild('whiteboardCanvas') whiteboardCanvasRef?: ElementRef<HTMLCanvasElement>;

  private store = inject(Store);
  private livekitService = inject(LivekitService);
  private courseService = inject(CourseService);
  private notificationService = inject(NotificationService);
  private fb = inject(FormBuilder);
  private toastr = inject(ToastrService);

  loading = signal(true);
  scheduling = signal(false);
  sessions = signal<LiveSession[]>([]);
  courses = signal<Course[]>([]);
  currentUser: User | null = null;

  // Virtual Studio State
  activeStudioSession = signal<LiveSession | null>(null);
  viewMode = signal<'video' | 'whiteboard'>('video');
  studioTab = signal<'chat' | 'participants' | 'notes_pdf'>('chat');
  isMuted = signal(false);
  isCameraOff = signal(false);
  isScreenSharing = signal(false);
  localMediaStream: MediaStream | null = null;
  liveTimerSeconds = signal(0);
  private timerInterval: any = null;
  private studioSessionSub?: any;

  // 5-Minute Capsule State
  isCapsule5Min = signal(false);
  capsuleSecondsLeft = signal(300);
  capsuleNotes = '';
  capsulePdfName = '';
  capsulePdfUrl = '';
  showCapsuleConfigModal = signal(false);
  capsuleCourseId = 'general';
  capsuleTitle = 'Capsule 5 min : Synthèse & Démonstration';
  private capsuleInterval: any = null;
  recordedVideoUrl = signal<string | null>(null);
  private mediaRecorder: MediaRecorder | null = null;
  private recordedChunks: Blob[] = [];

  capsuleTimerFormatted = computed(() => {
    const s = this.capsuleSecondsLeft();
    const mins = Math.floor(s / 60);
    const secs = s % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  });

  // Whiteboard State
  wbTool: 'pen' | 'highlighter' | 'eraser' | 'rect' = 'pen';
  wbColor = '#2563EB';
  wbLineWidth = 4;
  wbColors = ['#000000', '#2563EB', '#DC2626', '#059669', '#7C3AED', '#D97706', '#FFFFFF'];
  private isDrawing = false;
  private lastX = 0;
  private lastY = 0;

  chatMessages = signal<LiveChatMessage[]>([
    { id: '1', sender: 'Système', text: 'La salle de réunion est ouverte. Bienvenue à tous !', time: 'Direct', isTeacher: true },
    { id: '2', sender: 'Moussa Diop', text: 'Bonjour Monsieur, nous vous entendons très bien !', time: '10:02' },
    { id: '3', sender: 'Fatou Kiné', text: 'Bonjour ! Le tableau blanc est bien visible.', time: '10:03' },
  ]);
  newChatMessage = '';

  mockLiveStudents = [
    { id: '1', name: 'Moussa Diop' },
    { id: '2', name: 'Fatou Kiné Diagne' },
    { id: '3', name: 'Maimouna Kane' },
    { id: '4', name: 'Adjaratou Gueye' },
    { id: '5', name: 'Mame Diarra Thiaw' },
  ];

  liveForm = this.fb.group({
    title: ['Visioconférence interactive & Correction'],
    courseId: ['general'],
    scheduledAt: [this.getDefaultDateTimeString()],
  });

  liveTimerFormatted = computed(() => {
    const s = this.liveTimerSeconds();
    const hrs = Math.floor(s / 3600);
    const mins = Math.floor((s % 3600) / 60);
    const secs = s % 60;
    return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  });

  ngOnInit(): void {
    const safetyTimer = setTimeout(() => {
      if (this.loading()) {
        this.loading.set(false);
      }
    }, 1500);

    this.store.select(selectCurrentUser).pipe(
      switchMap(user => {
        this.currentUser = user;
        if (!user) return of({ sessions: [], courses: [] });

        return combineLatest({
          sessions: this.livekitService.getTeacherSessions(user.uid).pipe(catchError(() => of([]))),
          courses: this.courseService.getTeacherCourses(user.uid).pipe(catchError(() => of([])))
        });
      }),
      timeout({
        first: 3000,
        with: () => of({ sessions: [], courses: [] })
      }),
      catchError(err => {
        console.warn('LiveManager load error:', err);
        return of({ sessions: [], courses: [] });
      })
    ).subscribe(({ sessions, courses }) => {
      clearTimeout(safetyTimer);
      this.sessions.set(sessions || []);
      this.courses.set(courses || []);
      this.loading.set(false);
    });
  }

  ngOnDestroy(): void {
    this.stopMediaStream();
    this.stopMediaRecorder();
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
    if (this.capsuleInterval) {
      clearInterval(this.capsuleInterval);
    }
    if (this.studioSessionSub) {
      this.studioSessionSub.unsubscribe();
    }
  }

  openCapsuleModal(): void {
    this.capsuleTitle = 'Capsule 5 min : Synthèse & Démonstration';
    this.showCapsuleConfigModal.set(true);
  }

  async start5MinCapsule(): Promise<void> {
    this.showCapsuleConfigModal.set(false);
    const now = new Date();
    const teacherUid = this.currentUser?.uid || 'teacher_anonymous';
    const teacherName = this.currentUser?.displayName || 'Formateur';
    const course = this.courses().find(c => c.id === this.capsuleCourseId);
    const courseName = course ? course.title : 'Formation Générale';

    try {
      const sessionId = await this.livekitService.createSession(
        this.capsuleCourseId,
        this.capsuleTitle,
        now,
        teacherUid,
        teacherName,
        courseName,
        this.currentUser?.photoURL || ''
      );

      await this.livekitService.startSession(sessionId);

      const sessionObj: LiveSession = {
        id: sessionId,
        courseId: this.capsuleCourseId,
        courseName,
        teacherId: teacherUid,
        teacherName,
        teacherPhotoURL: this.currentUser?.photoURL,
        title: this.capsuleTitle,
        scheduledAt: now as any,
        status: 'live',
        isFlash5Min: true,
        pdfDocUrl: this.capsulePdfUrl,
        pdfDocName: this.capsulePdfName,
        notes: this.capsuleNotes,
        roomName: `live_capsule_${Date.now()}`
      };

      this.sessions.update(list => [sessionObj, ...list]);
      this.isCapsule5Min.set(true);
      this.capsuleSecondsLeft.set(300);

      this.joinVirtualStudio(sessionObj);

      // Verrouiller tous les micros des étudiants par défaut
      await this.livekitService.muteAllStudents(sessionId);

      // Démarrage de l'enregistrement MediaRecorder
      setTimeout(() => this.startMediaRecorder(), 1200);

      this.notificationService.notifyEnrolledStudentsForLive(
        this.capsuleCourseId,
        courseName,
        teacherName,
        this.capsuleTitle,
        sessionId,
        false
      ).then(count => {
        this.toastr.success(`⏱️ Capsule 5 minutes lancée ! ${count} apprenant(s) notifié(s).`);
      });

    } catch (e) {
      this.toastr.error('Erreur lors du lancement de la capsule.');
    }
  }

  onPdfFileSelected(event: any): void {
    const file = event.target.files?.[0];
    if (!file) return;
    this.capsulePdfName = file.name;
    this.capsulePdfUrl = URL.createObjectURL(file);
    this.toastr.info(`Document PDF "${file.name}" attaché.`);
  }

  async publishNotesAndPdf(): Promise<void> {
    const s = this.activeStudioSession();
    if (!s) return;

    try {
      await this.livekitService.updateSessionData(s.id, {
        notes: this.capsuleNotes,
        pdfDocUrl: this.capsulePdfUrl,
        pdfDocName: this.capsulePdfName
      });

      const pdfInfo = this.capsulePdfName ? `\n📄 Document PDF joint : "${this.capsulePdfName}"` : '';
      const notesInfo = this.capsuleNotes ? `\n📝 Notes : ${this.capsuleNotes}` : '';
      const announceText = `📢 [Notes & Support du Professeur]${notesInfo}${pdfInfo}`;

      this.chatMessages.update(msgs => [
        ...msgs,
        {
          id: String(Date.now()),
          sender: this.currentUser?.displayName || 'Professeur',
          text: announceText,
          time: 'Direct',
          isTeacher: true
        }
      ]);

      this.toastr.success('Notes et document PDF publiés avec succès aux apprenants !');
    } catch {
      this.toastr.error('Erreur lors de la publication.');
    }
  }

  startMediaRecorder(): void {
    try {
      const stream = this.localMediaStream || this.localVideoRef?.nativeElement?.srcObject;
      if (stream && typeof MediaRecorder !== 'undefined') {
        this.recordedChunks = [];
        const mime = MediaRecorder.isTypeSupported('video/webm;codecs=vp9')
          ? 'video/webm;codecs=vp9'
          : (MediaRecorder.isTypeSupported('video/mp4') ? 'video/mp4' : 'video/webm');
        this.mediaRecorder = new MediaRecorder(stream as MediaStream, { mimeType: mime });
        this.mediaRecorder.ondataavailable = (e) => {
          if (e.data && e.data.size > 0) this.recordedChunks.push(e.data);
        };
        this.mediaRecorder.onstop = () => {
          const blob = new Blob(this.recordedChunks, { type: mime });
          this.recordedVideoUrl.set(URL.createObjectURL(blob));
        };
        this.mediaRecorder.start(1000);
      }
    } catch (e) {
      console.warn('MediaRecorder not available:', e);
    }
  }

  stopMediaRecorder(): void {
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      try {
        this.mediaRecorder.stop();
      } catch (e) {
        console.warn('Error stopping MediaRecorder:', e);
      }
    }
  }

  downloadRecordedVideo(): void {
    const url = this.recordedVideoUrl();
    if (!url) return;
    const a = document.createElement('a');
    a.href = url;
    a.download = `capsule_video_5min_${Date.now()}.webm`;
    a.click();
    this.toastr.success('Téléchargement de la vidéo lancé.');
  }

  getDefaultDateTimeString(): string {
    const now = new Date();
    now.setMinutes(now.getMinutes() + 15);
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, '0');
    const dd = String(now.getDate()).padStart(2, '0');
    const hh = String(now.getHours()).padStart(2, '0');
    const min = String(now.getMinutes()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}T${hh}:${min}`;
  }

  getNextLiveTime(): string {
    const scheduled = this.sessions().find(s => s.status === 'scheduled');
    if (!scheduled || !scheduled.scheduledAt) return 'Aucun';
    const date = scheduled.scheduledAt.toDate ? scheduled.scheduledAt.toDate() : new Date(scheduled.scheduledAt as any);
    return `${date.getDate().toString().padStart(2, '0')}/${(date.getMonth() + 1).toString().padStart(2, '0')} à ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  getEndedCount(): number {
    return this.sessions().filter(s => s.status === 'ended').length;
  }

  scrollToSchedule(): void {
    document.querySelector('aside')?.scrollIntoView({ behavior: 'smooth' });
  }

  async startInstantMeeting(): Promise<void> {
    const now = new Date();
    const dateStr = `${now.getDate().toString().padStart(2, '0')}/${(now.getMonth() + 1).toString().padStart(2, '0')}`;
    const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    const instantTitle = `Cours en direct du ${dateStr} à ${timeStr}`;

    const teacherUid = this.currentUser?.uid || 'teacher_anonymous';
    const teacherName = this.currentUser?.displayName || 'Formateur';

    try {
      const sessionId = await this.livekitService.createSession(
        'general',
        instantTitle,
        now,
        teacherUid,
        teacherName,
        'Formation Générale'
      );

      await this.livekitService.startSession(sessionId);

      const sessionObj: LiveSession = {
        id: sessionId,
        courseId: 'general',
        courseName: 'Formation Générale',
        teacherId: teacherUid,
        teacherName,
        title: instantTitle,
        scheduledAt: now as any,
        status: 'live',
        roomName: `live_instant_${Date.now()}`
      };

      this.sessions.update(list => [sessionObj, ...list]);
      this.joinVirtualStudio(sessionObj);

      // Notification automatique aux apprenants
      this.notificationService.notifyEnrolledStudentsForLive(
        'general',
        'Formation Générale',
        teacherName,
        instantTitle,
        sessionId,
        false
      ).then(count => {
        this.toastr.success(`🔴 En direct ! ${count} apprenant(s) notifié(s) automatiquement.`);
      });

    } catch (e) {
      this.toastr.error('Erreur lors du démarrage du Live.');
    }
  }

  async scheduleLive(): Promise<void> {
    if (this.liveForm.invalid || !this.currentUser) return;

    this.scheduling.set(true);
    const form = this.liveForm.value;
    const course = this.courses().find(c => c.id === form.courseId);

    try {
      const scheduledDate = new Date(form.scheduledAt!);
      const sessionId = await this.livekitService.createSession(
        form.courseId!,
        form.title!,
        scheduledDate,
        this.currentUser.uid,
        this.currentUser.displayName || 'Formateur',
        course?.title || 'Formation Générale'
      );

      this.toastr.success('Session planifiée avec succès !');
      this.liveForm.reset({
        title: 'Visioconférence interactive & Q&A',
        courseId: 'general',
        scheduledAt: this.getDefaultDateTimeString(),
      });
    } catch (e) {
      this.toastr.error('Erreur lors de la planification.');
    } finally {
      this.scheduling.set(false);
    }
  }

  joinVirtualStudio(session: LiveSession): void {
    this.activeStudioSession.set(session);
    this.viewMode.set('video');
    this.startMediaStream();

    this.liveTimerSeconds.set(0);
    if (this.timerInterval) clearInterval(this.timerInterval);
    this.timerInterval = setInterval(() => {
      this.liveTimerSeconds.update(s => s + 1);
    }, 1000);

    // 5-Minute Capsule countdown timer
    if (this.capsuleInterval) clearInterval(this.capsuleInterval);
    if (session.isFlash5Min) {
      this.isCapsule5Min.set(true);
      this.capsuleSecondsLeft.set(300);
      this.capsuleInterval = setInterval(() => {
        this.capsuleSecondsLeft.update(s => {
          if (s <= 1) {
            clearInterval(this.capsuleInterval);
            this.toastr.info('⏱️ Les 5 minutes sont écoulées ! Finalisation automatique de la capsule.');
            this.endStudioLive();
            return 0;
          }
          if (s === 61) {
            this.toastr.warning('⚠️ Attention : plus qu\'une minute pour votre capsule vidéo !');
          }
          return s - 1;
        });
      }, 1000);
    } else {
      this.isCapsule5Min.set(false);
    }

    if (this.studioSessionSub) this.studioSessionSub.unsubscribe();
    this.studioSessionSub = this.livekitService.getLiveSessionById(session.id).subscribe(updated => {
      if (updated) {
        this.activeStudioSession.set(updated);
      }
    });
  }

  async grantSpeaking(studentId: string, studentName?: string): Promise<void> {
    const s = this.activeStudioSession();
    if (!s) return;
    await this.livekitService.grantSpeakingPermission(s.id, studentId);
    this.toastr.success(`🎙️ Parole accordée à ${studentName || 'l\'étudiant'}`);
  }

  async revokeSpeaking(studentId: string, studentName?: string): Promise<void> {
    const s = this.activeStudioSession();
    if (!s) return;
    await this.livekitService.revokeSpeakingPermission(s.id, studentId);
    this.toastr.info(`🔇 Micro coupé pour ${studentName || 'l\'étudiant'}`);
  }

  async muteAll(): Promise<void> {
    const s = this.activeStudioSession();
    if (!s) return;
    await this.livekitService.muteAllStudents(s.id);
    this.toastr.warning('🔇 Tous les micros des apprenants ont été coupés.');
  }

  async lowerHand(studentId: string): Promise<void> {
    const s = this.activeStudioSession();
    if (!s) return;
    await this.livekitService.lowerHand(s.id, studentId);
  }

  isHandRaisedByUid(uid: string): boolean {
    const hands = this.activeStudioSession()?.raisedHands || [];
    return hands.some(h => h.uid === uid);
  }

  getStudentDisplayName(uid: string): string {
    const hand = (this.activeStudioSession()?.raisedHands || []).find(h => h.uid === uid);
    if (hand) return hand.displayName;
    const mock = this.mockLiveStudents.find(m => m.id === uid);
    if (mock) return mock.name;
    return 'Étudiant';
  }

  async endStudioLive(): Promise<void> {
    if (this.capsuleInterval) {
      clearInterval(this.capsuleInterval);
      this.capsuleInterval = null;
    }
    this.stopMediaRecorder();

    const s = this.activeStudioSession();
    if (s) {
      const mins = this.isCapsule5Min() ? 5 : Math.max(1, Math.floor(this.liveTimerSeconds() / 60));
      const durationStr = `${mins} min`;

      await this.livekitService.endSessionWithReplay(s.id, this.recordedVideoUrl() || undefined, durationStr);
      await this.livekitService.updateSessionData(s.id, {
        notes: this.capsuleNotes,
        pdfDocUrl: this.capsulePdfUrl,
        pdfDocName: this.capsulePdfName,
        isFlash5Min: this.isCapsule5Min()
      });

      // Si rattaché à un cours, ajouter automatiquement la leçon avec formats Vidéo & PDF
      if (s.courseId && s.courseId !== 'general') {
        try {
          await this.courseService.addLesson(s.courseId, {
            title: s.title,
            description: `Capsule vidéo (${durationStr}) avec support PDF d'appui et tableau blanc. ${this.capsuleNotes ? 'Notes de synthèse incluses.' : ''}`,
            type: 'video',
            videoUrl: this.recordedVideoUrl() || s.replayUrl || 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            pdfUrl: this.capsulePdfUrl || '',
            pdfDocName: this.capsulePdfName || 'Support PDF du cours',
            notes: this.capsuleNotes || '',
            duration: mins * 60,
            isFree: true,
            order: 99
          } as any);
        } catch (err) {
          console.warn('Could not auto-add lesson to course:', err);
        }
      }

      this.sessions.update(list => list.map(item => item.id === s.id ? {
        ...item,
        status: 'ended',
        hasReplay: true,
        replayDuration: durationStr,
        notes: this.capsuleNotes,
        pdfDocUrl: this.capsulePdfUrl,
        pdfDocName: this.capsulePdfName
      } : item));
      
      // Notifier les apprenants que le replay est disponible
      this.notificationService.notifyEnrolledStudentsForLive(
        s.courseId,
        s.courseName,
        s.teacherName,
        s.title,
        s.id,
        true
      ).then(() => {
        this.toastr.success(`🎥 ${this.isCapsule5Min() ? 'Capsule 5 min sauvegardée' : 'Live terminé'} & Replay généré (${durationStr}) ! Les apprenants ont été notifiés.`);
      });
    }
    this.stopMediaStream();
    if (this.timerInterval) clearInterval(this.timerInterval);
    if (this.studioSessionSub) {
      this.studioSessionSub.unsubscribe();
      this.studioSessionSub = null;
    }
    this.activeStudioSession.set(null);
  }

  async startMediaStream(): Promise<void> {
    try {
      this.localMediaStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      setTimeout(() => {
        if (this.localVideoRef?.nativeElement && this.localMediaStream) {
          this.localVideoRef.nativeElement.srcObject = this.localMediaStream;
        }
      }, 300);
    } catch (err) {
      console.warn('Cam/mic not allowed or not available:', err);
    }
  }

  stopMediaStream(): void {
    if (this.localMediaStream) {
      this.localMediaStream.getTracks().forEach(track => track.stop());
      this.localMediaStream = null;
    }
  }

  toggleMicrophone(): void {
    this.isMuted.update(m => !m);
    if (this.localMediaStream) {
      this.localMediaStream.getAudioTracks().forEach(t => t.enabled = !this.isMuted());
    }
  }

  toggleCamera(): void {
    this.isCameraOff.update(c => !c);
    if (this.localMediaStream) {
      this.localMediaStream.getVideoTracks().forEach(t => t.enabled = !this.isCameraOff());
    }
  }

  async toggleScreenShare(): Promise<void> {
    if (this.isScreenSharing()) {
      this.isScreenSharing.set(false);
      this.startMediaStream();
    } else {
      try {
        const screenStream = await navigator.mediaDevices.getDisplayMedia({ video: true });
        this.isScreenSharing.set(true);
        if (this.localVideoRef?.nativeElement) {
          this.localVideoRef.nativeElement.srcObject = screenStream;
        }
        screenStream.getVideoTracks()[0].onended = () => {
          this.isScreenSharing.set(false);
          this.startMediaStream();
        };
      } catch (e) {
        this.isScreenSharing.set(false);
      }
    }
  }

  // ─── Whiteboard Methods ────────────────────────────────────────

  switchToWhiteboard(): void {
    this.viewMode.set('whiteboard');
    setTimeout(() => this.initWhiteboard(), 100);
  }

  private initWhiteboard(): void {
    const canvas = this.whiteboardCanvasRef?.nativeElement;
    if (!canvas) return;

    canvas.width = canvas.parentElement?.clientWidth || 900;
    canvas.height = canvas.parentElement?.clientHeight || 600;

    const ctx = canvas.getContext('2d');
    if (ctx) {
      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }
  }

  startDrawing(e: MouseEvent): void {
    this.isDrawing = true;
    const canvas = this.whiteboardCanvasRef?.nativeElement;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    this.lastX = e.clientX - rect.left;
    this.lastY = e.clientY - rect.top;
  }

  draw(e: MouseEvent): void {
    if (!this.isDrawing) return;
    const canvas = this.whiteboardCanvasRef?.nativeElement;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const currentX = e.clientX - rect.left;
    const currentY = e.clientY - rect.top;

    ctx.beginPath();
    ctx.moveTo(this.lastX, this.lastY);
    ctx.lineTo(currentX, currentY);

    if (this.wbTool === 'eraser') {
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 24;
      ctx.globalAlpha = 1.0;
    } else if (this.wbTool === 'highlighter') {
      ctx.strokeStyle = this.wbColor;
      ctx.lineWidth = 16;
      ctx.globalAlpha = 0.35;
    } else {
      ctx.strokeStyle = this.wbColor;
      ctx.lineWidth = this.wbLineWidth;
      ctx.globalAlpha = 1.0;
    }

    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.stroke();

    this.lastX = currentX;
    this.lastY = currentY;
  }

  startDrawingTouch(e: TouchEvent): void {
    if (e.touches.length > 0) {
      this.isDrawing = true;
      const canvas = this.whiteboardCanvasRef?.nativeElement;
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      this.lastX = e.touches[0].clientX - rect.left;
      this.lastY = e.touches[0].clientY - rect.top;
    }
  }

  drawTouch(e: TouchEvent): void {
    if (!this.isDrawing || e.touches.length === 0) return;
    const canvas = this.whiteboardCanvasRef?.nativeElement;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const currentX = e.touches[0].clientX - rect.left;
    const currentY = e.touches[0].clientY - rect.top;

    ctx.beginPath();
    ctx.moveTo(this.lastX, this.lastY);
    ctx.lineTo(currentX, currentY);
    ctx.strokeStyle = this.wbTool === 'eraser' ? '#FFFFFF' : this.wbColor;
    ctx.lineWidth = this.wbTool === 'eraser' ? 24 : this.wbLineWidth;
    ctx.lineCap = 'round';
    ctx.stroke();

    this.lastX = currentX;
    this.lastY = currentY;
    e.preventDefault();
  }

  stopDrawing(): void {
    this.isDrawing = false;
  }

  clearWhiteboard(): void {
    if (!confirm('Voulez-vous effacer tout le tableau blanc ?')) return;
    this.initWhiteboard();
    this.toastr.info('Tableau blanc réinitialisé.');
  }

  exportWhiteboardImage(): void {
    const canvas = this.whiteboardCanvasRef?.nativeElement;
    if (!canvas) return;

    const link = document.createElement('a');
    link.download = `tableau_blanc_${Date.now()}.png`;
    link.href = canvas.toDataURL('image/png');
    link.click();
    this.toastr.success('Image du tableau téléchargée avec succès !');
  }

  sendChatMessage(): void {
    const text = this.newChatMessage.trim();
    if (!text) return;

    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    this.chatMessages.update(msgs => [
      ...msgs,
      {
        id: Date.now().toString(),
        sender: this.currentUser?.displayName || 'Professeur',
        text,
        time: timeStr,
        isTeacher: true
      }
    ]);
    this.newChatMessage = '';
  }
}
