import { Component, inject, signal, OnInit } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink, ActivatedRoute } from '@angular/router';
import { Store } from '@ngrx/store';
import { AsyncPipe, CommonModule } from '@angular/common';
import { authActions } from '../../../store/auth/auth.actions';
import { selectAuthLoading, selectAuthError } from '../../../store/auth/auth.selectors';
import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { UserRole } from '../../../core/models';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, AsyncPipe, CommonModule, BackButtonComponent],
  template: `
    <div class="min-h-screen bg-[#F8FAFC] flex flex-col justify-center items-center px-4 py-8 sm:py-12 relative font-body overflow-hidden">
      
      <!-- Back to Home Button (Top Left) -->
      <div class="w-full max-w-[480px] mb-4 flex items-center justify-between">
        <app-back-button label="Retour à l'accueil" defaultRoute="/" variant="light" />
        <span class="text-xs font-bold text-slate-400">Club des Formateurs</span>
      </div>

      <!-- App Logo -->
      <div class="mb-5 text-center">
        <a routerLink="/" class="inline-flex items-center gap-2.5 group">
          <div class="w-10 h-10 rounded-2xl bg-gradient-to-tr from-[#2D5BE3] to-[#4F46E5] flex items-center justify-center text-white shadow-md shadow-primary/20 group-hover:scale-105 transition-transform">
            <svg width="24" height="24" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#ffffff"/>
              <circle cx="20" cy="20" r="4" fill="#2D5BE3"/>
            </svg>
          </div>
          <span class="font-display text-xl sm:text-2xl font-black text-[#0F172A] tracking-tight group-hover:text-primary transition-colors">
            Club des Formateurs
          </span>
        </a>
      </div>

      <!-- Main Login Card -->
      <div class="w-full max-w-[480px] bg-white rounded-[28px] shadow-xl shadow-slate-200/60 overflow-hidden relative border border-[#EEF2FF] z-10">
        
        <!-- Top Gradient Accent -->
        <div class="h-1.5 w-full bg-gradient-to-r"
             [ngClass]="selectedRole() === 'teacher' ? 'from-amber-500 via-primary to-purple-600' : 'from-[#2D5BE3] via-[#4F46E5] to-[#8B5CF6]'"></div>

        <!-- Role Switcher Tabs (Étudiant vs Formateur) -->
        <div class="p-3 bg-slate-50 border-b border-slate-100 flex items-center gap-2">
          <button type="button"
                  (click)="setRole('student')"
                  class="flex-1 py-2.5 px-3 rounded-2xl text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer active:scale-95"
                  [ngClass]="selectedRole() === 'student' 
                    ? 'bg-white text-primary shadow-sm border border-slate-200/80' 
                    : 'text-slate-500 hover:text-slate-900 hover:bg-white/60'">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
            </svg>
            <span>Espace Étudiant</span>
          </button>

          <button type="button"
                  (click)="setRole('teacher')"
                  class="flex-1 py-2.5 px-3 rounded-2xl text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer active:scale-95"
                  [ngClass]="selectedRole() === 'teacher' 
                    ? 'bg-white text-primary shadow-sm border border-slate-200/80' 
                    : 'text-slate-500 hover:text-slate-900 hover:bg-white/60'">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
            </svg>
            <span>Espace Formateur</span>
          </button>
        </div>

        <div class="p-6 sm:p-8">
          
          <!-- Heading per Role -->
          <div class="mb-6">
            <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider mb-2"
                 [ngClass]="selectedRole() === 'teacher' ? 'bg-amber-50 text-amber-700 border border-amber-200' : 'bg-blue-50 text-primary border border-blue-200'">
              <span>{{ selectedRole() === 'teacher' ? '👨‍🏫 CORPS PROFESSORAL' : '🎓 ESPACE APPRENANT' }}</span>
            </div>
            
            <h1 class="font-display text-2xl font-extrabold text-[#0F172A] tracking-tight">
              {{ selectedRole() === 'teacher' ? 'Connexion Formateur' : 'Bon retour parmi nous !' }}
            </h1>
            <p class="text-xs text-[#64748B] mt-1 leading-relaxed">
              {{ selectedRole() === 'teacher' 
                ? 'Accédez à votre espace enseignant pour animer vos cours et suivre vos gains.' 
                : 'Connectez-vous pour accéder à vos formations, devoirs et sessions directes.' }}
            </p>
          </div>

          <!-- Error Alert Banner -->
          @if (error$ | async; as error) {
            <div class="mb-5 p-3.5 rounded-2xl bg-red-50 border border-red-200/80 flex items-start gap-3 text-red-700 animate-fade-in">
              <svg class="w-5 h-5 text-red-500 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
              <div class="text-xs font-semibold leading-relaxed">
                {{ error }}
              </div>
            </div>
          }

          <!-- Google Dedicated Sign-In Button -->
          <button type="button"
                  (click)="loginWithGoogle()"
                  class="w-full py-3 px-4 border border-[#E2E8F0] hover:border-[#CBD5E1] bg-white hover:bg-[#F8FAFC] rounded-2xl text-xs font-bold text-[#0F172A] shadow-xs active:scale-[0.98] transition-all flex items-center justify-center gap-3 cursor-pointer mb-5">
            <svg class="w-4 h-4" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            <span>Continuer avec Google ({{ selectedRole() === 'teacher' ? 'Formateur' : 'Étudiant' }})</span>
          </button>

          <!-- Divider -->
          <div class="relative my-5">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-[#E2E8F0]"></div>
            </div>
            <div class="relative flex justify-center text-[11px] font-bold uppercase tracking-wider text-[#94A3B8]">
              <span class="bg-white px-3">ou par email</span>
            </div>
          </div>

          <form [formGroup]="form" (ngSubmit)="onSubmit()" class="space-y-4">
            
            <!-- Email Field -->
            <div>
              <label class="block text-xs font-bold text-[#0F172A] mb-1.5">
                Adresse email
              </label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#94A3B8]">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.255 1.206"/>
                  </svg>
                </div>
                <input type="email"
                       formControlName="email"
                       placeholder="votre.email@exemple.com"
                       class="w-full pl-10 pr-4 py-3 bg-[#F8FAFC] border border-[#E2E8F0] rounded-2xl text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:bg-white focus:border-[#2D5BE3] focus:ring-4 focus:ring-[#2D5BE3]/10 transition-all font-medium">
              </div>
              @if (form.get('email')?.invalid && form.get('email')?.touched) {
                <p class="text-red-500 text-[11px] font-semibold mt-1 flex items-center gap-1">
                  <span>●</span> Veuillez entrer une adresse email valide.
                </p>
              }
            </div>

            <!-- Password Field -->
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="block text-xs font-bold text-[#0F172A]">
                  Mot de passe
                </label>
                <a routerLink="/auth/forgot-password"
                   class="text-xs font-bold text-[#2D5BE3] hover:text-[#1E40AF] transition-colors">
                  Mot de passe oublié ?
                </a>
              </div>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#94A3B8]">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                  </svg>
                </div>
                <input [type]="showPassword() ? 'text' : 'password'"
                       formControlName="password"
                       placeholder="••••••••••••"
                       class="w-full pl-10 pr-11 py-3 bg-[#F8FAFC] border border-[#E2E8F0] rounded-2xl text-xs text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:bg-white focus:border-[#2D5BE3] focus:ring-4 focus:ring-[#2D5BE3]/10 transition-all font-medium">
                
                <!-- Toggle Password Visibility Button -->
                <button type="button"
                        (click)="togglePasswordVisibility()"
                        class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-[#94A3B8] hover:text-[#0F172A] transition-colors cursor-pointer"
                        title="Afficher/Masquer le mot de passe">
                  @if (showPassword()) {
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"/>
                    </svg>
                  } @else {
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                    </svg>
                  }
                </button>
              </div>
            </div>

            <!-- Submit Button -->
            <button type="submit"
                    [disabled]="form.invalid || (loading$ | async)"
                    class="w-full py-3.5 bg-gradient-to-r from-[#2D5BE3] to-[#1E40AF] hover:from-[#1E40AF] hover:to-[#2D5BE3] text-white font-bold rounded-2xl shadow-md shadow-[#2D5BE3]/25 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed transition-all text-xs flex items-center justify-center gap-2 cursor-pointer mt-2">
              @if (loading$ | async) {
                <svg class="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                </svg>
                <span>Connexion en cours...</span>
              } @else {
                <span>Se connecter en tant que {{ selectedRole() === 'teacher' ? 'Formateur' : 'Étudiant' }}</span>
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                </svg>
              }
            </button>
          </form>

        </div>

        <!-- Footer link inside Card -->
        <div class="px-6 py-4 bg-[#F8FAFC] border-t border-[#EEF2FF] text-center">
          <p class="text-xs text-[#64748B]">
            {{ selectedRole() === 'teacher' ? "Pas encore formateur dans le club ?" : "Pas encore inscrit ?" }}
            <a [routerLink]="['/auth/register']" [queryParams]="returnUrl() ? { role: selectedRole(), returnUrl: returnUrl() } : { role: selectedRole() }"
               class="font-bold text-[#2D5BE3] hover:text-[#1E40AF] hover:underline ml-1">
              {{ selectedRole() === 'teacher' ? "Rejoindre l'équipe enseignante →" : "Créer un compte gratuitement →" }}
            </a>
          </p>
        </div>

      </div>

      <!-- Security Trust Footer -->
      <div class="mt-6 text-center text-[11px] text-[#94A3B8] flex items-center justify-center gap-1.5">
        <svg class="w-3.5 h-3.5 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
        </svg>
        <span>Connexion sécurisée SSL 256-bit • Club des Formateurs</span>
      </div>

    </div>
  `,
})
export class LoginComponent implements OnInit {
  private fb = inject(FormBuilder);
  private store = inject(Store);
  private route = inject(ActivatedRoute);

  selectedRole = signal<UserRole>('student');
  showPassword = signal(false);
  returnUrl = signal<string | null>(null);

  loading$ = this.store.select(selectAuthLoading);
  error$ = this.store.select(selectAuthError);

  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  ngOnInit(): void {
    const roleParam = this.route.snapshot.queryParamMap.get('role');
    if (roleParam === 'teacher' || roleParam === 'student') {
      this.selectedRole.set(roleParam as UserRole);
    }

    const emailParam = this.route.snapshot.queryParamMap.get('email');
    if (emailParam) {
      this.form.patchValue({ email: emailParam });
    }

    const retParam = this.route.snapshot.queryParamMap.get('returnUrl');
    if (retParam) {
      this.returnUrl.set(retParam);
    }
  }

  setRole(role: UserRole): void {
    this.selectedRole.set(role);
  }

  togglePasswordVisibility(): void {
    this.showPassword.update(v => !v);
  }

  onSubmit(): void {
    if (this.form.invalid) return;
    const { email, password } = this.form.value;
    this.store.dispatch(authActions.login({ email: email!, password: password! }));
  }

  loginWithGoogle(): void {
    this.store.dispatch(authActions.loginWithGoogle({ role: this.selectedRole() }));
  }
}
