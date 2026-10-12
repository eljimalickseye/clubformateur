import { Component, Input, Output, EventEmitter, OnDestroy, OnInit, ElementRef, ViewChild, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Lesson } from '../../../core/models';

@Component({
  selector: 'app-video-player',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="relative bg-black rounded-2xl overflow-hidden aspect-video group shadow-xl border border-dark-border select-none"
         (contextmenu)="$event.preventDefault()">

      <!-- Video Title Header Overlay -->
      <div class="absolute top-3 left-3 sm:top-4 sm:left-4 z-20 pointer-events-none select-none max-w-[75%] sm:max-w-[80%] drop-shadow-md">
        <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/65 backdrop-blur-md border border-white/15 text-white shadow-lg">
          <span class="w-2 h-2 rounded-full bg-primary animate-pulse shrink-0"></span>
          <h3 class="text-xs sm:text-sm font-bold truncate tracking-tight text-white">{{ lesson.title }}</h3>
        </div>
      </div>

      <!-- Watermark Logo Club des Formateurs at Bottom -->
      <div class="absolute bottom-12 right-3 sm:bottom-14 sm:right-5 z-20 pointer-events-none select-none flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/55 backdrop-blur-md border border-white/15 opacity-85 group-hover:opacity-100 transition-opacity shadow-lg">
        <svg width="22" height="22" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" class="shrink-0">
          <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
          <circle cx="20" cy="20" r="4" fill="white"/>
        </svg>
        <div class="flex flex-col leading-tight">
          <span class="font-display text-[11px] font-black text-white tracking-tight drop-shadow-sm">
            Club des Formateurs
          </span>
          <span class="text-[8px] font-bold text-sky-300 uppercase tracking-widest -mt-0.5">
            Plateforme Officielle
          </span>
        </div>
      </div>
      
      <!-- Resume Playback Toast Banner -->
      @if (showResumeBanner() && resumeTime()) {
        <div class="absolute top-12 left-3 right-3 sm:top-14 sm:left-4 sm:right-4 z-30 flex items-center justify-between p-2.5 px-3.5 bg-slate-900/95 backdrop-blur-md border border-primary/40 rounded-xl text-white text-xs shadow-2xl animate-fade-in">
          <div class="flex items-center gap-2">
            <span class="text-primary text-base">🔄</span>
            <span>Lecture reprise à <strong>{{ formatTime(resumeTime()!) }}</strong></span>
          </div>
          <div class="flex items-center gap-2">
            <button (click)="restartFromBeginning()"
                    class="px-2.5 py-1 bg-white/15 hover:bg-white/25 text-sky-300 rounded-lg text-[11px] font-bold cursor-pointer transition-colors active:scale-95">
              Reprendre du début
            </button>
            <button (click)="showResumeBanner.set(false)" class="text-slate-400 hover:text-white p-1 cursor-pointer" title="Fermer">
              ✕
            </button>
          </div>
        </div>
      }

      <video #videoEl
             [src]="lesson.videoUrl"
             class="w-full h-full object-contain pointer-events-auto"
             [poster]="poster"
             controlsList="nodownload"
             (contextmenu)="$event.preventDefault()"
             (timeupdate)="onTimeUpdate()"
             (ended)="onEnded()"
             (loadedmetadata)="onMetadata()">
      </video>

      <!-- Custom controls overlay -->
      <div class="absolute inset-0 flex flex-col justify-end opacity-0 group-hover:opacity-100 transition-opacity duration-300"
           (contextmenu)="$event.preventDefault()"
           style="background: linear-gradient(transparent 40%, rgba(0,0,0,0.85) 100%)">

        <!-- Progress bar -->
        <div class="px-4 pb-2">
          <div class="relative h-1.5 bg-white/20 rounded-full cursor-pointer hover:h-2 transition-all"
               (click)="seekTo($event)">
            <!-- Buffered -->
            <div class="absolute h-full bg-white/30 rounded-full" [style.width.%]="bufferedPercent()"></div>
            <!-- Played -->
            <div class="absolute h-full bg-primary rounded-full" [style.width.%]="progressPercent()">
              <div class="absolute right-0 top-1/2 -translate-y-1/2 w-3.5 h-3.5 bg-white border-2 border-primary rounded-full
                          opacity-0 group-hover:opacity-100 transition-opacity -translate-x-1/2 shadow-md"></div>
            </div>
          </div>
        </div>

        <!-- Controls row -->
        <div class="flex items-center justify-between px-4 pb-3">
          <div class="flex items-center gap-3">
            <!-- Play/Pause -->
            <button (click)="togglePlay()" class="text-white hover:text-primary transition-colors cursor-pointer" title="Lecture / Pause">
              @if (isPlaying()) {
                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
                </svg>
              } @else {
                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8 5v14l11-7z"/>
                </svg>
              }
            </button>

            <!-- Volume -->
            <button (click)="toggleMute()" class="text-white hover:text-primary transition-colors cursor-pointer">
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                @if (isMuted()) {
                  <path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>
                } @else {
                  <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z"/>
                }
              </svg>
            </button>

            <!-- Time -->
            <span class="text-white text-xs font-mono">
              {{ formatTime(currentTime()) }} / {{ formatTime(duration()) }}
            </span>
          </div>

          <div class="flex items-center gap-3">
            <!-- Speed -->
            <select (change)="setSpeed($event)" class="bg-dark-surface2 text-white text-xs border border-dark-border rounded px-1.5 py-0.5 outline-none cursor-pointer">
              <option value="0.75">0.75x</option>
              <option value="1" selected>1x</option>
              <option value="1.25">1.25x</option>
              <option value="1.5">1.5x</option>
              <option value="2">2x</option>
            </select>

            <!-- Fullscreen -->
            <button (click)="toggleFullscreen()" class="text-white hover:text-primary transition-colors cursor-pointer" title="Plein écran">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"/>
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Center play button (when paused) -->
      @if (!isPlaying()) {
        <button (click)="togglePlay()"
                class="absolute inset-0 flex items-center justify-center cursor-pointer">
          <div class="w-16 h-16 bg-primary/90 hover:bg-primary text-white rounded-full flex items-center justify-center
                      transition-transform hover:scale-110 shadow-2xl">
            <svg class="w-7 h-7 ml-1" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z"/>
            </svg>
          </div>
        </button>
      }
    </div>
  `,
})
export class VideoPlayerComponent implements OnInit, OnDestroy {
  @Input({ required: true }) lesson!: Lesson;
  @Input() poster = '';
  @Output() lessonCompleted = new EventEmitter<Lesson>();

  @ViewChild('videoEl', { static: true }) videoEl!: ElementRef<HTMLVideoElement>;

  isPlaying = signal(false);
  isMuted = signal(false);
  currentTime = signal(0);
  duration = signal(0);
  progressPercent = signal(0);
  bufferedPercent = signal(0);

  resumeTime = signal<number | null>(null);
  showResumeBanner = signal(false);

  private lastSaveTime = 0;
  private completedEmitted = false;

  ngOnInit(): void {
    const video = this.videoEl.nativeElement;
    video.addEventListener('play', () => this.isPlaying.set(true));
    video.addEventListener('pause', () => this.isPlaying.set(false));
  }

  ngOnDestroy(): void {
    this.videoEl?.nativeElement?.pause();
  }

  togglePlay(): void {
    const v = this.videoEl.nativeElement;
    v.paused ? v.play() : v.pause();
  }

  toggleMute(): void {
    const v = this.videoEl.nativeElement;
    v.muted = !v.muted;
    this.isMuted.set(v.muted);
  }

  onTimeUpdate(): void {
    const v = this.videoEl.nativeElement;
    this.currentTime.set(v.currentTime);
    this.progressPercent.set(v.duration ? (v.currentTime / v.duration) * 100 : 0);

    if (v.buffered.length > 0) {
      this.bufferedPercent.set((v.buffered.end(v.buffered.length - 1) / v.duration) * 100);
    }

    // Save position to localStorage every 2 seconds
    const now = Date.now();
    if (now - this.lastSaveTime > 2000 && v.currentTime > 2 && this.lesson?.id) {
      this.lastSaveTime = now;
      try {
        localStorage.setItem(`school_vid_pos_${this.lesson.id}`, v.currentTime.toString());
      } catch (e) {}
    }

    // Auto-mark completed at 90%
    if (v.duration && (v.currentTime / v.duration) >= 0.90 && !this.completedEmitted) {
      this.completedEmitted = true;
      this.lessonCompleted.emit(this.lesson);
    }
  }

  onMetadata(): void {
    const v = this.videoEl.nativeElement;
    this.duration.set(v.duration);
    this.completedEmitted = false;

    // Check saved position to resume
    if (this.lesson?.id) {
      try {
        const saved = localStorage.getItem(`school_vid_pos_${this.lesson.id}`);
        if (saved) {
          const pos = parseFloat(saved);
          if (pos > 5 && pos < (v.duration - 10)) {
            v.currentTime = pos;
            this.resumeTime.set(pos);
            this.showResumeBanner.set(true);
            setTimeout(() => this.showResumeBanner.set(false), 7000);
          }
        }
      } catch (e) {}
    }
  }

  restartFromBeginning(): void {
    const v = this.videoEl.nativeElement;
    v.currentTime = 0;
    this.showResumeBanner.set(false);
    if (this.lesson?.id) {
      try {
        localStorage.removeItem(`school_vid_pos_${this.lesson.id}`);
      } catch (e) {}
    }
  }

  onEnded(): void {
    this.isPlaying.set(false);
    if (!this.completedEmitted) {
      this.completedEmitted = true;
      this.lessonCompleted.emit(this.lesson);
    }
    if (this.lesson?.id) {
      try {
        localStorage.removeItem(`school_vid_pos_${this.lesson.id}`);
      } catch (e) {}
    }
  }

  seekTo(event: MouseEvent): void {
    const el = event.currentTarget as HTMLElement;
    const rect = el.getBoundingClientRect();
    const ratio = (event.clientX - rect.left) / rect.width;
    const v = this.videoEl.nativeElement;
    v.currentTime = ratio * v.duration;
  }

  setSpeed(event: Event): void {
    const speed = parseFloat((event.target as HTMLSelectElement).value);
    this.videoEl.nativeElement.playbackRate = speed;
  }

  toggleFullscreen(): void {
    const el = this.videoEl.nativeElement.parentElement!;
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      el.requestFullscreen();
    }
  }

  formatTime(seconds: number): string {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
  }
}
