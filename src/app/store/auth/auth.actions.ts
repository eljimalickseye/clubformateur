// ─── auth.actions.ts ──────────────────────────────────────────
import { createActionGroup, emptyProps, props } from '@ngrx/store';
import { User, UserRole } from '../../core/models';

export const authActions = createActionGroup({
  source: 'Auth',
  events: {
    'Init Auth': emptyProps(),
    'Set User': props<{ user: User | null }>(),
    'Login': props<{ email: string; password: string }>(),
    'Login Success': props<{ user: User }>(),
    'Login Failure': props<{ error: string }>(),
    'Login With Google': props<{ role?: UserRole }>(),
    'Register': props<{ email: string; password: string; displayName: string; role: string; phone?: string }>(),
    'Register Success': props<{ user: User }>(),
    'Register Failure': props<{ error: string }>(),
    'Logout': emptyProps(),
    'Logout Success': emptyProps(),
    'Update Profile': props<{ data: Partial<User> }>(),
    'Update Profile Success': props<{ data: Partial<User> }>(),
  },
});
