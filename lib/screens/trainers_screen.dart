import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trainer_model.dart';
import '../services/trainer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/footer_section.dart';
import '../widgets/navbar.dart';
import '../widgets/teacher_registration_flow_dialog.dart';

class TrainersScreen extends StatefulWidget {
  final Function(String route)? onNavigate;
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const TrainersScreen({
    super.key,
    this.onNavigate,
    this.onLoginTap,
    this.onRegisterTap,
  });

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  String _selectedDomain = 'Tous les domaines';
  String _selectedExperience = 'Tous niveaux';
  String _selectedLanguage = 'Toutes langues';
  bool _availableMentoring = false;
  bool _availableLive = false;
  String _sortBy = 'Popularité';
  int _currentPage = 1;
  List<TrainerModel> _trainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    final list = await TrainerService().getExpertTrainers();
    if (mounted) {
      setState(() {
        _trainers = list;
        _isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> _domains = [
    {'label': 'Tous les domaines', 'count': 240},
    {'label': 'Informatique & Tech', 'count': 65},
    {'label': 'Marketing & Digital', 'count': 42},
    {'label': 'Design & Multimédia', 'count': 38},
    {'label': 'Business & Entrepreneuriat', 'count': 45},
    {'label': 'Langues & Communication', 'count': 30},
    {'label': 'Développement personnel', 'count': 20},
  ];

  final List<String> _experiences = [
    'Tous niveaux',
    'Junior (1-3 ans)',
    'Confirmé (3-5 ans)',
    'Senior (+5 ans)',
  ];

  final List<String> _languages = [
    'Toutes langues',
    'Français',
    'Anglais',
    'Wolof',
  ];

  void _resetFilters() {
    setState(() {
      _selectedDomain = 'Tous les domaines';
      _selectedExperience = 'Tous niveaux';
      _selectedLanguage = 'Toutes langues';
      _availableMentoring = false;
      _availableLive = false;
      _sortBy = 'Popularité';
      _currentPage = 1;
    });
  }

  void _showTrainerModal(TrainerModel trainer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.paleMint,
                    backgroundImage: trainer.image.startsWith('http')
                        ? NetworkImage(trainer.image)
                        : (trainer.image.isNotEmpty && !trainer.image.contains('dummy')
                            ? AssetImage(trainer.image)
                            : null) as ImageProvider<Object>?,
                    child: (trainer.image.isEmpty || (!trainer.image.startsWith('http') && trainer.image.contains('dummy')))
                        ? Text(
                            trainer.name.isNotEmpty
                                ? trainer.name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
                                : 'P',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.emeraldGreenDark,
                            ),
                          )
                        : null,
                  ),
                  if (trainer.isVerified)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.emeraldGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                trainer.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trainer.role,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.amberStar, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${trainer.rating} (${trainer.reviewsCount} avis)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.school_rounded, color: AppTheme.textMuted, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${trainer.coursesCount} cours',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.groups_rounded, color: AppTheme.textMuted, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${(trainer.studentsCount / 1000).toStringAsFixed(1)}k étudiants',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (trainer.bio.isNotEmpty) ...[
                Text(
                  trainer.bio,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: trainer.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.chipMint,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.emeraldGreenDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        'Fermer',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message envoyé à ${trainer.name}'),
                            backgroundColor: AppTheme.emeraldGreenDark,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Contacter',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 980;
    final trainers = _trainers;

    return Scaffold(
      backgroundColor: AppTheme.ivoryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Bar
            Navbar(
              activeRoute: '/formateurs',
              onLoginTap: widget.onLoginTap,
              onRegisterTap: widget.onRegisterTap,
              onNavigate: widget.onNavigate,
            ),

            // Hero Section (Vert Sapin)
            _buildTrainersHero(isDesktop),

            // Main Body: Filters Sidebar + Trainers Grid
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar Filters (Desktop)
                      if (isDesktop) ...[
                        SizedBox(
                          width: 280,
                          child: _buildFiltersSidebar(),
                        ),
                        const SizedBox(width: 32),
                      ],

                      // Main Trainers Grid Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTrainersTopBar(trainers.length),
                            const SizedBox(height: 24),
                            _buildTrainersGrid(trainers),
                            const SizedBox(height: 40),
                            _buildPagination(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            FooterSection(
              onNavigate: widget.onNavigate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainersHero(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: isDesktop ? 48 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Row(
            children: [
              // Left Column
              Expanded(
                flex: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'NOS FORMATEURS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.mintAccent,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Des experts passionnés pour vous accompagner',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 36 : 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Apprenez auprès de professionnels reconnus, en direct ou à votre rythme, partout en Afrique et dans le monde.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFFD9ECE7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4 Hero Stats
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _buildHeroStat('200+', 'Formateurs vérifiés', Icons.verified_rounded),
                        _buildHeroStat('1 500+', 'Heures de formation', Icons.access_time_filled_rounded),
                        _buildHeroStat('12 000+', 'Étudiants formés', Icons.groups_rounded),
                        _buildHeroStat('4.8/5', 'Note moyenne', Icons.star_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Mosaic / Visual (Desktop only)
              if (isDesktop) ...[
                const SizedBox(width: 36),
                Expanded(
                  flex: 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/student-school.jpeg',
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay badges
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildFloatingTag(Icons.auto_awesome_rounded, 'Former avec impact'),
                      ),
                      Positioned(
                        bottom: 48,
                        right: 16,
                        child: _buildFloatingTag(Icons.lightbulb_rounded, 'Inspirer des talents'),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 24,
                        child: _buildFloatingTag(Icons.school_rounded, 'Transmettre une expertise'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.emeraldGreenDark, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String num, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.mintAccent, size: 16),
        const SizedBox(width: 6),
        Text(
          num,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFFD8EEE7),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSidebar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10233F).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Filtres',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: _resetFilters,
                child: Text(
                  'Réinitialiser',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.emeraldGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.cardBorder),

          // Domaine d'expertise
          _buildFilterSectionTitle('Domaine d\'expertise'),
          for (final domain in _domains)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: InkWell(
                onTap: () => setState(() => _selectedDomain = domain['label'] as String),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Radio<String>(
                      value: domain['label'] as String,
                      groupValue: _selectedDomain,
                      activeColor: AppTheme.emeraldGreen,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDomain = val);
                      },
                    ),
                    Expanded(
                      child: Text(
                        domain['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.ink,
                          fontWeight: _selectedDomain == domain['label'] ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${domain['count']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 24, color: AppTheme.cardBorder),

          // Niveau d'expérience
          _buildFilterSectionTitle('Niveau d\'expérience'),
          for (final exp in _experiences)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Radio<String>(
                    value: exp,
                    groupValue: _selectedExperience,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExperience = val);
                    },
                  ),
                  Expanded(
                    child: Text(
                      exp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.ink,
                        fontWeight: _selectedExperience == exp ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 24, color: AppTheme.cardBorder),

          // Langue
          _buildFilterSectionTitle('Langue'),
          for (final lang in _languages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Radio<String>(
                    value: lang,
                    groupValue: _selectedLanguage,
                    activeColor: AppTheme.emeraldGreen,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                  Expanded(
                    child: Text(
                      lang,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.ink,
                        fontWeight: _selectedLanguage == lang ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 24, color: AppTheme.cardBorder),

          // Disponibilité
          _buildFilterSectionTitle('Disponibilité'),
          CheckboxListTile(
            value: _availableMentoring,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'Mentorat individuel',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink),
            ),
            activeColor: AppTheme.emeraldGreen,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _availableMentoring = v ?? false),
          ),
          CheckboxListTile(
            value: _availableLive,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              'Formations en direct',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink),
            ),
            activeColor: AppTheme.emeraldGreen,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _availableLive = v ?? false),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filtres appliqués avec succès')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Appliquer les filtres',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
    );
  }

  Widget _buildTrainersTopBar(int count) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tous les formateurs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Trouvez l\'expert idéal selon vos besoins d\'apprentissage.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count formateurs trouvés',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.ink, fontWeight: FontWeight.w600),
                  items: ['Popularité', 'Mieux notés', 'Plus récents']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _sortBy = v);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrainersGrid(List<TrainerModel> trainers) {
    int crossAxisCount = 3;
    final width = MediaQuery.of(context).size.width;
    if (width < 640) {
      crossAxisCount = 1;
    } else if (width < 1000) {
      crossAxisCount = 2;
    } else if (width > 1400) {
      crossAxisCount = 4;
    }

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
        ),
      );
    }

    if (trainers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'Aucun professeur trouvé',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink),
              ),
              const SizedBox(height: 4),
              const Text(
                'Les professeurs inscrits s\'afficheront ici dès leur enregistrement.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    double childAspectRatio = 0.50;
    if (width < 640) {
      crossAxisCount = 1;
      childAspectRatio = 0.68;
    } else if (width < 1000) {
      crossAxisCount = 2;
      childAspectRatio = 0.52;
    } else if (width > 1400) {
      crossAxisCount = 4;
      childAspectRatio = 0.48;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 0.49;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trainers.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final trainer = trainers[index];
        return _buildTrainerCard(trainer);
      },
    );
  }

  Widget _buildTrainerCard(TrainerModel trainer) {
    final currency = NumberFormat('#,###', 'fr_FR');
    final formattedFee = '${currency.format(trainer.registrationFee)} FCFA';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10233F).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Avatar + Name + Subject badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.emeraldGreenDark,
                    backgroundImage: trainer.image.startsWith('http')
                        ? NetworkImage(trainer.image)
                        : (trainer.image.isNotEmpty && !trainer.image.contains('dummy')
                            ? AssetImage(trainer.image)
                            : null) as ImageProvider<Object>?,
                    child: (trainer.image.isEmpty || (!trainer.image.startsWith('http') && trainer.image.contains('dummy')))
                        ? Text(
                            trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : 'P',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
                          )
                        : null,
                  ),
                  if (trainer.isVerified)
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: AppTheme.emeraldGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.chipMint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trainer.subject,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.emeraldGreenDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Levels taught badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Niveau enseigné :',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (trainer.levels.isNotEmpty ? trainer.levels : ['Licence 3']).map((lvl) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        lvl,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Availability
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trainer.availability,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Schedule (Emploi du temps)
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trainer.schedule,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Montant de l'inscription
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Frais d\'inscription',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                formattedFee,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.emeraldGreenDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Primary Button: « S'inscrire auprès de ce professeur »
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () {
                TeacherRegistrationFlowDialog.show(context, teacher: trainer);
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
              label: Text(
                'S\'inscrire auprès de ce professeur',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldGreenDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Secondary Button: « Voir le profil »
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/trainer-profile', arguments: trainer),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.ink,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Voir le profil complet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageItem('<', false, () {}),
        for (int p in [1, 2, 3, 4])
          _buildPageItem('$p', _currentPage == p, () => setState(() => _currentPage = p)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('...', style: TextStyle(color: AppTheme.textMuted)),
        ),
        _buildPageItem('8', false, () {}),
        _buildPageItem('>', false, () {}),
      ],
    );
  }

  Widget _buildPageItem(String text, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.emeraldGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppTheme.emeraldGreen : AppTheme.cardBorder),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
