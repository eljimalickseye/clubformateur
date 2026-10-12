import { Component, Input, signal } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-refresh-button',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button (click)="refresh()"
            type="button"
            [class]="getButtonClass()"
            class="group inline-flex items-center gap-1.5 transition-all duration-200 cursor-pointer select-none active:scale-95 focus:outline-none focus:ring-2 focus:ring-primary/20"
            [title]="label || 'Actualiser la page'"
            [attr.aria-label]="label || 'Actualiser la page'">
      <!-- Circular Refresh Arrow SVG -->
      <svg class="w-4 h-4 shrink-0 transition-transform duration-500 group-hover:rotate-180"
           [class.animate-spin]="isRefreshing()"
           fill="none"
           viewBox="0 0 24 24"
           stroke="currentColor"
           stroke-width="2.5">
        <path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
      </svg>
      @if (label) {
        <span class="font-semibold text-xs sm:text-sm">
          {{ label }}
        </span>
      }
    </button>
  `,
})
export class RefreshButtonComponent {
  @Input() label?: string;
  @Input() variant: 'light' | 'dark' | 'ghost' = 'light';

  isRefreshing = signal(false);

  refresh(): void {
    this.isRefreshing.set(true);
    setTimeout(() => {
      window.location.reload();
    }, 350);
  }

  getButtonClass(): string {
    switch (this.variant) {
      case 'dark':
        return 'min-h-[40px] px-3 py-2 rounded-xl bg-slate-800/90 hover:bg-slate-700 text-slate-200 hover:text-white border border-slate-700/80 shadow-xs';
      case 'ghost':
        return 'min-h-[40px] px-2.5 py-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100';
      case 'light':
      default:
        return 'min-h-[42px] px-3 py-2 rounded-xl bg-white hover:bg-slate-50 text-slate-700 hover:text-primary border border-slate-200/90 shadow-2xs hover:border-slate-300';
    }
  }
}
