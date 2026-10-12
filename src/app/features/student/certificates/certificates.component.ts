import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { Observable, switchMap, of } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { EnrollmentService } from '../../../core/services/enrollment.service';
import { CourseService } from '../../../core/services/course.service';
import { Enrollment, Course } from '../../../core/models';
import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../../shared/components/refresh-button/refresh-button.component';

@Component({
  selector: 'app-student-certificates',
  standalone: true,
  imports: [CommonModule, RouterLink, BackButtonComponent, RefreshButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-3 sm:py-6 font-body space-y-6 animate-fade-in">
      
      <!-- Sticky Navigation Bar with Back & Refresh Buttons -->
      <div class="sticky top-0 z-30 -mx-3.5 sm:-mx-6 lg:-mx-8 px-3.5 sm:px-6 lg:px-8 py-3 bg-white/95 backdrop-blur-md border-b border-slate-200/80 flex items-center justify-between shadow-2xs">
        <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" />
        <div class="flex items-center gap-2">
          <app-refresh-button />
          <a routerLink="/student/progress" class="px-3.5 py-1.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 text-xs font-bold transition-all">Progression</a>
        </div>
      </div>

      <div class="rounded-3xl border border-slate-200 bg-white p-5 sm:p-7 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-2 border border-emerald-200">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
            </svg>
            <span>Certifications Officielles</span>
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-slate-900 tracking-tight">Mes certificats</h1>
          <p class="text-xs sm:text-sm text-slate-600 mt-1">Consultez, téléchargez et vérifiez vos certificats officiels d'achèvement de cours.</p>
        </div>
      </div>

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-xs"><p class="text-xs text-slate-500 font-medium">Certificats obtenus</p><p class="font-display text-2xl font-black text-slate-900 mt-1">{{ certificates().length }}</p></div>
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-xs"><p class="text-xs text-slate-500 font-medium">Nouveaux ce mois</p><p class="font-display text-2xl font-black text-emerald-600 mt-1">{{ newThisMonth() }}</p></div>
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-xs"><p class="text-xs text-slate-500 font-medium">Partageables</p><p class="font-display text-2xl font-black text-primary mt-1">{{ certificates().length }}</p></div>
        <div class="rounded-2xl border border-slate-200 bg-white p-4 shadow-xs"><p class="text-xs text-slate-500 font-medium">Vérifications</p><p class="font-display text-2xl font-black text-amber-500 mt-1">0</p></div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        @for (cert of certificates(); track cert.id) {
          @if (cert.course) {
            <article class="rounded-3xl border border-slate-200 bg-white p-5 shadow-xs hover:border-primary/40 hover:shadow-md transition-all">
              <div class="flex items-start justify-between mb-3">
                <div class="h-10 w-10 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z" />
                  </svg>
                </div>
                <span class="text-[11px] font-mono text-slate-500 font-bold">ID : {{ cert.id | slice:0:8 | uppercase }}</span>
              </div>
              <h3 class="text-sm font-bold text-slate-900 mb-1 line-clamp-2">{{ cert.course.title }}</h3>
              <p class="text-xs text-slate-500 mb-3">Par {{ cert.course.teacherName }}</p>
              @if (cert.certificateIssuedAt) {
                <p class="text-xs text-slate-500 mb-4">Date d'émission : {{ cert.certificateIssuedAt.toDate() | date:'dd/MM/yyyy' }}</p>
              }
              <div class="flex items-center gap-3">
                @if (cert.certificateUrl) {
                  <a [href]="cert.certificateUrl" target="_blank" class="px-3.5 py-1.5 rounded-xl bg-primary text-white text-xs font-bold hover:bg-primary-600 transition-all">Télécharger PDF</a>
                }
                <a [routerLink]="['/certificate/verify', cert.id]" class="text-xs text-primary font-bold hover:underline">Vérifier</a>
              </div>
            </article>
          }
        } @empty {
          <div class="col-span-full text-center py-12 border border-dashed border-slate-200 rounded-3xl bg-slate-50">
            <div class="w-12 h-12 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mx-auto mb-3">
              <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
            </div>
            <p class="text-slate-700 font-bold text-sm">Vous n'avez pas encore de certificat.</p>
            <p class="text-xs text-slate-500 mt-1">Complétez vos cours pour obtenir des certificats certifiés.</p>
          </div>
        }
      </div>
    </div>
  `,
})
export class CertificatesComponent implements OnInit {
  private store = inject(Store);
  private enrollmentService = inject(EnrollmentService);
  private courseService = inject(CourseService);

  certificates = signal<(Enrollment & { course?: Course })[]>([]);
  newThisMonth = signal(0);

  ngOnInit() {
    this.store.select(selectCurrentUser).pipe(
      switchMap(user => user ? this.enrollmentService.getStudentEnrollments(user.uid) : of([]))
    ).subscribe(enrollments => {
      // Filter enrollments that have a certificate issued
      const certs = enrollments.filter(e => e.certificateIssued);
      this.certificates.set(certs);
      
      // Calculate "Nouveaux ce mois"
      const now = new Date();
      const thisMonth = certs.filter(c => {
        if (!c.certificateIssuedAt) return false;
        const date = c.certificateIssuedAt.toDate();
        return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
      });
      this.newThisMonth.set(thisMonth.length);

      // Load course details for each certificate
      certs.forEach((cert, index) => {
        this.courseService.getCourseById(cert.courseId).subscribe(course => {
          const updatedCerts = [...this.certificates()];
          updatedCerts[index] = { ...updatedCerts[index], course };
          this.certificates.set(updatedCerts);
        });
      });
    });
  }
}
