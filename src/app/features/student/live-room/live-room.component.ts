import { Component, inject, OnInit, OnDestroy, signal, computed, ElementRef, ViewChild } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { Subscription } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { LivekitService } from '../../../core/services/livekit.service';
import { LiveSession, User } from '../../../core/models';
import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-student-live-room',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule, DatePipe, BackButtonComponent],
  template: `
    <div class="min-h-screen bg-[#0B0F19] text-white flex flex-col font-body select-none">
      
      <!-- Top Navigation Bar -->
      <header class="h-16 px-3 sm:px-6 bg-[#111827] border-b border-slate-800 flex items-center justify-between shrink-0 z-20">
        
        <!-- Left: Live Badge & Title -->
        <div class="flex items-center gap-2.5 sm:gap-4 min-w-0">
          <app-back-button label="Quitter" defaultRoute="/student/lives" variant="dark" [showIconOnlyOnMobile]="true" />

          <div class="flex items-center gap-2 shrink-0">
            @if (session()?.status === 'live') {
              <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-500/20 border border-red-500/40 text-red-400 text-xs font-black uppercase tracking-wider animate-pulse">
                <span class="w-2 h-2 rounded-full bg-red-500"></span>
                EN DIRECT
              </span>
            } @else if (session()?.status === 'ended') {
              <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-500/20 border border-amber-500/40 text-amber-400 text-xs font-bold uppercase tracking-wider">
                ● TERMINÉ
              </span>
            } @else {
              <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/20 border border-blue-500/40 text-blue-400 text-xs font-bold uppercase tracking-wider">
                ● PROGRAMMÉ
              </span>
            }
          </div>

          <div class="min-w-0">
            <h1 class="font-display text-sm sm:text-base font-bold text-white truncate">
              {{ session()?.title || 'Cours en direct' }}
            </h1>
            <p class="text-[11px] text-slate-400 truncate flex items-center gap-2">
              <span>{{ session()?.courseName || 'Formation' }}</span>
              <span>•</span>
              <span>Prof. {{ session()?.teacherName || 'Formateur' }}</span>
            </p>
          </div>
        </div>

        <!-- Right: Participant Count & Actions -->
        <div class="flex items-center gap-3 shrink-0">
          <div class="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-800/80 border border-slate-700 text-xs text-slate-300 font-medium">
            <svg class="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
            </svg>
            <span><strong class="text-white">{{ connectedCount() }}</strong> en ligne</span>
          </div>

          <button (click)="leaveLive()"
                  class="px-4 py-2 bg-red-600/90 hover:bg-red-600 text-white rounded-xl text-xs font-bold transition-all shadow-md shadow-red-600/20 flex items-center gap-1.5 cursor-pointer">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
            </svg>
            <span class="hidden sm:inline">Quitter</span>
          </button>
        </div>
      </header>

      <!-- Notification Banners: Raised Hand & Speaking Permission Granted -->
      @if (canSpeak()) {
        <div class="bg-emerald-600 px-4 py-2.5 text-white text-xs font-bold flex items-center justify-between shadow-lg animate-bounce-short z-20">
          <div class="flex items-center gap-2.5">
            <span class="flex h-3 w-3 relative">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
              <span class="relative inline-flex rounded-full h-3 w-3 bg-white"></span>
            </span>
            <span>🎙️ Le professeur vous a accordé la parole ! Votre micro est maintenant déverrouillé ci-dessous.</span>
          </div>
          <span class="text-[11px] bg-black/20 px-2.5 py-0.5 rounded-full uppercase tracking-wider">Parole Accordée</span>
        </div>
      } @else if (isHandRaised()) {
        <div class="bg-amber-500/95 text-slate-950 px-4 py-2 text-xs font-bold flex items-center justify-between z-20">
          <div class="flex items-center gap-2">
            <svg class="w-4 h-4 text-slate-950 animate-bounce" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11" />
            </svg>
            <span>Votre main est levée. Le professeur a été notifié et va vous donner la parole.</span>
          </div>
          <button (click)="toggleRaiseHand()" class="text-xs font-black underline hover:text-white cursor-pointer">
            Baisser la main
          </button>
        </div>
      }

      <!-- Main Live Workspace Layout -->
      <div class="flex-1 flex flex-col lg:flex-row overflow-hidden relative">
        
        <!-- Left: Stage (Video Stream / Whiteboard Viewer) -->
        <main class="flex-1 flex flex-col bg-black relative overflow-hidden">
          
          <!-- Stage View Toggle Tabs -->
          <div class="absolute top-4 left-4 z-10 flex items-center gap-2 bg-slate-900/90 backdrop-blur-md p-1 rounded-xl border border-slate-700">
            <button (click)="activeStageView.set('video')"
                    [class.bg-primary]="activeStageView() === 'video'"
                    [class.text-white]="activeStageView() === 'video'"
                    [class.text-slate-400]="activeStageView() !== 'video'"
                    class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
              <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
              </svg>
              <span>Flux Vidéo HD</span>
            </button>

            <button (click)="activeStageView.set('whiteboard')"
                    [class.bg-primary]="activeStageView() === 'whiteboard'"
                    [class.text-white]="activeStageView() === 'whiteboard'"
                    [class.text-slate-400]="activeStageView() !== 'whiteboard'"
                    class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
              <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
              </svg>
              <span>Tableau Blanc</span>
            </button>

            <button (click)="activeStageView.set('notes_pdf')"
                    [class.bg-primary]="activeStageView() === 'notes_pdf'"
                    [class.text-white]="activeStageView() === 'notes_pdf'"
                    [class.text-slate-400]="activeStageView() !== 'notes_pdf'"
                    class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
              <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
              </svg>
              <span>Notes & Support PDF</span>
            </button>
          </div>

          <!-- Video Stage Content -->
          @if (activeStageView() === 'video') {
            <div class="flex-1 flex items-center justify-center relative p-4 bg-gradient-to-b from-[#0F172A] to-black">
              
              @if (session()?.status === 'ended') {
                <!-- Ended State Banner -->
                <div class="max-w-md p-8 bg-slate-900/90 border border-slate-800 rounded-3xl text-center space-y-4 animate-fade-in">
                  <div class="w-16 h-16 rounded-full bg-amber-500/20 text-amber-400 flex items-center justify-center mx-auto">
                    <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                    </svg>
                  </div>
                  <h2 class="font-display text-xl font-bold text-white">Le cours en direct est terminé</h2>
                  <p class="text-xs text-slate-400 leading-relaxed">
                    L'enregistrement a été sauvegardé. Vous pouvez dès à présent visionner la rediffusion complète.
                  </p>
                  <div class="flex items-center justify-center gap-3 pt-2">
                    <a routerLink="/student/lives" class="px-5 py-2.5 bg-primary hover:bg-primary-600 text-white rounded-xl text-xs font-bold transition-all shadow-md">
                      Accéder au Replay
                    </a>
                  </div>
                </div>
              } @else {
                <!-- Live Teacher Stage -->
                <div class="w-full max-w-4xl aspect-video bg-slate-900 rounded-2xl overflow-hidden relative border border-slate-800 shadow-2xl flex items-center justify-center group">
                  
                  <div class="absolute inset-0 bg-gradient-to-tr from-slate-950 via-slate-900 to-indigo-950 flex flex-col items-center justify-center p-6 text-center">
                    <div class="relative mb-4">
                      <div class="w-24 h-24 rounded-2xl bg-primary/20 border-2 border-primary overflow-hidden shadow-xl shadow-primary/20 flex items-center justify-center">
                        <img loading="lazy" decoding="async" [src]="session()?.teacherPhotoURL || 'assets/default-avatar.png'"
                             class="w-full h-full object-cover"
                             alt="Photo formateur"
                             onerror="this.src='assets/default-avatar.png'">
                      </div>
                      <span class="absolute bottom-0 right-0 h-7 w-7 rounded-xl bg-emerald-500 ring-4 ring-slate-900 flex items-center justify-center text-white" title="Enseignant Hôte">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                        </svg>
                      </span>
                    </div>

                    <h3 class="font-display text-lg font-bold text-white">{{ session()?.teacherName || 'Formateur' }}</h3>
                    <p class="text-xs text-primary font-semibold mt-0.5">{{ session()?.courseName }}</p>
                    
                    <div class="mt-4 flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-800/80 border border-slate-700 text-xs text-slate-300">
                      <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                      <span>Micro & Caméra du Professeur Actifs • En direct</span>
                    </div>
                  </div>

                  <!-- Overlay Bottom Controls -->
                  <div class="absolute bottom-4 left-4 right-4 flex items-center justify-between pointer-events-none">
                    <div class="px-3 py-1.5 rounded-xl bg-black/60 backdrop-blur-md text-xs font-medium text-white flex items-center gap-2">
                      <span class="text-red-400 font-bold flex items-center gap-1">
                        <span class="w-2 h-2 rounded-full bg-red-500 animate-ping"></span>
                        REC
                      </span>
                      <span>Enregistrement automatique en cours</span>
                    </div>
                  </div>
                </div>
              }

            </div>
          } @else if (activeStageView() === 'whiteboard') {
            <!-- Whiteboard Viewer -->
            <div class="flex-1 flex flex-col items-center justify-center p-4 bg-slate-950">
              <div class="w-full max-w-4xl aspect-video bg-white rounded-2xl overflow-hidden relative shadow-2xl border border-slate-800 flex flex-col">
                <div class="p-3 bg-slate-100 border-b border-slate-200 flex items-center justify-between text-xs text-slate-700 font-bold">
                  <div class="flex items-center gap-2">
                    <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/>
                    </svg>
                    <span>Tableau Blanc Partagé du Formateur</span>
                  </div>
                  <span class="text-[11px] text-slate-500">Synchronisé en temps réel</span>
                </div>
                <div class="flex-1 bg-white flex items-center justify-center p-8 text-center text-slate-400">
                  <div>
                    <div class="w-12 h-12 rounded-2xl bg-purple-100 text-purple-600 flex items-center justify-center mx-auto mb-3">
                      <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </div>
                    <p class="text-xs font-bold text-slate-700">Tableau Blanc Interactif Actif</p>
                    <p class="text-[11px] text-slate-400 mt-1">Les schémas, formules et explications du formateur s'affichent ici.</p>
                  </div>
                </div>
              </div>
            </div>
          } @else if (activeStageView() === 'notes_pdf') {
            <!-- Notes and Attached PDF Viewer -->
            <div class="flex-1 flex flex-col p-4 sm:p-6 bg-slate-950 overflow-y-auto">
              <div class="max-w-3xl mx-auto w-full space-y-4">
                
                <!-- Attached PDF Card -->
                <div class="p-4 rounded-2xl bg-slate-900 border border-slate-800 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 shadow-md">
                  <div>
                    <span class="text-[10px] font-bold text-primary uppercase tracking-wider">Document d'accompagnement</span>
                    <h3 class="font-bold text-white text-sm mt-0.5">{{ session()?.pdfDocName || 'Document Support de cours PDF' }}</h3>
                  </div>
                  @if (session()?.pdfDocUrl) {
                    <a [href]="session()?.pdfDocUrl" target="_blank" download
                       class="px-4 py-2 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-xs flex items-center justify-center gap-1.5 cursor-pointer">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                      </svg>
                      <span>Télécharger le PDF</span>
                    </a>
                  } @else {
                    <span class="text-xs text-slate-500 italic">Aucun PDF joint pour l'instant</span>
                  }
                </div>

                <!-- Teacher Notes Card -->
                <div class="p-5 rounded-2xl bg-slate-900 border border-slate-800 space-y-2 shadow-md">
                  <h4 class="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                    <span>📝 Notes de synthèse transmises par le professeur :</span>
                  </h4>
                  <p class="text-xs text-slate-300 whitespace-pre-wrap leading-relaxed">
                    {{ session()?.notes || 'Le formateur n\'a pas encore rédigé de notes pour cette session. Vous pouvez poser vos questions par message dans la discussion.' }}
                  </p>
                </div>

              </div>
            </div>
          }

          <!-- Student Interactive Control Bar (100% SVG, Teacher Mic Lock Enforcement) -->
          <footer class="h-20 bg-[#111827] border-t border-slate-800 px-4 sm:px-8 flex items-center justify-center sm:justify-between shrink-0 z-20">
            
            <!-- Left Info (Desktop) -->
            <div class="hidden sm:flex items-center gap-3 text-xs text-slate-400">
              <span class="w-2.5 h-2.5 rounded-full" [class.bg-emerald-500]="canSpeak()" [class.bg-slate-600]="!canSpeak()"></span>
              <span>
                @if (session()?.isFlash5Min) {
                  Capsule 5 min : Réponse par message textuel uniquement
                } @else {
                  {{ canSpeak() ? 'Parole autorisée par le formateur' : 'Micro sous contrôle du professeur' }}
                }
              </span>
            </div>

            <!-- Central Control Buttons -->
            <div class="flex items-center gap-3 sm:gap-4">
              
              <!-- 1. Bouton Lever / Baisser la main (désactivé si mode capsule 5 min) -->
              @if (session()?.isFlash5Min) {
                <div class="px-4 py-2.5 rounded-2xl bg-purple-950/50 border border-purple-500/30 text-purple-300 text-xs font-bold flex items-center gap-2">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                  </svg>
                  <span>Échanges par message</span>
                </div>
              } @else {
                <button (click)="toggleRaiseHand()"
                        [class.bg-amber-500]="isHandRaised()"
                        [class.text-slate-950]="isHandRaised()"
                        [class.border-amber-400]="isHandRaised()"
                        [class.bg-slate-800]="!isHandRaised()"
                        [class.text-white]="!isHandRaised()"
                        [class.border-slate-700]="!isHandRaised()"
                        class="px-4 py-2.5 rounded-2xl border transition-all active:scale-95 shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer"
                        [title]="isHandRaised() ? 'Baisser la main' : 'Lever la main pour demander la parole'">
                  <svg class="w-5 h-5 shrink-0" [class.animate-bounce]="isHandRaised()" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11" />
                  </svg>
                  <span>{{ isHandRaised() ? 'Baisser la main ✋' : 'Lever la main' }}</span>
                </button>
              }

              <!-- 2. Bouton Micro (Verrouillé en mode capsule ou par défaut) -->
              @if (session()?.isFlash5Min) {
                <button class="px-4 py-2.5 rounded-2xl bg-slate-800/80 border border-slate-700/80 text-slate-500 text-xs font-bold flex items-center gap-2 cursor-not-allowed"
                        title="En mode capsule vidéo 5 min, les étudiants répondent uniquement par message textuel.">
                  <svg class="w-5 h-5 text-slate-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                    <line x1="1" y1="1" x2="23" y2="23" stroke="currentColor" stroke-width="2" />
                  </svg>
                  <span>Micro Verrouillé</span>
                </button>
              } @else if (!canSpeak()) {
                <button (click)="onLockedMicClick()"
                        class="px-4 py-2.5 rounded-2xl bg-slate-800/80 border border-slate-700/80 text-slate-400 opacity-80 hover:opacity-100 transition-all flex items-center gap-2 text-xs font-bold cursor-not-allowed"
                        title="Seul le professeur peut ouvrir votre micro. Levez la main pour demander la parole.">
                  <svg class="w-5 h-5 text-red-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                  <span class="hidden sm:inline">Micro Verrouillé</span>
                  <span class="sm:hidden">Verrouillé</span>
                </button>
              } @else {
                <button (click)="toggleMicrophone()"
                        [class.bg-emerald-600]="!isMuted()"
                        [class.bg-red-600]="isMuted()"
                        class="px-4 py-2.5 rounded-2xl text-white transition-all active:scale-95 shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer">
                  @if (!isMuted()) {
                    <svg class="w-5 h-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                    </svg>
                    <span>Micro Ouvert</span>
                  } @else {
                    <svg class="w-5 h-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                      <line x1="1" y1="1" x2="23" y2="23" stroke="currentColor" stroke-width="2" />
                    </svg>
                    <span>Micro Coupé</span>
                  }
                </button>
              }

              <!-- 3. Bouton Caméra (Uniquement si parole accordée) -->
              @if (canSpeak()) {
                <button (click)="toggleCamera()"
                        [class.bg-slate-800]="isCameraOff()"
                        [class.bg-primary]="!isCameraOff()"
                        class="px-3.5 py-2.5 rounded-2xl border border-slate-700 text-white transition-all active:scale-95 shadow-md flex items-center gap-2 text-xs font-bold cursor-pointer">
                  <svg class="w-5 h-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                  <span class="hidden sm:inline">{{ isCameraOff() ? 'Caméra Off' : 'Caméra On' }}</span>
                </button>
              }

            </div>

            <!-- Right: Leave shortcut -->
            <div class="hidden sm:block">
              <button (click)="leaveLive()"
                      class="px-3.5 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold transition-all cursor-pointer">
                Quitter la session
              </button>
            </div>

          </footer>

        </main>

        <!-- Right: Interactive Live Chat & Audience -->
        <aside class="w-full lg:w-80 xl:w-96 bg-[#111827] border-t lg:border-t-0 lg:border-l border-slate-800 flex flex-col shrink-0 h-80 lg:h-auto">
          
          <!-- Tabs: Chat & Participants -->
          <div class="p-3 border-b border-slate-800 flex items-center justify-between bg-slate-900/50">
            <div class="flex items-center gap-2">
              <button (click)="activeSideTab.set('chat')"
                      [class.text-white]="activeSideTab() === 'chat'"
                      [class.border-primary]="activeSideTab() === 'chat'"
                      [class.text-slate-400]="activeSideTab() !== 'chat'"
                      class="px-3 py-1.5 text-xs font-bold border-b-2 transition-all cursor-pointer">
                Discussion ({{ chatMessages().length }})
              </button>

              <button (click)="activeSideTab.set('participants')"
                      [class.text-white]="activeSideTab() === 'participants'"
                      [class.border-primary]="activeSideTab() === 'participants'"
                      [class.text-slate-400]="activeSideTab() !== 'participants'"
                      class="px-3 py-1.5 text-xs font-bold border-b-2 border-transparent transition-all cursor-pointer">
                Participants ({{ connectedCount() }})
              </button>
            </div>
          </div>

          <!-- Chat Stream -->
          @if (activeSideTab() === 'chat') {
            <div #chatContainer class="flex-1 overflow-y-auto p-4 space-y-3">
              @for (msg of chatMessages(); track msg.id) {
                <div class="space-y-1">
                  <div class="flex items-center gap-2 text-[11px] text-slate-400">
                    <span class="font-bold text-white" [class.text-primary]="msg.isTeacher">{{ msg.sender }}</span>
                    @if (msg.isTeacher) {
                      <span class="px-1.5 py-0.2 bg-primary/20 text-primary rounded text-[9px] font-bold">PROFESSEUR</span>
                    }
                    <span>{{ msg.time }}</span>
                  </div>
                  <div class="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/60 text-xs leading-relaxed text-slate-200">
                    {{ msg.text }}
                  </div>
                </div>
              }
            </div>

            <!-- Chat Input Composer -->
            <div class="p-3 bg-slate-900 border-t border-slate-800">
              <div class="flex items-center gap-2">
                <input type="text"
                       [(ngModel)]="newChatMessage"
                       (keyup.enter)="sendChatMessage()"
                       placeholder="Poser une question au formateur..."
                       class="flex-1 px-3.5 py-2 bg-slate-800 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-400 focus:outline-none focus:border-primary">
                
                <button (click)="sendChatMessage()"
                        [disabled]="!newChatMessage.trim()"
                        class="px-3.5 py-2 bg-primary hover:bg-primary-600 disabled:opacity-40 text-white rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer">
                  Envoyer
                </button>
              </div>
            </div>
          } @else {
            <!-- Participants Roster with Realtime Status -->
            <div class="flex-1 overflow-y-auto p-3 space-y-2">
              <!-- Teacher -->
              <div class="p-2.5 rounded-xl bg-primary/10 border border-primary/30 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                  <div class="w-8 h-8 rounded-full bg-primary/30 border border-primary flex items-center justify-center font-bold text-xs text-primary">
                    Prof
                  </div>
                  <div>
                    <p class="text-xs font-bold text-white">{{ session()?.teacherName || 'Formateur' }}</p>
                    <p class="text-[10px] text-primary font-bold">Hôte • Seul habilité à ouvrir les micros</p>
                  </div>
                </div>
                <span class="text-[10px] text-emerald-400 font-bold flex items-center gap-1">
                  <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                  Micro Ouvert
                </span>
              </div>

              <!-- Student list -->
              @for (name of mockStudentsList; track name) {
                <div class="p-2.5 rounded-xl bg-slate-800/50 border border-slate-700/40 flex items-center justify-between text-xs">
                  <div class="flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                    <span class="text-slate-200 font-medium">{{ name }}</span>
                  </div>
                  
                  <div class="flex items-center gap-1">
                    @if (isStudentHandRaised(name)) {
                      <span class="px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 border border-amber-500/30 text-[10px] font-bold flex items-center gap-1">
                        <span>✋ Main levée</span>
                      </span>
                    } @else if (isStudentSpeaking(name)) {
                      <span class="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 text-[10px] font-bold">
                        🎙️ Parole accordée
                      </span>
                    } @else {
                      <span class="px-2 py-0.5 rounded-full bg-slate-700/40 text-slate-400 text-[10px] flex items-center gap-1">
                        <svg class="w-3 h-3 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                        <span>Écoute seule</span>
                      </span>
                    }
                  </div>
                </div>
              }
            </div>
          }

        </aside>

      </div>

    </div>
  `,
})
export class StudentLiveRoomComponent implements OnInit, OnDestroy {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private store = inject(Store);
  private livekitService = inject(LivekitService);

