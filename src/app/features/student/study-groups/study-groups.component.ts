import { Component, inject, OnInit, signal, effect, ElementRef, ViewChild, OnDestroy } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { Subscription, switchMap, of, combineLatest } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { CourseService } from '../../../core/services/course.service';
import { StudyGroupService } from '../../../core/services/study-group.service';
import { StudyGroup, GroupSharedTask, Message, Course, User } from '../../../core/models';
import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../../shared/components/refresh-button/refresh-button.component';

@Component({
  selector: 'app-student-study-groups',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, DatePipe, BackButtonComponent, RefreshButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-2 sm:py-4 space-y-3 font-body animate-fade-in">

      <!-- Sticky Navigation Bar with Back & Refresh Buttons -->
      <div class="sticky top-0 z-30 -mx-3 sm:-mx-6 lg:-mx-8 px-3 sm:px-6 lg:px-8 py-2.5 bg-white/95 backdrop-blur-md border-b border-slate-200/80 flex items-center justify-between shadow-2xs">
        <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" />
        <app-refresh-button />
      </div>

      <!-- Header: Simple, Épuré & Compact PWA -->
      <div class="flex items-center justify-between gap-3 pt-1">
        <h1 class="font-display text-base sm:text-lg font-black text-slate-900 tracking-tight">
          Groupes de travail & entraide
        </h1>

        <button (click)="openCreateModal()"
                class="px-3 py-2 rounded-xl bg-primary hover:bg-primary-600 text-white text-xs font-bold shadow-sm transition-all flex items-center gap-1.5 cursor-pointer active:scale-95 shrink-0">
          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
          </svg>
          <span>Créer un groupe</span>
        </button>
      </div>

      <!-- Navigation Tabs (Mes groupes / Découvrir les groupes) -->
      <div class="flex items-center gap-2 border-b border-slate-200 pb-2">
        <button (click)="activeTab.set('my-groups')"
                class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5"
                [class.bg-primary]="activeTab() === 'my-groups'"
                [class.text-white]="activeTab() === 'my-groups'"
                [class.shadow-2xs]="activeTab() === 'my-groups'"
                [class.text-slate-600]="activeTab() !== 'my-groups'"
                [class.hover:bg-slate-100]="activeTab() !== 'my-groups'">
          <span>Mes groupes</span>
          <span class="px-1.5 py-0.2 rounded-full text-[10px]"
                [class.bg-white]="activeTab() === 'my-groups'"
                [class.text-primary]="activeTab() === 'my-groups'"
                [class.bg-slate-100]="activeTab() !== 'my-groups'">
            {{ myGroups().length }}
          </span>
        </button>

        <button (click)="activeTab.set('explore')"
                class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5"
                [class.bg-primary]="activeTab() === 'explore'"
                [class.text-white]="activeTab() === 'explore'"
                [class.shadow-2xs]="activeTab() === 'explore'"
                [class.text-slate-600]="activeTab() !== 'explore'"
                [class.hover:bg-slate-100]="activeTab() !== 'explore'">
          <span>Découvrir les groupes</span>
          <span class="px-1.5 py-0.2 rounded-full text-[10px]"
                [class.bg-white]="activeTab() === 'explore'"
                [class.text-primary]="activeTab() === 'explore'"
                [class.bg-slate-100]="activeTab() !== 'explore'">
            {{ availableGroups().length }}
          </span>
        </button>
      </div>

      <!-- ======================================================== -->
      <!-- TAB 1: MES GROUPES & SALON DE TRAVAIL                    -->
      <!-- ======================================================== -->
      @if (activeTab() === 'my-groups') {
        @if (myGroups().length > 0) {
          <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 h-[780px] bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
            
            <!-- Left: Groups list (4 cols) -->
            <div class="lg:col-span-4 border-r border-slate-200 flex flex-col bg-white">
              <div class="p-4 border-b border-slate-200 flex items-center justify-between">
                <span class="text-xs font-bold text-slate-800 uppercase tracking-wider">Vos Squads</span>
                <span class="text-[11px] font-bold text-primary bg-primary/10 px-2.5 py-0.5 rounded-full">
                  {{ myGroups().length }} groupe(s)
                </span>
              </div>

              <div class="flex-1 overflow-y-auto p-3 space-y-2">
                @for (group of myGroups(); track group.id) {
                  <div (click)="selectGroup(group)"
                       role="button"
                       tabindex="0"
                       class="w-full text-left p-3.5 rounded-2xl transition-all flex flex-col space-y-2 cursor-pointer border"
                       [class.bg-primary]="selectedGroup()?.id === group.id"
                       [class.text-white]="selectedGroup()?.id === group.id"
                       [class.border-primary]="selectedGroup()?.id === group.id"
                       [class.shadow-md]="selectedGroup()?.id === group.id"
                       [class.bg-slate-50]="selectedGroup()?.id !== group.id"
                       [class.border-slate-200]="selectedGroup()?.id !== group.id">
                    
                    <div class="flex items-center justify-between">
                      <span class="text-xs font-bold truncate max-w-[170px]"
                            [class.text-white]="selectedGroup()?.id === group.id"
                            [class.text-slate-900]="selectedGroup()?.id !== group.id">
                        {{ group.name }}
                      </span>
                      <div class="flex items-center gap-1.5 shrink-0">
                        @if (group.joinRequests && group.joinRequests.length > 0 && isGroupAdmin(group)) {
                          <span class="px-1.5 py-0.5 rounded-full bg-amber-500 text-white text-[9px] font-bold animate-pulse" title="Demandes en attente">
                            +{{ group.joinRequests.length }}
                          </span>
                        }
                        <span class="text-[10px] font-black px-2 py-0.5 rounded-full"
                              [class.bg-white]="selectedGroup()?.id === group.id"
                              [class.text-primary]="selectedGroup()?.id === group.id"
                              [class.bg-purple-100]="selectedGroup()?.id !== group.id"
                              [class.text-purple-700]="selectedGroup()?.id !== group.id">
                          {{ group.members.length }}/{{ group.maxMembers || 5 }}
                        </span>
                      </div>
                    </div>

                    <div class="flex items-center justify-between text-[11px]"
                         [class.text-blue-100]="selectedGroup()?.id === group.id"
                         [class.text-slate-500]="selectedGroup()?.id !== group.id">
                      <span class="truncate max-w-[160px]">{{ group.courseTitle }}</span>
                      <span class="text-[10px]">
                        {{ group.joinMode === 'request' ? '🔒 Sur Demande' : '🔓 Libre' }}
                      </span>
                    </div>
                  </div>
                }
              </div>
            </div>

            <!-- Right: Active Group Workspace (8 cols) -->
            <div class="lg:col-span-8 flex flex-col bg-white overflow-hidden">
              @if (selectedGroup(); as group) {
                
                <!-- Group Top Bar -->
                <div class="p-4 border-b border-slate-200 flex items-center justify-between bg-slate-50/50">
                  <div class="min-w-0">
                    <div class="flex items-center gap-2">
                      <h3 class="font-display text-base font-bold text-slate-900 truncate">
                        {{ group.name }}
                      </h3>
                      <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-purple-50 text-purple-700 border border-purple-200 shrink-0">
                        {{ group.members.length }}/{{ group.maxMembers || 5 }} membres
                      </span>
                      @if (group.joinMode === 'request') {
                        <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200 shrink-0">
                          🔒 Sur Approbation
                        </span>
                      }
                    </div>
                    <p class="text-xs text-slate-500 truncate mt-0.5">{{ group.courseTitle }}</p>
                  </div>

                  <div class="flex items-center gap-2 shrink-0">
                    <!-- Launch Group Live -->
                    <button (click)="startGroupLive(group)"
                            class="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all shadow-sm flex items-center gap-1.5 cursor-pointer active:scale-95">
                      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                      </svg>
                      <span>Lancer Visio Squad</span>
                    </button>

                    <!-- Add Task -->
                    <button (click)="showPostTaskModal.set(true)"
                            title="Partager un devoir ou exercice à faire"
                            class="px-3 py-1.5 rounded-xl bg-primary/10 text-primary hover:bg-primary hover:text-white text-xs font-bold transition-all flex items-center gap-1 cursor-pointer">
                      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                      </svg>
                      <span>+ Sujet</span>
                    </button>

                    <!-- Leave group button -->
                    <button (click)="leaveGroup(group)"
                            title="Quitter ce groupe"
                            class="p-2 rounded-xl bg-slate-100 hover:bg-red-50 text-slate-500 hover:text-red-600 transition-all cursor-pointer">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                      </svg>
                    </button>
                  </div>
                </div>

                <!-- Sub-nav: Chat vs Tasks vs Join Requests (for Admins) -->
                <div class="px-4 py-2 bg-white border-b border-slate-200 flex items-center justify-between text-xs">
                  <div class="flex items-center gap-2">
                    <button (click)="groupView.set('chat')"
                            [class.font-bold]="groupView() === 'chat'"
                            [class.text-primary]="groupView() === 'chat'"
                            [class.text-slate-500]="groupView() !== 'chat'"
                            class="px-3 py-1.5 rounded-xl hover:bg-slate-100 cursor-pointer transition-all">
                      💬 Salon de discussion
                    </button>

                    <button (click)="groupView.set('tasks')"
                            [class.font-bold]="groupView() === 'tasks'"
                            [class.text-primary]="groupView() === 'tasks'"
                            [class.text-slate-500]="groupView() !== 'tasks'"
                            class="px-3 py-1.5 rounded-xl hover:bg-slate-100 cursor-pointer transition-all flex items-center gap-1.5">
                      <span>📚 Devoirs & Sujets</span>
                      <span class="px-1.5 py-0.2 rounded-full bg-primary/10 text-primary text-[10px]">
                        {{ groupTasks().length }}
                      </span>
                    </button>

                    @if (isGroupAdmin(group)) {
                      <button (click)="groupView.set('requests')"
                              [class.font-bold]="groupView() === 'requests'"
                              [class.text-amber-700]="groupView() === 'requests'"
                              [class.bg-amber-50]="groupView() === 'requests'"
                              [class.text-slate-500]="groupView() !== 'requests'"
                              class="px-3 py-1.5 rounded-xl hover:bg-slate-100 cursor-pointer transition-all flex items-center gap-1.5 border border-transparent"
                              [class.border-amber-200]="groupView() === 'requests'">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                        </svg>
                        <span>Demandes d'adhésion</span>
                        @if ((group.joinRequests?.length || 0) > 0) {
                          <span class="px-2 py-0.5 rounded-full bg-amber-500 text-white text-[10px] font-bold animate-pulse">
                            {{ group.joinRequests?.length }}
                          </span>
                        }
                      </button>
                    }
                  </div>
                </div>

                <!-- VIEW 1: CHAT STREAM -->
                @if (groupView() === 'chat') {
                  <div #messagesContainer class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4">
                    @for (msg of groupMessages(); track msg.id) {
                      <div class="flex items-end gap-2.5 max-w-[85%] sm:max-w-[75%]"
                           [class.ml-auto]="isMyMessage(msg)"
                           [class.flex-row-reverse]="isMyMessage(msg)">
                        
                        <img loading="lazy" decoding="async" [src]="msg.senderPhotoURL || getAvatarUrl(msg.senderName)"
                             class="w-7 h-7 rounded-full object-cover shrink-0 border border-slate-200"
                             alt="Avatar">

                        <div class="space-y-1">
                          <div class="flex items-center gap-2 text-[10px] text-slate-400"
                               [class.justify-end]="isMyMessage(msg)">
                            <span class="font-bold text-slate-800">{{ isMyMessage(msg) ? 'Vous' : msg.senderName }}</span>
                            @if (msg.createdAt) {
                              <span>{{ msg.createdAt.toMillis ? (msg.createdAt.toMillis() | date:'shortTime') : 'À l\'instant' }}</span>
                            }
                          </div>

                          <div class="p-3.5 rounded-2xl text-xs leading-relaxed"
                               [class.bg-primary]="isMyMessage(msg)"
                               [class.text-white]="isMyMessage(msg)"
                               [class.bg-slate-100]="!isMyMessage(msg)"
                               [class.text-slate-800]="!isMyMessage(msg)">
                            
                            @if (msg.type === 'image' && msg.fileUrl) {
                              <div class="space-y-2">
                                <img loading="lazy" decoding="async" [src]="msg.fileUrl" class="rounded-xl max-h-48 object-cover cursor-pointer">
                                <p>{{ msg.content }}</p>
                              </div>
                            } @else if (msg.type === 'file' && msg.fileUrl) {
                              <div class="flex items-center gap-2">
                                <a [href]="msg.fileUrl" target="_blank" class="font-bold underline flex items-center gap-1">
                                  <span>📎 Télécharger le document</span>
                                </a>
                              </div>
                            } @else {
                              <p class="whitespace-pre-wrap">{{ msg.content }}</p>
                            }

                          </div>
                        </div>
                      </div>
                    }
                  </div>

                  <!-- Chat Input Composer -->
                  <div class="p-3 sm:p-4 bg-white border-t border-slate-200">
                    <div class="flex items-center gap-2">
                      <input type="text"
                             [(ngModel)]="newMessage"
                             (keyup.enter)="sendMessage()"
                             placeholder="Partagez vos réflexions avec vos camarades..."
                             class="flex-1 px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-primary">

                      <button (click)="sendMessage()" [disabled]="!newMessage.trim() || isSending()"
                              class="px-4 py-2.5 bg-primary hover:bg-primary-600 disabled:opacity-40 text-white rounded-xl text-xs font-bold shadow-md shadow-primary/25 cursor-pointer">
                        Envoyer
                      </button>
                    </div>
                  </div>
                }

                <!-- VIEW 2: TASKS & DEVOIRS DU GROUPE -->
                @if (groupView() === 'tasks') {
                  <div class="flex-1 overflow-y-auto p-6 space-y-4">
                    <div class="flex items-center justify-between">
                      <h4 class="font-display font-bold text-xs text-slate-700 uppercase tracking-wider">Exercices et Devoirs du Groupe</h4>
                      <button (click)="showPostTaskModal.set(true)"
                              class="px-3 py-1.5 rounded-xl bg-primary text-white text-xs font-bold shadow-xs cursor-pointer">
                        + Proposer un devoir
                      </button>
                    </div>

                    @for (task of groupTasks(); track task.id) {
                      <div class="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs space-y-3">
                        <div class="flex items-center justify-between">
                          <span class="text-xs font-bold text-slate-900">{{ task.title }}</span>
                          <span class="text-[10px] text-slate-500">Partagé par {{ task.authorName }}</span>
                        </div>
                        <p class="text-xs text-slate-600 whitespace-pre-wrap">{{ task.description }}</p>
                        @if (task.fileUrl) {
                          <div class="flex items-center justify-between p-2.5 bg-blue-50 border border-blue-200 rounded-xl">
                            <span class="text-xs font-bold text-blue-900 truncate">{{ task.fileName || 'Sujet joint' }}</span>
                            <a [href]="task.fileUrl" target="_blank" class="px-3 py-1 bg-blue-600 text-white rounded-lg text-xs font-bold">Télécharger</a>
                          </div>
                        }
                      </div>
                    } @empty {
                      <div class="text-center py-16 text-slate-400 text-xs">
                        <p class="font-bold text-slate-700">Aucun devoir partagé dans ce groupe</p>
                        <p class="text-[11px] mt-1">Tous les membres peuvent publier des sujets d'exercices à résoudre.</p>
                      </div>
                    }
                  </div>
                }

                <!-- VIEW 3: DEMANDES D'ADHÉSION EN ATTENTE (POUR LE CRÉATEUR) -->
                @if (groupView() === 'requests') {
                  <div class="flex-1 overflow-y-auto p-6 space-y-4">
                    <div class="flex items-center justify-between border-b border-slate-100 pb-3">
                      <div>
                        <h4 class="font-display font-bold text-sm text-slate-900">Demandes d'adhésion au groupe</h4>
                        <p class="text-xs text-slate-500">Validez ou refusez les étudiants qui souhaitent rejoindre votre groupe ({{ group.members.length }}/{{ group.maxMembers || 5 }} membres actuels).</p>
                      </div>
                      <span class="px-3 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200 text-xs font-bold">
                        {{ group.joinRequests?.length || 0 }} en attente
                      </span>
                    </div>

                    @for (req of group.joinRequests; track req.uid) {
                      <div class="p-4 rounded-2xl bg-white border border-slate-200 shadow-xs flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                        <div class="flex items-center gap-3">
                          <img loading="lazy" decoding="async" [src]="req.photoURL || getAvatarUrl(req.displayName)"
                               class="w-11 h-11 rounded-2xl object-cover border border-slate-200"
                               alt=""
                               onerror="this.src='assets/default-avatar.png'">
                          <div>
                            <p class="font-display text-sm font-bold text-slate-900">{{ req.displayName }}</p>
                            <div class="flex items-center gap-2 mt-0.5 text-xs text-slate-500">
                              <span class="font-mono text-primary font-bold">{{ req.matricule || 'Étudiant' }}</span>
                              <span>•</span>
                              <span>{{ req.academicLevel || 'Licence' }}</span>
                            </div>
                          </div>
                        </div>

                        <div class="flex items-center gap-2 shrink-0">
                          <button (click)="acceptApplicant(group, req)"
                                  [disabled]="group.members.length >= (group.maxMembers || 5)"
                                  class="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 disabled:opacity-40 text-white text-xs font-bold transition-all shadow-sm flex items-center gap-1.5 cursor-pointer active:scale-95">
                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                              <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                            </svg>
                            <span>Accepter</span>
                          </button>

                          <button (click)="rejectApplicant(group, req.uid)"
                                  class="px-3.5 py-2 rounded-xl bg-red-50 hover:bg-red-100 text-red-600 text-xs font-bold transition-all cursor-pointer">
                            <span>Refuser</span>
                          </button>
                        </div>
                      </div>
                    } @empty {
                      <div class="text-center py-16 text-slate-400 space-y-3">
                        <div class="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center mx-auto">
                          <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                        </div>
                        <div>
                          <p class="font-bold text-slate-700 text-sm">Aucune demande en attente</p>
                          <p class="text-xs text-slate-400 mt-0.5">Toutes les demandes d'adhésion ont été traitées.</p>
                        </div>
                      </div>
                    }
                  </div>
                }

              }
            </div>

          </div>
        } @else {
          <!-- Empty State: Aucun groupe pour le moment (Simple & sans doublon de bouton) -->
          <div class="rounded-2xl border border-dashed border-slate-200 bg-white p-6 sm:p-8 text-center max-w-sm mx-auto shadow-2xs space-y-2.5 animate-fade-in">
            <div class="w-10 h-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center mx-auto">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div>
              <h2 class="font-display text-sm font-bold text-slate-900">
                Aucun groupe rejoint
              </h2>
              <p class="text-xs text-slate-500 mt-0.5">
                Rejoignez un groupe existant ci-dessous ou créez-en un avec le bouton en haut.
              </p>
            </div>
            <button (click)="activeTab.set('explore')"
                    class="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold transition-all inline-flex items-center gap-1.5 cursor-pointer active:scale-95">
              <span>Découvrir les groupes</span>
            </button>
          </div>
        }
      }

      <!-- ======================================================== -->
      <!-- TAB 2: REJOINDRE UN GROUPE (EXPLORE)                     -->
      <!-- ======================================================== -->
      @if (activeTab() === 'explore') {
        @if (availableGroups().length > 0) {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 animate-fade-in">
            @for (group of availableGroups(); track group.id) {
              <div class="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5 shadow-xs flex flex-col justify-between hover:shadow-md transition-shadow">
                <div class="space-y-2.5">
                  <div class="flex items-center justify-between">
                    <span class="px-2.5 py-0.5 rounded-full bg-blue-50 text-primary text-[10px] font-extrabold uppercase tracking-wider border border-blue-100 truncate max-w-[160px]">
                      {{ group.courseTitle || 'Général' }}
                    </span>
                    <div class="flex items-center gap-1.5 shrink-0">
                      @if (group.joinMode === 'request') {
                        <span class="px-2 py-0.5 rounded-full bg-purple-50 text-purple-700 border border-purple-200 text-[10px] font-bold">
                          Sur demande
                        </span>
                      } @else {
                        <span class="px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-bold">
                          Accès libre
                        </span>
                      }
                      <span class="text-[11px] font-bold text-slate-600 bg-slate-100 px-2 py-0.5 rounded-full">
                        {{ group.members.length }}/{{ group.maxMembers || 5 }}
                      </span>
                    </div>
                  </div>

                  <h3 class="font-display text-sm sm:text-base font-bold text-slate-900">
                    {{ group.name }}
                  </h3>

                  <p class="text-xs text-slate-500 line-clamp-2">
                    {{ group.description || 'Groupe de révision et entraide pour progresser ensemble.' }}
                  </p>

                  <div class="pt-1.5 flex items-center gap-2 text-xs text-slate-600">
                    <img loading="lazy" decoding="async" [src]="group.creatorPhoto || getAvatarUrl(group.creatorName)"
                         class="w-5 h-5 rounded-full object-cover border border-slate-200"
                         onerror="this.src='assets/default-avatar.png'">
                    <span class="truncate text-[11px]">Créé par <strong class="text-slate-800">{{ group.creatorName }}</strong></span>
                  </div>
                </div>

                <div class="pt-3 mt-3 border-t border-slate-100">
                  @if (isUserMember(group)) {
                    <button (click)="selectGroup(group); activeTab.set('my-groups')"
                            class="w-full py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer">
                      <svg class="w-3.5 h-3.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                      <span>Déjà membre • Ouvrir</span>
                    </button>
                  } @else if (hasPendingRequest(group)) {
                    <button (click)="cancelRequest(group)"
                            class="w-full py-2 rounded-xl bg-amber-50 hover:bg-amber-100 text-amber-900 border border-amber-200 text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer active:scale-95"
                            title="Cliquez pour annuler votre demande">
                      <svg class="w-3.5 h-3.5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <span>Demande en attente (Annuler)</span>
                    </button>
                  } @else if (isGroupFull(group)) {
                    <button disabled
                            class="w-full py-2 rounded-xl bg-slate-100 text-slate-400 text-xs font-bold flex items-center justify-center cursor-not-allowed">
                      <span>Complet ({{ group.members.length }}/{{ group.maxMembers || 5 }})</span>
                    </button>
                  } @else if (group.joinMode === 'request') {
                    <button (click)="requestToJoinGroup(group)"
                            class="w-full py-2 rounded-xl bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5 active:scale-95 cursor-pointer">
                      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                      </svg>
                      <span>Demander à rejoindre</span>
                    </button>
                  } @else {
                    <button (click)="joinGroup(group)"
                            class="w-full py-2 rounded-xl bg-primary hover:bg-primary-600 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5 active:scale-95 cursor-pointer">
                      <span>Rejoindre</span>
                      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                      </svg>
                    </button>
                  }
                </div>
              </div>
            }
          </div>
        } @else {
          <div class="rounded-2xl border border-dashed border-slate-200 bg-white p-6 sm:p-10 text-center max-w-sm mx-auto shadow-2xs space-y-3 animate-fade-in">
            <div class="w-10 h-10 rounded-xl bg-slate-100 text-slate-400 flex items-center justify-center mx-auto">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <div>
              <h2 class="font-display text-sm font-bold text-slate-900">
                Aucun autre groupe disponible
              </h2>
              <p class="text-xs text-slate-500 mt-0.5">
                Tous les groupes existants sont complets ou vous en faites déjà partie.
              </p>
            </div>
          </div>
        }
      }

      <!-- ======================================================== -->
      <!-- MODAL: CRÉER UN GROUPE (CAPACITÉ & MODE CONFIGURABLES)   -->
      <!-- ======================================================== -->
      @if (showCreateModal()) {
        <div class="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/80 backdrop-blur-sm animate-fade-in"
             (click)="showCreateModal.set(false)">
          <div class="w-full h-full sm:h-auto sm:max-w-md bg-white sm:rounded-3xl p-5 sm:p-7 shadow-2xl space-y-5 text-slate-800 border-0 sm:border sm:border-slate-100 overflow-y-auto max-sm:max-h-[100dvh]"
               style="padding-top: max(1.25rem, env(safe-area-inset-top, 1.25rem)); padding-bottom: max(1.5rem, env(safe-area-inset-bottom, 1.5rem));"
               (click)="$event.stopPropagation()">
            <div class="flex items-center justify-between border-b border-slate-100 pb-3">
              <div class="flex items-center gap-2">
                <div class="w-8 h-8 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h3 class="font-display text-sm sm:text-base font-bold text-slate-900">Créer un groupe de travail</h3>
              </div>
              <button (click)="showCreateModal.set(false)" class="text-slate-400 hover:text-slate-700 p-1 cursor-pointer">✕</button>
            </div>

            <form [formGroup]="createGroupForm" (ngSubmit)="submitCreateGroup()" class="space-y-3.5">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Nom du groupe *</label>
                <input type="text" formControlName="name" placeholder="Ex: Squad Mathématiques & Algorithmique"
                       class="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:bg-white focus:border-primary font-medium">
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Cours rattaché *</label>
                <select formControlName="courseId"
                        class="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:bg-white focus:border-primary">
                  <option value="" disabled selected>Sélectionner un cours</option>
                  @for (course of courses(); track course.id) {
                    <option [value]="course.id">{{ course.title }}</option>
                  }
                  <option value="general">Entraide générale & révision</option>
                </select>
              </div>

              <!-- Nombre max de membres configurable -->
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Nombre max de membres *</label>
                <select formControlName="maxMembers"
                        class="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:bg-white focus:border-primary">
                  <option [value]="2">2 membres max</option>
                  <option [value]="3">3 membres max</option>
                  <option [value]="4">4 membres max</option>
                  <option [value]="5">5 membres max</option>
                  <option [value]="8">8 membres max</option>
                  <option [value]="10">10 membres max</option>
                </select>
              </div>

              <!-- Mode d'adhésion (Libre ou sur Demande) -->
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Mode d'adhésion au groupe *</label>
                <div class="grid grid-cols-2 gap-2">
                  <label class="p-2.5 rounded-xl border cursor-pointer flex flex-col gap-0.5 transition-all select-none"
                         [class.border-primary]="createGroupForm.get('joinMode')?.value === 'open'"
                         [class.bg-blue-50]="createGroupForm.get('joinMode')?.value === 'open'"
                         [class.border-slate-200]="createGroupForm.get('joinMode')?.value !== 'open'">
                    <div class="flex items-center gap-1.5">
                      <input type="radio" formControlName="joinMode" value="open" class="text-primary focus:ring-0">
                      <span class="text-xs font-bold text-slate-900">Accès libre</span>
                    </div>
                    <span class="text-[10px] text-slate-500">Adhésion directe</span>
                  </label>

                  <label class="p-2.5 rounded-xl border cursor-pointer flex flex-col gap-0.5 transition-all select-none"
                         [class.border-primary]="createGroupForm.get('joinMode')?.value === 'request'"
                         [class.bg-purple-50]="createGroupForm.get('joinMode')?.value === 'request'"
                         [class.border-slate-200]="createGroupForm.get('joinMode')?.value !== 'request'">
                    <div class="flex items-center gap-1.5">
                      <input type="radio" formControlName="joinMode" value="request" class="text-primary focus:ring-0">
                      <span class="text-xs font-bold text-slate-900">Sur validation</span>
                    </div>
                    <span class="text-[10px] text-slate-500">Vous approuvez</span>
                  </label>
                </div>
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Description / Objectifs</label>
                <textarea formControlName="description" rows="2" placeholder="Ex: Révision des devoirs, entraide exercices..."
                          class="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:bg-white focus:border-primary resize-none"></textarea>
              </div>

              <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                <button type="button" (click)="showCreateModal.set(false)"
                        class="px-4 py-2 rounded-xl text-xs font-bold text-slate-500 hover:text-slate-800 cursor-pointer">
                  Annuler
                </button>
                <button type="submit" [disabled]="createGroupForm.invalid || isSubmitting()"
                        class="px-5 py-2.5 rounded-xl bg-primary hover:bg-primary-600 disabled:opacity-50 text-white text-xs font-bold shadow-md shadow-primary/20 flex items-center gap-2 cursor-pointer active:scale-95">
                  @if (isSubmitting()) {
                    <span>Création...</span>
                  } @else {
                    <span>Créer le Groupe</span>
                  }
                </button>
              </div>
            </form>
          </div>
        </div>
      }

      <!-- ======================================================== -->
      <!-- MODAL: POSTER UN SUJET / DEVOIR D'ÉQUIPE                 -->
      <!-- ======================================================== -->
      @if (showPostTaskModal()) {
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in"
             (click)="showPostTaskModal.set(false)">
          <div class="relative w-full max-w-lg bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 space-y-4"
               (click)="$event.stopPropagation()">
            
            <div class="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 class="font-display text-base font-bold text-slate-900">Proposer un Devoir / Exercice au Groupe</h3>
              <button (click)="showPostTaskModal.set(false)" class="text-slate-400 hover:text-slate-700 p-1 cursor-pointer">✕</button>
            </div>

            <form [formGroup]="taskForm" (ngSubmit)="submitGroupTask()" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Titre de l'exercice *</label>
                <input type="text" formControlName="title" placeholder="Ex: Devoir de Mathématiques - Série 3"
                       class="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900">
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Consignes et notes</label>
                <textarea formControlName="description" rows="3" placeholder="Indiquez les questions, astuces ou difficultés..."
                          class="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 resize-none"></textarea>
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">Fichier joint (PDF / Image)</label>
                <input type="file" (change)="onTaskFileSelected($event)" accept=".pdf,image/*"
                       class="w-full text-xs text-slate-500 file:mr-3 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-primary/10 file:text-primary hover:file:bg-primary/20">
              </div>

              <div class="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                <button type="button" (click)="showPostTaskModal.set(false)" class="px-4 py-2 text-xs font-bold text-slate-500">Annuler</button>
                <button type="submit" [disabled]="taskForm.invalid || isSubmittingTask()"
                        class="px-5 py-2 bg-primary text-white rounded-xl text-xs font-bold shadow-md shadow-primary/20 cursor-pointer">
                  {{ isSubmittingTask() ? 'Publication...' : 'Publier' }}
                </button>
              </div>
            </form>

          </div>
        </div>
      }

    </div>
  `,
})
export class StudentStudyGroupsComponent implements OnInit, OnDestroy {
  @ViewChild('messagesContainer') private messagesContainer!: ElementRef;

  private store = inject(Store);
  private courseService = inject(CourseService);
  private studyGroupService = inject(StudyGroupService);
  private toastr = inject(ToastrService);
  private fb = inject(FormBuilder);

  currentUser$ = this.store.select(selectCurrentUser);
  currentUser: User | null = null;

  activeTab = signal<'my-groups' | 'explore'>('my-groups');
  groupView = signal<'chat' | 'tasks' | 'requests'>('chat');

  courses = signal<Course[]>([]);
  allGroups = signal<StudyGroup[]>([]);
  myGroups = signal<StudyGroup[]>([]);
  selectedGroup = signal<StudyGroup | null>(null);
  groupMessages = signal<Message[]>([]);
  groupTasks = signal<GroupSharedTask[]>([]);

  showCreateModal = signal(false);
  showPostTaskModal = signal(false);

  isSubmitting = signal(false);
  isSubmittingTask = signal(false);
  isSending = signal(false);
  newMessage = '';
  selectedTaskFile: File | null = null;

  private messagesSub?: Subscription;
  private tasksSub?: Subscription;

  taskForm = this.fb.group({
    title: ['', Validators.required],
    description: [''],
  });

  createGroupForm = this.fb.group({
    name: ['', Validators.required],
    courseId: ['', Validators.required],
    description: [''],
    maxMembers: [5, [Validators.required, Validators.min(2), Validators.max(10)]],
    joinMode: ['open', Validators.required],
  });

  constructor() {
    effect(() => {
      const msgs = this.groupMessages();
      setTimeout(() => this.scrollToBottom(), 100);
    });
  }

  ngOnInit(): void {
    this.currentUser$.pipe(
      switchMap(user => {
        this.currentUser = user;
        if (!user) return of(null);
        return combineLatest([
          this.courseService.getCourses(),
          this.studyGroupService.getAllStudyGroups(),
          this.studyGroupService.getMyStudyGroups(user.uid)
        ]);
      })
    ).subscribe(data => {
      if (!data) return;
      const [courses, allG, myG] = data;
      this.courses.set(courses);
      this.allGroups.set(allG);
      this.myGroups.set(myG);

      if (!this.selectedGroup() && myG.length > 0) {
        this.selectGroup(myG[0]);
      } else if (this.selectedGroup()) {
        const fresh = myG.find(g => g.id === this.selectedGroup()!.id);
        if (fresh) this.selectedGroup.set(fresh);
      }
    });
  }

  ngOnDestroy(): void {
    if (this.messagesSub) this.messagesSub.unsubscribe();
    if (this.tasksSub) this.tasksSub.unsubscribe();
  }

  isUserMember(group: StudyGroup): boolean {
    return !!(this.currentUser && group.members.includes(this.currentUser.uid));
  }

  isGroupAdmin(group: StudyGroup): boolean {
    if (!this.currentUser) return false;
    return group.admin1Id === this.currentUser.uid || group.admin2Id === this.currentUser.uid;
  }

  availableGroups(): StudyGroup[] {
    return this.allGroups().filter(g => !this.isUserMember(g));
  }

  hasPendingRequest(group: StudyGroup): boolean {
    if (!this.currentUser || !group.joinRequests) return false;
    return group.joinRequests.some(r => r.uid === this.currentUser!.uid);
  }

  isGroupFull(group: StudyGroup): boolean {
    return group.members.length >= (group.maxMembers || 5);
  }

  selectGroup(group: StudyGroup): void {
    this.selectedGroup.set(group);
    this.groupView.set('chat');
    if (this.messagesSub) this.messagesSub.unsubscribe();
    if (this.tasksSub) this.tasksSub.unsubscribe();

    this.messagesSub = this.studyGroupService.getGroupMessages(group.id).subscribe(msgs => {
      this.groupMessages.set(msgs);
    });

    this.tasksSub = this.studyGroupService.getGroupTasks(group.id).subscribe(tasks => {
      this.groupTasks.set(tasks);
    });
  }

  async startGroupLive(group: StudyGroup): Promise<void> {
    if (!this.currentUser) return;
    try {
      await this.studyGroupService.startGroupLive(group.id, this.currentUser.uid, this.currentUser.displayName || 'Admin');
      this.toastr.success('Session Live lancée ! Vos camarades ont été alertés.');
    } catch (e) {
      this.toastr.error('Erreur lors du lancement du live.');
    }
  }

  async onTaskFileSelected(event: Event): Promise<void> {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) this.selectedTaskFile = file;
  }

  async submitGroupTask(): Promise<void> {
    const group = this.selectedGroup();
    if (!group || !this.currentUser || this.taskForm.invalid) return;

    this.isSubmittingTask.set(true);
    try {
      let fileUrl = '';
      let fileName = '';

      if (this.selectedTaskFile) {
        const uploadRes = await this.studyGroupService.uploadGroupFile(group.id, this.selectedTaskFile);
        fileUrl = uploadRes.url;
        fileName = uploadRes.name;
      }

      await this.studyGroupService.postGroupTask(group.id, {
        title: this.taskForm.value.title!,
        description: this.taskForm.value.description || '',
        authorId: this.currentUser.uid,
        authorName: this.currentUser.displayName || 'Étudiant',
        authorPhoto: this.currentUser.photoURL || '',
        fileUrl,
        fileName,
      });

      this.toastr.success('Devoir/Exercice partagé avec le groupe !');
      this.showPostTaskModal.set(false);
      this.taskForm.reset();
      this.selectedTaskFile = null;
    } catch (e) {
      this.toastr.error('Erreur lors de la publication.');
    } finally {
      this.isSubmittingTask.set(false);
    }
  }

  isMyMessage(msg: Message): boolean {
    return !!(this.currentUser && msg.senderId === this.currentUser.uid);
  }

  async sendMessage(): Promise<void> {
    const text = this.newMessage.trim();
    const group = this.selectedGroup();
    if (!text || !group || !this.currentUser) return;

    this.isSending.set(true);
    try {
      await this.studyGroupService.sendGroupMessage(
        group.id,
        this.currentUser.uid,
        this.currentUser.displayName || 'Étudiant',
        text,
        this.currentUser.photoURL || '',
        'text'
      );
      this.newMessage = '';
    } catch (e) {
      this.toastr.error('Erreur lors de l\'envoi.');
    } finally {
      this.isSending.set(false);
    }
  }

  getAvatarUrl(name?: string, bg = '2D5BE3', color = 'fff'): string {
    const encoded = encodeURIComponent(name || 'Utilisateur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=${bg}&color=${color}`;
  }

  private scrollToBottom(): void {
    try {
      if (this.messagesContainer) {
        this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
      }
    } catch(err) { }
  }

  openCreateModal(): void {
    this.createGroupForm.reset({
      name: '',
      courseId: '',
      description: '',
      maxMembers: 5,
      joinMode: 'open'
    });
    this.showCreateModal.set(true);
  }

  async submitCreateGroup(): Promise<void> {
    if (this.createGroupForm.invalid || !this.currentUser) {
      this.createGroupForm.markAllAsTouched();
      return;
    }

    this.isSubmitting.set(true);
    try {
      const { name, courseId, description, maxMembers, joinMode } = this.createGroupForm.value;
      const selectedCourse = this.courses().find(c => c.id === courseId);
      const courseTitle = selectedCourse ? selectedCourse.title : (courseId === 'general' ? 'Entraide Générale' : 'Formation');

      await this.studyGroupService.createStudyGroup({
        name: name!.trim(),
        description: description?.trim() || '',
        courseId: courseId!,
        courseTitle,
        creator: this.currentUser,
        maxMembers: Number(maxMembers) || 5,
        joinMode: (joinMode as any) || 'open',
      });

      this.toastr.success(`Groupe « ${name} » créé avec succès !`);
      this.showCreateModal.set(false);
      this.activeTab.set('my-groups');
    } catch (err: any) {
      this.toastr.error('Erreur lors de la création du groupe.');
    } finally {
      this.isSubmitting.set(false);
    }
  }

  async joinGroup(group: StudyGroup): Promise<void> {
    if (!this.currentUser) {
      this.toastr.warning('Veuillez vous connecter pour rejoindre un groupe.');
      return;
    }
    const limit = group.maxMembers || 5;
    if (group.members.length >= limit) {
      this.toastr.warning(`Ce groupe a atteint la limite de ${limit} membres.`);
      return;
    }
    try {
      await this.studyGroupService.joinStudyGroup(group.id, this.currentUser);
      this.toastr.success(`Bienvenue dans le groupe « ${group.name} » !`);
      this.selectGroup(group);
      this.activeTab.set('my-groups');
    } catch (err: any) {
      this.toastr.error(err?.message || 'Erreur lors de l\'adhésion.');
    }
  }

  async requestToJoinGroup(group: StudyGroup): Promise<void> {
    if (!this.currentUser) {
      this.toastr.warning('Veuillez vous connecter pour envoyer une demande.');
      return;
    }
    try {
      await this.studyGroupService.requestToJoin(group.id, this.currentUser);
      this.toastr.success(`Demande d'adhésion envoyée à ${group.creatorName} !`);
    } catch (err: any) {
      this.toastr.error(err?.message || 'Erreur lors de la demande.');
    }
  }

  async cancelRequest(group: StudyGroup): Promise<void> {
    if (!this.currentUser) return;
    try {
      await this.studyGroupService.cancelJoinRequest(group.id, this.currentUser.uid);
      this.toastr.info('Demande d\'adhésion annulée.');
    } catch (err: any) {
      this.toastr.error('Erreur lors de l\'annulation.');
    }
  }

  async acceptApplicant(group: StudyGroup, applicant: any): Promise<void> {
    try {
      await this.studyGroupService.acceptJoinRequest(group.id, applicant);
      this.toastr.success(`Demande de ${applicant.displayName} acceptée !`);
    } catch (err: any) {
      this.toastr.error(err?.message || 'Erreur lors de l\'acceptation.');
    }
  }

  async rejectApplicant(group: StudyGroup, applicantUid: string): Promise<void> {
    try {
      await this.studyGroupService.rejectJoinRequest(group.id, applicantUid);
      this.toastr.info('Demande d\'adhésion refusée.');
    } catch (err: any) {
      this.toastr.error('Erreur lors du refus.');
    }
  }

  async leaveGroup(group: StudyGroup): Promise<void> {
    if (!this.currentUser) return;
    if (confirm(`Voulez-vous vraiment quitter le groupe « ${group.name} » ?`)) {
      try {
        await this.studyGroupService.leaveStudyGroup(group.id, this.currentUser.uid, this.currentUser.displayName || 'Étudiant');
        this.toastr.info(`Vous avez quitté le groupe « ${group.name} ».`);
        this.selectedGroup.set(null);
      } catch (e) {
        this.toastr.error('Erreur lors de la sortie du groupe.');
      }
    }
  }
}
