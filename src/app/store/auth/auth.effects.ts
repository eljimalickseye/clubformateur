import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { ToastrService } from 'ngx-toastr';
import { catchError, map, switchMap, tap, from, of } from 'rxjs';
import { AuthService } from '../../core/services/auth.service';
import { authActions } from './auth.actions';
import { UserRole } from '../../core/models';

@Injectable()
export class AuthEffects {
  private actions$ = inject(Actions);
  private authService = inject(AuthService);
  private router = inject(Router);
  private toastr = inject(ToastrService);

  initAuth$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.initAuth),
      switchMap(() =>
        this.authService.currentUser$.pipe(
          map(user => authActions.setUser({ user }))
        )
      )
    )
  );

  login$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.login),
      switchMap(({ email, password }) =>
        from(this.authService.login(email, password)).pipe(
          switchMap(() =>
            this.authService.currentUser$.pipe(
              map(user => {
                if (!user) throw new Error('Utilisateur introuvable');
                return authActions.loginSuccess({ user });
              })
            )
          ),
          catchError(err => of(authActions.loginFailure({ error: this.getErrorMessage(err.code) })))
        )
      )
    )
  );

  loginSuccess$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.loginSuccess),
      tap(({ user }) => {
        this.toastr.success(`Bienvenue, ${user.displayName} !`);
        let returnUrl: string | null = null;
        try {
          const urlParams = new URLSearchParams(window.location.search);
          returnUrl = urlParams.get('returnUrl');
        } catch {}

        if (returnUrl && returnUrl.startsWith('/') && !returnUrl.startsWith('//')) {
          this.router.navigateByUrl(returnUrl);
        } else {
          this.router.navigate([`/${user.role}/dashboard`]);
        }
      })
    ),
    { dispatch: false }
  );

  loginWithGoogle$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.loginWithGoogle),
      switchMap(({ role }) =>
        from(this.authService.loginWithGoogle(role || 'student')).pipe(
          map(user => authActions.loginSuccess({ user })),
          catchError(err => of(authActions.loginFailure({ error: this.getErrorMessage(err.code || err.message) })))
        )
      )
    )
  );

  register$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.register),
      switchMap(({ email, password, displayName, role, phone }) =>
        from(this.authService.register({ email, password, displayName, role: role as UserRole, phone })).pipe(
          map(user => authActions.registerSuccess({ user })),
          catchError(err => of(authActions.registerFailure({ error: this.getErrorMessage(err.code || err.message) })))
        )
      )
    )
  );

  registerSuccess$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.registerSuccess),
      tap(() => {
        this.toastr.success('Compte créé avec succès !');
        // NOTE: Redirection is handled by the register component (step 3 → catalogue button)
      })
    ),
    { dispatch: false }
  );

  updateProfile$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.updateProfile),
      switchMap(({ data }) =>
        from(this.authService.currentUser$).pipe(
          switchMap(user => {
            if (!user) throw new Error('Utilisateur non connecté');
            return from(this.authService.updateProfile(user.uid, data)).pipe(
              map(() => {
                this.toastr.success('Profil mis à jour avec succès !');
                return authActions.updateProfileSuccess({ data });
              })
            );
          }),
          catchError(err => {
            this.toastr.error('Erreur lors de la mise à jour du profil.');
            return of(authActions.loginFailure({ error: err.message }));
          })
        )
      )
    )
  );

  logout$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.logout),
      switchMap(() =>
        from(this.authService.logout()).pipe(
          map(() => authActions.logoutSuccess()),
          catchError(() => of(authActions.logoutSuccess()))
        )
      )
    )
  );

  logoutSuccess$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.logoutSuccess),
      tap(() => this.router.navigate(['/']))
    ),
    { dispatch: false }
  );

  authError$ = createEffect(() =>
    this.actions$.pipe(
      ofType(authActions.loginFailure, authActions.registerFailure),
      tap(({ error }) => this.toastr.error(error))
    ),
    { dispatch: false }
  );

  private getErrorMessage(codeOrMessage: string): string {
    if (!codeOrMessage) return 'Une erreur est survenue.';
    if (codeOrMessage.includes('auth/unauthorized-domain') || codeOrMessage.includes('unauthorized-domain')) {
      return 'Ce domaine (club-des-formateurs.web.app) doit être autorisé dans Firebase Console > Authentification > Paramètres > Domaines autorisés.';
    }
    if (codeOrMessage.includes('auth/popup-closed-by-user')) {
      return 'Connexion annulée : la fenêtre Google a été fermée.';
    }
    const messages: Record<string, string> = {
      'auth/user-not-found': 'Aucun compte avec cet email.',
      'auth/wrong-password': 'Mot de passe incorrect.',
      'auth/email-already-in-use': 'Cet email est déjà utilisé.',
      'auth/weak-password': 'Mot de passe trop faible (6 caractères minimum).',
      'auth/invalid-email': 'Adresse email invalide.',
      'auth/too-many-requests': 'Trop de tentatives. Réessayez plus tard.',
      'auth/network-request-failed': 'Erreur réseau. Vérifiez votre connexion.',
      'auth/unauthorized-domain': 'Ce domaine doit être autorisé dans Firebase Console > Authentication > Settings > Authorized domains.',
      'auth/popup-closed-by-user': 'Connexion Google annulée.',
      'auth/cancelled-popup-request': 'Une seule fenêtre de connexion Google peut être ouverte.',
    };
    return messages[codeOrMessage] ?? 'Identifiants invalides ou erreur de connexion.';
  }
}
