import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/study_group_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class GroupLiveScreen extends StatefulWidget {
  final StudyGroupModel group;
  final UserModel currentUser;

  const GroupLiveScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupLiveScreen> createState() => _GroupLiveScreenState();
}

class _GroupLiveScreenState extends State<GroupLiveScreen> with SingleTickerProviderStateMixin {
  bool _isMicOn = true;
  bool _isHandRaised = false;
  bool _showWhiteboard = false;
  bool _showChat = false;

  late Timer _durationTimer;
  int _secondsElapsed = 0;

  late AnimationController _pulseController;

  final TextEditingController _sharedNotesController = TextEditingController(
    text: '📝 Notes partagées de la session de travail en groupe :\n\n- Sujet du jour : Résolution des exercices et entraide\n- Objectif : Préparation du devoir et validation des concepts clés\n',
  );

  final List<Map<String, String>> _inLiveMessages = [
    {
      'sender': 'Modérateur',
      'text': 'Bienvenue dans la salle audio de groupe ! Vous pouvez échanger librement.',
      'time': '10:00',
    }
  ];
  final TextEditingController _liveChatInput = TextEditingController();

  late List<Map<String, dynamic>> _participants;

  @override
  void initState() {
    super.initState();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Initialize participants from group members
    _participants = [
      {
        'id': widget.currentUser.uid,
        'name': '${widget.currentUser.displayName} (Vous)',
        'avatar': widget.currentUser.photoUrl ?? '',
        'isSpeaking': false,
        'isMuted': false,
        'isHost': widget.group.isCreator(widget.currentUser.uid),
      },
    ];

    for (final memberId in widget.group.members) {
      if (memberId != widget.currentUser.uid) {
        final name = widget.group.memberNames[memberId] ?? 'Apprenant';
        final photo = widget.group.memberPhotos[memberId] ?? '';
        _participants.add({
          'id': memberId,
          'name': name,
          'avatar': photo,
          'isSpeaking': _participants.length == 1, // simulate active speaker
          'isMuted': false,
          'isHost': widget.group.isCreator(memberId),
        });
      }
    }
  }

