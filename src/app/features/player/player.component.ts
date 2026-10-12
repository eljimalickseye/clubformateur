import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { AsyncPipe, DatePipe, NgClass, CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { switchMap, of } from 'rxjs';
import { CourseService } from '../../core/services/course.service';
import { EnrollmentService } from '../../core/services/enrollment.service';
import { ChatService } from '../../core/services/chat.service';
import { LivekitService } from '../../core/services/livekit.service';
import { selectCurrentUser } from '../../store/auth/auth.selectors';
import { VideoPlayerComponent } from '../../shared/components/video-player/video-player.component';
import { Course, Lesson, User, LiveSession, Section } from '../../core/models';
import { BackButtonComponent } from '../../shared/components/back-button/back-button.component';

export interface ChapterGroup {
  id: string;
  title: string;
  order: number;
  lessons: Lesson[];
  isCollapsed: boolean;
  isMeetChapter?: boolean;
}

@Component({
  selector: 'app-player',
  standalone: true,
  imports: [CommonModule, RouterLink, AsyncPipe, FormsModule, VideoPlayerComponent, NgClass, DatePipe, BackButtonComponent],
  template: `
    <div class="flex h-screen bg-dark overflow-hidden font-body text-light">

      <!-- Sidebar: Chapter & lesson list -->
      <aside [class]="sidebarOpen() ? 'w-80 sm:w-96' : 'w-0'"
             class="flex-shrink-0 bg-dark-surface border-r border-dark-border overflow-y-auto transition-all duration-300 flex flex-col z-20">
        @if (course()) {
          <!-- Course Header in Sidebar -->
          <div class="p-4 border-b border-dark-border shrink-0 bg-dark-surface2/40 space-y-3">
            <div class="flex items-start justify-between gap-2">
              <div>
                <span class="text-[10px] font-bold text-primary uppercase tracking-wider">Formation</span>
                <h2 class="font-display font-bold text-light text-sm line-clamp-2 mt-0.5">
                  {{ course()!.title }}
                </h2>
              </div>
            </div>

            <!-- Overall Progress -->
            <div>
              <div class="flex items-center justify-between text-xs text-light-muted mb-1.5">
                <span class="font-medium">{{ completedCount() }} sur {{ allPlayableLessons().length }} leçons terminées</span>
                <span class="font-bold text-emerald-400">{{ progressPercent() }}%</span>
              </div>
              <div class="w-full bg-dark-surface rounded-full h-2 overflow-hidden border border-dark-border">
                <div class="bg-gradient-to-r from-primary to-emerald-400 h-2 rounded-full transition-all duration-500"
                     [style.width.%]="progressPercent()"></div>
              </div>
            </div>
          </div>

          <!-- Chapters Accordions -->
          <div class="py-2 flex-1 overflow-y-auto space-y-2 px-2">
            @for (chapter of chapters(); track chapter.id; let chIdx = $index) {
              <div class="rounded-2xl border border-dark-border overflow-hidden bg-dark-surface/60 transition-all">
                
                <!-- Chapter Header (Accordion Toggle) -->
                <button (click)="toggleChapter(chapter.id)"
                        class="w-full flex items-center justify-between p-3.5 text-left hover:bg-dark-surface2 transition-colors cursor-pointer"
                        [class.bg-dark-surface2]="!chapter.isCollapsed">
                  <div class="flex items-center gap-2.5 min-w-0">
                    <span class="text-base shrink-0">
                      {{ chapter.isMeetChapter ? '📹' : '📁' }}
                    </span>
                    <div class="truncate">
                      <h3 class="text-xs font-bold text-light truncate">
                        {{ chapter.title }}
                      </h3>
                      <p class="text-[10px] text-light-muted">
                        {{ chapter.lessons.length }} vidéo{{ chapter.lessons.length > 1 ? 's' : '' }}
                        {{ chapter.isMeetChapter ? '• Directs & Replays' : '' }}
                      </p>
                    </div>
                  </div>

                  <div class="flex items-center gap-2 shrink-0">
                    <span class="text-[10px] font-mono px-2 py-0.5 rounded-full bg-dark-surface border border-dark-border text-light-muted">
                      {{ getChapterCompletedCount(chapter) }}/{{ chapter.lessons.length }}
                    </span>
                    <svg class="w-4 h-4 text-light-muted transition-transform duration-200"
                         [class.rotate-180]="!chapter.isCollapsed"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                    </svg>
                  </div>
                </button>

                <!-- Lessons in this Chapter -->
                @if (!chapter.isCollapsed) {
                  <div class="divide-y divide-dark-border/40 bg-black/20">
                    @for (lesson of chapter.lessons; track lesson.id; let lIdx = $index) {
                      <button (click)="selectLesson(lesson)"
                              [class]="currentLesson()?.id === lesson.id
                                        ? 'bg-primary/15 border-l-4 border-primary text-white'
                                        : 'hover:bg-dark-surface2/70 border-l-4 border-transparent text-light-muted'"
                              class="w-full flex items-center gap-3 px-3.5 py-2.5 transition-all text-left cursor-pointer">
                        
                        <!-- Status Icon -->
                        <div class="shrink-0">
                          @if (completedLessons().includes(lesson.id)) {
                            <div class="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center text-xs font-bold">
                              ✓
                            </div>
                          } @else if (currentLesson()?.id === lesson.id) {
                            <div class="w-5 h-5 rounded-full bg-primary text-white flex items-center justify-center text-[10px] font-bold animate-pulse">
                              ▶
                            </div>
                          } @else {
                            <div class="w-5 h-5 rounded-full bg-dark-surface2 text-light-muted flex items-center justify-center text-[10px] font-mono">
                              {{ lIdx + 1 }}
                            </div>
                          }
                        </div>

                        <!-- Lesson Details -->
                        <div class="flex-1 min-w-0">
                          <p class="text-xs font-semibold truncate"
                             [class.text-primary]="currentLesson()?.id === lesson.id"
                             [class.text-light]="currentLesson()?.id !== lesson.id">
                            {{ lesson.title }}
                          </p>
                          <div class="flex items-center gap-2 mt-0.5 text-[10px] text-light-muted">
                            @if (chapter.isMeetChapter) {
                              <span class="px-1.5 py-0.2 rounded bg-red-500/20 text-red-400 font-bold">REPLAY MEET</span>
                            } @else {
                              <span>🎥 Vidéo</span>
                              @if (lesson.pdfUrl) {
                                <span>• 📄 PDF</span>
                              }
                            }
                            @if (lesson.duration) {
                              <span>• {{ formatDuration(lesson.duration) }}</span>
                            }
                          </div>
                        </div>
                      </button>
                    }
                  </div>
                }

              </div>
            }
          </div>
        }
      </aside>

      <!-- Main content -->
      <div class="flex-1 flex flex-col overflow-hidden">
        <!-- Top Navigation Bar in Player -->
        <div class="flex items-center justify-between px-3 sm:px-5 py-3 border-b border-dark-border bg-dark-surface flex-shrink-0 gap-2">
          <div class="flex items-center gap-2 sm:gap-3 min-w-0">
            <button (click)="toggleSidebar()"
                    title="Menu du programme"
                    class="p-2 rounded-xl bg-dark-surface2 hover:bg-slate-700 text-light-muted hover:text-white transition-colors cursor-pointer shrink-0">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7"/>
              </svg>
            </button>
            <app-back-button label="Quitter le cours" defaultRoute="/student/my-courses" variant="dark" [showIconOnlyOnMobile]="true" />
            @if (currentLesson()) {
              <div class="min-w-0 hidden sm:block">
                <p class="text-[10px] text-primary uppercase font-bold tracking-wider">Leçon en cours</p>
                <h1 class="font-bold text-light text-xs sm:text-sm truncate max-w-[200px] md:max-w-md">
                  {{ currentLesson()!.title }}
                </h1>
              </div>
            }
          </div>

          <!-- Complete & Next Buttons -->
          <div class="flex items-center gap-2 sm:gap-3">
            @if (currentLesson() && !completedLessons().includes(currentLesson()!.id)) {
              <button (click)="markComplete()"
                      class="px-3 py-1.5 text-xs font-bold border border-emerald-500/50 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500 hover:text-white rounded-xl transition-all cursor-pointer">
                ✓ Marquer terminé
              </button>
            }
            
            <div class="flex items-center gap-1 border border-dark-border rounded-xl p-0.5 bg-dark-surface2">
              <button (click)="prevLesson()" [disabled]="currentLessonIndex() === 0"
                      title="Leçon précédente"
                      class="p-1.5 rounded-lg hover:bg-slate-700 disabled:opacity-30 transition-colors text-light-muted cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
                </svg>
              </button>
              <button (click)="nextLesson()" [disabled]="currentLessonIndex() === allPlayableLessons().length - 1"
                      title="Leçon suivante"
                      class="p-1.5 rounded-lg hover:bg-slate-700 disabled:opacity-30 transition-colors text-light-muted cursor-pointer">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Lesson content -->
        <div class="flex-1 overflow-y-auto p-3 sm:p-6">
          @if (currentLesson(); as lesson) {
            <div class="max-w-4xl mx-auto space-y-5">
              
              <!-- SÉLECTEUR DE FORMAT (VIDÉO & PDF DISPONIBLES) -->
              <div class="flex items-center justify-between bg-dark-surface border border-dark-border p-2 rounded-2xl">
                <div class="flex items-center gap-1.5">
                  <button (click)="activeFormat.set('video')"
                          [class.bg-primary]="activeFormat() === 'video'"
                          [class.text-white]="activeFormat() === 'video'"
                          [class.text-light-muted]="activeFormat() !== 'video'"
                          class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span>Format Vidéo</span>
                  </button>

                  <button (click)="activeFormat.set('pdf')"
                          [class.bg-primary]="activeFormat() === 'pdf'"
                          [class.text-white]="activeFormat() === 'pdf'"
                          [class.text-light-muted]="activeFormat() !== 'pdf'"
                          class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                    </svg>
                    <span>Format Document PDF</span>
                  </button>
                </div>

                <span class="text-[11px] text-emerald-400 font-bold hidden sm:inline-flex items-center gap-1">
                  <span>✓ Accès Complet (2 formats inclus)</span>
                </span>
              </div>

              <!-- FORMAT 1: VIDÉO HD (AVEC REPRISE AUTOMATIQUE DE LECTURE) -->
              @if (activeFormat() === 'video') {
                <div class="space-y-4 animate-fade-in">
                  <app-video-player [lesson]="getVideoReadyLesson(lesson)"
                                    (lessonCompleted)="onVideoCompleted($event)" />

                  <div class="mt-4">
                    <div class="flex items-start justify-between gap-3">
                      <div>
                        <h2 class="font-display text-xl sm:text-2xl font-bold text-light mb-1">{{ lesson.title }}</h2>
                        <p class="text-light-muted text-xs sm:text-sm leading-relaxed">
                          {{ lesson.description || 'Visionnez ce cours interactif avec explications détaillées et reprise automatique de lecture.' }}
                        </p>
                      </div>

                      @if (currentLessonIndex() < allPlayableLessons().length - 1) {
                        <button (click)="nextLesson()"
                                class="px-3.5 py-2 bg-primary/20 hover:bg-primary text-sky-300 hover:text-white rounded-xl text-xs font-bold transition-all shrink-0 cursor-pointer flex items-center gap-1">
                          <span>Suivant</span>
                          <span>→</span>
                        </button>
                      }
                    </div>

                    @if (lesson.notes) {
                      <div class="mt-4 p-4 rounded-2xl bg-dark-surface border border-dark-border space-y-1">
                        <p class="text-xs font-bold text-primary flex items-center gap-1.5">
                          <span>📝 Notes de synthèse du professeur :</span>
                        </p>
                        <p class="text-xs text-light-muted whitespace-pre-wrap">{{ lesson.notes }}</p>
                      </div>
                    }

                    @if (lesson.resources?.length) {
                      <div class="mt-4">
                        <h3 class="font-medium text-light mb-2 text-xs uppercase tracking-wider">Documents & Ressources liées</h3>
                        <div class="space-y-2">
                          @for (res of lesson.resources; track res.url) {
                            <a [href]="res.url" target="_blank"
                               class="flex items-center gap-3 p-3 bg-dark-surface border border-dark-border
                                      rounded-xl hover:border-primary/40 transition-colors text-xs text-primary font-bold">
                              📎 {{ res.name }}
                            </a>
                          }
                        </div>
                      </div>
                    }
                  </div>
                </div>
              }

              <!-- FORMAT 2: DOCUMENT PDF -->
              @if (activeFormat() === 'pdf') {
                <div class="space-y-4 animate-fade-in">
                  <!-- PDF Header Toolbar -->
                  <div class="p-4 rounded-2xl bg-dark-surface border border-dark-border flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                    <div>
                      <span class="text-[10px] font-bold uppercase tracking-wider text-primary">Document Officiel de Cours</span>
                      <h3 class="font-bold text-sm text-light mt-0.5">{{ lesson.pdfDocName || (lesson.title + ' - Document Support PDF') }}</h3>
                    </div>

                    <a [href]="getDownloadPdfUrl(lesson)" target="_blank" download
                       class="px-4 py-2 rounded-xl bg-primary hover:bg-primary-600 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5 cursor-pointer shrink-0">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
                      </svg>
                      <span>Télécharger le PDF</span>
                    </a>
                  </div>

                  <!-- PDF Embedded Frame or Viewer -->
                  <div class="rounded-2xl border border-dark-border overflow-hidden bg-slate-900 h-[65vh]">
                    @if (lesson.pdfUrl) {
                      <iframe [src]="getSafePdfUrl(lesson)" class="w-full h-full border-0"></iframe>
                    } @else {
                      <div class="w-full h-full p-6 sm:p-10 flex flex-col items-center justify-center text-center space-y-4 bg-slate-950/80">
                        <div class="w-16 h-16 rounded-2xl bg-primary/10 text-primary flex items-center justify-center">
                          <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                          </svg>
                        </div>
                        <div class="max-w-md">
                          <h4 class="font-bold text-base text-white">Support de cours & Fiche mémo PDF</h4>
                          <p class="text-xs text-light-muted mt-1 leading-relaxed">
                            Ce document regroupe les points clés, schémas et exercices résolus de la leçon <strong>{{ lesson.title }}</strong>.
                          </p>
                        </div>
                        <a [href]="getDownloadPdfUrl(lesson)" target="_blank"
                           class="px-5 py-2.5 rounded-xl bg-primary text-white text-xs font-bold transition-all shadow-md">
                          Ouvrir le document PDF complet
                        </a>
                      </div>
                    }
                  </div>
                </div>
              }

              <!-- QUESTIONS AU PROFESSEUR (L'ÉTUDIANT RÉPOND/POSE UNIQUEMENT PAR MESSAGE) -->
              <div class="p-4 sm:p-5 rounded-3xl bg-dark-surface border border-dark-border space-y-3">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class="p-1.5 rounded-xl bg-primary/15 text-primary">
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                      </svg>
                    </span>
                    <h3 class="font-bold text-xs sm:text-sm text-light">Poser une question au formateur</h3>
                  </div>
                  <span class="text-[10px] text-light-muted bg-dark-surface2 px-2.5 py-0.5 rounded-full">
                    Échanges par message uniquement
                  </span>
                </div>

                <div class="flex flex-col sm:flex-row gap-2">
                  <input type="text" [(ngModel)]="studentMessageText"
                         placeholder="Votre question sur cette leçon (ex: explication sur un schéma, formule...)"
                         class="flex-1 px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary">
                  <button (click)="sendQuestionToTeacher()" [disabled]="!studentMessageText.trim() || sendingMessage()"
                          class="px-5 py-2.5 bg-primary hover:bg-primary-600 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-xs transition-all cursor-pointer">
                    {{ sendingMessage() ? 'Envoi...' : 'Envoyer par message' }}
                  </button>
                </div>
              </div>

            </div>
          } @else {
            <div class="flex items-center justify-center h-full">
              <p class="text-light-muted">Sélectionnez une leçon pour commencer</p>
            </div>
          }
        </div>
      </div>
    </div>
  `,
})
export class PlayerComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private store = inject(Store);
  private courseService = inject(CourseService);
  private enrollmentService = inject(EnrollmentService);
  private livekitService = inject(LivekitService);
  private sanitizer = inject(DomSanitizer);
  private toastr = inject(ToastrService);
  private chatService = inject(ChatService);

  course = signal<Course | null>(null);
  lessons = signal<Lesson[]>([]);
  meetSessions = signal<LiveSession[]>([]);
  chapters = signal<ChapterGroup[]>([]);
  currentLesson = signal<Lesson | null>(null);
  completedLessons = signal<string[]>([]);
  sidebarOpen = signal(true);
  activeFormat = signal<'video' | 'pdf'>('video');

  studentMessageText = '';
  sendingMessage = signal(false);
  private currentUser: User | null = null;

  allPlayableLessons = computed(() => {
    const list: Lesson[] = [];
    this.chapters().forEach(ch => {
      list.push(...ch.lessons);
    });
    return list.length > 0 ? list : this.lessons();
  });

  currentLessonIndex = computed(() => {
    const all = this.allPlayableLessons();
    const idx = all.findIndex(l => l.id === this.currentLesson()?.id);
    return idx >= 0 ? idx : 0;
  });

  completedCount = computed(() => this.completedLessons().length);
  progressPercent = computed(() => {
    const total = this.allPlayableLessons().length;
    return total ? Math.min(100, Math.round((this.completedCount() / total) * 100)) : 0;
  });

  private userId = '';
  private courseId = '';

  ngOnInit(): void {
    this.courseId = this.route.snapshot.params['courseId'];
    const initialLessonId = this.route.snapshot.params['lessonId'];

    this.store.select(selectCurrentUser).subscribe(user => {
      if (user) {
        this.userId = user.uid;
        this.currentUser = user;
      }
    });

    this.courseService.getCourseById(this.courseId).subscribe(c => {
      if (c) this.course.set(c);
    });

    // 1. Fetch Lessons & Sections & Meet replays
    this.courseService.getLessons(this.courseId).subscribe(lessons => {
      this.lessons.set(lessons);

      this.courseService.getSections(this.courseId).subscribe(sections => {
        // Also fetch live Meet recordings for this course
        this.livekitService.getCourseReplays(this.courseId).subscribe(replays => {
          this.meetSessions.set(replays);
          this.buildChapterGroups(lessons, sections, replays, initialLessonId);
        });
      });
    });

    // 2. Load enrollment progress
    this.store.select(selectCurrentUser).pipe(
      switchMap(user => user
        ? this.enrollmentService.getProgress(user.uid, this.courseId)
        : of(undefined)
      )
    ).subscribe(progress => {
      if (progress) this.completedLessons.set(progress.completedLessons);
    });
  }

  private buildChapterGroups(lessons: Lesson[], sections: Section[], replays: LiveSession[], initialLessonId?: string): void {
    const groups: ChapterGroup[] = [];

    if (sections && sections.length > 0) {
      // Group by declared sections
      sections.forEach(sec => {
        const secLessons = lessons.filter(l => sec.lessonIds?.includes(l.id));
        groups.push({
          id: sec.id,
          title: `Chapitre ${sec.order} : ${sec.title}`,
          order: sec.order,
          lessons: secLessons,
          isCollapsed: false,
        });
      });

      // Lessons without section
      const unassigned = lessons.filter(l => !sections.some(s => s.lessonIds?.includes(l.id)));
      if (unassigned.length > 0) {
        groups.push({
          id: 'other',
          title: 'Modules complémentaires',
          order: groups.length + 1,
          lessons: unassigned,
          isCollapsed: false,
        });
      }
    } else {
      // Auto-cluster lessons by chapters (e.g. for 15+ lessons)
      if (lessons.length > 8) {
        const chunkSize = Math.ceil(lessons.length / 3);
        const ch1 = lessons.slice(0, chunkSize);
        const ch2 = lessons.slice(chunkSize, chunkSize * 2);
        const ch3 = lessons.slice(chunkSize * 2);

        groups.push({
          id: 'chap-1',
          title: 'Chapitre 1 : Les Fondamentaux',
          order: 1,
          lessons: ch1,
          isCollapsed: false,
        });
        if (ch2.length) {
          groups.push({
            id: 'chap-2',
            title: 'Chapitre 2 : Maîtrise & Approfondissement',
            order: 2,
            lessons: ch2,
            isCollapsed: false,
          });
        }
        if (ch3.length) {
          groups.push({
            id: 'chap-3',
            title: 'Chapitre 3 : Ateliers & Pratiques avancées',
            order: 3,
            lessons: ch3,
            isCollapsed: false,
          });
        }
      } else {
        groups.push({
          id: 'main',
          title: 'Programme Principal',
          order: 1,
          lessons: lessons,
          isCollapsed: false,
        });
      }
    }

    // ─── CHAPITRE DÉDIÉ : SÉANCES MEET & REPLAYS EN DIRECT ───
    if (replays && replays.length > 0) {
      const meetLessons: Lesson[] = replays.map((rep, idx) => ({
        id: `meet_${rep.id}`,
        courseId: this.courseId,
        title: rep.title || `Séance Meet #${idx + 1}`,
        description: rep.description || 'Enregistrement de la session Live interactive avec le formateur.',
        type: 'video',
        videoUrl: rep.replayUrl || rep.recordingUrl || rep.recordingBlobUrl || '',
        pdfUrl: rep.pdfDocUrl,
        pdfDocName: rep.pdfDocName,
        notes: rep.notes,
        duration: rep.durationMinutes ? rep.durationMinutes * 60 : 3600,
        isFree: false,
        order: 900 + idx,
        createdAt: rep.scheduledAt as any,
      }));

      groups.push({
        id: 'meet-replays',
        title: '📹 Séances Meet & Replays en direct',
        order: 999,
        lessons: meetLessons,
        isCollapsed: false,
        isMeetChapter: true,
      });
    }

    this.chapters.set(groups);

    // ─── AUTO-RESUME LESSON (Reprendre la dernière leçon ou cible) ───
    const all = this.allPlayableLessons();
    let targetLesson: Lesson | undefined;

    if (initialLessonId && initialLessonId !== 'default') {
      targetLesson = all.find(l => l.id === initialLessonId);
    }

    if (!targetLesson) {
      // Check localStorage for last watched lesson
      const lastId = localStorage.getItem(`school_last_lesson_${this.courseId}`);
      if (lastId) {
        targetLesson = all.find(l => l.id === lastId);
      }
    }

    if (!targetLesson) {
      // Pick first uncompleted lesson
      targetLesson = all.find(l => !this.completedLessons().includes(l.id)) || all[0];
    }

    if (targetLesson) {
      this.selectLesson(targetLesson);
    }
  }

  toggleChapter(chapterId: string): void {
    this.chapters.update(list =>
      list.map(ch => ch.id === chapterId ? { ...ch, isCollapsed: !ch.isCollapsed } : ch)
    );
  }

  getChapterCompletedCount(chapter: ChapterGroup): number {
    return chapter.lessons.filter(l => this.completedLessons().includes(l.id)).length;
  }

  toggleSidebar(): void {
    this.sidebarOpen.update(v => !v);
  }

  selectLesson(lesson: Lesson): void {
    this.currentLesson.set(lesson);
    if (lesson.type === 'pdf') {
      this.activeFormat.set('pdf');
    }

    // Save active lesson ID for this course
    try {
      localStorage.setItem(`school_last_lesson_${this.courseId}`, lesson.id);
    } catch (e) {}
  }

  nextLesson(): void {
    const all = this.allPlayableLessons();
    const idx = this.currentLessonIndex();
    if (idx < all.length - 1) {
      this.selectLesson(all[idx + 1]);
    }
  }

  prevLesson(): void {
    const all = this.allPlayableLessons();
    const idx = this.currentLessonIndex();
    if (idx > 0) {
      this.selectLesson(all[idx - 1]);
    }
  }

  onVideoCompleted(lesson: Lesson): void {
    if (!this.completedLessons().includes(lesson.id)) {
      this.markComplete();
      this.toastr.success(`Leçon « ${lesson.title} » terminée avec succès ! 🎉`);
    }
  }

  markComplete(): void {
    const lesson = this.currentLesson();
    if (!lesson || !this.userId) return;
    this.enrollmentService.completeLesson(this.userId, this.courseId, lesson.id, this.allPlayableLessons().length)
      .then(() => this.completedLessons.update(arr => arr.includes(lesson.id) ? arr : [...arr, lesson.id]));
  }

  getVideoReadyLesson(lesson: Lesson): Lesson {
    if (lesson.videoUrl) return lesson;
    const fallbackVideo = this.course()?.promoVideoUrl || 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    return { ...lesson, videoUrl: fallbackVideo };
  }

  getSafePdfUrl(lesson: Lesson): SafeResourceUrl {
    const url = lesson.pdfUrl || 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  getDownloadPdfUrl(lesson: Lesson): string {
    return lesson.pdfUrl || 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';
  }

  async sendQuestionToTeacher(): Promise<void> {
    const text = this.studentMessageText.trim();
    const course = this.course();
    const lesson = this.currentLesson();
    if (!text || !course || !this.currentUser) return;

    this.sendingMessage.set(true);
    try {
      const fullText = `[Question sur la leçon "${lesson?.title || 'Cours'}"] : ${text}`;
      const convId = await this.chatService.getOrCreateConversation(
        this.currentUser.uid,
        this.currentUser.displayName || 'Étudiant',
        this.currentUser.photoURL || '',
        course.teacherId,
        course.teacherName || 'Formateur',
        course.teacherPhotoURL || '',
        course.title
      );
      await this.chatService.sendMessage(convId, this.currentUser.uid, this.currentUser.displayName || 'Étudiant', fullText);
      this.toastr.success('Votre question a été envoyée au professeur par message !');
      this.studentMessageText = '';
    } catch {
      this.toastr.error('Erreur lors de l\'envoi de votre question.');
    } finally {
      this.sendingMessage.set(false);
    }
  }

  formatDuration(seconds: number): string {
    const m = Math.floor(seconds / 60);
    return m > 60 ? `${Math.floor(m / 60)}h${m % 60}min` : `${m}min`;
  }
}
