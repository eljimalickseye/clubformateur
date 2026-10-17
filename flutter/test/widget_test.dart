import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivia/models/course_model.dart';
import 'package:olivia/screens/catalog_screen.dart';
import 'package:olivia/screens/course_detail_screen.dart';
import 'package:olivia/screens/landing_screen.dart';
import 'package:olivia/screens/trainers_screen.dart';
import 'package:olivia/screens/trainer_profile_screen.dart';
import 'package:olivia/screens/dashboards/student_dashboard_screen.dart';
import 'package:olivia/screens/dashboards/teacher_dashboard_screen.dart';
import 'package:olivia/theme/app_theme.dart';
import 'package:olivia/widgets/navbar.dart';
import 'package:olivia/widgets/search_strip.dart';
import 'package:olivia/widgets/stats_band.dart';

void main() {
  testWidgets('Navbar displays Club des Formateurs branding and links', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          appBar: Navbar(),
        ),
      ),
    );

    expect(find.text('Club des'), findsOneWidget);
    expect(find.text('Formateurs'), findsWidgets);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Formations'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);
  });

  testWidgets('SearchStrip displays input, category selector and popular chips', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SearchStrip(),
        ),
      ),
    );

    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('Que souhaitez-vous apprendre ?'), findsOneWidget);
    expect(find.text('Formations populaires :'), findsOneWidget);
  });

  testWidgets('StatsBand displays key growth metrics', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: StatsBand(),
        ),
      ),
    );

    expect(find.text('10K+'), findsOneWidget);
    expect(find.text('200+'), findsOneWidget);
    expect(find.text('50+'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('Apprenants actifs'), findsOneWidget);
  });

  testWidgets('CatalogScreen renders hero, filters and course cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: CatalogScreen(),
        ),
      ),
    );

    expect(find.text('CATALOGUE DES FORMATIONS'), findsOneWidget);
    expect(find.text('Toutes les formations'), findsOneWidget);
    expect(find.text('Filtres'), findsOneWidget);
  });

  testWidgets('TrainersScreen renders hero, stats and trainer cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: TrainersScreen(),
        ),
      ),
    );

    expect(find.text('NOS FORMATEURS'), findsOneWidget);
    expect(find.text('Des experts passionnés pour vous accompagner'), findsOneWidget);
    expect(find.text('Mamadou Fall'), findsOneWidget);
  });

  testWidgets('CourseDetailScreen renders course details and curriculum', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final course = CourseModel.showcaseCourses.first;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CourseDetailScreen(course: course),
        ),
      ),
    );

    expect(find.text(course.title), findsWidgets);
    expect(find.text('Vous allez apprendre'), findsOneWidget);
    expect(find.text('Formateur'), findsWidgets);
  });

  testWidgets('LandingScreen renders without errors on mobile Pixel 7 (412x915)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LandingScreen(),
      ),
    );

    final err = tester.takeException();
    debugPrint('*** LANDING SCREEN EXCEPTION: $err ***');
    expect(err, isNull);
    expect(find.text('Club des'), findsWidgets);
  });

  testWidgets('TrainerProfileScreen renders trainer info, stats, and tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        routes: {
          '/dashboard/apprenant': (context) => const Scaffold(body: Text('Student Dashboard')),
        },
        home: const TrainerProfileScreen(),
      ),
    );

    expect(find.text('Mamadou Fall'), findsWidgets);
    expect(find.text('À propos'), findsWidgets);
    expect(find.textContaining('Formations'), findsWidgets);
    expect(find.textContaining('Avis'), findsWidgets);
    expect(find.text('Prendre un rendez-vous'), findsWidgets);
  });

  testWidgets('StudentDashboardScreen renders courses, stats and direct planning', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const StudentDashboardScreen(),
      ),
    );

    expect(find.text('Tableau de bord'), findsWidgets);
    expect(find.text('Cours en direct'), findsWidgets);
    expect(find.text('Mes objectifs'), findsWidgets);
  });

  testWidgets('TeacherDashboardScreen renders courses management, stats and creation modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const TeacherDashboardScreen(),
      ),
    );

    expect(find.text('ESPACE FORMATEUR'), findsWidgets);
    expect(find.text('+ Créer une formation'), findsOneWidget);
    expect(find.text('Mes formations'), findsWidgets);
  });
}

