import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_model.dart';
import '../models/study_group_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/firebase_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_message_widgets.dart';
import 'group_live_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final StudyGroupModel group;
  final UserModel? currentUser;

  const GroupChatScreen({
    super.key,
    required this.group,
    this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  UserModel get _user => widget.currentUser ?? AuthService().currentUser ?? UserModel.demoStudent;
  final ChatService _chatService = ChatService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploadingDoc = false;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? fileUrl, String? fileName, MessageType type = MessageType.text}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && fileUrl == null) return;

    _msgController.clear();
    await _chatService.sendMessage(
      conversationId: widget.group.id,
      senderId: _user.uid,
      senderName: _user.displayName,
      senderPhotoUrl: _user.photoUrl ?? '',
      senderRole: 'student',
      content: text.isNotEmpty ? text : (fileName != null ? 'Fichier partagé : $fileName' : ''),
      type: type,
      fileUrl: fileUrl,
      fileName: fileName,
    );

    _scrollToBottom();
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingDoc = true);

      final extension = file.extension?.toLowerCase() ?? 'bin';
      MessageType msgType = MessageType.file;
      String contentType = 'application/octet-stream';
      if (['png', 'jpg', 'jpeg'].contains(extension)) {
        msgType = MessageType.image;
        contentType = 'image/$extension';
      } else if (extension == 'pdf') {
        contentType = 'application/pdf';
      }

      final uploadedUrl = await _storageService.uploadChatMedia(
        conversationId: widget.group.id,
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );

      setState(() => _isUploadingDoc = false);

      if (uploadedUrl != null) {
        await _sendMessage(
          fileUrl: uploadedUrl,
          fileName: file.name,
          type: msgType,
        );
      }
    } catch (e) {
      setState(() => _isUploadingDoc = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'envoi du fichier: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          tooltip: 'Retour',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.emeraldGreen.withValues(alpha: 0.15),
              child: const Icon(Icons.groups_rounded, color: AppTheme.emeraldGreenDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.group.courseTitle} • ${widget.group.members.length} membres',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Launch Group Audio Live Button
          ElevatedButton.icon(
            icon: const Icon(Icons.mic_rounded, size: 16),
            label: Text(isDesktop ? 'Lancer le Live Audio' : 'Live Audio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupLiveScreen(
                    group: widget.group,
                    currentUser: _user,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Banner for group live action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFE6F4EA),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.emeraldGreenDark, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Salon de travail plein écran : échangez par messages, partagez vos devoirs / fichiers Word & PDF, ou lancez un live audio entre membres.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldGreenDark),
                  ),
                ),
              ],
            ),
          ),

          // Messages stream
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getGroupMessagesStream(widget.group.id),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun message pour le moment dans ce groupe.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Envoyez un message ou partagez un document pour démarrer l\'entraide !',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _user.uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          if (_isUploadingDoc)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.amber.shade50,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Téléversement du document en cours...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: VoiceRecordingBar(
              conversationId: widget.group.id,
              onAudioSent: (audioUrl, duration) async {
                final user = widget.currentUser ?? AuthService().currentUser;
                final myUid = user?.uid ?? 'guest';
                final myName = user?.displayName.isNotEmpty == true ? user!.displayName : 'Apprenant';
                final myRole = user?.role ?? 'student';
                await _chatService.sendGroupMessage(
                  groupId: widget.group.id,
                  senderId: myUid,
                  senderName: myName,
                  senderRole: myRole,
                  content: 'Note vocale (${duration}s)',
                  type: MessageType.audio,
                  fileUrl: audioUrl,
                  audioDuration: duration,
                );
              },
              child: Row(
                children: [
                  // Attach Document Button (PDF, Word, Images)
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppTheme.emeraldGreenDark),
                    tooltip: 'Partager un document (Word, PDF, Image)',
                    onPressed: _isUploadingDoc ? null : _pickAndUploadDocument,
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: 'Écrivez votre message d\'entraide...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  CircleAvatar(
                    backgroundColor: AppTheme.emeraldGreenDark,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    if (msg.isAudio) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.paleMint,
                child: Text(
                  msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.emeraldGreenDark),
                ),
              ),
              const SizedBox(width: 8),
            ],
            AudioMessageBubble(
              audioUrl: msg.fileUrl ?? '',
              durationSeconds: msg.audioDuration ?? 10,
              isMe: isMe,
            ),
          ],
        ),
      );
    }

    final hasMedia = msg.fileUrl != null && msg.fileUrl!.isNotEmpty;
    final isImage = msg.isImage || (hasMedia && (msg.fileName?.endsWith('.png') == true || msg.fileName?.endsWith('.jpg') == true || msg.fileName?.endsWith('.jpeg') == true));
    final isDoc = hasMedia && !isImage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.paleMint,
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : 'U',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.emeraldGreenDark),
              ),
            ),
            const SizedBox(width: 8),
          ],

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.emeraldGreenDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isMe ? Colors.transparent : AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg.senderName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppTheme.emeraldGreenDark,
                      ),
                    ),

                  // Document / File preview card
                  if (hasMedia) ...[
                    const SizedBox(height: 6),
                    if (isImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          msg.fileUrl!,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 48),
                        ),
                      )
                    else if (isDoc)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: isMe ? Colors.white : AppTheme.emeraldGreenDark,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.fileName ?? 'Document joint',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: isMe ? Colors.white : AppTheme.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  InkWell(
                                    onTap: () async {
                                      final uri = Uri.tryParse(msg.fileUrl!);
                                      if (uri != null && await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                    child: Text(
                                      'Télécharger / Ouvrir',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isMe ? Colors.white70 : AppTheme.emeraldGreenDark,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  if (msg.content.isNotEmpty && !msg.content.startsWith('Fichier partagé :')) ...[
                    const SizedBox(height: 6),
                    Text(
                      msg.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: isMe ? Colors.white : AppTheme.ink,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
