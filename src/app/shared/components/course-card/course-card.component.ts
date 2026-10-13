import { Component, Input, Output, EventEmitter } from '@angular/core';
import { RouterLink } from '@angular/router';
import { DecimalPipe } from '@angular/common';
import { Course } from '../../../core/models';

@Component({
  selector: 'app-course-card',
  standalone: true,
  imports: [RouterLink, DecimalPipe],
  template: `
    <a [routerLink]="['/course', course.id]"
       class="group block bg-dark-surface border border-dark-border rounded-2xl overflow-hidden
              hover:border-primary/40 hover:shadow-2xl hover:shadow-primary/5 transition-all duration-500 hover:-translate-y-1">
      <!-- Thumbnail -->
      <div class="relative aspect-[16/10] overflow-hidden">
        <img loading="lazy" decoding="async" [src]="course.thumbnailUrl" [alt]="course.title"
             class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700">
        
        <!-- Overlays -->
        <div class="absolute inset-0 bg-gradient-to-t from-dark/80 via-transparent to-transparent opacity-60 group-hover:opacity-40 transition-opacity"></div>
        
        <!-- Badges -->
        <div class="absolute top-3 left-3 flex flex-wrap gap-2">
          @if (course.isFree) {
            <span class="px-3 py-1 bg-emerald-500 text-white text-xs font-black rounded-lg shadow-lg">
              GRATUIT
            </span>
          }
          @if (course.hasLiveClasses) {
            <span class="px-3 py-1 bg-red-500 text-white text-xs font-black rounded-lg shadow-lg flex items-center gap-1.5">
              <span class="w-2 h-2 bg-white rounded-full animate-pulse"></span> LIVE
            </span>
          }
        </div>

        @if (course.hasCertificate) {
          <div class="absolute top-3 right-3 w-8 h-8 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center text-primary border border-white/20" title="Certificat inclus">
            <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
            </svg>
          </div>
        }

        <!-- Play Button Overlay on Hover -->
        <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
           <button (click)="$event.preventDefault(); $event.stopPropagation(); onPlayVideo()" 
                   class="w-12 h-12 rounded-full bg-primary text-white flex items-center justify-center shadow-xl transform scale-75 group-hover:scale-100 transition-transform duration-300">
             <svg class="w-6 h-6 ml-1" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
           </button>
        </div>
      </div>

      <!-- Content -->
      <div class="p-5 sm:p-6">
        <!-- Category & Rating -->
        <div class="flex items-center justify-between mb-3">
          <span class="px-2.5 py-1 bg-primary/10 text-primary text-xs font-black uppercase tracking-wider rounded-lg">
            {{ course.categoryName }}
          </span>
          <div class="flex items-center gap-1.5 px-2.5 py-1 bg-amber-400/10 rounded-lg">
            <svg class="w-3.5 h-3.5 text-amber-500 fill-current" viewBox="0 0 20 20">
              <path d="M10 1l2.39 4.84 5.34.78-3.87 3.77.91 5.32L10 13.27l-4.77 2.44.91-5.32L2.27 6.62l5.34-.78z"/>
            </svg>
            <span class="text-xs font-black text-amber-600">{{ course.rating | number:'1.1-1' }}</span>
          </div>
        </div>

        <!-- Title -->
        <h3 class="font-display text-base sm:text-lg font-bold text-light line-clamp-2 mb-2
                   group-hover:text-primary transition-colors leading-snug">
          {{ course.title }}
        </h3>
        
        <p class="text-xs sm:text-sm text-light-muted line-clamp-2 mb-4 leading-relaxed font-medium">{{ course.shortDescription || course.description }}</p>

        <!-- Stats Row -->
        <div class="flex items-center gap-4 text-xs sm:text-sm font-semibold text-light-muted mb-5 border-y border-dark-border/80 py-3">
          <div class="flex items-center gap-1.5">
            <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span>{{ formatDuration(course.totalDuration) }}</span>
          </div>
          <div class="flex items-center gap-1.5">
            <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
            </svg>
            <span>{{ course.totalLessons }} leçons</span>
          </div>
          <div class="flex items-center gap-1.5">
            <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
            </svg>
            <span class="capitalize">{{ course.level }}</span>
          </div>
        </div>

        <!-- Footer: Teacher & Price -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2.5">
            <img loading="lazy" decoding="async" [src]="course.teacherPhotoURL" [alt]="course.teacherName" 
                 class="w-9 h-9 rounded-full object-cover border border-dark-border"
                 onerror="this.src='https://ui-avatars.com/api/?name=' + course.teacherName + '&background=2D5BE3&color=fff'">
            <div class="flex flex-col">
              <span class="text-xs sm:text-sm font-bold text-light leading-none mb-0.5">{{ course.teacherName }}</span>
              <span class="text-[11px] sm:text-xs font-semibold text-light-muted">Formateur</span>
            </div>
          </div>

          <div class="text-right">
            @if (course.isFree || course.price === 0) {
              <span class="text-lg sm:text-xl font-black text-emerald-600">GRATUIT</span>
            } @else {
              <div class="flex flex-col items-end">
                <span class="text-lg sm:text-xl font-black text-[#0D6B4D]">{{ course.price | number }} FCFA</span>
                @if (course.originalPrice && course.originalPrice > course.price) {
                  <span class="text-xs text-slate-400 line-through">{{ course.originalPrice | number }} FCFA</span>
                }
              </div>
            }
          </div>
        </div>
      </div>
    </a>
  `,
})
export class CourseCardComponent {
  @Input({ required: true }) course!: Course;
  @Output() playVideo = new EventEmitter<Course>();

  onPlayVideo() {
    this.playVideo.emit(this.course);
  }

  formatDuration(seconds: number): string {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? `${h}h${m > 0 ? m + 'min' : ''}` : `${m}min`;
  }
}
