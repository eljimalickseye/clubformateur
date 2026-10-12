import { Component, inject } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { LoadingService } from '../../../core/services/loading.service';

@Component({
  selector: 'app-loading-bar',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    @if (loading$ | async) {
      <div class="fixed top-0 left-0 right-0 z-[100] h-0.5">
        <div class="h-full bg-primary animate-[loading_1.5s_ease-in-out_infinite]"></div>
      </div>
    }
  `,
  styles: [`
    @keyframes loading {
      0% { width: 0%; margin-left: 0%; }
      50% { width: 70%; margin-left: 10%; }
      100% { width: 0%; margin-left: 100%; }
    }
  `],
})
export class LoadingBarComponent {
  loading$ = inject(LoadingService).loading$;
}
