import { Component, inject, OnInit, signal, effect, ElementRef, ViewChild, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { Subscription, switchMap, of, firstValueFrom } from 'rxjs';
import { Firestore, collection, query, where, getDocs } from '@angular/fire/firestore';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { ChatService } from '../../../core/services/chat.service';
import { AuthService } from '../../../core/services/auth.service';
import { PresenceService, UserPresence } from '../../../core/services/presence.service';
import { Conversation, Message, User } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../../shared/components/refresh-button/refresh-button.component';

@Component({
  selector: 'app-student-chat',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule, BackButtonComponent, RefreshButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-2 sm:px-6 lg:px-8 py-2 sm:py-3 font-body animate-fade-in flex flex-col h-[calc(100dvh-5rem)] md:h-[calc(100vh-2rem)] overflow-hidden">
      <!-- Header -->
      <div class="mb-2 sm:mb-3 rounded-2xl border border-slate-200 bg-white p-3 sm:p-4 flex items-center justify-between gap-3 shadow-xs shrink-0">
        <div>
          <div class="flex items-center gap-2">
            <span class="inline-block w-2.5 h-2.5 rounded-full bg-primary animate-pulse"></span>
            <p class="text-[11px] uppercase font-bold tracking-wider text-light-muted">Messagerie directe</p>
          </div>
          <h1 class="font-display text-lg sm:text-xl font-black text-light mt-0.5">Échanges & Devoirs</h1>
          <p class="text-light-muted text-xs hidden sm:block">Discutez en direct avec vos formateurs et échangez vos questions et devoirs.</p>
        </div>
        <div class="flex items-center gap-2 shrink-0">
          <app-refresh-button />
          <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" [showIconOnlyOnMobile]="true" />
        </div>
      </div>

      <!-- Main Chat Area (Fixed to viewport height, perfectly positioned) -->
      <div class="grid grid-cols-1 lg:grid-cols-[320px_1fr] gap-3 flex-1 min-h-0 overflow-hidden">

        <!-- Conversations Sidebar -->
        <aside class="card overflow-hidden flex flex-col h-full bg-white border border-slate-200 shadow-xs"
               [class.hidden]="mobileView() === 'chat'"
               [class.flex]="mobileView() === 'list'">
          
          <div class="p-3.5 border-b border-dark-border bg-slate-50 space-y-2.5">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-light uppercase tracking-wider">Discussions</span>
              <button (click)="openNewChatModal()"
                      class="px-2.5 py-1 rounded-xl bg-primary text-white text-[11px] font-bold shadow-xs hover:bg-primary-600 transition-all flex items-center gap-1 cursor-pointer active:scale-95">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
                <span>+ Écrire</span>
              </button>
            </div>

            <div class="relative">
              <svg class="w-4 h-4 text-light-muted absolute left-3 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input class="input !pl-9 !py-2 text-xs" placeholder="Rechercher un formateur..." [(ngModel)]="searchQuery" />
            </div>
          </div>

          <div class="divide-y divide-dark-border overflow-y-auto flex-1">
            @for (conv of filteredConversations(); track conv.id) {
              <button class="w-full text-left px-4 py-3.5 hover:bg-primary/5 transition-colors group relative cursor-pointer"
                      [class.bg-primary-50]="selectedConversation()?.id === conv.id"
                      (click)="selectConversation(conv)">
                <div class="flex items-center gap-3">
                  <div class="relative shrink-0">
                    <img loading="lazy" decoding="async" [src]="getOtherParticipantPhoto(conv)" class="h-11 w-11 rounded-xl object-cover bg-dark-surface2 border border-dark-border" alt="Avatar" onerror="this.src='assets/default-avatar.png'">
                    <span class="absolute -bottom-1 -right-1 w-3 h-3 rounded-full bg-emerald-500 border-2 border-white"></span>
                  </div>

                  <div class="min-w-0 flex-1">
                    <div class="flex justify-between items-center mb-0.5">
                      <p class="text-xs font-bold text-light truncate group-hover:text-primary transition-colors">{{ getOtherParticipantName(conv) }}</p>
                      @if (conv.lastMessageAt) {
                        <span class="text-[10px] text-light-muted font-medium">{{ formatTime(conv.lastMessageAt) }}</span>
                      }
                    </div>
                    <p class="text-[11px] text-light-muted truncate" [class.font-bold]="getUnreadCount(conv) > 0" [class.text-primary]="getUnreadCount(conv) > 0">
                      {{ conv.lastMessage || 'Nouvelle discussion' }}
                    </p>
                  </div>

                  @if (getUnreadCount(conv) > 0) {
                    <div class="w-5 h-5 rounded-full bg-primary flex items-center justify-center text-[10px] font-bold text-white shrink-0 shadow-sm">
                      {{ getUnreadCount(conv) }}
                    </div>
                  }
                </div>
              </button>
            } @empty {
              <div class="p-6 text-center text-light-muted text-xs space-y-3">
                <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto shadow-xs">
                  <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                  </svg>
                </div>
                <div>
                  <p class="font-bold text-light text-xs">Aucune conversation active</p>
                  <p class="text-[11px] text-light-muted mt-0.5">Échangez directement avec vos professeurs.</p>
                </div>
                <button (click)="openNewChatModal()"
                        class="w-full py-2.5 rounded-xl bg-primary hover:bg-primary-600 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5 cursor-pointer active:scale-95">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                  </svg>
                  <span>Contacter un Formateur</span>
                </button>
              </div>
            }
          </div>
        </aside>

        <!-- Chat Main Window -->
        <section class="card flex flex-col h-full bg-white border border-dark-border shadow-sm overflow-hidden"
                 [class.hidden]="mobileView() === 'list'"
                 [class.flex]="mobileView() === 'chat'">
          
          @if (selectedConversation()) {
            <!-- Chat Header -->
            <div class="px-4 sm:px-5 py-3.5 border-b border-dark-border flex items-center justify-between bg-white shadow-xs">
              <div class="flex items-center gap-3">
                <!-- Mobile Back Button -->
                <button (click)="mobileView.set('list')" class="lg:hidden p-2 -ml-2 rounded-xl text-light-muted hover:text-light hover:bg-slate-100 transition-colors cursor-pointer" title="Retour aux discussions">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>

                <div class="relative">
                  <img loading="lazy" decoding="async" [src]="getOtherParticipantPhoto(selectedConversation()!)" class="h-10 w-10 rounded-xl object-cover bg-dark-surface2 border border-dark-border" alt="Avatar" onerror="this.src='assets/default-avatar.png'">
                  <span class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-white"
                        [class.bg-emerald-500]="otherPresence().isOnline"
                        [class.bg-slate-300]="!otherPresence().isOnline"></span>
                </div>
                <div>
                  <h3 class="font-display text-sm font-bold text-light">{{ getOtherParticipantName(selectedConversation()!) }}</h3>
                  <p class="text-[11px] font-medium flex items-center gap-1.5"
                     [class.text-emerald-600]="otherPresence().isOnline"
                     [class.text-slate-500]="!otherPresence().isOnline">
                    <span class="inline-block w-2 h-2 rounded-full"
                          [class.bg-emerald-500]="otherPresence().isOnline"
                          [class.animate-pulse]="otherPresence().isOnline"
                          [class.bg-slate-300]="!otherPresence().isOnline"></span>
                    <span class="font-bold">{{ otherPresence().statusText }}</span>
                    @if (selectedConversation()?.courseName) {
                      <span class="text-slate-400">• {{ selectedConversation()?.courseName }}</span>
                    }
                  </p>
                </div>
              </div>

              <!-- Action buttons -->
              <div class="flex items-center gap-2">
                <button (click)="openNewChatModal()" class="p-2 rounded-xl text-light-muted hover:text-primary hover:bg-slate-100 transition-all cursor-pointer" title="Changer ou contacter un autre formateur">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                  </svg>
                </button>
              </div>
            </div>

            <!-- Messages Stream -->
            <div #messagesContainer class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-4 bg-slate-50/50">
              @if (loadingMessages()) {
                <div class="flex h-full items-center justify-center">
                  <div class="flex items-center gap-2 text-xs text-light-muted">
                    <span class="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin"></span>
                    <span>Chargement des messages...</span>
                  </div>
                </div>
              } @else {
                @for (msg of currentMessages(); track msg.id) {
                  <div class="flex items-end gap-2.5 max-w-[85%] sm:max-w-[75%]"
                       [class.ml-auto]="isMyMessage(msg)"
                       [class.flex-row-reverse]="isMyMessage(msg)">
                    
                    <img loading="lazy" decoding="async" [src]="msg.senderPhotoURL || (isMyMessage(msg) ? (currentUser?.photoURL || 'assets/default-avatar.png') : getOtherParticipantPhoto(selectedConversation()!))"
                         class="w-7 h-7 rounded-full object-cover shrink-0 border border-dark-border"
                         alt="Sender" onerror="this.src='assets/default-avatar.png'">

                    <div class="max-w-[85%] sm:max-w-[70%] rounded-2xl px-4 py-2.5 text-xs shadow-xs"
                         [class.bg-primary]="isMyMessage(msg)"
                         [class.text-white]="isMyMessage(msg)"
                         [class.bg-white]="!isMyMessage(msg)"
                         [class.border]="!isMyMessage(msg)"
                         [class.border-dark-border]="!isMyMessage(msg)"
                         [class.text-light]="!isMyMessage(msg)">

                      <!-- Text message -->
                      @if (!msg.type || msg.type === 'text') {
                        <p class="whitespace-pre-wrap break-words leading-relaxed text-[13px]">{{ msg.content }}</p>
                      }

                      <!-- Voice note message -->
                      @if (msg.type === 'audio') {
                        <div class="py-1 min-w-[220px]">
                          <div class="flex items-center gap-2 mb-2">
                            <span class="p-1.5 rounded-lg text-xs" [class.bg-primary-600]="isMyMessage(msg)" [class.bg-primary-100]="!isMyMessage(msg)">
                              <svg class="w-4 h-4" [class.text-white]="isMyMessage(msg)" [class.text-primary]="!isMyMessage(msg)" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                              </svg>
                            </span>
                            <span class="font-bold text-[11px]" [class.text-white]="isMyMessage(msg)" [class.text-light]="!isMyMessage(msg)">Message vocal</span>
                            @if (msg.audioDuration) {
                              <span class="text-[10px] opacity-75 font-mono ml-auto">({{ formatVoiceDuration(msg.audioDuration) }})</span>
                            }
                          </div>
                          @if (msg.fileUrl) {
                            <audio controls class="w-full h-8 mt-1 rounded" [src]="msg.fileUrl"></audio>
                          }
                        </div>
                      }

                      <!-- File attachment message -->
                      @if (msg.type === 'file' || msg.type === 'image') {
                        <div class="py-1">
                          @if (msg.type === 'image' || isImageUrl(msg.fileUrl || '')) {
                            <a [href]="msg.fileUrl" target="_blank" class="block mb-2 rounded-xl overflow-hidden border border-black/10 max-w-sm">
                              <img loading="lazy" decoding="async" [src]="msg.fileUrl" class="w-full max-h-60 object-cover hover:scale-105 transition-transform" alt="Image">
                            </a>
                          }
                          <div class="flex items-center gap-3 p-2.5 rounded-xl border"
                               [class.bg-primary-600]="isMyMessage(msg)"
                               [class.border-primary-400]="isMyMessage(msg)"
                               [class.bg-slate-100]="!isMyMessage(msg)"
                               [class.border-dark-border]="!isMyMessage(msg)">
                            <div class="p-2 rounded-lg" [class.bg-primary-700]="isMyMessage(msg)" [class.bg-primary-50]="!isMyMessage(msg)">
                              <svg class="w-5 h-5" [class.text-white]="isMyMessage(msg)" [class.text-primary]="!isMyMessage(msg)" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                              </svg>
                            </div>
                            <div class="min-w-0 flex-1">
                              <p class="font-bold text-xs truncate" [class.text-white]="isMyMessage(msg)" [class.text-light]="!isMyMessage(msg)">
                                {{ msg.fileName || 'Document joint' }}
                              </p>
                              <span class="text-[10px] opacity-75">Pièce jointe</span>
                            </div>
                            @if (msg.fileUrl) {
                              <a [href]="msg.fileUrl" target="_blank" download class="p-2 rounded-lg hover:bg-black/10 transition-all shrink-0" title="Télécharger">
                                <svg class="w-4 h-4" [class.text-white]="isMyMessage(msg)" [class.text-primary]="!isMyMessage(msg)" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                                </svg>
                              </a>
                            }
                          </div>
                        </div>
                      }

                      <!-- Timestamp -->
                      <div class="text-[10px] text-right mt-1 opacity-75 flex items-center justify-end gap-1">
                        <span>{{ formatTime(msg.createdAt) }}</span>
                        @if (isMyMessage(msg)) {
                          <svg class="w-3 h-3 text-white/90 inline" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                          </svg>
                        }
                      </div>
                    </div>
                  </div>
                } @empty {
                  <div class="flex h-full flex-col items-center justify-center text-light-muted text-xs p-6 text-center">
                    <div class="w-12 h-12 rounded-2xl bg-white border border-dark-border flex items-center justify-center text-primary mb-3 shadow-xs">
                      <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                      </svg>
                    </div>
                    <p class="font-bold text-light text-sm">Démarrez la conversation</p>
                    <p class="text-light-muted mt-1 max-w-xs">Posez vos questions et échangez directement avec votre formateur.</p>
                  </div>
                }
              }
            </div>

            <!-- Chat Input Bar -->
            <div class="p-3 sm:p-4 border-t border-dark-border bg-white flex items-center gap-2">
              <!-- File Attachment Button -->
              <input type="file" #fileInput class="hidden" (change)="onFileSelected($event)" accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.png,.jpg,.jpeg,.zip,.rar,.txt" />
              <button (click)="fileInput.click()" [disabled]="sending()"
                      class="p-2.5 text-light-muted hover:text-primary hover:bg-slate-100 rounded-xl transition-all cursor-pointer" title="Joindre un fichier (PDF, image, document)">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                </svg>
              </button>

              <!-- Text Input -->
              <input class="input flex-1 !py-2.5 text-xs sm:text-sm" placeholder="Écrire un message..." [(ngModel)]="newMessage" (keyup.enter)="sendMessage()" />
              
              <!-- Send Button -->
              <button class="btn-primary !px-4 sm:!px-5 !py-2.5 flex items-center gap-1.5 cursor-pointer" (click)="sendMessage()" [disabled]="!newMessage.trim() || sending()">
                <span>{{ sending() ? '...' : 'Envoyer' }}</span>
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
              </button>
            </div>
          } @else {
            <div class="flex-1 flex flex-col items-center justify-center text-center p-8 bg-slate-50 space-y-4">
              <div class="w-16 h-16 rounded-2xl bg-white border border-dark-border shadow-sm flex items-center justify-center text-primary">
                <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
              </div>
              <div class="space-y-1">
                <h3 class="font-display text-lg sm:text-xl font-bold text-light">Messagerie directe avec vos Formateurs</h3>
                <p class="text-xs sm:text-sm text-light-muted max-w-sm mx-auto">
                  Sélectionnez une discussion existante ou écrivez à un formateur pour poser des questions et échanger sur vos devoirs.
                </p>
              </div>
              <button (click)="openNewChatModal()"
                      class="px-5 py-2.5 rounded-xl bg-primary hover:bg-primary-600 text-white text-xs font-bold transition-all shadow-md shadow-primary/20 flex items-center gap-2 cursor-pointer active:scale-95">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
                <span>Nouvelle discussion avec un Formateur</span>
              </button>
            </div>
          }
        </section>
      </div>

      <!-- MODAL: NOUVELLE DISCUSSION / SÉLECTION D'UN FORMATEUR -->
      @if (showNewChatModal()) {
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-xs animate-fade-in"
             (click)="showNewChatModal.set(false)">
          <div class="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-dark-border space-y-4 text-slate-800"
               (click)="$event.stopPropagation()">
            
            <div class="flex items-center justify-between border-b border-dark-border pb-3">
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <h3 class="font-display text-base font-bold text-slate-900">Écrire à un Formateur</h3>
              </div>
              <button (click)="showNewChatModal.set(false)" class="text-slate-400 hover:text-slate-700 p-1 cursor-pointer">✕</button>
            </div>

            <!-- Search input inside modal -->
            <div class="relative">
              <svg class="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
              </svg>
              <input type="text" [(ngModel)]="teacherSearchQuery" placeholder="Rechercher par nom ou matière..."
                     class="w-full pl-9 pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 outline-none focus:bg-white focus:border-primary">
            </div>

            <!-- Teachers list -->
            <div class="max-h-72 overflow-y-auto divide-y divide-slate-100 pr-1 space-y-1">
              @if (loadingTeachers()) {
                <div class="py-8 text-center text-xs text-slate-500 flex items-center justify-center gap-2">
                  <span class="w-4 h-4 border-2 border-primary border-t-transparent rounded-full animate-spin"></span>
                  <span>Chargement des formateurs...</span>
                </div>
              } @else {
                @for (t of filteredTeachers(); track t.uid) {
                  <button (click)="startConversationWithTeacher(t)"
                          class="w-full text-left p-3 rounded-2xl hover:bg-primary/5 transition-all flex items-center justify-between gap-3 group cursor-pointer border border-transparent hover:border-primary/20">
                    <div class="flex items-center gap-3 min-w-0">
                      <div class="relative shrink-0">
                        <img loading="lazy" decoding="async" [src]="t.photoURL || getAvatarUrl(t.displayName)"
                             class="w-10 h-10 rounded-xl object-cover bg-slate-100 border border-slate-200"
                             alt="Avatar"
                             onerror="this.src='assets/default-avatar.png'">
                        <span class="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-white"
                              [class.bg-emerald-500]="t.isOnline"
                              [class.bg-slate-300]="!t.isOnline"
                              [title]="t.isOnline ? 'En ligne' : 'Hors ligne'"></span>
                      </div>
                      <div class="min-w-0">
                        <div class="flex items-center gap-1.5">
                          <p class="text-xs font-bold text-slate-900 group-hover:text-primary transition-colors truncate">
                            {{ t.displayName || 'Formateur' }}
                          </p>
                          @if (t.isOnline) {
                            <span class="px-1.5 py-0.2 rounded-md bg-emerald-50 text-emerald-700 text-[9px] font-bold">En ligne</span>
                          }
                        </div>
                        <p class="text-[11px] text-slate-500 truncate">
                          {{ t.speciality || 'Formateur Certifié' }}
                        </p>
                      </div>
                    </div>
                    <span class="px-2.5 py-1 rounded-xl bg-primary/10 group-hover:bg-primary group-hover:text-white text-primary text-[11px] font-bold transition-all shrink-0">
                      Discuter
                    </span>
                  </button>
                } @empty {
                  <div class="py-8 text-center text-xs text-slate-500">
                    Aucun formateur trouvé.
                  </div>
                }
              }
            </div>

            <div class="pt-2 border-t border-slate-100 flex justify-end">
              <button (click)="showNewChatModal.set(false)"
                      class="px-4 py-2 rounded-xl text-xs font-bold text-slate-500 hover:text-slate-800 cursor-pointer">
                Fermer
              </button>
            </div>
          </div>
        </div>
      }

    </div>
  `,
})
export class ChatComponent implements OnInit, OnDestroy {
  @ViewChild('messagesContainer') private messagesContainer!: ElementRef;

  private store = inject(Store);
  private chatService = inject(ChatService);
  private authService = inject(AuthService);
  private presenceService = inject(PresenceService);
  private toastr = inject(ToastrService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private firestore = inject(Firestore);

  currentUser: User | null = null;
  conversations = signal<Conversation[]>([]);
  selectedConversation = signal<Conversation | null>(null);
  currentMessages = signal<Message[]>([]);
  otherPresence = signal<UserPresence>({ isOnline: false, statusText: 'Hors ligne' });
  private presenceSub?: Subscription;
  private userSub?: Subscription;
  private queryParamsSub?: Subscription;
  private handledTeacherId: string | null = null;
  
  searchQuery = '';
  newMessage = '';
  
  loadingMessages = signal(false);
  sending = signal(false);
  mobileView = signal<'list' | 'chat'>('list');

  // Teacher picker modal
  showNewChatModal = signal(false);
  teachers = signal<User[]>([]);
  loadingTeachers = signal(false);
  teacherSearchQuery = '';

  
  private messagesSub?: Subscription;

  constructor() {
    effect(() => {
      const msgs = this.currentMessages();
      setTimeout(() => this.scrollToBottom(), 100);
    });
  }

  ngOnInit() {
    this.userSub = this.store.select(selectCurrentUser).pipe(
      switchMap(user => {
        this.currentUser = user;
        if (!user) return of([]);
        return this.chatService.getUserConversations(user.uid);
      })
    ).subscribe(convs => {
      this.conversations.set(convs);
      
      // Auto select first conversation on desktop if none selected and not navigating to a specific teacher
      if (convs.length > 0 && !this.selectedConversation() && !this.route.snapshot.queryParams['teacherId'] && window.innerWidth >= 1024) {
        this.selectConversation(convs[0]);
      }
    });

    // Dedicated queryParams listener for robust direct teacher contacting
    this.queryParamsSub = this.route.queryParams.subscribe(async params => {
      const teacherId = params['teacherId'] || params['userId'] || params['with'];
      if (!teacherId || teacherId === this.handledTeacherId) return;

      this.handledTeacherId = teacherId;

      // Ensure currentUser is available
      if (!this.currentUser) {
        try {
          const user = await firstValueFrom(this.store.select(selectCurrentUser));
          if (user) this.currentUser = user;
        } catch {}
      }

      if (!this.currentUser) return;

      // Check if conversation already exists in current list
      const existing = this.conversations().find(c => c.participants && c.participants.includes(teacherId));
      if (existing) {
        this.selectConversation(existing);
        this.router.navigate([], { relativeTo: this.route, queryParams: {}, replaceUrl: true });
        return;
      }

      // Fetch teacher info or fallback to query params
      let teacherName = params['teacherName'];
      let teacherPhoto = params['teacherPhoto'];
      let speciality = params['speciality'] || 'Formation';

      if (!teacherName) {
        try {
          const teacherDoc = await firstValueFrom(this.authService.getUserById(teacherId));
          if (teacherDoc) {
            teacherName = teacherDoc.displayName;
            teacherPhoto = teacherDoc.photoURL;
            speciality = teacherDoc.speciality || speciality;
          }
        } catch {}
      }

      await this.startConversationWithTeacher({
        uid: teacherId,
        displayName: teacherName || 'Formateur',
        photoURL: teacherPhoto || '',
        speciality: speciality
      } as User);

      // Clean queryParams from URL cleanly to avoid loops
      this.router.navigate([], { relativeTo: this.route, queryParams: {}, replaceUrl: true });
    });
  }


  filteredConversations(): Conversation[] {
    if (!this.searchQuery.trim()) return this.conversations();
    const q = this.searchQuery.toLowerCase();
    return this.conversations().filter(c => 
      this.getOtherParticipantName(c).toLowerCase().includes(q) ||
      (c.courseName && c.courseName.toLowerCase().includes(q))
    );
  }

  filteredTeachers(): User[] {
    if (!this.teacherSearchQuery.trim()) return this.teachers();
    const q = this.teacherSearchQuery.toLowerCase();
    return this.teachers().filter(t =>
      (t.displayName && t.displayName.toLowerCase().includes(q)) ||
      (t.speciality && t.speciality.toLowerCase().includes(q)) ||
      (t.email && t.email.toLowerCase().includes(q))
    );
  }

  async openNewChatModal() {
    this.showNewChatModal.set(true);
    if (this.teachers().length === 0) {
      await this.loadTeachers();
    }
  }

  async loadTeachers() {
    this.loadingTeachers.set(true);
    try {
      const q = query(collection(this.firestore, 'users'), where('role', '==', 'teacher'));
      const snap = await getDocs(q);
      const list: User[] = [];
      snap.forEach(d => list.push({ uid: d.id, ...d.data() } as User));
      this.teachers.set(list);
    } catch (e) {
      console.error('Error loading teachers:', e);
    } finally {
      this.loadingTeachers.set(false);
    }
  }

  async startConversationWithTeacher(teacher: User) {
    if (!this.currentUser) {
      this.toastr.warning('Veuillez vous connecter pour démarrer un échange.');
      return;
    }

    // If conversation already exists locally, select immediately
    const existing = this.conversations().find(c => c.participants && c.participants.includes(teacher.uid));
    if (existing) {
      this.showNewChatModal.set(false);
      this.selectConversation(existing);
      return;
    }

    try {
      this.toastr.info('Connexion avec le formateur...');
      const convId = await this.chatService.getOrCreateConversation(
        this.currentUser.uid,
        this.currentUser.displayName || 'Étudiant',
        this.currentUser.photoURL || '',
        teacher.uid,
        teacher.displayName || 'Formateur',
        teacher.photoURL || '',
        teacher.speciality || 'Formation'
      );

      this.showNewChatModal.set(false);

      // Find or create conversation in local state
      let conv = this.conversations().find(c => c.id === convId);
      if (!conv) {
        conv = {
          id: convId,
          participants: [this.currentUser.uid, teacher.uid],
          participantNames: {
            [this.currentUser.uid]: this.currentUser.displayName || 'Étudiant',
            [teacher.uid]: teacher.displayName || 'Formateur',
          },
          participantPhotos: {
            [this.currentUser.uid]: this.currentUser.photoURL || '',
            [teacher.uid]: teacher.photoURL || '',
          },
          lastMessage: 'Conversation démarrée',
          unreadCount: { [this.currentUser.uid]: 0, [teacher.uid]: 0 },
          courseName: teacher.speciality || 'Formation',
        } as Conversation;
        this.conversations.update(list => [conv!, ...list]);
      }

      this.selectConversation(conv);
      this.toastr.success(`Discussion ouverte avec ${teacher.displayName || 'le formateur'}`);
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors de l\'ouverture de la discussion.');
    }
  }

  selectConversation(conv: Conversation) {
    this.selectedConversation.set(conv);
    this.mobileView.set('chat');
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

  isMyMessage(msg: Message): boolean {
    return !!(this.currentUser && msg.senderId === this.currentUser.uid);
  }

  isImageUrl(url: string): boolean {
    return /\.(jpeg|jpg|gif|png|webp)($|\?)/i.test(url);
  }

  async sendMessage() {
    const text = this.newMessage.trim();
    if (!text || !this.currentUser || !this.selectedConversation()) return;

    this.sending.set(true);
    try {
      await this.chatService.sendMessage(
        this.selectedConversation()!.id,
        this.currentUser.uid,
        this.currentUser.displayName || 'Étudiant',
        text,
        this.currentUser.photoURL || ''
      );
      this.newMessage = '';
    } catch (e) {
      console.error('Error sending message:', e);
      this.toastr.error('Erreur lors de l\'envoi du message.');
    } finally {
      this.sending.set(false);
    }
  }

  // ─── File Attachment ──────────────────────────────────────────────

  async onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0 || !this.selectedConversation() || !this.currentUser) return;

    const file = input.files[0];
    const targetId = this.selectedConversation()!.id;

    this.sending.set(true);
    try {
      this.toastr.info('Téléversement du document en cours...');
      const uploadRes = await this.chatService.uploadChatFile(targetId, file);

      await this.chatService.sendMessage(
        targetId,
        this.currentUser.uid,
        this.currentUser.displayName || 'Étudiant',
        uploadRes.name,
        this.currentUser.photoURL || '',
        'file',
        uploadRes.url,
        uploadRes.name
      );

      this.toastr.success('Document partagé avec succès !');
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors du téléversement.');
    } finally {
      this.sending.set(false);
      input.value = '';
    }
  }


  formatVoiceDuration(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return m + ':' + s.toString().padStart(2, '0');
  }

  getOtherParticipantName(conv: Conversation): string {
    if (!this.currentUser) return 'Formateur';
    const otherId = conv.participants.find(id => id !== this.currentUser!.uid);
    if (otherId && conv.participantNames && conv.participantNames[otherId]) {
      return conv.participantNames[otherId];
    }
    return 'Formateur';
  }

  getOtherParticipantPhoto(conv: Conversation): string {
    if (!this.currentUser) return 'assets/default-avatar.png';
    const otherId = conv.participants.find(id => id !== this.currentUser!.uid);
    if (otherId && conv.participantPhotos && conv.participantPhotos[otherId]) {
      return conv.participantPhotos[otherId];
    }
    return 'assets/default-avatar.png';
  }

  getUnreadCount(conv: Conversation): number {
    if (!this.currentUser || !conv.unreadCount) return 0;
    return conv.unreadCount[this.currentUser.uid] || 0;
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Formateur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  formatTime(val: any): string {
    if (!val) return '';
    try {
      if (typeof val?.toDate === 'function') {
        const d = val.toDate();
        const hh = d.getHours().toString().padStart(2, '0');
        const mm = d.getMinutes().toString().padStart(2, '0');
        return hh + ':' + mm;
      }
      if (typeof val?.toMillis === 'function') {
        const d = new Date(val.toMillis());
        const hh = d.getHours().toString().padStart(2, '0');
        const mm = d.getMinutes().toString().padStart(2, '0');
        return hh + ':' + mm;
      }
      if (val instanceof Date) {
        const hh = val.getHours().toString().padStart(2, '0');
        const mm = val.getMinutes().toString().padStart(2, '0');
        return hh + ':' + mm;
      }
      if (typeof val === 'number') {
        const d = new Date(val);
        const hh = d.getHours().toString().padStart(2, '0');
        const mm = d.getMinutes().toString().padStart(2, '0');
        return hh + ':' + mm;
      }
    } catch {
      return '';
    }
    return '';
  }

  private scrollToBottom() {
    try {
      if (this.messagesContainer) {
        this.messagesContainer.nativeElement.scrollTop = this.messagesContainer.nativeElement.scrollHeight;
      }
    } catch(err) { }
  }

  ngOnDestroy(): void {
    if (this.queryParamsSub) this.queryParamsSub.unsubscribe();
    if (this.userSub) this.userSub.unsubscribe();
    if (this.messagesSub) this.messagesSub.unsubscribe();
    if (this.presenceSub) this.presenceSub.unsubscribe();
  }
}
