import { inject } from '@angular/core';
import { CanActivateFn, Router, ActivatedRouteSnapshot } from '@angular/router';
import { Store } from '@ngrx/store';
import { map, take, filter } from 'rxjs';
import { selectCurrentUser } from '../../store/auth/auth.selectors';

export const roleGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const store = inject(Store);
  const router = inject(Router);
  const requiredRole = route.data['role'] as string;

  return store.select(selectCurrentUser).pipe(
    filter(user => user !== undefined),
    take(1),
    map(user => {
      if (!user) return router.createUrlTree(['/auth/login']);
      if (user.role === requiredRole || user.role === 'admin') return true;
      // Redirect to their own dashboard
      return router.createUrlTree([`/${user.role}/dashboard`]);
    })
  );
};
