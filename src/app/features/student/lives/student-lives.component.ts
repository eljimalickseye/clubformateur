import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { LivekitService } from '../../../core/services/livekit.service';
import { NotificationService } from '../../../core/services/notification.service';
import { LiveSession, User } from '../../../core/models';
import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../../shared/components/refresh-button/refresh-button.component';

@Component({
  selector: 'app-student-lives',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule, DatePipe, BackButtonComponent, RefreshButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-3.5 sm:py-6 space-y-4 sm:space-y-6 font-body animate-fade-in pb-16 sm:pb-8">
      
      <!-- Sticky Top Navigation with Back & Refresh Buttons -->
      <div class="sticky top-0 z-30 -mx-3.5 sm:-mx-6 lg:-mx-8 px-3.5 sm:px-6 lg:px-8 py-3 bg-white/95 backdrop-blur-md border-b border-slate-200/80 flex items-center justify-between shadow-2xs">
        <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" />
        <app-refresh-button />
      </div>

      <!-- Sleek Modern Hero Banner -->
      <div class="rounded-3xl bg-gradient-to-br from-slate-900 via-slate-850 to-blue-950 p-5 sm:p-7 border border-slate-800 text-white shadow-lg relative overflow-hidden">
        <div class="relative z-10 max-w-2xl space-y-2">
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-500/15 border border-red-500/30 text-red-400 text-[11px] font-bold uppercase tracking-wider">
            <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
            <span>Directs & Replays Vidéo</span>
          </div>

          <h1 class="font-display text-xl sm:text-3xl font-black text-white tracking-tight">
            Mes Cours en Direct & Replays
          </h1>

          <p class="text-xs sm:text-sm text-slate-300 leading-relaxed max-w-xl">
            Participez aux sessions interactives avec vos formateurs ou visionnez les rediffusions complètes à tout moment.
          </p>

          <!-- Notification Permission Banner (Simple & Compact) -->
          @if (!notificationEnabled()) {
            <div class="pt-2">
              <div class="p-3 rounded-2xl bg-white/10 backdrop-blur-md border border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
                <div class="flex items-center gap-2 text-xs text-slate-200">
                  <svg class="w-4 h-4 text-amber-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                  </svg>
                  <span>Recevez une alerte dès qu'un formateur démarre un direct !</span>
                </div>
                <button (click)="enableNotifications()"
                        class="px-3.5 py-1.5 bg-primary hover:bg-primary-600 text-white rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer shadow-sm">
                  Activer
                </button>
              </div>
            </div>
          }
        </div>
      </div>

      <!-- Navigation Tabs & Search (Clean & Responsive) -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-200 pb-3">
        
        <!-- Segmented Tabs (100% SVG, Zero Emojis) -->
        <div class="flex items-center gap-1.5 p-1 bg-slate-100 rounded-2xl border border-slate-200 overflow-x-auto max-w-full">
          
          <!-- Tab 1: Live -->
          <button (click)="activeTab.set('live')"
                  [class.bg-white]="activeTab() === 'live'"
                  [class.text-slate-900]="activeTab() === 'live'"
                  [class.shadow-xs]="activeTab() === 'live'"
                  [class.text-slate-600]="activeTab() !== 'live'"
                  class="px-3.5 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer shrink-0">
            <span class="relative flex h-2 w-2">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75" *ngIf="activeLives().length > 0"></span>
              <span class="relative inline-flex rounded-full h-2 w-2 bg-red-500"></span>
            </span>
            <span>En direct</span>
            <span class="px-2 py-0.5 rounded-full text-[10px]"
                  [class.bg-red-50]="activeTab() === 'live'"
                  [class.text-red-600]="activeTab() === 'live'"
                  [class.bg-slate-200]="activeTab() !== 'live'">
              {{ activeLives().length }}
            </span>
          </button>

          <!-- Tab 2: Replays -->
          <button (click)="activeTab.set('replays')"
                  [class.bg-white]="activeTab() === 'replays'"
                  [class.text-slate-900]="activeTab() === 'replays'"
                  [class.shadow-xs]="activeTab() === 'replays'"
                  [class.text-slate-600]="activeTab() !== 'replays'"
                  class="px-3.5 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer shrink-0">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span>Replays</span>
            <span class="px-2 py-0.5 rounded-full text-[10px]"
                  [class.bg-blue-50]="activeTab() === 'replays'"
                  [class.text-primary]="activeTab() === 'replays'"
                  [class.bg-slate-200]="activeTab() !== 'replays'">
              {{ replays().length }}
            </span>
          </button>

          <!-- Tab 3: Upcoming -->
          <button (click)="activeTab.set('upcoming')"
                  [class.bg-white]="activeTab() === 'upcoming'"
                  [class.text-slate-900]="activeTab() === 'upcoming'"
                  [class.shadow-xs]="activeTab() === 'upcoming'"
                  [class.text-slate-600]="activeTab() !== 'upcoming'"
                  class="px-3.5 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer shrink-0">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
            </svg>
            <span>À venir</span>
            <span class="px-2 py-0.5 rounded-full text-[10px]"
                  [class.bg-purple-50]="activeTab() === 'upcoming'"
                  [class.text-purple-700]="activeTab() === 'upcoming'"
                  [class.bg-slate-200]="activeTab() !== 'upcoming'">
              {{ upcomingLives().length }}
            </span>
          </button>
        </div>

        <!-- Search Bar -->
        <div class="relative w-full sm:w-64">
          <input type="text"
                 [(ngModel)]="searchQuery"
                 placeholder="Rechercher une session..."
                 class="w-full pl-9 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-primary font-medium">
          <svg class="w-4 h-4 text-slate-400 absolute left-3 top-2.5 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>
      </div>

      <!-- ======================================================== -->
      <!-- TAB 1: EN DIRECT MAINTENANT                              -->
      <!-- ======================================================== -->
      @if (activeTab() === 'live') {
        @if (activeLives().length > 0) {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 animate-fade-in">
            @for (live of filteredActiveLives(); track live.id) {
              <div class="bg-white border-2 border-red-500/40 rounded-3xl overflow-hidden shadow-lg shadow-red-500/5 flex flex-col hover:border-red-500 transition-all group">
                <!-- Live Thumbnail / Preview -->
                <div class="aspect-video bg-slate-900 relative flex items-center justify-center text-white overflow-hidden">
                  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent z-10"></div>
                  
                  <div class="relative z-20 text-center p-4">
                    <span class="w-12 h-12 rounded-2xl bg-red-600 flex items-center justify-center text-white mx-auto shadow-lg shadow-red-600/50 group-hover:scale-105 transition-transform">
                      <svg class="w-6 h-6 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                      </svg>
                    </span>
                    <p class="font-display text-sm font-bold text-white mt-2">{{ live.teacherName }}</p>
                    <p class="text-[11px] text-red-300 font-medium">Session interactive en cours</p>
                  </div>

                  <div class="absolute top-3 left-3 z-20">
                    <span class="px-2.5 py-1 rounded-full bg-red-600 text-white text-[10px] font-black uppercase tracking-wider flex items-center gap-1.5 shadow-md">
                      <span class="w-1.5 h-1.5 rounded-full bg-white animate-ping"></span>
                      EN DIRECT
                    </span>
                  </div>

                  <div class="absolute bottom-3 right-3 z-20">
                    <span class="px-2.5 py-1 rounded-full bg-black/60 backdrop-blur-md text-white text-[10px] font-bold flex items-center gap-1.5">
                      <svg class="w-3.5 h-3.5 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                      </svg>
                      <span>{{ (live.participantCount || 0) + 1 }} participants</span>
                    </span>
                  </div>
                </div>

                <!-- Info Body -->
                <div class="p-5 flex-1 flex flex-col justify-between space-y-4">
                  <div>
                    <span class="px-2.5 py-1 rounded-lg bg-blue-50 text-primary text-[10px] font-bold">
                      {{ live.courseName }}
                    </span>
                    <h3 class="font-display text-base font-bold text-slate-900 mt-2 line-clamp-1 group-hover:text-primary transition-colors">
                      {{ live.title }}
                    </h3>
                  </div>

                  <!-- Join Button -->
                  <a [routerLink]="['/student/live', live.id]"
                     class="w-full py-3 bg-red-600 hover:bg-red-700 text-white rounded-2xl text-xs font-bold flex items-center justify-center gap-2 shadow-lg shadow-red-600/25 active:scale-95 transition-all">
                    <span>Rejoindre le direct</span>
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                    </svg>
                  </a>
                </div>
              </div>
            }
          </div>
        } @else {
          <!-- Simple, Elegant Empty State (Pure SVG) -->
          <div class="p-8 sm:p-14 bg-white border border-slate-200 rounded-3xl text-center space-y-4 shadow-xs max-w-xl mx-auto">
            <div class="w-16 h-16 rounded-3xl bg-blue-50 text-primary flex items-center justify-center mx-auto shadow-sm">
              <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </div>
            
            <div class="space-y-1.5">
              <h3 class="font-display text-base sm:text-lg font-bold text-slate-900">
                Aucun cours en direct en ce moment
              </h3>
              <p class="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
                Dès qu'un de vos formateurs démarre une session interactive, elle s'affichera immédiatement ici et vous recevrez une alerte.
              </p>
            </div>

            <div class="pt-2">
              <button (click)="activeTab.set('replays')"
                      class="inline-flex items-center justify-center gap-2 px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-2xl text-xs font-bold transition-all shadow-sm active:scale-95 cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                  <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <span>Explorer les replays récents</span>
              </button>
            </div>
          </div>
        }
      }

      <!-- ======================================================== -->
      <!-- TAB 2: REPLAYS & ENREGISTREMENTS                         -->
      <!-- ======================================================== -->
      @if (activeTab() === 'replays') {
        @if (replays().length > 0) {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 animate-fade-in">
            @for (replay of filteredReplays(); track replay.id) {
              <div class="bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-xs hover:shadow-md transition-all group flex flex-col">
                <!-- Replay Thumbnail -->
                <div class="aspect-video bg-slate-900 relative flex items-center justify-center text-white overflow-hidden">
                  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent z-10"></div>
                  
                  <div class="relative z-20 text-center p-4">
                    <button (click)="openReplayModal(replay)"
                            class="w-12 h-12 rounded-2xl bg-primary hover:bg-primary-600 text-white flex items-center justify-center mx-auto shadow-xl shadow-primary/30 group-hover:scale-110 transition-transform cursor-pointer">
                      <svg class="w-5 h-5 ml-0.5" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M8 5v14l11-7z"/>
                      </svg>
                    </button>
                  </div>

                  <div class="absolute top-3 left-3 z-20">
                    <span class="px-2.5 py-1 rounded-full bg-slate-900/80 backdrop-blur-md text-white text-[10px] font-bold flex items-center gap-1.5 border border-slate-700">
                      <svg class="w-3 h-3 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                      </svg>
                      <span>Replay</span>
                    </span>
                  </div>

                  <div class="absolute bottom-3 right-3 z-20">
                    <span class="px-2 py-0.5 rounded-md bg-black/70 text-white text-[10px] font-bold">
                      {{ replay.replayDuration || '45 min' }}
                    </span>
                  </div>
                </div>

                <!-- Info Body -->
                <div class="p-5 flex-1 flex flex-col justify-between space-y-4">
                  <div>
                    <span class="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 text-[10px] font-bold">
                      {{ replay.courseName }}
                    </span>
                    <h3 class="font-display text-sm font-bold text-slate-900 mt-2 line-clamp-1 group-hover:text-primary transition-colors">
                      {{ replay.title }}
                    </h3>
                    <div class="text-xs text-slate-500 mt-1.5 flex items-center gap-2">
                      <span class="flex items-center gap-1">
                        <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                        <span>{{ replay.teacherName }}</span>
                      </span>
                      <span>•</span>
                      <span class="flex items-center gap-1">
                        <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        <span>{{ replay.endedAt?.toDate() | date:'dd MMM yyyy' }}</span>
                      </span>
                    </div>
                  </div>

                  <!-- Watch Button -->
                  <button (click)="openReplayModal(replay)"
                          class="w-full py-2.5 bg-primary/10 hover:bg-primary text-primary hover:text-white rounded-2xl text-xs font-bold flex items-center justify-center gap-2 transition-all cursor-pointer active:scale-95">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span>Regarder la rediffusion</span>
                  </button>
                </div>
              </div>
            }
          </div>
        } @else {
          <!-- Empty Replays -->
          <div class="p-8 sm:p-14 bg-white border border-slate-200 rounded-3xl text-center space-y-4 shadow-xs max-w-xl mx-auto">
            <div class="w-16 h-16 rounded-3xl bg-blue-50 text-primary flex items-center justify-center mx-auto shadow-sm">
              <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
              </svg>
            </div>
            <div class="space-y-1.5">
              <h3 class="font-display text-base sm:text-lg font-bold text-slate-900">
                Aucun replay disponible pour l'instant
              </h3>
              <p class="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
                Les enregistrements des cours en direct auxquels vous avez accès seront automatiquement sauvegardés et consultables ici.
              </p>
            </div>
          </div>
        }
      }

      <!-- ======================================================== -->
      <!-- TAB 3: PROCHAINS LIVES PROGRAMMÉS                        -->
      <!-- ======================================================== -->
      @if (activeTab() === 'upcoming') {
        @if (upcomingLives().length > 0) {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 animate-fade-in">
            @for (live of upcomingLives(); track live.id) {
              <div class="bg-white border border-slate-200 rounded-3xl p-5 sm:p-6 shadow-xs flex flex-col justify-between space-y-4 hover:border-primary/50 transition-all">
                <div class="space-y-2">
                  <div class="flex items-center justify-between">
                    <span class="px-2.5 py-1 rounded-lg bg-blue-50 text-primary text-[10px] font-bold">
                      {{ live.courseName }}
                    </span>
                    <span class="text-xs text-slate-500 font-semibold flex items-center gap-1">
                      <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <span>{{ live.scheduledAt.toDate() | date:'dd/MM/yyyy à HH:mm' }}</span>
                    </span>
                  </div>
                  <h3 class="font-display text-base font-bold text-slate-900">{{ live.title }}</h3>
                  <p class="text-xs text-slate-500 flex items-center gap-1">
                    <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    <span>Formateur : {{ live.teacherName }}</span>
                  </p>
                </div>

                <div class="w-full py-2.5 bg-slate-100 text-slate-500 rounded-2xl text-xs font-bold flex items-center justify-center gap-1.5 border border-slate-200">
                  <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                  <span>Rappel programmé</span>
                </div>
              </div>
            }
          </div>
        } @else {
          <!-- Empty Upcoming -->
          <div class="p-8 sm:p-14 bg-white border border-slate-200 rounded-3xl text-center space-y-4 shadow-xs max-w-xl mx-auto">
            <div class="w-16 h-16 rounded-3xl bg-purple-50 text-purple-600 flex items-center justify-center mx-auto shadow-sm">
              <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
              </svg>
            </div>
            <div class="space-y-1.5">
              <h3 class="font-display text-base sm:text-lg font-bold text-slate-900">
                Aucun cours planifié pour le moment
              </h3>
              <p class="text-xs text-slate-500 max-w-sm mx-auto leading-relaxed">
                Votre calendrier sera mis à jour dès que vos formateurs programmeront une nouvelle session.
              </p>
            </div>
          </div>
        }
      }

      <!-- Interactive Replay Video Modal -->
      @if (selectedReplay()) {
        <div class="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 animate-fade-in" (click)="closeReplayModal()">
          <div class="bg-slate-900 border border-slate-800 rounded-3xl overflow-hidden max-w-3xl w-full shadow-2xl text-white" (click)="$event.stopPropagation()">
            <!-- Modal Header -->
            <div class="p-4 border-b border-slate-800 flex items-center justify-between">
              <div>
                <h3 class="font-display text-sm sm:text-base font-bold text-white">{{ selectedReplay()?.title }}</h3>
                <p class="text-xs text-slate-400">{{ selectedReplay()?.courseName }} • {{ selectedReplay()?.teacherName }}</p>
              </div>
              <button (click)="closeReplayModal()" class="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors cursor-pointer">
                ✕
              </button>
            </div>

            <!-- Video Player -->
            <div class="aspect-video bg-black flex items-center justify-center relative select-none"
                 (contextmenu)="$event.preventDefault()">
              <!-- Video Title Overlay -->
              <div class="absolute top-4 left-4 z-20 pointer-events-none select-none max-w-[70%]">
                <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/60 backdrop-blur-md border border-white/15 text-white shadow-lg">
                  <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                  <h4 class="text-xs font-bold truncate text-white">{{ selectedReplay()?.title }}</h4>
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

              <video [src]="selectedReplay()?.replayUrl || 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'"
                     controls
                     autoplay
                     controlsList="nodownload"
                     (contextmenu)="$event.preventDefault()"
                     class="w-full h-full object-contain"></video>
            </div>

            <!-- Modal Footer -->
            <div class="p-4 bg-slate-950 flex items-center justify-between text-xs text-slate-400">
              <span>Durée : {{ selectedReplay()?.replayDuration || '45 min' }}</span>
              <button (click)="closeReplayModal()" class="px-4 py-2 bg-primary text-white rounded-xl font-bold cursor-pointer">
                Fermer
              </button>
            </div>
          </div>
        </div>
      }

    </div>
  `,
})
export class StudentLivesComponent implements OnInit {
  private store = inject(Store);
  private livekitService = inject(LivekitService);
  private notificationService = inject(NotificationService);
  private toastr = inject(ToastrService);

  currentUser = signal<User | null>(null);
  activeTab = signal<'live' | 'replays' | 'upcoming'>('live');
  searchQuery = '';
  notificationEnabled = signal(false);

  activeLives = signal<LiveSession[]>([]);
  replays = signal<LiveSession[]>([]);
  upcomingLives = signal<LiveSession[]>([]);

  selectedReplay = signal<LiveSession | null>(null);

  filteredActiveLives = computed(() => {
    if (!this.searchQuery.trim()) return this.activeLives();
    const q = this.searchQuery.toLowerCase();
    return this.activeLives().filter(l => l.title.toLowerCase().includes(q) || l.courseName.toLowerCase().includes(q));
  });

  filteredReplays = computed(() => {
    if (!this.searchQuery.trim()) return this.replays();
    const q = this.searchQuery.toLowerCase();
    return this.replays().filter(l => l.title.toLowerCase().includes(q) || l.courseName.toLowerCase().includes(q) || l.teacherName.toLowerCase().includes(q));
  });

  ngOnInit() {
    if ('Notification' in window && Notification.permission === 'granted') {
      this.notificationEnabled.set(true);
    }

    this.store.select(selectCurrentUser).subscribe(u => {
      this.currentUser.set(u);
    });

    // 1. Écouter les lives actifs
    this.livekitService.getActiveLiveSessions().subscribe(lives => {
      this.activeLives.set(lives);
    });

    // 2. Écouter les replays
    this.livekitService.getAllReplays().subscribe(replays => {
      this.replays.set(replays);
    });
  }

  async enableNotifications() {
    const granted = await this.notificationService.requestBrowserNotificationPermission();
    if (granted) {
      this.notificationEnabled.set(true);
      this.toastr.success('Notifications activées avec succès !');
    } else {
      this.toastr.info('Les notifications sont désactivées dans votre navigateur.');
    }
  }

  openReplayModal(replay: LiveSession) {
    this.selectedReplay.set(replay);
  }

  closeReplayModal() {
    this.selectedReplay.set(null);
  }
}
