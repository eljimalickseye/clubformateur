import { createReducer, on } from '@ngrx/store';
import { User } from '../../core/models';
import { authActions } from './auth.actions';

export interface AuthState {
  user: User | null;
  loading: boolean;
  error: string | null;
  initialized: boolean;
}

const initialState: AuthState = {
  user: null,
  loading: false,
  error: null,
  initialized: false,
};

export const authReducer = createReducer(
  initialState,
  on(authActions.initAuth, state => ({ ...state, loading: true })),
  on(authActions.setUser, (state, { user }) => ({ ...state, user, loading: false, initialized: true })),
  on(authActions.login, state => ({ ...state, loading: true, error: null })),
  on(authActions.loginSuccess, (state, { user }) => ({ ...state, user, loading: false, error: null })),
  on(authActions.loginFailure, (state, { error }) => ({ ...state, loading: false, error })),
  on(authActions.loginWithGoogle, state => ({ ...state, loading: true, error: null })),
  on(authActions.register, state => ({ ...state, loading: true, error: null })),
  on(authActions.registerSuccess, (state, { user }) => ({ ...state, user, loading: false, error: null })),
  on(authActions.registerFailure, (state, { error }) => ({ ...state, loading: false, error })),
  on(authActions.logout, state => ({ ...state, loading: true })),
  on(authActions.logoutSuccess, state => ({ ...state, user: null, loading: false })),
  on(authActions.updateProfileSuccess, (state, { data }) => ({
    ...state,
    user: state.user ? { ...state.user, ...data } : null,
  })),
);
