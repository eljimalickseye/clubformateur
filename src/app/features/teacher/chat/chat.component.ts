import { Component, inject, OnInit, signal, computed, effect, ElementRef, ViewChild, OnDestroy } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { Subscription, switchMap, of, combineLatest } from 'rxjs';
import { Firestore, collection, query, where, getDocs, limit } from '@angular/fire/firestore';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { ChatService } from '../../../core/services/chat.service';
import { PresenceService, UserPresence } from '../../../core/services/presence.service';
import { CourseService } from '../../../core/services/course.service';
import { EnrollmentService } from '../../../core/services/enrollment.service';
import { Conversation, Message, User, Course } from '../../../core/models';
import { ToastrService } from 'ngx-toastr';

interface ActiveStudent {
  id: string;
  name: string;
  role: string;
  level: string;
  avatar?: string;
  email?: string;
  courseTitle?: string;
  progress?: number;
  online: boolean;
}

@Component({
  selector: 'app-teacher-chat',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule, DatePipe],
  template: `
    <div class="flex h-[calc(100vh-5rem)] bg-white overflow-hidden font-body animate-fade-in">

      <!-- ========================================== -->
      <!-- 1. LEFT PANE: Channels & Direct Chats      -->
      <!-- ========================================== -->
      <aside class="w-full md:w-72 lg:w-80 border-r border-dark-border flex-col bg-white shrink-0"
             [class.hidden]="mobileView() === 'chat'"
             [class.flex]="mobileView() === 'list'"
             [class.md:flex]="true">

        <!-- Top Search & Title -->
        <div class="p-4 border-b border-dark-border space-y-3">
          <div class="flex items-center justify-between">
            <h2 class="text-xs font-black uppercase tracking-widest text-light-muted">
              Canaux & Discussions
            </h2>
            <span class="text-[11px] font-bold text-primary bg-primary/10 px-2 py-0.5 rounded-full">
              {{ conversations().length + 2 }} actifs
            </span>
          </div>
          
          <!-- Search input -->
          <div class="relative">
            <input type="text"
                   [(ngModel)]="searchQuery"
                   placeholder="Rechercher un échange..."
                   class="w-full pl-9 pr-4 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-all" />
            <svg class="w-4 h-4 absolute left-3 top-2.5 text-light-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
          </div>
        </div>

        <!-- Channels & General Chats Section -->
        <div class="px-4 py-2 bg-dark-surface2/40 border-b border-dark-border/60">
          <p class="text-[10px] font-bold text-light-muted uppercase tracking-wider">Canaux Collectifs en Direct</p>
        </div>

        <div class="px-2 py-2 space-y-1">
          <!-- General Channel -->
          <button (click)="selectGeneralChannel()"
                  class="w-full text-left px-3 py-2.5 rounded-xl transition-all flex items-center justify-between group cursor-pointer"
                  [class.bg-primary]="activeChannel() === 'general'"
                  [class.text-white]="activeChannel() === 'general'"
                  [class.shadow-sm]="activeChannel() === 'general'"
                  [class.hover:bg-dark-surface2]="activeChannel() !== 'general'">
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 shrink-0" [class.text-white]="activeChannel() === 'general'" [class.text-primary]="activeChannel() !== 'general'" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"/>
              </svg>
              <span class="text-xs font-bold truncate" [class.text-white]="activeChannel() === 'general'" [class.text-light]="activeChannel() !== 'general'">
                général-formation
              </span>
            </div>
            <span class="h-2 w-2 rounded-full bg-emerald-400" [class.ring-2]="activeChannel() === 'general'" [class.ring-white]="activeChannel() === 'general'"></span>
          </button>

          <!-- Q&A Channel -->
          <button (click)="selectQAChannel()"
                  class="w-full text-left px-3 py-2.5 rounded-xl transition-all flex items-center justify-between group cursor-pointer"
                  [class.bg-primary]="activeChannel() === 'qa'"
                  [class.text-white]="activeChannel() === 'qa'"
                  [class.shadow-sm]="activeChannel() === 'qa'"
                  [class.hover:bg-dark-surface2]="activeChannel() !== 'qa'">
            <div class="flex items-center gap-2.5 min-w-0">
              <svg class="w-4 h-4 shrink-0" [class.text-white]="activeChannel() === 'qa'" [class.text-amber-500]="activeChannel() !== 'qa'" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              <span class="text-xs font-bold truncate" [class.text-white]="activeChannel() === 'qa'" [class.text-light]="activeChannel() !== 'qa'">
                questions-devoirs
              </span>
            </div>
            <span class="text-[10px] px-1.5 py-0.5 rounded font-bold"
                  [class.bg-white]="activeChannel() === 'qa'"
                  [class.bg-opacity-20]="activeChannel() === 'qa'"
                  [class.text-white]="activeChannel() === 'qa'"
                  [class.bg-amber-100]="activeChannel() !== 'qa'"
                  [class.text-amber-700]="activeChannel() !== 'qa'">
              Q&A
            </span>
          </button>
        </div>

        <div class="px-4 py-2 bg-dark-surface2/40 border-t border-b border-dark-border/60 flex items-center justify-between">
          <p class="text-[10px] font-bold text-light-muted uppercase tracking-wider">Messages Directs</p>
          <span class="text-[10px] text-light-muted font-bold">{{ filteredConversations().length }}</span>
        </div>

        <!-- Student Direct Conversations List -->
        <div class="flex-1 overflow-y-auto px-2 py-2 divide-y divide-dark-border/30">
          @for (conv of filteredConversations(); track conv.id) {
            <button class="w-full text-left px-3 py-2.5 rounded-xl my-0.5 hover:bg-dark-surface2 transition-all flex items-center gap-3 group cursor-pointer"
                    [class.bg-primary]="selectedConversation()?.id === conv.id && !activeChannel()"
                    [class.text-white]="selectedConversation()?.id === conv.id && !activeChannel()"
                    [class.shadow-md]="selectedConversation()?.id === conv.id && !activeChannel()"
                    (click)="selectConversation(conv)">
              
              <!-- Avatar -->
              <div class="relative shrink-0">
                <img loading="lazy" decoding="async" [src]="getOtherParticipantPhoto(conv)"
                     class="h-9 w-9 rounded-full object-cover border"
                     [class.border-white]="selectedConversation()?.id === conv.id && !activeChannel()"
                     [class.border-dark-border]="selectedConversation()?.id !== conv.id"
                     alt="Avatar">
                <span class="absolute bottom-0 right-0 h-2.5 w-2.5 rounded-full bg-emerald-500 ring-2 ring-white"></span>
              </div>

              <!-- Details -->
              <div class="min-w-0 flex-1">
                <div class="flex justify-between items-center mb-0.5">
                  <p class="text-xs font-bold truncate"
                     [class.text-white]="selectedConversation()?.id === conv.id && !activeChannel()"
                     [class.text-light]="selectedConversation()?.id !== conv.id">
                    {{ getOtherParticipantName(conv) }}
                  </p>
                  @if (conv.lastMessageAt) {
                    <span class="text-[9px]"
                          [class.text-white]="selectedConversation()?.id === conv.id && !activeChannel()"
                          [class.opacity-80]="selectedConversation()?.id === conv.id && !activeChannel()"
                          [class.text-light-muted]="selectedConversation()?.id !== conv.id">
                      {{ formatLastMessageTime(conv.lastMessageAt) }}
                    </span>
                  }
                </div>
                <p class="text-[11px] truncate"
                   [class.text-white]="selectedConversation()?.id === conv.id && !activeChannel()"
                   [class.opacity-90]="selectedConversation()?.id === conv.id && !activeChannel()"
                   [class.text-light-muted]="selectedConversation()?.id !== conv.id"
                   [class.font-bold]="getUnreadCount(conv) > 0">
                  {{ conv.lastMessage || 'Nouvelle conversation' }}
                </p>
              </div>

              @if (getUnreadCount(conv) > 0) {
                <span class="h-4 w-4 rounded-full bg-red-500 text-white text-[9px] font-bold flex items-center justify-center shrink-0">
                  {{ getUnreadCount(conv) }}
                </span>
              }
            </button>
          } @empty {
            <div class="text-center py-8 text-light-muted text-xs">
              <p>Aucune discussion directe.</p>
              <p class="text-[10px] mt-1 text-primary">Cliquez sur un élève à droite pour lui écrire.</p>
            </div>
          }
        </div>
      </aside>

      <!-- ========================================== -->
      <!-- 2. CENTER: Chat Stream & Message Input     -->
      <!-- ========================================== -->
      <main class="flex-1 flex-col bg-slate-50/50 min-w-0"
            [class.hidden]="mobileView() === 'list'"
            [class.flex]="mobileView() === 'chat'"
            [class.md:flex]="true">
        
        <!-- Header Bar -->
        <header class="h-16 border-b border-dark-border bg-white px-4 sm:px-6 flex items-center justify-between shrink-0 shadow-xs">
          <div class="flex items-center gap-2.5 sm:gap-3 min-w-0">
            <!-- Mobile Back Button -->
            <button (click)="mobileView.set('list')" 
                    class="md:hidden p-2 min-h-[40px] min-w-[40px] flex items-center justify-center rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 active:scale-95 transition-all cursor-pointer" 
                    title="Retour aux canaux"
                    aria-label="Retour aux canaux">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
              </svg>
            </button>
            @if (activeChannel()) {
              <div class="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-base shadow-xs shrink-0"
                   [class.bg-primary-50]="activeChannel() === 'general'"
                   [class.text-primary]="activeChannel() === 'general'"
                   [class.bg-amber-50]="activeChannel() === 'qa'"
                   [class.text-amber-600]="activeChannel() === 'qa'">
                @if (activeChannel() === 'general') {
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14"/>
                  </svg>
                } @else {
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                }
              </div>
              <div class="min-w-0">
                <h3 class="font-display font-bold text-light text-sm truncate">
                  {{ activeChannel() === 'general' ? 'général-formation' : 'questions-devoirs' }}
                </h3>
                <p class="text-[10px] text-light-muted">
                  {{ getChannelDescription() }}
                </p>
              </div>
            } @else if (selectedConversation()) {
              <div class="relative shrink-0">
                <img loading="lazy" decoding="async" [src]="getOtherParticipantPhoto(selectedConversation()!)" class="w-9 h-9 rounded-full object-cover border border-dark-border" alt="Avatar" onerror="this.src='assets/default-avatar.png'">
                <span class="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-white"
                      [class.bg-emerald-500]="otherPresence().isOnline"
                      [class.bg-slate-300]="!otherPresence().isOnline"></span>
              </div>
              <div class="min-w-0">
                <h3 class="font-display font-bold text-light text-sm truncate">
                  {{ getOtherParticipantName(selectedConversation()!) }}
                </h3>
                <p class="text-[10px] font-bold flex items-center gap-1"
                   [class.text-emerald-600]="otherPresence().isOnline"
                   [class.text-slate-500]="!otherPresence().isOnline">
                  <span class="w-1.5 h-1.5 rounded-full inline-block"
                        [class.bg-emerald-500]="otherPresence().isOnline"
                        [class.animate-pulse]="otherPresence().isOnline"
                        [class.bg-slate-300]="!otherPresence().isOnline"></span>
                  <span>{{ otherPresence().statusText }} • Discussion privée</span>
                </p>
              </div>
            }
          </div>

          <div class="flex items-center gap-2">
            <button (click)="openQuickLiveAlert()"
                    title="Envoyer un rappel de session"
                    class="px-3 py-1.5 bg-primary/10 hover:bg-primary text-primary hover:text-white rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
              </svg>
              <span class="hidden sm:inline">Alerte Direct</span>
            </button>
          </div>
        </header>

        <!-- Messages Stream -->
        <div #messagesContainer class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4">
          @if (loadingMessages()) {
            <div class="flex items-center justify-center py-12">
              <div class="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
            </div>
          } @else {
            @for (msg of currentMessages(); track msg.id) {
              <div class="flex items-end gap-2.5 max-w-[85%] sm:max-w-[75%]"
                   [class.ml-auto]="isMyMessage(msg)"
                   [class.flex-row-reverse]="isMyMessage(msg)">
                
                <!-- Sender Avatar -->
                <img loading="lazy" decoding="async" [src]="msg.senderPhotoURL || getAvatarUrl(msg.senderName)"
                     class="w-7 h-7 rounded-full object-cover shrink-0 border border-dark-border"
                     alt="Avatar">

                <div class="space-y-1">
                  <!-- Header Name & Time -->
                  <div class="flex items-center gap-2 text-[10px] text-light-muted"
                       [class.justify-end]="isMyMessage(msg)">
                    <span class="font-bold text-light">{{ isMyMessage(msg) ? 'Vous' : msg.senderName }}</span>
                    <span>{{ formatMsgTime(msg) }}</span>
                  </div>

                  <!-- Message Bubble -->
                  <div class="rounded-2xl px-4 py-2.5 text-xs leading-relaxed shadow-xs"
                       [class.bg-primary]="isMyMessage(msg)"
                       [class.text-white]="isMyMessage(msg)"
                       [class.bg-white]="!isMyMessage(msg)"
                       [class.text-light]="!isMyMessage(msg)"
                       [class.border]="!isMyMessage(msg)"
                       [class.border-dark-border]="!isMyMessage(msg)">
                    
                    <!-- Text Content -->
                    @if (msg.content && msg.type !== 'audio') {
                      <p class="whitespace-pre-wrap">{{ msg.content }}</p>
                    }

                    <!-- Audio Note Player -->
                    @if (msg.type === 'audio' && msg.fileUrl) {
                      <div class="space-y-1 py-1">
                        <div class="flex items-center gap-1.5 text-[11px] font-bold" [class.text-white]="isMyMessage(msg)" [class.text-purple-700]="!isMyMessage(msg)">
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"/>
                          </svg>
                          <span>Message Vocal</span>
                          @if (msg.audioDuration) {
                            <span>({{ msg.audioDuration }}s)</span>
                          }
                        </div>
                        <audio [src]="msg.fileUrl" controls class="w-56 h-8 rounded-lg"></audio>
                      </div>
                    }

                    <!-- File Attachment Bubble -->
                    @if (msg.type === 'file' && msg.fileUrl) {
                      <div class="flex items-center gap-2.5 p-2 rounded-xl mt-1.5"
                           [class.bg-blue-900]="isMyMessage(msg)"
                           [class.bg-opacity-30]="isMyMessage(msg)"
                           [class.bg-slate-100]="!isMyMessage(msg)">
                        <svg class="w-5 h-5 shrink-0" [class.text-white]="isMyMessage(msg)" [class.text-primary]="!isMyMessage(msg)" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                        </svg>
                        <div class="min-w-0">
                          <p class="font-bold truncate max-w-[150px]">{{ msg.fileName || 'Fichier joint' }}</p>
                          <a [href]="msg.fileUrl" target="_blank" class="text-[10px] font-semibold underline" [class.text-white]="isMyMessage(msg)" [class.text-primary]="!isMyMessage(msg)">
                            Télécharger
                          </a>
                        </div>
                      </div>
                    }
                  </div>
                </div>

              </div>
            } @empty {
              <div class="text-center py-16 text-light-muted text-xs">
                <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto mb-3 shadow-sm">
                  <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                  </svg>
                </div>
                <p class="font-bold text-light">Début de la discussion</p>
                <p class="text-[11px] mt-0.5">Envoyez un message texte, vocal ou un document.</p>
              </div>
            }
          }
        </div>

        <!-- Quick Response Suggestions -->
        <div class="px-4 py-2.5 bg-white border-t border-dark-border/60 flex items-center gap-2 overflow-x-auto shrink-0">
          <div class="flex items-center gap-1.5 text-[10px] font-bold text-light-muted uppercase whitespace-nowrap">
            <svg class="w-3.5 h-3.5 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"/>
            </svg>
            <span>Réponses rapides :</span>
          </div>
          @for (pill of quickPills; track pill.text) {
            <button (click)="useQuickPill(pill.text)"
                    class="px-3 py-1 rounded-full bg-dark-surface2 hover:bg-primary hover:text-white text-xs font-semibold text-light transition-all whitespace-nowrap cursor-pointer shrink-0 border border-dark-border/50 shadow-2xs">
              {{ pill.text }}
            </button>
          }
        </div>

        <!-- Voice Recording In-Progress Banner -->
        @if (isRecordingVoice()) {
          <div class="px-4 py-3 bg-red-50 border-t border-red-200 flex items-center justify-between animate-pulse shrink-0">
            <div class="flex items-center gap-3">
              <span class="w-3 h-3 rounded-full bg-red-600 inline-block animate-ping"></span>
              <span class="text-xs font-black text-red-700">Enregistrement vocal en cours...</span>
              <span class="text-xs font-mono font-bold text-red-600">{{ formatVoiceTime(recordingSeconds()) }}</span>
            </div>
            <div class="flex items-center gap-2">
              <button (click)="cancelVoiceRecording()" class="px-3 py-1 bg-white text-red-600 text-xs font-bold rounded-lg border border-red-200 cursor-pointer">
                Annuler
              </button>
              <button (click)="sendVoiceRecording()" class="px-3 py-1 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-lg shadow-sm cursor-pointer flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                </svg>
                <span>Envoyer le vocal</span>
              </button>
            </div>
          </div>
        }

        <!-- Bottom Composer Input -->
        <div class="p-4 bg-white border-t border-dark-border shrink-0">
          <div class="flex items-center gap-2">
            
            <!-- File Attachment Button -->
            <label class="p-2.5 rounded-xl border border-dark-border text-light-muted hover:text-primary hover:bg-dark-surface2 transition-all cursor-pointer">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"/>
              </svg>
              <input type="file" (change)="onFileSelected($event)" class="hidden" accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.png,.jpg,.jpeg,.zip,.rar,.txt">
            </label>

            <!-- Voice Note Trigger Button -->
            <button (click)="toggleVoiceRecording()"
                    title="Enregistrer un message vocal"
                    class="p-2.5 rounded-xl border border-dark-border text-light-muted hover:text-purple-600 hover:bg-purple-50 transition-all cursor-pointer">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"/>
              </svg>
            </button>

            <!-- Text input -->
            <input type="text"
                   [(ngModel)]="newMessage"
                   (keyup.enter)="sendMessage()"
                   placeholder="Écrivez votre message..."
                   class="flex-1 px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-all">

            <!-- Send button -->
            <button (click)="sendMessage()"
                    [disabled]="!newMessage.trim() || sending()"
                    class="px-4 py-2.5 bg-primary hover:bg-primary-600 disabled:opacity-40 text-white rounded-xl text-xs font-bold transition-all shadow-md shadow-primary/25 flex items-center gap-1.5 cursor-pointer">
              @if (sending()) {
                <span class="inline-block w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
              } @else {
                <svg class="w-4 h-4 rotate-45" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                </svg>
              }
              <span class="hidden sm:inline">Envoyer</span>
            </button>
          </div>
        </div>

      </main>

      <!-- ========================================== -->
      <!-- 3. RIGHT PANE: Dynamic Enrolled Students   -->
      <!-- ========================================== -->
      <aside class="w-72 lg:w-80 border-l border-dark-border bg-white hidden xl:flex flex-col shrink-0">
        
        <!-- Header -->
        <div class="p-4 border-b border-dark-border space-y-3 bg-slate-50/60">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <h3 class="font-display font-bold text-xs text-light uppercase tracking-wider">
                Mes Apprenants
              </h3>
            </div>
            <span class="px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-black">
              {{ onlineCount() }} en ligne
            </span>
          </div>

          <!-- Search input -->
          <div class="relative">
            <input type="text"
                   [ngModel]="studentSearchText()"
                   (ngModelChange)="studentSearchText.set($event)"
                   placeholder="Rechercher par nom, email..."
                   class="w-full pl-8 pr-3 py-2 bg-white border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary shadow-2xs">
            <svg class="w-3.5 h-3.5 text-light-muted absolute left-2.5 top-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
          </div>

          <!-- Quick Filter Tabs -->
          <div class="flex items-center gap-1.5 pt-0.5">
            <button (click)="studentFilter.set('all')"
                    [class.bg-primary]="studentFilter() === 'all'"
                    [class.text-white]="studentFilter() === 'all'"
                    [class.bg-white]="studentFilter() !== 'all'"
                    [class.text-light-muted]="studentFilter() !== 'all'"
                    class="px-2.5 py-1 rounded-lg text-[10px] font-bold border border-dark-border shadow-2xs transition-all cursor-pointer">
              Tous ({{ enrolledStudents().length }})
            </button>
            <button (click)="studentFilter.set('online')"
                    [class.bg-emerald-600]="studentFilter() === 'online'"
                    [class.text-white]="studentFilter() === 'online'"
                    [class.bg-white]="studentFilter() !== 'online'"
                    [class.text-light-muted]="studentFilter() !== 'online'"
                    class="px-2.5 py-1 rounded-lg text-[10px] font-bold border border-dark-border shadow-2xs transition-all cursor-pointer flex items-center gap-1">
              <span class="w-2 h-2 rounded-full bg-emerald-400"></span>
              <span>En ligne ({{ onlineCount() }})</span>
            </button>
          </div>
        </div>

        <!-- Dynamic Students List -->
        <div class="flex-1 overflow-y-auto p-3 space-y-2">
          @if (loadingStudents()) {
            <div class="space-y-3 p-2">
              @for (i of [1,2,3,4]; track i) {
                <div class="p-3 rounded-2xl bg-dark-surface2/40 animate-pulse flex items-center gap-3">
                  <div class="w-9 h-9 rounded-full bg-dark-border"></div>
                  <div class="space-y-1.5 flex-1">
                    <div class="h-3 bg-dark-border rounded w-2/3"></div>
                    <div class="h-2 bg-dark-border rounded w-1/2"></div>
                  </div>
                </div>
              }
            </div>
          } @else {
            @for (member of filteredStudents(); track member.id) {
              <div (click)="startDirectChatWithStudent(member)"
                   class="w-full text-left p-3 rounded-2xl bg-white hover:bg-primary/5 hover:border-primary/30 transition-all border border-dark-border/60 shadow-2xs group cursor-pointer space-y-2">
                
                <div class="flex items-center justify-between gap-2">
                  <div class="flex items-center gap-2.5 min-w-0">
                    <div class="relative shrink-0">
                      <img loading="lazy" decoding="async" [src]="member.avatar || getAvatarUrl(member.name)"
                           class="w-9 h-9 rounded-full object-cover border border-dark-border shadow-2xs"
                           [alt]="member.name">
                      @if (member.online) {
                        <span class="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-emerald-500 ring-2 ring-white"></span>
                      }
                    </div>
                    <div class="min-w-0">
                      <p class="text-xs font-bold text-light truncate group-hover:text-primary transition-colors">
                        {{ member.name }}
                      </p>
                      @if (member.email) {
                        <p class="text-[10px] text-light-muted truncate">
                          {{ member.email }}
                        </p>
                      }
                    </div>
                  </div>

                  <button class="opacity-0 group-hover:opacity-100 transition-opacity px-2 py-1 rounded-lg bg-primary text-white text-[10px] font-bold shadow-xs shrink-0 flex items-center gap-1">
                    <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                    </svg>
                    <span>Écrire</span>
                  </button>
                </div>

                <!-- Course badge & Progress -->
                <div class="flex items-center justify-between gap-2 pt-1 border-t border-dark-border/40 text-[10px]">
                  <span class="px-2 py-0.5 rounded-md bg-dark-surface2 text-light-muted font-medium truncate max-w-[170px] flex items-center gap-1" [title]="member.courseTitle || 'Formation'">
                    <svg class="w-3 h-3 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                    </svg>
                    <span class="truncate">{{ member.courseTitle || 'Formation active' }}</span>
                  </span>
                  @if (member.progress !== undefined) {
                    <span class="font-bold text-primary shrink-0">
                      {{ member.progress }}%
                    </span>
                  }
                </div>
              </div>
            } @empty {
              <div class="p-8 text-center space-y-2">
                <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto shadow-sm">
                  <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                  </svg>
                </div>
                <p class="text-xs font-bold text-light">Aucun apprenant trouvé</p>
                <p class="text-[11px] text-light-muted">
                  {{ studentSearchText() ? 'Aucun résultat pour cette recherche.' : 'Les apprenants inscrits à vos cours apparaîtront ici automatiquement.' }}
                </p>
              </div>
            }
          }
        </div>

        <!-- Footer Notice -->
        <div class="p-3 border-t border-dark-border bg-slate-50 text-center">
          <div class="flex items-center justify-center gap-1.5 text-[11px] text-light-muted font-medium">
            <svg class="w-3.5 h-3.5 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span>Cliquez sur un apprenant pour ouvrir son fil de discussion privé.</span>
          </div>
        </div>
      </aside>

    </div>
  `,
})
export class ChatComponent implements OnInit, OnDestroy {
  @ViewChild('messagesContainer') private messagesContainer!: ElementRef;

