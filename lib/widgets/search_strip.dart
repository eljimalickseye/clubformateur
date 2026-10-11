import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SearchStrip extends StatefulWidget {
  final Function(String query, String category)? onSearch;
  final Function(String category)? onTagSelected;

  const SearchStrip({
    super.key,
    this.onSearch,
    this.onTagSelected,
  });

  @override
  State<SearchStrip> createState() => _SearchStripState();
}

class _SearchStripState extends State<SearchStrip> {
  final TextEditingController _queryController = TextEditingController();
  String _selectedCategory = 'Toutes les catégories';

  final List<String> _categories = [
    'Toutes les catégories',
    'Informatique',
    'Marketing',
    'Business',
    'Design',
    'Développement personnel',
  ];

  final List<String> _popularTags = [
    'Informatique',
    'Marketing',
    'Design',
    'Business',
    'Développement personnel',
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    widget.onSearch?.call(_queryController.text, _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 860;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Search Floating Pill Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isDesktop ? 999 : 24),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10233F).withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 14,
                  vertical: isDesktop ? 8 : 12,
                ),
                child: isDesktop
                    ? Row(
                        children: [
                          // Search Input with green icon
                          Expanded(
                            flex: 5,
                            child: _buildSearchField(),
                          ),
                          const SizedBox(width: 12),
                          // Divider
                          Container(
                            height: 32,
                            width: 1,
                            color: AppTheme.cardBorder,
                          ),
                          const SizedBox(width: 12),
                          // Category Dropdown
                          Expanded(
                            flex: 3,
                            child: _buildCategoryDropdown(),
                          ),
                          const SizedBox(width: 12),
                          // Search Button (Green Pill)
                          _buildSearchButton(),
                        ],
                      )
                    : Column(
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 10),
                          _buildCategoryDropdown(),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _buildSearchButton(),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 14),

              // Popular tags row
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Formations populaires :',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  for (final tag in _popularTags)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = tag;
                        });
                        widget.onTagSelected?.call(tag);
                      },
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedCategory == tag ? AppTheme.paleMint : Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: _selectedCategory == tag ? AppTheme.emeraldGreen : AppTheme.cardBorder,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _selectedCategory == tag ? AppTheme.emeraldGreenDark : AppTheme.ink,
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
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryController,
      onSubmitted: (_) => _triggerSearch(),
      decoration: InputDecoration(
        hintText: 'Que souhaitez-vous apprendre ?',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.emeraldGreen,
          size: 20,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppTheme.ink,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 20),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.ink,
          fontWeight: FontWeight.w500,
        ),
        items: _categories.map((cat) {
          return DropdownMenuItem<String>(
            value: cat,
            child: Text(
              cat,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedCategory = val;
            });
          }
        },
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _triggerSearch,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.emeraldGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        elevation: 0,
      ),
      child: Text(
        'Rechercher',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
