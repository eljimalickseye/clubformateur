// ─── courses.actions.ts ─────────────────────────────────────
import { createActionGroup, emptyProps, props } from '@ngrx/store';
import { Course } from '../../core/models';
import { CourseFilters } from '../../core/services/course.service';

export const coursesActions = createActionGroup({
  source: 'Courses',
  events: {
    'Load Courses': props<{ filters?: any }>(),
    'Load Courses Success': props<{ courses: Course[] }>(),
    'Load Courses Failure': props<{ error: string }>(),
    'Load Featured': emptyProps(),
    'Load Featured Success': props<{ courses: Course[] }>(),
    'Select Course': props<{ id: string }>(),
    'Course Selected': props<{ course: Course }>(),
    'Clear Selected': emptyProps(),
  },
});
