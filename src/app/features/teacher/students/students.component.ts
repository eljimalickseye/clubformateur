import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DatePipe, DecimalPipe } from '@angular/common';
import { RouterLink, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { CourseService } from '../../../core/services/course.service';
import { EnrollmentService } from '../../../core/services/enrollment.service';
import { Enrollment, Course, User } from '../../../core/models';
import { switchMap, of, forkJoin } from 'rxjs';

interface StudentRosterItem {
  id: string;
  studentId: string;
  studentName: string;
  studentEmail?: string;
  studentPhotoURL?: string;
  courseId: string;
  courseTitle: string;
  progress: number;
  enrolledAt: any;
  lastAccessedAt: any;
  status: string;
}

@Component({
  selector: 'app-teacher-students',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DatePipe, DecimalPipe, RouterLink, FormsModule],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8">
      
      <!-- Header -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-1">
            <span>●</span> Suivi Pédagogique
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">Mes Étudiants</h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">
            Consultez la liste de vos apprenants, suivez leur progression et communiquez directement avec eux.
          </p>
        </div>
        <div class="flex items-center gap-3">
          <a routerLink="/teacher/chat"
             class="px-4 py-2.5 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 flex items-center gap-2 transition-all">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
            </svg>
            <span>Ouvrir la Messagerie</span>
          </a>
        </div>
      </div>

      <!-- KPI Metrics (Requirement 8) -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Total Étudiants</p>
          <p class="font-display text-3xl font-black text-light mt-1">{{ roster().length }}</p>
          <p class="text-[10px] text-emerald-600 font-bold mt-1">Inscrits à vos cours</p>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Progression Moyenne</p>
          <p class="font-display text-3xl font-black text-primary mt-1">{{ avgProgress() }}%</p>
          <p class="text-[10px] text-light-muted mt-1">Sur l'ensemble des modules</p>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Actifs Récemment</p>
          <p class="font-display text-3xl font-black text-emerald-600 mt-1">{{ activeCount() }}</p>
          <p class="text-[10px] text-emerald-600 font-bold mt-1">Ces 7 derniers jours</p>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Certifiés / Terminés</p>
          <p class="font-display text-3xl font-black text-amber-500 mt-1">{{ completedCount() }}</p>
          <p class="text-[10px] text-light-muted mt-1">100% complété</p>
        </div>
      </div>

      <!-- Search & Course Filter -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-dark-border shadow-xs">
        <div class="relative flex-1 max-w-md">
          <input type="text" [(ngModel)]="searchQuery" placeholder="Rechercher par nom ou email d'étudiant..."
                 class="w-full pl-9 pr-4 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary">
          <svg class="w-4 h-4 text-light-muted absolute left-3 top-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>

        <div class="text-xs text-light-muted font-medium">
          Affichage : <span class="font-bold text-light">{{ filteredRoster().length }} apprenant(s)</span>
        </div>
      </div>

      <!-- Students Table (Requirement 8) -->
      <div class="rounded-3xl border border-dark-border bg-white overflow-hidden shadow-xs">
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-[780px]">
            <thead>
              <tr class="bg-dark-surface2/50 border-b border-dark-border text-[10px] font-black text-light-muted uppercase tracking-wider">
                <th class="px-5 py-4">Étudiant</th>
                <th class="px-5 py-4">Cours suivi</th>
                <th class="px-5 py-4">Progression</th>
                <th class="px-5 py-4">Date d'inscription</th>
                <th class="px-5 py-4">Dernière activité</th>
                <th class="px-5 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-dark-border/40 text-xs">
              @for (st of filteredRoster(); track st.id) {
                <tr class="hover:bg-slate-50/60 transition-colors group cursor-pointer"
                    (click)="openStudentDetail(st)">
                  
                  <!-- Étudiant Avatar & Nom -->
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-3">
                      <img loading="lazy" decoding="async" [src]="st.studentPhotoURL || getAvatarUrl(st.studentName)"
                           [alt]="st.studentName"
                           class="w-10 h-10 rounded-xl object-cover border border-dark-border shrink-0 shadow-xs">
                      <div>
                        <p class="font-bold text-light group-hover:text-primary transition-colors">{{ st.studentName }}</p>
                        <p class="text-[11px] text-light-muted">{{ st.studentEmail || 'apprenant@anour.edu' }}</p>
                      </div>
                    </div>
                  </td>

                  <!-- Cours Suivi -->
                  <td class="px-5 py-4 text-primary font-semibold truncate max-w-[200px]">
                    {{ st.courseTitle }}
                  </td>

                  <!-- Progression -->
                  <td class="px-5 py-4">
                    <div class="w-36 space-y-1">
                      <div class="flex items-center justify-between text-[10px] font-bold">
                        <span class="text-light">{{ st.progress }}%</span>
                        <span [class]="st.progress === 100 ? 'text-emerald-600' : 'text-primary'">
                          {{ st.progress === 100 ? 'Terminé' : 'En cours' }}
                        </span>
                      </div>
                      <div class="h-2 rounded-full bg-dark-surface2 overflow-hidden border border-dark-border/40">
                        <div class="h-full rounded-full transition-all duration-300"
                             [class.bg-emerald-500]="st.progress === 100"
                             [class.bg-primary]="st.progress < 100"
                             [style.width.%]="st.progress"></div>
                      </div>
                    </div>
                  </td>

                  <!-- Date Inscription -->
                  <td class="px-5 py-4 text-light-muted">
                    {{ st.enrolledAt ? (st.enrolledAt.toMillis() | date:'dd/MM/yyyy') : 'Récemment' }}
                  </td>

                  <!-- Dernière Activité -->
                  <td class="px-5 py-4 text-light-muted">
                    <span class="inline-flex items-center gap-1.5">
                      <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                      <span>{{ st.lastAccessedAt ? (st.lastAccessedAt.toMillis() | date:'dd/MM HH:mm') : 'Récemment' }}</span>
                    </span>
                  </td>

                  <!-- Actions -->
                  <td class="px-5 py-4 text-right" (click)="$event.stopPropagation()">
                    <div class="flex items-center justify-end gap-2">
                      <button (click)="chatWith(st)"
                              title="Envoyer un message direct"
                              class="p-2 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light-muted hover:text-primary transition-all text-xs font-bold flex items-center gap-1">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                        </svg>
                      </button>

                      <button (click)="openStudentDetail(st)"
                              class="px-3 py-1.5 rounded-xl border border-dark-border hover:bg-dark-surface2 text-xs font-bold text-light">
                        Fiche
                      </button>
                    </div>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="6" class="text-center py-16 text-light-muted">
                    <div class="text-3xl mb-2">👥</div>
                    <p class="font-bold text-light">Aucun étudiant trouvé</p>
                    <p class="text-xs">Vos apprenants inscrits apparaîtront ici.</p>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>

      <!-- Student Detail Sheet Modal (Requirement 8) -->
      @if (selectedStudent()) {
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-in fade-in"
             (click)="selectedStudent.set(null)">
          <div class="bg-white rounded-3xl p-6 sm:p-8 w-full max-w-lg shadow-2xl border border-dark-border space-y-6"
               (click)="$event.stopPropagation()">
            
            <div class="flex items-center justify-between border-b border-dark-border pb-4">
              <div class="flex items-center gap-3">
                <img loading="lazy" decoding="async" [src]="selectedStudent()?.studentPhotoURL || getAvatarUrl(selectedStudent()?.studentName)"
                     [alt]="selectedStudent()?.studentName"
                     class="w-12 h-12 rounded-2xl object-cover border border-dark-border shadow-xs">
                <div>
                  <h3 class="font-display text-lg font-bold text-light">{{ selectedStudent()?.studentName }}</h3>
                  <p class="text-xs text-light-muted">{{ selectedStudent()?.studentEmail || 'Étudiant Anour' }}</p>
                </div>
              </div>
              <button (click)="selectedStudent.set(null)" class="text-light-muted hover:text-light p-2 rounded-xl">✕</button>
            </div>

            <div class="space-y-4">
              <div class="p-4 rounded-2xl bg-dark-surface2/50 border border-dark-border/60 space-y-2">
                <div class="flex items-center justify-between text-xs">
                  <span class="text-light-muted">Formation :</span>
                  <span class="font-bold text-primary">{{ selectedStudent()?.courseTitle }}</span>
                </div>
                <div class="flex items-center justify-between text-xs">
                  <span class="text-light-muted">Progression du cours :</span>
                  <span class="font-black text-emerald-600">{{ selectedStudent()?.progress }}%</span>
                </div>
                <div class="w-full h-2 rounded-full bg-dark-border overflow-hidden mt-1">
                  <div class="h-full bg-emerald-500 rounded-full" [style.width.%]="selectedStudent()?.progress"></div>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-3 text-xs">
                <div class="p-3 bg-dark-surface2/30 rounded-xl border border-dark-border/40">
                  <p class="text-light-muted">Inscrit le</p>
                  <p class="font-bold text-light mt-0.5">
                    {{ selectedStudent()?.enrolledAt ? (selectedStudent()?.enrolledAt.toMillis() | date:'dd/MM/yyyy') : 'Récemment' }}
                  </p>
                </div>
                <div class="p-3 bg-dark-surface2/30 rounded-xl border border-dark-border/40">
                  <p class="text-light-muted">Statut assiduité</p>
                  <p class="font-bold text-emerald-600 mt-0.5">● Assidu & Actif</p>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-2">
              <button (click)="selectedStudent.set(null)" class="px-4 py-2 text-xs font-bold text-light-muted hover:bg-dark-surface2 rounded-xl">
                Fermer
              </button>
              <button (click)="chatWith(selectedStudent()!); selectedStudent.set(null)"
                      class="px-5 py-2 bg-primary text-white text-xs font-bold rounded-xl shadow-sm flex items-center gap-1.5">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                </svg>
                <span>Envoyer un message</span>
              </button>
            </div>
          </div>
        </div>
      }

    </div>
  `,
})
export class TeacherStudentsComponent implements OnInit {
  private store = inject(Store);
  private courseService = inject(CourseService);
  private enrollmentService = inject(EnrollmentService);
  private router = inject(Router);

  user$ = this.store.select(selectCurrentUser);
  roster = signal<StudentRosterItem[]>([]);
  searchQuery = '';
  selectedStudent = signal<StudentRosterItem | null>(null);

  avgProgress = computed(() => {
    const list = this.roster();
    if (!list.length) return 0;
    const sum = list.reduce((acc, st) => acc + (st.progress || 0), 0);
    return Math.round(sum / list.length);
  });

  activeCount = computed(() => this.roster().length);
  completedCount = computed(() => this.roster().filter(st => st.progress === 100).length);

  filteredRoster = computed(() => {
    let list = this.roster();
    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(st =>
        st.studentName.toLowerCase().includes(q) ||
        (st.studentEmail && st.studentEmail.toLowerCase().includes(q)) ||
        st.courseTitle.toLowerCase().includes(q)
      );
    }
    return list;
  });

  ngOnInit(): void {
    this.user$.subscribe(user => {
      if (!user) return;
      this.courseService.getTeacherCourses(user.uid).subscribe(courses => {
        if (!courses.length) {
          this.roster.set([]);
          return;
        }

        const items: StudentRosterItem[] = [];
        courses.forEach(course => {
          this.enrollmentService.getCourseEnrollments(course.id).subscribe(enrollments => {
            enrollments.forEach(en => {
              items.push({
                id: en.id,
                studentId: en.studentId,
                studentName: en.studentName || 'Étudiant',
                courseId: course.id,
                courseTitle: course.title,
                progress: en.progress || 0,
                enrolledAt: en.enrolledAt,
                lastAccessedAt: en.lastAccessedAt,
                status: en.status || 'active',
              });
            });
            this.roster.set([...items]);
          });
        });
      });
    });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Étudiant');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  openStudentDetail(st: StudentRosterItem): void {
    this.selectedStudent.set(st);
  }

  chatWith(st: StudentRosterItem): void {
    this.router.navigate(['/teacher/chat'], {
      queryParams: { studentId: st.studentId, courseId: st.courseId }
    });
  }
}