  @ViewChild('chatContainer') private chatContainer!: ElementRef;

  currentUser = signal<User | null>(null);
  session = signal<LiveSession | null>(null);
  sessionId = '';

  activeStageView = signal<'video' | 'whiteboard' | 'notes_pdf'>('video');
  activeSideTab = signal<'chat' | 'participants'>('chat');

  isMuted = signal(true);
  isCameraOff = signal(true);

  connectedCount = computed(() => (this.session()?.participantCount || 0) + 1);

  // Computed properties for teacher control & hand raise
  isHandRaised = computed(() => {
    const u = this.currentUser();
    const s = this.session();
    if (!u || !s || !s.raisedHands) return false;
    return s.raisedHands.some(h => h.uid === u.uid);
  });

  canSpeak = computed(() => {
    const u = this.currentUser();
    const s = this.session();
    if (!u || !s) return false;
    if (s.isMuteAll || s.isFlash5Min) return false; // Micro verrouillé si capsule 5 min
    return (s.allowedSpeakers || []).includes(u.uid);
  });

  chatMessages = signal<Array<{ id: string; sender: string; text: string; time: string; isTeacher?: boolean }>>([
    { id: '1', sender: 'Système', text: 'Bienvenue dans la classe en direct ! Le professeur gère les micros.', time: 'Direct', isTeacher: true },
    { id: '2', sender: 'Moussa Diop', text: 'Bonjour professeur, nous vous entendons très bien !', time: '10:02' },
  ]);
  newChatMessage = '';

