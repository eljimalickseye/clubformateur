import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { Auth, authState } from '@angular/fire/auth';
import { Firestore, doc, getDoc } from '@angular/fire/firestore';
import { switchMap, map, take } from 'rxjs';

export const redirectIfAuthGuard: CanActivateFn = () => {
  const auth = inject(Auth);
  const firestore = inject(Firestore);
  const router = inject(Router);

  return authState(auth).pipe(
    take(1),
    switchMap(async user => {
      if (!user) return true;
      const snap = await getDoc(doc(firestore, `users/${user.uid}`));
      const role = snap.data()?.['role'] ?? 'student';
      return router.createUrlTree([`/${role}/dashboard`]);
    })
  );
};
