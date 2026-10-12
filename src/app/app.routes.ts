import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';
import { courseAccessGuard } from './core/guards/course-access.guard';
import { redirectIfAuthGuard } from './core/guards/redirect-if-auth.guard';

export const routes: Routes = [
  // Public
  {
    path: '',
    loadComponent: () => import('./features/home/home.component').then(m => m.HomeComponent),
  },
  {
    path: 'catalogue',
    loadComponent: () => import('./features/catalogue/catalogue.component').then(m => m.CatalogueComponent),
  },
  {
    path: 'formateurs',
    loadComponent: () => import('./features/teachers-directory/teachers-directory.component').then(m => m.TeachersDirectoryComponent),
  },
  {
    path: 'course/:id',
    loadComponent: () => import('./features/course-detail/course-detail.component').then(m => m.CourseDetailComponent),
  },
  {
    path: 'cours/:id',
    redirectTo: 'course/:id',
    pathMatch: 'full',
  },
  {
    path: 'certificate/verify/:code',
    loadComponent: () => import('./features/certificate-verify/certificate-verify.component').then(m => m.CertificateVerifyComponent),
  },
  {
    path: 'formateur/:id',
    loadComponent: () => import('./features/formateur-profile/formateur-profile.component').then(m => m.FormateurProfileComponent),
  },

  // Auth (redirect if already logged in)
  {
    path: 'auth',
    canActivate: [redirectIfAuthGuard],
    children: [
      {
        path: 'login',
        loadComponent: () => import('./features/auth/login/login.component').then(m => m.LoginComponent),
      },
      {
        path: 'register',
        loadComponent: () => import('./features/auth/register/register.component').then(m => m.RegisterComponent),
      },
      {
        path: 'forgot-password',
        loadComponent: () => import('./features/auth/forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent),
      },
      { path: '', redirectTo: 'login', pathMatch: 'full' },
    ],
  },

  // Learn (player)
  {
    path: 'learn/:courseId/:lessonId',
    canActivate: [authGuard, courseAccessGuard],
    loadComponent: () => import('./features/player/player.component').then(m => m.PlayerComponent),
  },

  // Student
  {
    path: 'student',
    canActivate: [authGuard, roleGuard],
    data: { role: 'student' },
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('./features/student/dashboard/dashboard.component').then(m => m.StudentDashboardComponent),
      },
      {
        path: 'my-courses',
        loadComponent: () => import('./features/student/my-courses/my-courses.component').then(m => m.MyCoursesComponent),
      },
      {
        path: 'progress',
        loadComponent: () => import('./features/student/progress/progress.component').then(m => m.ProgressComponent),
      },
      {
        path: 'chat',
        loadComponent: () => import('./features/student/chat/chat.component').then(m => m.ChatComponent),
      },
      {
        path: 'certificates',
        loadComponent: () => import('./features/student/certificates/certificates.component').then(m => m.CertificatesComponent),
      },
      {
        path: 'assignments',
        loadComponent: () => import('./features/student/assignments/assignments.component').then(m => m.StudentAssignmentsComponent),
      },
      {
        path: 'study-groups',
        loadComponent: () => import('./features/student/study-groups/study-groups.component').then(m => m.StudentStudyGroupsComponent),
      },
      {
        path: 'lives',
        loadComponent: () => import('./features/student/lives/student-lives.component').then(m => m.StudentLivesComponent),
      },
      {
        path: 'live/:id',
        loadComponent: () => import('./features/student/live-room/live-room.component').then(m => m.StudentLiveRoomComponent),
      },
      {
        path: 'purchases',
        loadComponent: () => import('./features/student/purchases/purchases.component').then(m => m.PurchasesComponent),
      },
      {
        path: 'settings',
        loadComponent: () => import('./features/student/settings/settings.component').then(m => m.StudentSettingsComponent),
      },
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
    ],
  },

  // Direct Live access (e.g. from notification)
  {
    path: 'live/:id',
    canActivate: [authGuard],
    data: { preload: false },
    loadComponent: () => import('./features/student/live-room/live-room.component').then(m => m.StudentLiveRoomComponent),
  },

  // Teacher Workspace
  {
    path: 'teacher',
    canActivate: [authGuard, roleGuard],
    data: { role: 'teacher' },
    loadComponent: () => import('./features/teacher/teacher-layout/teacher-layout.component').then(m => m.TeacherLayoutComponent),
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('./features/teacher/dashboard/dashboard.component').then(m => m.TeacherDashboardComponent),
      },
      {
        path: 'courses',
        loadComponent: () => import('./features/teacher/my-courses/my-courses.component').then(m => m.TeacherMyCoursesComponent),
      },
      {
        path: 'assignments',
        loadComponent: () => import('./features/teacher/assignments/assignments.component').then(m => m.TeacherAssignmentsComponent),
      },
      {
        path: 'requests',
        loadComponent: () => import('./features/teacher/requests/requests.component').then(m => m.TeacherRequestsComponent),
      },
      {
        path: 'students',
        loadComponent: () => import('./features/teacher/students/students.component').then(m => m.TeacherStudentsComponent),
      },
      {
        path: 'earnings',
        loadComponent: () => import('./features/teacher/earnings/earnings.component').then(m => m.TeacherEarningsComponent),
      },
      {
        path: 'notifications',
        loadComponent: () => import('./features/teacher/notifications/notifications.component').then(m => m.TeacherNotificationsComponent),
      },
      {
        path: 'profile',
        loadComponent: () => import('./features/teacher/profile/teacher-profile-edit.component').then(m => m.TeacherProfileEditComponent),
      },
      {
        path: 'course/new',
        loadComponent: () => import('./features/teacher/course-creator/course-creator.component').then(m => m.CourseCreatorComponent),
      },
      {
        path: 'course/edit/:id',
        loadComponent: () => import('./features/teacher/course-creator/course-creator.component').then(m => m.CourseCreatorComponent),
      },
      {
        path: 'chat',
        loadComponent: () => import('./features/teacher/chat/chat.component').then(m => m.ChatComponent),
      },
      {
        path: 'live',
        loadComponent: () => import('./features/teacher/live-manager/live-manager.component').then(m => m.LiveManagerComponent),
      },
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
    ],
  },

  // Centralized Admin Workspace
  {
    path: 'admin',
    canActivate: [authGuard, roleGuard],
    data: { role: 'admin' },
    loadComponent: () => import('./features/admin/admin-layout/admin-layout.component').then(m => m.AdminLayoutComponent),
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('./features/admin/dashboard/dashboard.component').then(m => m.AdminDashboardComponent),
      },
      {
        path: 'users',
        loadComponent: () => import('./features/admin/users/users.component').then(m => m.AdminUsersComponent),
      },
      {
        path: 'courses',
        loadComponent: () => import('./features/admin/courses-validation/courses-validation.component').then(m => m.AdminCoursesValidationComponent),
      },
      {
        path: 'payments',
        loadComponent: () => import('./features/admin/payments/payments.component').then(m => m.AdminPaymentsComponent),
      },
      {
        path: 'analytics',
        loadComponent: () => import('./features/admin/analytics/analytics.component').then(m => m.AdminAnalyticsComponent),
      },
      {
        path: 'settings',
        loadComponent: () => import('./features/admin/settings/settings.component').then(m => m.AdminSettingsComponent),
      },
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
    ],
  },

  // 404
  {
    path: '**',
    loadComponent: () => import('./features/not-found/not-found.component').then(m => m.NotFoundComponent),
  },
];

/**
 * Marque chaque page d'un espace protégé (student / teacher / admin) avec le rôle requis,
 * afin que SmartPreloadingStrategy ne précharge que l'espace de l'utilisateur connecté.
 */
for (const route of routes) {
  const role = route.data?.['role'];
  if (!role) continue;
  route.data = { ...route.data, preloadRole: role };
  route.children?.forEach(child => {
    child.data = { ...child.data, preloadRole: role };
  });
}