  mockStudentsList = ['Moussa Diop', 'Fatou Kiné Diagne', 'Maimouna Kane', 'Malick Seye', 'Adjaratou Gueye'];

  private sessionSub?: Subscription;

  ngOnInit() {
    this.sessionId = this.route.snapshot.params['id'];
    this.store.select(selectCurrentUser).subscribe(u => {
      this.currentUser.set(u);
      if (u && this.sessionId) {
        this.livekitService.joinLiveSession(this.sessionId, { uid: u.uid, displayName: u.displayName });
      }
    });

    if (this.sessionId) {
      this.sessionSub = this.livekitService.getLiveSessionById(this.sessionId).subscribe(sess => {
        this.session.set(sess);
      });
    }
  }

  ngOnDestroy() {
    if (this.sessionSub) this.sessionSub.unsubscribe();
    const user = this.currentUser();
    if (user && this.sessionId) {
      this.livekitService.leaveLiveSession(this.sessionId, user.uid);
    }
  }

  async toggleRaiseHand(): Promise<void> {
    const u = this.currentUser();
    if (!u || !this.sessionId) return;
    await this.livekitService.toggleRaiseHand(this.sessionId, {
      uid: u.uid,
      displayName: u.displayName || 'Étudiant',
      photoURL: u.photoURL || '',
    });
  }