  private store = inject(Store);
  private chatService = inject(ChatService);
  private presenceService = inject(PresenceService);
  private courseService = inject(CourseService);
  private enrollmentService = inject(EnrollmentService);
  private firestore = inject(Firestore);
  private toastr = inject(ToastrService);

  currentUser: User | null = null;
  conversations = signal<Conversation[]>([]);
  selectedConversation = signal<Conversation | null>(null);
  currentMessages = signal<Message[]>([]);
  otherPresence = signal<UserPresence>({ isOnline: false, statusText: 'Hors ligne' });
  private presenceSub?: Subscription;
  
  activeChannel = signal<'general' | 'qa' | null>('general');

  searchQuery = '';
  newMessage = '';
  loadingMessages = signal(false);
  sending = signal(false);

  mobileView = signal<'list' | 'chat'>('list');

  // Audio Recording
  mediaRecorder: MediaRecorder | null = null;
  mediaStream: MediaStream | null = null;
  audioChunks: Blob[] = [];
  isRecordingVoice = signal(false);
  recordingSeconds = signal(0);
  recordingTimer: any = null;

  // Dynamic Students Roster (Right Pane)
  studentSearchText = signal('');
  studentFilter = signal<'all' | 'online'>('all');
  loadingStudents = signal(true);
  enrolledStudents = signal<ActiveStudent[]>([]);

