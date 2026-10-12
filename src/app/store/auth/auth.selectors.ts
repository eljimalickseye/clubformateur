import { createFeatureSelector, createSelector } from '@ngrx/store';
import { AuthState } from './auth.reducer';

export const selectAuthState = createFeatureSelector<AuthState>('auth');
export const selectCurrentUser = createSelector(selectAuthState, s => s.user);
export const selectAuthLoading = createSelector(selectAuthState, s => s.loading);
export const selectAuthError = createSelector(selectAuthState, s => s.error);
export const selectIsAuthenticated = createSelector(selectAuthState, s => !!s.user);
export const selectIsInitialized = createSelector(selectAuthState, s => s.initialized);
export const selectUserRole = createSelector(selectCurrentUser, u => u?.role ?? null);
export const selectIsAdmin = createSelector(selectUserRole, r => r === 'admin');
export const selectIsTeacher = createSelector(selectUserRole, r => r === 'teacher' || r === 'admin');
export const selectIsStudent = createSelector(selectUserRole, r => r === 'student');