  @override
  void dispose() {
    _durationTimer.cancel();
    _pulseController.dispose();
    _sharedNotesController.dispose();
    _liveChatInput.dispose();
    super.dispose();
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF071F22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2B30),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Quitter le live',
          onPressed: () => _confirmExit(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE AUDIO DE GROUPE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Durée : ${_formatDuration(_secondsElapsed)} • ${_participants.length} en direct',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_off_rounded, color: AppTheme.mintAccent, size: 15),
                const SizedBox(width: 6),
                Text(
                  isDesktop ? 'Visages masqués (Confidentialité)' : 'Sans visage',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.call_end_rounded, size: 16),
            label: Text(isDesktop ? 'Quitter' : ''),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _confirmExit(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Main Collaboration Stage
          Expanded(
            child: Column(
              children: [
                // Privacy banner reminder
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: const Color(0xFF0F3E44),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, color: AppTheme.mintAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Session vocale collaborative : les caméras sont désactivées pour protéger votre vie privée.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFD6F5EC)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Center area: either Whiteboard or Audio Avatars Stage
                Expanded(
                  child: _showWhiteboard ? _buildWhiteboardView() : _buildAudioStage(),
                ),

                // Control Bar
                _buildBottomControlBar(isDesktop),
              ],
            ),
          ),

          // In-Live Text Chat Drawer (Optional)
          if (_showChat)
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: Color(0xFF082226),
                border: Border(left: BorderSide(color: Color(0xFF13434A))),
              ),
              child: _buildInLiveChatPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioStage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: _participants.map((p) => _buildParticipantAvatarCard(p)).toList(),
        ),
      ),
    );
  }

  Widget _buildParticipantAvatarCard(Map<String, dynamic> p) {
    final isMe = p['id'] == widget.currentUser.uid;
    final isSpeaking = isMe ? (_isMicOn && !_isHandRaised) : (p['isSpeaking'] as bool? ?? false);
    final isMuted = isMe ? !_isMicOn : (p['isMuted'] as bool? ?? false);
    final name = p['name'] as String;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 170,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0C333A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSpeaking
                  ? AppTheme.mintAccent.withValues(alpha: 0.5 + (_pulseController.value * 0.5))
                  : const Color(0xFF164B53),
              width: isSpeaking ? 2.5 : 1.2,
            ),
            boxShadow: isSpeaking
                ? [
                    BoxShadow(
                      color: AppTheme.mintAccent.withValues(alpha: 0.25 * _pulseController.value),
                      blurRadius: 18,
                      spreadRadius: 4,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isSpeaking)
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.mintAccent.withValues(alpha: 0.15 * _pulseController.value),
                      ),
                    ),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF134C56),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'A',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: isMuted ? Colors.red.shade700 : AppTheme.emeraldGreen,
                      child: Icon(
                        isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (p['isHost'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Animateur', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w700)),
                )
              else if (isSpeaking)
                Text(
                  'En train de parler...',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.mintAccent, fontWeight: FontWeight.w600),
                )
              else
                const Text('En écoute', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhiteboardView() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C333A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF17515A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppTheme.mintAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Tableau blanc & Notes collaboratives du groupe',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Sauvegarder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes partagées enregistrées !'), backgroundColor: AppTheme.emeraldGreen),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _sharedNotesController,
              maxLines: null,
              expands: true,
              style: GoogleFonts.robotoMono(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF072125),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: 'Tapez vos notes ou formules ici...',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInLiveChatPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          color: const Color(0xFF0A2E33),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Chat du live',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                onPressed: () => setState(() => _showChat = false),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _inLiveMessages.length,
            itemBuilder: (context, index) {
              final m = _inLiveMessages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D373D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m['sender']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.mintAccent)),
                        Text(m['time']!, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(m['text']!, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF09282D),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _liveChatInput,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Message rapide...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0E3A40),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendInLiveMessage(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.mintAccent, size: 18),
                onPressed: _sendInLiveMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendInLiveMessage() {
    final text = _liveChatInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _inLiveMessages.add({
        'sender': widget.currentUser.displayName,
        'text': text,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _liveChatInput.clear();
    });
  }

  Widget _buildBottomControlBar(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0A2B30),
        border: Border(top: BorderSide(color: Color(0xFF13434A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic Toggle
          _buildControlButton(
            icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: _isMicOn ? 'Micro activé' : 'Micro coupé',
            isActive: _isMicOn,
            activeColor: AppTheme.emeraldGreen,
            inactiveColor: Colors.red.shade700,
            onTap: () => setState(() => _isMicOn = !_isMicOn),
          ),
          const SizedBox(width: 14),

          // Raise Hand Toggle
          _buildControlButton(
            icon: Icons.front_hand_rounded,
            label: _isHandRaised ? 'Main levée' : 'Lever la main',
            isActive: _isHandRaised,
            activeColor: Colors.amber,
            inactiveColor: const Color(0xFF134C55),
            onTap: () {
              setState(() => _isHandRaised = !_isHandRaised);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isHandRaised ? 'Vous avez levé la main ✋' : 'Main baissée'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 14),

          // Shared Whiteboard / Notes Toggle
          _buildControlButton(
            icon: Icons.edit_note_rounded,
            label: 'Tableau blanc',
            isActive: _showWhiteboard,
            activeColor: AppTheme.mintAccent,
            inactiveColor: const Color(0xFF134C55),
            onTap: () => setState(() => _showWhiteboard = !_showWhiteboard),
          ),
          const SizedBox(width: 14),

          // In-Live Chat Toggle
          _buildControlButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            isActive: _showChat,
            activeColor: AppTheme.mintAccent,
            inactiveColor: const Color(0xFF134C55),
            onTap: () => setState(() => _showChat = !_showChat),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Quitter le live audio ?'),
        content: const Text('Êtes-vous sûr de vouloir quitter cette session de travail en direct ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Rester')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
