import { createReducer, on, createFeatureSelector, createSelector } from '@ngrx/store';
import { Course } from '../../core/models';
import { coursesActions } from './courses.actions';

export interface CoursesState {
  courses: Course[];
  featured: Course[];
  selected: Course | null;
  loading: boolean;
  error: string | null;
}

const initialState: CoursesState = {
  courses: [],
  featured: [],
  selected: null,
  loading: false,
  error: null,
};

export const coursesReducer = createReducer(
  initialState,
  on(coursesActions.loadCourses, state => ({ ...state, loading: true })),
  on(coursesActions.loadCoursesSuccess, (state, { courses }) => ({ ...state, courses, loading: false })),
  on(coursesActions.loadCoursesFailure, (state, { error }) => ({ ...state, error, loading: false })),
  on(coursesActions.loadFeaturedSuccess, (state, { courses }) => ({ ...state, featured: courses })),
  on(coursesActions.courseSelected, (state, { course }) => ({ ...state, selected: course })),
  on(coursesActions.clearSelected, state => ({ ...state, selected: null })),
);

// Selectors
const selectCoursesState = createFeatureSelector<CoursesState>('courses');
export const selectAllCourses = createSelector(selectCoursesState, s => s.courses);
export const selectFeaturedCourses = createSelector(selectCoursesState, s => s.featured);
export const selectSelectedCourse = createSelector(selectCoursesState, s => s.selected);
export const selectCoursesLoading = createSelector(selectCoursesState, s => s.loading);
