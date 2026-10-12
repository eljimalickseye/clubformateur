import { Injectable, inject } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { catchError, map, switchMap, of } from 'rxjs';
import { CourseService } from '../../core/services/course.service';
import { coursesActions } from './courses.actions';

@Injectable()
export class CoursesEffects {
  private actions$ = inject(Actions);
  private courseService = inject(CourseService);

  loadCourses$ = createEffect(() =>
    this.actions$.pipe(
      ofType(coursesActions.loadCourses),
      switchMap(({ filters }) =>
        this.courseService.getCourses(filters ?? {}).pipe(
          map(courses => coursesActions.loadCoursesSuccess({ courses })),
          catchError(err => of(coursesActions.loadCoursesFailure({ error: err.message })))
        )
      )
    )
  );

  loadFeatured$ = createEffect(() =>
    this.actions$.pipe(
      ofType(coursesActions.loadFeatured),
      switchMap(() =>
        this.courseService.getFeaturedCourses().pipe(
          map(courses => coursesActions.loadFeaturedSuccess({ courses })),
          catchError(() => of(coursesActions.loadCoursesFailure({ error: 'Erreur chargement' })))
        )
      )
    )
  );

  selectCourse$ = createEffect(() =>
    this.actions$.pipe(
      ofType(coursesActions.selectCourse),
      switchMap(({ id }) =>
        this.courseService.getCourseById(id).pipe(
          map(course => course
            ? coursesActions.courseSelected({ course })
            : coursesActions.loadCoursesFailure({ error: 'Cours introuvable' })
          ),
          catchError(err => of(coursesActions.loadCoursesFailure({ error: err.message })))
        )
      )
    )
  );
}