  onlineCount = computed(() => this.enrolledStudents().filter(s => s.online).length);

  filteredStudents = computed(() => {
    let list = this.enrolledStudents();
    if (this.studentFilter() === 'online') {
      list = list.filter(s => s.online);
    }
    const q = this.studentSearchText().trim().toLowerCase();
    if (q) {
      list = list.filter(s =>
        s.name.toLowerCase().includes(q) ||
        (s.email && s.email.toLowerCase().includes(q)) ||
        (s.courseTitle && s.courseTitle.toLowerCase().includes(q))
      );
    }
    return list;
  });

  quickPills = [
    { text: 'Bonjour à tous !' },
    { text: 'Avez-vous des questions sur le cours ?' },
    { text: 'Très bien compris !' },
    { text: 'Merci pour votre participation !' },
    { text: 'Rendez-vous pour la session live !' },
    { text: 'N\'hésitez pas à consulter le devoir.' },
  ];

  private messagesSub?: Subscription;

  constructor() {
    effect(() => {
      const msgs = this.currentMessages();
      setTimeout(() => this.scrollToBottom(), 100);
    });
  }

  ngOnInit() {
    this.store.select(selectCurrentUser).pipe(
      switchMap(user => {
        this.currentUser = user;
        if (!user) return of([]);
        this.loadDynamicStudents(user.uid);
        return this.chatService.getUserConversations(user.uid);
      })
    ).subscribe(convs => {
      this.conversations.set(convs);
    });

    // Default to general channel
    this.selectGeneralChannel();
  }

