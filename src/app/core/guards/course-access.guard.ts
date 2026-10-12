import { inject } from '@angular/core';
import { CanActivateFn, Router, ActivatedRouteSnapshot } from '@angular/router';
import { Auth, authState } from '@angular/fire/auth';
import { Firestore, doc, getDoc } from '@angular/fire/firestore';
import { from, switchMap, map, take } from 'rxjs';
import { Course } from '../models';

export const courseAccessGuard: CanActivateFn = (route: ActivatedRouteSnapshot) => {
  const auth = inject(Auth);
  const firestore = inject(Firestore);
  const router = inject(Router);
  const courseId = route.params['courseId'];

  return authState(auth).pipe(
    take(1),
    switchMap(user => {
      if (!user) return [router.createUrlTree(['/auth/login'])];

      return from(Promise.all([
        getDoc(doc(firestore, `courses/${courseId}`)),
        getDoc(doc(firestore, `enrollments/${user.uid}_${courseId}`)),
        getDoc(doc(firestore, `users/${user.uid}`)),
      ])).pipe(
        map(([courseSnap, enrollSnap, userSnap]) => {
          const course = courseSnap.data() as Course;
          const userRole = userSnap.data()?.['role'];

          // Admin always has access
          if (userRole === 'admin') return true;

          // Teacher of the course has access
          if (userRole === 'teacher' && course?.teacherId === user.uid) return true;

          // Free course — any logged-in user can access
          if (course?.isFree) return true;

          // Check enrollment
          if (enrollSnap.exists()) {
            const enroll = enrollSnap.data() as any;
            const now = new Date();
            const validUntil = enroll.validUntil?.toDate();

            if (enroll.status === 'active') {
              if (!validUntil || now < validUntil) {
                return true;
              }
            }
          }

          // Redirect to course detail page for purchase/renewal
          return router.createUrlTree([`/course/${courseId}`]);
        })
      );
    })
  );
};
