import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { Observable, switchMap, of, forkJoin, map, catchError } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { EnrollmentService } from '../../../core/services/enrollment.service';
import { CourseService } from '../../../core/services/course.service';
import { Enrollment, Course, Progress } from '../../../core/models';

interface ProgressWithCourse extends Progress {
  course?: Course;
  enrollment?: Enrollment;
}

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-student-progress',
  standalone: true,
  imports: [CommonModule, RouterLink, BackButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-4 sm:py-8 font-body space-y-6">
      <!-- Back Navigation -->
      <div class="flex items-center justify-between gap-3">
        <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" />
        <a routerLink="/student/my-courses" class="btn-secondary text-xs py-2 px-3.5 inline-flex">Mes cours</a>
      </div>

      <div class="rounded-2xl border border-dark-border bg-dark-surface p-5 sm:p-6 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <p class="text-xs uppercase tracking-wider text-light-muted mb-1 font-semibold">Suivi d'apprentissage</p>
          <h1 class="font-display text-xl sm:text-2xl font-bold text-light">Ma progression</h1>
          <p class="text-light-muted text-xs sm:text-sm mt-0.5">Suivi détaillé de vos performances par formation.</p>
        </div>
      </div>

      @if (loading()) {
        <div class="flex justify-center py-20">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      } @else {
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <section class="lg:col-span-2 card p-5">
            <h2 class="font-display text-lg font-semibold text-light mb-4">Progression par cours</h2>
            <div class="space-y-4">
              @for (item of progressData(); track item.courseId) {
                <div class="p-4 rounded-xl border border-dark-border bg-dark">
                  <div class="flex items-center justify-between mb-2">
                    <p class="text-sm font-semibold text-light">{{ item.course?.title }}</p>
                    <p class="text-xs text-light-muted">{{ item.progress }}%</p>
                  </div>
                  <div class="h-2 rounded-full bg-dark-surface2 mb-2">
                    <div class="h-2 rounded-full bg-primary transition-all" [style.width.%]="item.progress"></div>
                  </div>
                  <div class="flex items-center justify-between text-xs text-light-muted">
                    <span>{{ item.completedLessons.length }}/{{ item.course?.totalLessons || 0 }} leçons complétées</span>
                    <span>{{ formatWatchTime(item.totalWatchTime) }} de visionnage</span>
                  </div>
                </div>
              } @empty {
                <div class="text-center py-10">
                  <p class="text-light-muted text-sm">Vous n'avez pas encore commencé de cours.</p>
                </div>
              }
            </div>
          </section>

          <aside class="space-y-4">
            <div class="card p-5">
              <h3 class="font-display text-base font-semibold text-light mb-3">Résumé global</h3>
              <div class="space-y-3 text-sm">
                <div class="flex items-center justify-between"><span class="text-light-muted">Cours actifs</span><span class="text-light font-semibold">{{ activeCourses() }}</span></div>
                <div class="flex items-center justify-between"><span class="text-light-muted">Heures étudiées</span><span class="text-light font-semibold">{{ totalWatchHours() | number:'1.0-1' }}h</span></div>
                <div class="flex items-center justify-between"><span class="text-light-muted">Quiz réussis</span><span class="text-emerald-500 font-semibold">{{ averageQuizScore() }}%</span></div>
              </div>
            </div>
            
            <div class="card p-5">
              <h3 class="font-display text-base font-semibold text-light mb-3">Objectif hebdo</h3>
              <p class="text-sm text-light-muted mb-2">5h d'étude cette semaine</p>
              <div class="h-2 rounded-full bg-dark-surface2">
                <div class="h-2 rounded-full bg-emerald-500 transition-all" [style.width.%]="weeklyGoalProgress()"></div>
              </div>
              <p class="text-xs text-emerald-500 mt-2 font-medium">{{ totalWatchHours() | number:'1.0-1' }}h / 5h complétées</p>
            </div>
          </aside>
        </div>
      }
    </div>
  `,
})
export class ProgressComponent implements OnInit {
  private store = inject(Store);
  private enrollmentService = inject(EnrollmentService);
  private courseService = inject(CourseService);

  loading = signal(true);
  progressData = signal<ProgressWithCourse[]>([]);
  activeCourses = signal(0);
  totalWatchHours = signal(0);
  averageQuizScore = signal(0);

  ngOnInit() {
    this.store.select(selectCurrentUser).pipe(
      switchMap(user => {
        if (!user) return of([]);
        return this.enrollmentService.getStudentEnrollments(user.uid).pipe(
          switchMap(enrollments => {
            if (enrollments.length === 0) return of([]);
            
            this.activeCourses.set(enrollments.filter(e => e.progress < 100).length);

            // Fetch progress and course details for each enrollment
            const requests = enrollments.map(enrollment => 
              this.enrollmentService.getProgress(user.uid, enrollment.courseId).pipe(
                catchError(() => of(null)),
                switchMap(progress => {
                  return this.courseService.getCourseById(enrollment.courseId).pipe(
                    map(course => {
                      // Fallback progress if not initialized in progress subcollection
                      const actualProgress = progress || {
                        userId: user.uid,
                        courseId: enrollment.courseId,
                        completedLessons: enrollment.completedLessons,
                        quizAttempts: {},
                        totalWatchTime: 0,
                        lastAccessedAt: enrollment.lastAccessedAt,
                        progress: enrollment.progress
                      };
                      return { ...actualProgress, course, enrollment };
                    })
                  );
                })
              )
            );
            return forkJoin(requests);
          })
        );
      })
    ).subscribe((data: any[]) => {
      this.progressData.set(data.filter(d => d !== null));
      this.calculateGlobals(this.progressData());
      this.loading.set(false);
    });
  }

  private calculateGlobals(data: ProgressWithCourse[]) {
    let totalSeconds = 0;
    let totalQuizScores = 0;
    let quizCount = 0;

    data.forEach(item => {
      totalSeconds += item.totalWatchTime || 0;
      
      if (item.quizAttempts) {
        Object.values(item.quizAttempts).forEach((attempt: any) => {
          totalQuizScores += attempt.score;
          quizCount++;
        });
      }
    });

    this.totalWatchHours.set(totalSeconds / 3600);
    this.averageQuizScore.set(quizCount > 0 ? Math.round(totalQuizScores / quizCount) : 0);
  }

  weeklyGoalProgress(): number {
    const hours = this.totalWatchHours();
    return Math.min((hours / 5) * 100, 100);
  }

  formatWatchTime(seconds: number): string {
    if (!seconds) return '0min';
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? `${h}h${m > 0 ? m + 'm' : ''}` : `${m}min`;
  }
}