  private loadDynamicStudents(teacherId: string) {
    this.loadingStudents.set(true);
    const studentMap = new Map<string, ActiveStudent>();

    // 1. Charger les cours du formateur et les inscriptions associées
    this.courseService.getTeacherCourses(teacherId).subscribe({
      next: (courses) => {
        if (courses.length > 0) {
          const obsList = courses.map(c => this.enrollmentService.getCourseEnrollments(c.id));
          combineLatest(obsList).subscribe({
            next: (enrollmentArrays) => {
              enrollmentArrays.flat().forEach(en => {
                const cTitle = courses.find(c => c.id === en.courseId)?.title || 'Formation active';
                studentMap.set(en.studentId, {
                  id: en.studentId,
                  name: en.studentName || 'Apprenant',
                  role: 'Inscrit',
                  level: 'Apprenant actif',
                  courseTitle: cTitle,
                  progress: en.progress || 0,
                  avatar: `https://ui-avatars.com/api/?name=${encodeURIComponent(en.studentName || 'Apprenant')}&background=2D5BE3&color=fff`,
                  online: true,
                });
              });
              this.fetchUsersFromFirestore(studentMap);
            },
            error: () => this.fetchUsersFromFirestore(studentMap)
          });
        } else {
          this.fetchUsersFromFirestore(studentMap);
        }
      },
      error: () => this.fetchUsersFromFirestore(studentMap)
    });
  }