  onLockedMicClick(): void {
    alert('🔒 Votre micro est verrouillé.\nSeul le formateur peut vous donner la parole.\n\n👉 Cliquez sur « Lever la main » pour demander la parole.');
  }

  toggleMicrophone(): void {
    if (!this.canSpeak()) {
      this.onLockedMicClick();
      return;
    }
    this.isMuted.update(v => !v);
  }

  toggleCamera(): void {
    if (!this.canSpeak()) return;
    this.isCameraOff.update(v => !v);
  }

  isStudentHandRaised(name: string): boolean {
    const hands = this.session()?.raisedHands || [];
    return hands.some(h => h.displayName === name);
  }

  isStudentSpeaking(name: string): boolean {
    const allowed = this.session()?.allowedSpeakers || [];
    // If current user
    if (this.currentUser()?.displayName === name && this.canSpeak()) return true;
    return false;
  }

  sendChatMessage() {
    const text = this.newChatMessage.trim();
    if (!text) return;
    const user = this.currentUser();
    const now = new Date();
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

    this.chatMessages.update(msgs => [
      ...msgs,
      {
        id: Date.now().toString(),
        sender: user?.displayName || 'Apprenant',
        text,
        time,
        isTeacher: false
      }
    ]);
    this.newChatMessage = '';
    setTimeout(() => {
      if (this.chatContainer) {
        this.chatContainer.nativeElement.scrollTop = this.chatContainer.nativeElement.scrollHeight;
      }
    }, 50);
  }

  leaveLive() {
    this.router.navigate(['/student/lives']);
  }
}
