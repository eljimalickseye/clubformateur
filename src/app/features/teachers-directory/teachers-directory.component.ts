import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DecimalPipe } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { CourseService } from '../../core/services/course.service';
import { selectCurrentUser } from '../../store/auth/auth.selectors';
import { User, Course } from '../../core/models';

interface TeacherCardData {
  teacher: User;
  courses: Course[];
  totalStudents: number;
  avgRating: number;
}

import { BackButtonComponent } from '../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-teachers-directory',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DecimalPipe, RouterLink, FormsModule, BackButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-6 sm:py-12 space-y-8 sm:space-y-12 font-body">
      
      <!-- PWA / Mobile Back Navigation -->
      <div class="flex items-center justify-between">
        <app-back-button label="Retour" defaultRoute="/student/dashboard" variant="light" />
      </div>

      <!-- Hero Banner -->
      <div class="text-center max-w-3xl mx-auto space-y-4">
        <span class="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider">
          Corps Professoral d'Excellence
        </span>
        <h1 class="font-display text-4xl sm:text-5xl font-black text-light tracking-tight">
          Découvrez nos <span class="text-primary">Professeurs & Formateurs</span>
        </h1>
        <p class="text-sm sm:text-base text-light-muted">
          Apprenez auprès d'experts pédagogiques reconnus, certifiés et passionnés par la transmission du savoir.
        </p>

        <!-- Search Bar (Requirement 4) -->
        <div class="max-w-xl mx-auto pt-4 relative">
          <input type="text" [(ngModel)]="searchQuery" placeholder="Rechercher un professeur par nom ou spécialité..."
                 class="w-full pl-11 pr-4 py-3.5 bg-white border border-dark-border rounded-2xl text-sm text-light placeholder-light-muted focus:ring-4 focus:ring-primary/10 focus:border-primary shadow-lg shadow-dark-border/20 outline-none transition-all">
          <svg class="w-5 h-5 text-primary/60 absolute left-4 top-7.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>
      </div>

      <!-- Teachers Grid (Requirement 4) -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        @for (item of filteredTeachers(); track item.teacher.uid) {
          <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-7 shadow-xs hover:shadow-xl transition-all duration-300 flex flex-col justify-between group space-y-6">
            
            <div class="space-y-4">
              <!-- Top: Avatar & Verification -->
              <div class="flex items-start gap-4">
                <div class="relative shrink-0">
                  <img loading="lazy" decoding="async" [src]="item.teacher.photoURL || getAvatarUrl(item.teacher.displayName)"
                       [alt]="item.teacher.displayName"
                       class="w-16 h-16 rounded-2xl object-cover border-2 border-primary shadow-sm group-hover:scale-105 transition-transform duration-300">
                  <span class="absolute -bottom-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-emerald-500 ring-2 ring-white text-white"
                        title="Formateur Certifié">
                    <svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  </span>
                </div>

                <div class="min-w-0">
                  <h3 class="font-display font-bold text-light text-lg truncate group-hover:text-primary transition-colors">
                    {{ item.teacher.displayName }}
                  </h3>
                  <p class="text-xs font-semibold text-primary truncate">
                    {{ item.teacher.speciality || 'Formateur d’Excellence' }}
                  </p>
                  
                  <!-- Niveau Enseigné (Licence 3) -->
                  <div class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-700 text-[10px] font-bold mt-1.5">
                    <svg class="w-3 h-3 text-emerald-600 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"/>
                    </svg>
                    <span>Niveau enseigné : {{ item.teacher.teachingLevel || item.teacher.taughtLevels || 'Licence 3' }}</span>
                  </div>
                  
                  <div class="flex items-center gap-2.5 mt-1.5 text-xs text-light-muted">
                    <span class="text-amber-500 font-bold inline-flex items-center gap-1">
                      <svg class="w-3.5 h-3.5 fill-amber-500 text-amber-500 shrink-0" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                      </svg>
                      <span>{{ item.avgRating > 0 ? (item.avgRating | number:'1.1-1') : '5.0' }}</span>
                    </span>
                    <span class="text-slate-300">•</span>
                    <span class="inline-flex items-center gap-1">
                      <svg class="w-3.5 h-3.5 text-slate-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                      </svg>
                      <span>{{ item.totalStudents | number }} apprenants</span>
                    </span>
                  </div>
                </div>
              </div>

              <!-- Presentation / Bio -->
              <p class="text-xs text-light-muted leading-relaxed line-clamp-3">
                {{ item.teacher.bio || 'Formateur passionné dédié à la réussite et à l’accompagnement de chaque étudiant.' }}
              </p>

              <!-- Offered Courses Preview (Requirement 4) -->
              <div class="pt-3 border-t border-dark-border/60 space-y-2">
                <p class="text-[10px] font-bold uppercase tracking-wider text-light-muted">
                  Formations proposées ({{ item.courses.length }})
                </p>
                <div class="flex flex-wrap gap-1.5">
                  @for (course of item.courses.slice(0, 2); track course.id) {
                    <span class="px-2.5 py-1 rounded-xl bg-dark-surface2 text-[11px] font-medium text-light truncate max-w-[200px]">
                      {{ course.title }}
                    </span>
                  }
                  @if (item.courses.length > 2) {
                    <span class="px-2 py-1 rounded-xl bg-primary/10 text-[10px] font-bold text-primary">
                      +{{ item.courses.length - 2 }} autre(s)
                    </span>
                  }
                  @if (item.courses.length === 0) {
                    <span class="text-[11px] text-light-muted italic">Formations en cours de publication</span>
                  }
                </div>
              </div>
            </div>

            <!-- CTA: Voir le Profil & Contacter -->
            <div class="pt-4 border-t border-dark-border/60 flex items-center justify-between gap-2">
              <button (click)="contactTeacher(item.teacher)"
                      class="px-3.5 py-2 rounded-xl bg-gradient-to-r from-sky-500 to-primary hover:from-sky-400 hover:to-primary-600 text-white text-xs font-bold transition-all flex items-center gap-1.5 active:scale-95 cursor-pointer shadow-sm">
                <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
                <span>Message</span>
              </button>
              <a [routerLink]="['/formateur', item.teacher.uid]"
                 class="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold transition-all flex items-center gap-1.5 active:scale-95 cursor-pointer">
                <span>Voir le profil</span>
                <svg class="w-3.5 h-3.5 text-slate-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                </svg>
              </a>
            </div>

          </div>
        } @empty {
          <div class="col-span-full text-center py-20 bg-white border border-dashed border-dark-border rounded-3xl shadow-xs">
            <div class="w-14 h-14 mx-auto mb-3 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400">
              <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
            </div>
            <h3 class="font-display text-base font-bold text-light">Aucun formateur trouvé</h3>
            <p class="text-xs text-light-muted mt-1">Essayez un autre mot-clé pour votre recherche.</p>
          </div>
        }
      </div>

    </div>
  `,
})
export class TeachersDirectoryComponent implements OnInit {
  private courseService = inject(CourseService);
  private router = inject(Router);
  private store = inject(Store);

  currentUser: User | null = null;
  teachersData = signal<TeacherCardData[]>([]);
  searchQuery = '';

  filteredTeachers = computed(() => {
    let list = this.teachersData();
    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(item =>
        item.teacher.displayName.toLowerCase().includes(q) ||
        (item.teacher.speciality && item.teacher.speciality.toLowerCase().includes(q)) ||
        (item.teacher.bio && item.teacher.bio.toLowerCase().includes(q))
      );
    }
    return list;
  });

  ngOnInit(): void {
    this.store.select(selectCurrentUser).subscribe(u => this.currentUser = u);

    this.courseService.getPublicTeachers().subscribe(teachers => {
      teachers.forEach(teacher => {
        this.courseService.getTeacherCourses(teacher.uid).subscribe(courses => {
          const published = courses.filter(c => c.isPublished || c.publicationStatus === 'published');
          const totalStudents = published.reduce((sum, c) => sum + (c.enrolledCount || 0), 0);
          const rated = published.filter(c => c.ratingCount > 0);
          const avgRating = rated.length ? rated.reduce((s, c) => s + c.rating, 0) / rated.length : 5.0;

          this.teachersData.update(current => {
            const index = current.findIndex(t => t.teacher.uid === teacher.uid);
            const newItem: TeacherCardData = { teacher, courses: published, totalStudents, avgRating };
            if (index >= 0) {
              current[index] = newItem;
              return [...current];
            }
            return [...current, newItem];
          });
        });
      });
    });
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

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Professeur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }
}