  private async fetchUsersFromFirestore(studentMap: Map<string, ActiveStudent>) {
    try {
      const q = query(collection(this.firestore, 'users'), where('role', '==', 'student'), limit(30));
      const snap = await getDocs(q);
      snap.forEach(docSnap => {
        const u = docSnap.data() as any;
        if (!studentMap.has(u.uid)) {
          let isOnline = u.isOnline === true;
          if (u.lastSeen) {
            const d = u.lastSeen?.toDate ? u.lastSeen.toDate() : new Date(u.lastSeen);
            if ((Date.now() - d.getTime()) <= 3 * 60 * 1000) {
              isOnline = true;
            }
          }

          studentMap.set(u.uid, {
            id: u.uid,
            name: u.displayName || 'Apprenant',
            email: u.email || '',
            role: 'Étudiant',
            level: 'Club des Formateurs',
            courseTitle: 'Apprenant inscrit',
            progress: 0,
            avatar: u.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(u.displayName || 'Apprenant')}&background=2D5BE3&color=fff`,
            online: isOnline,
          });
        }
      });
    } catch (e) {
      console.warn('Could not query users collection directly:', e);
    } finally {
      this.enrolledStudents.set(Array.from(studentMap.values()));
      this.loadingStudents.set(false);
    }
  }

  ngOnDestroy() {
    if (this.messagesSub) this.messagesSub.unsubscribe();
    if (this.presenceSub) this.presenceSub.unsubscribe();
    this.cancelVoiceRecording();
  }

  selectGeneralChannel() {
    this.activeChannel.set('general');
    this.selectedConversation.set(null);
    this.mobileView.set('chat');
    this.listenToChannel('channel_general');
  }

  selectQAChannel() {
    this.activeChannel.set('qa');
    this.selectedConversation.set(null);
    this.mobileView.set('chat');
    this.listenToChannel('channel_qa');
  }

  private listenToChannel(channelId: string) {
    this.loadingMessages.set(true);
    if (this.messagesSub) this.messagesSub.unsubscribe();

    this.messagesSub = this.chatService.getChannelMessages(channelId).subscribe(msgs => {
      this.currentMessages.set(msgs);
      this.loadingMessages.set(false);
    });
  }

  getChannelDescription(): string {
    return this.activeChannel() === 'general'
      ? 'Discussion ouverte en direct avec tous les apprenants'
      : 'Salon d’entraide pour les devoirs et exercices';
  }

  formatMsgTime(msg: Message): string {
    if (!msg?.createdAt) return 'À l’instant';
    if (typeof (msg.createdAt as any).toDate === 'function') {
      const d = (msg.createdAt as any).toDate();
      const hh = d.getHours().toString().padStart(2, '0');
      const mm = d.getMinutes().toString().padStart(2, '0');
      return `${hh}:${mm}`;
    }
    if (typeof (msg.createdAt as any).toMillis === 'function') {
      const d = new Date((msg.createdAt as any).toMillis());
      const hh = d.getHours().toString().padStart(2, '0');
      const mm = d.getMinutes().toString().padStart(2, '0');
      return `${hh}:${mm}`;
    }
    return 'À l’instant';
  }

  formatLastMessageTime(val: any): string {
    if (!val) return '';
    try {
      if (typeof val?.toDate === 'function') {
        const d = val.toDate();
        const hh = d.getHours().toString().padStart(2, '0');
        const mm = d.getMinutes().toString().padStart(2, '0');
        return `${hh}:${mm}`;
      }
      if (typeof val?.toMillis === 'function') {
        const d = new Date(val.toMillis());
        const hh = d.getHours().toString().padStart(2, '0');
        const mm = d.getMinutes().toString().padStart(2, '0');
        return `${hh}:${mm}`;
      }
      if (val instanceof Date) {
        const hh = val.getHours().toString().padStart(2, '0');
        const mm = val.getMinutes().toString().padStart(2, '0');
        return `${hh}:${mm}`;
      }
      if (typeof val === 'number') {
        const d = new Date(val);
        const hh = d.getHours().toString().padStart(2, '0');
        const mm = d.getMinutes().toString().padStart(2, '0');
        return `${hh}:${mm}`;
      }
    } catch {
      return '';
    }
    return '';
  }

  isMyMessage(msg: Message): boolean {
    return !!(this.currentUser && msg.senderId === this.currentUser.uid);
  }

  filteredConversations(): Conversation[] {
    if (!this.searchQuery.trim()) return this.conversations();
    const q = this.searchQuery.toLowerCase();
    return this.conversations().filter(c => 
      this.getOtherParticipantName(c).toLowerCase().includes(q) ||
      (c.courseName && c.courseName.toLowerCase().includes(q))
    );
  }

  selectConversation(conv: Conversation) {
    this.activeChannel.set(null);
    this.mobileView.set('chat');
    this.selectedConversation.set(conv);
    this.loadingMessages.set(true);
    
    if (this.messagesSub) {
      this.messagesSub.unsubscribe();
    }

    if (this.presenceSub) {
      this.presenceSub.unsubscribe();
    }

    const otherUid = conv.participants.find(id => id !== this.currentUser?.uid);
    if (otherUid) {
      this.presenceSub = this.presenceService.getUserPresence(otherUid).subscribe(p => {
        this.otherPresence.set(p);
      });
    }

    this.messagesSub = this.chatService.getMessages(conv.id).subscribe(msgs => {
      this.currentMessages.set(msgs);
      this.loadingMessages.set(false);
      setTimeout(() => this.scrollToBottom(), 50);
    });
  }

  async startDirectChatWithStudent(student: ActiveStudent) {
    if (!this.currentUser) return;
    try {
      const convId = await this.chatService.getOrCreateConversation(
        this.currentUser.uid,
        this.currentUser.displayName || 'Professeur',
        this.currentUser.photoURL || '',
        student.id,
        student.name,
        student.avatar || '',
        'Formation'
      );
      this.activeChannel.set(null);
      this.mobileView.set('chat');
      this.selectConversation({
        id: convId,
        participants: [this.currentUser.uid, student.id],
        participantNames: { [student.id]: student.name },
        participantPhotos: { [student.id]: student.avatar || '' },
        lastMessage: 'Discussion initialisée',
        lastMessageAt: null as any,
        unreadCount: {}
      });
      this.toastr.success(`Discussion avec ${student.name} ouverte !`);
    } catch (e) {
      this.toastr.error('Erreur lors de l\'ouverture de la discussion.');
    }
  }

  useQuickPill(text: string) {
    this.newMessage = text;
  }

  openQuickLiveAlert() {
    this.newMessage = '🔴 Rappel : Une session visioconférence en direct va débuter ! Rejoignez la salle dès maintenant.';
  }

  async onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0 || !this.currentUser) return;

    const file = input.files[0];
    const targetId = this.activeChannel() ? `channel_${this.activeChannel()}` : this.selectedConversation()?.id;
    if (!targetId) return;

    this.sending.set(true);
    try {
      this.toastr.info('Téléversement du fichier...');
      const uploadRes = await this.chatService.uploadChatFile(targetId, file);

      if (this.activeChannel()) {
        await this.chatService.sendChannelMessage(
          `channel_${this.activeChannel()}`,
          this.currentUser.uid,
          this.currentUser.displayName || 'Formateur',
          uploadRes.name,
          this.currentUser.photoURL || '',
          'file',
          uploadRes.url,
          uploadRes.name
        );
      } else {
        await this.chatService.sendMessage(
          this.selectedConversation()!.id,
          this.currentUser.uid,
          this.currentUser.displayName || 'Formateur',
          uploadRes.name,
          this.currentUser.photoURL || '',
          'file',
          uploadRes.url,
          uploadRes.name
        );
      }

      this.toastr.success('Fichier envoyé avec succès !');
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors de l\'envoi du document.');
    } finally {
      this.sending.set(false);
      input.value = '';
    }
  }

  // ─── Voice Note Recording in Chat ───────────────────────────────

  async toggleVoiceRecording() {
    if (this.isRecordingVoice()) {
      await this.sendVoiceRecording();
    } else {
      await this.startVoiceRecording();
    }
  }

  async startVoiceRecording() {
    try {
      this.mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(this.mediaStream);
      this.audioChunks = [];

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) this.audioChunks.push(event.data);
      };

      this.mediaRecorder.start();
      this.isRecordingVoice.set(true);
      this.recordingSeconds.set(0);

      this.recordingTimer = setInterval(() => {
        this.recordingSeconds.update(s => s + 1);
      }, 1000);
    } catch (e) {
      this.toastr.error('Impossible d\'accéder au microphone.');
    }
  }

  cancelVoiceRecording() {
    if (this.mediaRecorder && this.isRecordingVoice()) {
      this.mediaRecorder.stop();
      this.isRecordingVoice.set(false);
      clearInterval(this.recordingTimer);
      this.audioChunks = [];
      if (this.mediaStream) {
        this.mediaStream.getTracks().forEach(t => t.stop());
        this.mediaStream = null;
      }
    }
  }

  private blobToDataUrl(blob: Blob): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  async sendVoiceRecording() {
    if (!this.mediaRecorder || !this.currentUser) return;

    this.mediaRecorder.onstop = async () => {
      const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });
      const duration = this.recordingSeconds();
      const targetId = this.activeChannel() ? `channel_${this.activeChannel()}` : this.selectedConversation()?.id;
      
      if (this.mediaStream) {
        this.mediaStream.getTracks().forEach(t => t.stop());
        this.mediaStream = null;
      }

      if (!targetId) return;

      this.sending.set(true);
      try {
        let audioUrl = '';
        try {
          audioUrl = await this.chatService.uploadChatAudio(targetId, audioBlob);
        } catch (uploadErr) {
          console.warn('Storage upload fallback to base64:', uploadErr);
          audioUrl = await this.blobToDataUrl(audioBlob);
        }

        if (this.activeChannel()) {
          await this.chatService.sendChannelMessage(
            `channel_${this.activeChannel()}`,
            this.currentUser!.uid,
            this.currentUser!.displayName || 'Formateur',
            'Message vocal',
            this.currentUser!.photoURL || '',
            'audio',
            audioUrl,
            'vocal.webm',
            duration
          );
        } else {
          await this.chatService.sendMessage(
            this.selectedConversation()!.id,
            this.currentUser!.uid,
            this.currentUser!.displayName || 'Formateur',
            'Message vocal',
            this.currentUser!.photoURL || '',
            'audio',
            audioUrl,
            'audio.webm',
            duration
          );
        }

        this.toastr.success('Note vocale envoyée !');
      } catch (err) {
        console.error(err);
        this.toastr.error('Erreur lors de l\'envoi du message vocal.');
      } finally {
        this.sending.set(false);
      }
    };

    this.mediaRecorder.stop();
    this.isRecordingVoice.set(false);
    clearInterval(this.recordingTimer);
  }

  formatVoiceTime(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  async sendMessage() {
    const text = this.newMessage.trim();
    if (!text || !this.currentUser) return;

    this.sending.set(true);
    try {
      if (this.activeChannel()) {
        await this.chatService.sendChannelMessage(
          `channel_${this.activeChannel()}`,
          this.currentUser.uid,
          this.currentUser.displayName || 'Formateur',
          text,
          this.currentUser.photoURL || ''
        );
      } else if (this.selectedConversation()) {
        await this.chatService.sendMessage(
          this.selectedConversation()!.id,
          this.currentUser.uid,
          this.currentUser.displayName || 'Formateur',
          text,
          this.currentUser.photoURL || ''
        );
      }
      this.newMessage = '';
    } catch (e) {
      console.error('Error sending message:', e);
      this.toastr.error('Erreur lors de l\'envoi du message.');
    } finally {
      this.sending.set(false);
    }
  }

  getOtherParticipantName(conv: Conversation): string {
    if (!this.currentUser) return 'Étudiant';
    const otherId = conv.participants?.find(id => id !== this.currentUser!.uid);
    if (otherId && conv.participantNames && conv.participantNames[otherId]) {
      return conv.participantNames[otherId];
    }
    return 'Étudiant';
  }

  getOtherParticipantPhoto(conv: Conversation): string {
    if (!this.currentUser) return 'https://ui-avatars.com/api/?name=E&background=2D5BE3&color=fff';
    const otherId = conv.participants?.find(id => id !== this.currentUser!.uid);
    if (otherId && conv.participantPhotos && conv.participantPhotos[otherId]) {
      return conv.participantPhotos[otherId];
    }
    return 'https://ui-avatars.com/api/?name=' + (encodeURIComponent(this.getOtherParticipantName(conv))) + '&background=2D5BE3&color=fff';
  }

  getAvatarUrl(name?: string, bg = '2D5BE3', color = 'fff'): string {
    const encoded = encodeURIComponent(name || 'Utilisateur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=${bg}&color=${color}`;
  }

  getUnreadCount(conv: Conversation): number {
    if (!this.currentUser || !conv.unreadCount) return 0;
    return conv.unreadCount[this.currentUser.uid] || 0;
  }

  private scrollToBottom() {
    try {
      if (this.messagesContainer) {
        this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
      }
    } catch(err) { }
  }
}
