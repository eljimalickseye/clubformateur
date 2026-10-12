import { Component, inject, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { Observable, switchMap, of } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { EnrollmentService } from '../../../core/services/enrollment.service';
import { CourseService } from '../../../core/services/course.service';
import { Enrollment, Course } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-my-courses',
  standalone: true,
  imports: [RouterLink, BackButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-4 sm:py-8 font-body space-y-6">
      <!-- Back Navigation -->
      <div class="flex items-center justify-between gap-3">
        <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" />
        <a routerLink="/catalogue" class="btn-primary text-xs py-2 px-3.5 inline-flex shrink-0">Explorer le catalogue</a>
      </div>

      <div class="rounded-2xl border border-dark-border bg-dark-surface p-5 sm:p-6 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <p class="text-xs uppercase tracking-wider text-light-muted mb-1 font-semibold">Formations inscrites</p>
          <h1 class="font-display text-xl sm:text-2xl font-bold text-light">Mes cours</h1>
          <p class="text-light-muted text-xs sm:text-sm mt-0.5">Retrouvez vos cours en cours et terminés.</p>
        </div>
      </div>

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="card p-4"><p class="text-xs text-light-muted">Cours actifs</p><p class="font-display text-2xl font-bold text-light mt-1">{{ enrolledCount - completedCount }}</p></div>
        <div class="card p-4"><p class="text-xs text-light-muted">Terminés</p><p class="font-display text-2xl font-bold text-emerald-500 mt-1">{{ completedCount }}</p></div>
        <div class="card p-4"><p class="text-xs text-light-muted">Certificats</p><p class="font-display text-2xl font-bold text-primary mt-1">{{ certificatesCount }}</p></div>
        <div class="card p-4"><p class="text-xs text-light-muted">Progression moyenne</p><p class="font-display text-2xl font-bold text-amber-500 mt-1">{{ averageProgress }}%</p></div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        @for (item of recentEnrollments; track item.id) {
          @if (item.course) {
            <article class="card-hover overflow-hidden flex flex-col">
              <div class="aspect-video relative">
                <img loading="lazy" decoding="async" [src]="item.course.thumbnailUrl" [alt]="item.course.title" class="w-full h-full object-cover">
                @if (item.progress === 100) {
                  <span class="absolute top-2 right-2 px-2 py-0.5 bg-emerald-500 text-white text-xs font-bold rounded">
                    TERMINÉ
                  </span>
                }
              </div>
              <div class="p-4 flex-1 flex flex-col">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-xs text-primary font-medium">{{ item.course.categoryName }}</span>
                  <span class="text-xs text-light-muted">{{ item.progress === 100 ? 'Terminé' : 'En cours' }}</span>
                </div>
                <h3 class="text-sm font-semibold text-light mb-1 line-clamp-2 flex-1">{{ item.course.title }}</h3>
                <p class="text-xs text-light-muted mb-3 flex items-center gap-1.5">
                  <img loading="lazy" decoding="async" [src]="item.course.teacherPhotoURL || 'assets/images/default-avatar.png'" class="w-4 h-4 rounded-full object-cover" alt="Avatar">
                  Par {{ item.course.teacherName }}
                </p>
                <div class="w-full bg-dark-surface2 rounded-full h-1.5 mb-2">
                  <div class="bg-primary h-1.5 rounded-full transition-all" [style.width.%]="item.progress"></div>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-xs text-light-muted">{{ item.progress }}% complété</span>
                  <a [routerLink]="['/learn', item.courseId, item.lastLessonId || '']" class="text-xs text-primary font-medium hover:underline">
                    {{ item.progress === 100 ? 'Revoir' : 'Reprendre' }}
                  </a>
                </div>
              </div>
            </article>
          }
        } @empty {
          <div class="col-span-full text-center py-12 border border-dashed border-dark-border rounded-xl bg-dark-surface">
            <div class="text-4xl mb-3">📚</div>
            <p class="text-light-muted text-sm">Vous n'êtes inscrit à aucun cours pour le moment.</p>
          </div>
        }
      </div>
    </div>
  `,
})
export class MyCoursesComponent implements OnInit {
  private store = inject(Store);
  private enrollmentService = inject(EnrollmentService);
  private courseService = inject(CourseService);

  user$ = this.store.select(selectCurrentUser);
  recentEnrollments: (Enrollment & { course?: Course })[] = [];
  enrolledCount = 0;
  completedCount = 0;
  certificatesCount = 0;
  averageProgress = 0;

  ngOnInit(): void {
    this.user$.pipe(
      switchMap(user => user
        ? this.enrollmentService.getStudentEnrollments(user.uid)
        : of([])
      )
    ).subscribe(enrollments => {
      this.enrolledCount = enrollments.length;
      this.completedCount = enrollments.filter(e => e.progress === 100).length;
      this.certificatesCount = enrollments.filter(e => e.certificateIssued).length;
      
      let totalProgress = 0;
      enrollments.forEach(e => totalProgress += e.progress);
      this.averageProgress = enrollments.length > 0 ? Math.round(totalProgress / enrollments.length) : 0;
      
      this.recentEnrollments = enrollments;
      this.loadCourseDetails();
    });
  }

  private loadCourseDetails(): void {
    this.recentEnrollments.forEach((enrollment, index) => {
      this.courseService.getCourseById(enrollment.courseId).subscribe(course => {
        this.recentEnrollments[index] = { ...enrollment, course };
      });
    });
  }
}
