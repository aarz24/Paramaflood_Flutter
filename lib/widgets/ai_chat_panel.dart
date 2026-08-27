import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

/// 💬 ParaBot — panel chat AI (Fitur 3).
/// Ditampilkan sebagai modal bottom sheet dari dashboard.
class AiChatPanel extends StatefulWidget {
  const AiChatPanel({super.key});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const _suggestions = [
    'Apakah aman beraktivitas di luar?',
    'Bagaimana kondisi air saat ini?',
    'Ada risiko banjir hari ini?',
    'Kenapa suhu sensor beda sama internet?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    context.read<AppState>().sendChatMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Auto-scroll saat ada pesan baru dari bot
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Padding(
      // Naikkan sheet saat keyboard muncul
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.bgAlt,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.cardSolid,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.heroAcc.withValues(alpha: 0.35),
                          AppTheme.internet.withValues(alpha: 0.25),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome_rounded, color: AppTheme.heroAcc, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ParaBot AI Assistant',
                          style: GoogleFonts.outfit(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Tanyakan kondisi cuaca & sensor real-time',
                          style: GoogleFonts.outfit(
                            color: AppTheme.subtext,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.subtext),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Message list ───────────────────────────────────────
            Expanded(
              child: state.chatMessages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.chatMessages.length +
                          (state.isChatLoading ? 1 : 0),
                      itemBuilder: (ctx, idx) {
                        // Bubble "mengetik..." saat menunggu jawaban bot
                        if (idx == state.chatMessages.length) {
                          return _typingBubble();
                        }
                        final msg = state.chatMessages[idx];
                        final isUser = msg['sender'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppTheme.heroAcc
                                  : AppTheme.cardSolid,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 4),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                            ),
                            child: SelectableText(
                              msg['message'] ?? '',
                              style: GoogleFonts.outfit(
                                color:
                                    isUser ? Colors.white : AppTheme.text,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: isUser
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Input box ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.cardSolid,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: GoogleFonts.outfit(
                          color: AppTheme.text,
                          fontSize: 13,
                        ),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText:
                              'Tanyakan sesuatu (misal: "Aman keluar?")...',
                          hintStyle: GoogleFonts.outfit(
                            color: AppTheme.subtext.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: AppTheme.bgAlt,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: state.isChatLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.heroAcc,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: AppTheme.heroAcc),
                      onPressed:
                          state.isChatLoading ? null : () => _sendMessage(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text(
            'Halo! Aku ParaBot.',
            style: GoogleFonts.outfit(
              color: AppTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tanyakan apa saja soal cuaca & kondisi banjir\nberdasarkan data sensor real-time kamu.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.subtext,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions
                .map(
                  (s) => GestureDetector(
                    onTap: () => _sendMessage(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.heroAcc.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.heroAcc.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.outfit(
                          color: AppTheme.heroAcc,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardSolid,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.heroAcc,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ParaBot sedang mengetik...',
              style: GoogleFonts.outfit(
                color: AppTheme.subtext,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
