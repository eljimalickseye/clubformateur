import { Injectable, inject } from '@angular/core';
import { PreloadingStrategy, Route } from '@angular/router';
import { Store } from '@ngrx/store';
import { Observable, EMPTY, timer } from 'rxjs';
import { filter, switchMap, take } from 'rxjs/operators';
import { selectAuthState } from '../../store/auth/auth.selectors';

/**
 * Préchargement intelligent des pages (lazy chunks) :
 *  - attend quelques secondes après le démarrage pour ne pas concurrencer le rendu initial ;
 *  - ne précharge rien si l'utilisateur est en mode « économie de données » ou en 2G ;
 *  - ne précharge que les pages publiques + celles de l'espace correspondant au rôle connecté
 *    (un étudiant ne télécharge pas les écrans formateur / admin).
 *
 * Résultat : les changements de page deviennent instantanés (plus d'attente du téléchargement du chunk),
 * ce qui est particulièrement visible sur iPhone.
 */
@Injectable({ providedIn: 'root' })
export class SmartPreloadingStrategy implements PreloadingStrategy {
  private store = inject(Store);

  preload(route: Route, load: () => Observable<unknown>): Observable<unknown> {
    if (route.data?.['preload'] === false || this.isSlowConnection()) {
      return EMPTY;
    }

    const requiredRole: string | undefined = route.data?.['preloadRole'];

    return timer(2500).pipe(
      switchMap(() =>
        this.store.select(selectAuthState).pipe(
          filter(state => state.initialized),
          take(1),
        )
      ),
      switchMap(state => {
        if (!requiredRole) return load();
        const role = state.user?.role;
        if (!role) return EMPTY;
        // Les admins peuvent consulter tous les espaces
        if (role === requiredRole || role === 'admin') return load();
        return EMPTY;
      }),
    );
  }

  private isSlowConnection(): boolean {
    const conn = (navigator as any)?.connection;
    if (!conn) return false; // Safari n'expose pas cette API → on précharge
    if (conn.saveData) return true;
    return typeof conn.effectiveType === 'string' && /(^|-)2g$/.test(conn.effectiveType);
  }
}
