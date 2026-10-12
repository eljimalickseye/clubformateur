import { createReducer, on, createFeatureSelector, createSelector, createActionGroup, props, emptyProps } from '@ngrx/store';
import { Notification } from '../../core/models';

export const notificationsActions = createActionGroup({
  source: 'Notifications',
  events: {
    'Load': emptyProps(),
    'Load Success': props<{ notifications: Notification[] }>(),
    'Mark Read': props<{ id: string }>(),
    'Mark All Read': emptyProps(),
    'New Notification': props<{ notification: Notification }>(),
  },
});

export interface NotificationsState {
  items: Notification[];
  unreadCount: number;
}

const initialState: NotificationsState = { items: [], unreadCount: 0 };

export const notificationsReducer = createReducer(
  initialState,
  on(notificationsActions.loadSuccess, (state, { notifications }) => ({
    ...state,
    items: notifications,
    unreadCount: notifications.filter(n => !n.isRead).length,
  })),
  on(notificationsActions.markRead, (state, { id }) => ({
    ...state,
    items: state.items.map(n => n.id === id ? { ...n, isRead: true } : n),
    unreadCount: Math.max(0, state.unreadCount - 1),
  })),
  on(notificationsActions.markAllRead, state => ({
    ...state,
    items: state.items.map(n => ({ ...n, isRead: true })),
    unreadCount: 0,
  })),
  on(notificationsActions.newNotification, (state, { notification }) => ({
    ...state,
    items: [notification, ...state.items],
    unreadCount: state.unreadCount + 1,
  })),
);

const selectNotifState = createFeatureSelector<NotificationsState>('notifications');
export const selectNotifications = createSelector(selectNotifState, s => s.items);
export const selectUnreadCount = createSelector(selectNotifState, s => s.unreadCount);
