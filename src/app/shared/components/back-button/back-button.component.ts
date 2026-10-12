import { Component, Input, inject } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router } from '@angular/router';

@Component({
  selector: 'app-back-button',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button (click)="goBack()"
            type="button"
            [class]="getButtonClass()"
            class="group inline-flex items-center gap-2 transition-all duration-200 cursor-pointer select-none active:scale-95 focus:outline-none focus:ring-2 focus:ring-primary/20"
            [attr.aria-label]="label || 'Retour'">
      <!-- Crisp Left Arrow SVG -->
      <svg class="w-4 h-4 shrink-0 transition-transform duration-200 group-hover:-translate-x-1"
           fill="none"
           viewBox="0 0 24 24"
           stroke="currentColor"
           stroke-width="2.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"/>
      </svg>
      @if (label) {
        <span [class]="showIconOnlyOnMobile ? 'hidden sm:inline font-semibold text-xs sm:text-sm' : 'font-semibold text-xs sm:text-sm'">
          {{ label }}
        </span>
      }
    </button>
  `,
})
export class BackButtonComponent {
  private location = inject(Location);
  private router = inject(Router);

  @Input() label: string = 'Retour';
  @Input() defaultRoute: string = '/';
  @Input() variant: 'light' | 'dark' | 'ghost' | 'pill' = 'light';
  @Input() showIconOnlyOnMobile: boolean = false;

  goBack(): void {
    if (window.history.length > 1) {
      this.location.back();
    } else {
      this.router.navigate([this.defaultRoute]);
    }
  }

  getButtonClass(): string {
    switch (this.variant) {
      case 'dark':
        return 'min-h-[40px] px-3.5 py-2 rounded-xl bg-slate-800/90 hover:bg-slate-700 text-slate-200 hover:text-white border border-slate-700/80 shadow-xs';
      case 'ghost':
        return 'min-h-[40px] px-2.5 py-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100';
      case 'pill':
        return 'min-h-[42px] px-4 py-2 rounded-full bg-white hover:bg-slate-50 text-slate-800 hover:text-primary border border-slate-200 shadow-xs';
      case 'light':
      default:
        return 'min-h-[42px] px-3.5 py-2 rounded-xl bg-white hover:bg-slate-50 text-slate-700 hover:text-primary border border-slate-200/90 shadow-2xs hover:border-slate-300';
    }
  }
}
