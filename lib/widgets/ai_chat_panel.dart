import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
              decoration: const BoxDecoration(
                color: AppTheme.cardSolid,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.heroAcc, AppTheme.internet],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.heroAcc.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 20),
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
                        final bubble = Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? null : AppTheme.cardSolid,
                            gradient: isUser
                                ? const LinearGradient(
                                    colors: [AppTheme.heroAcc, AppTheme.colHum],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            border: isUser
                                ? null
                                : Border.all(color: AppTheme.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.heroAcc
                                    .withValues(alpha: isUser ? 0.2 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                              color: isUser ? Colors.white : AppTheme.text,
                              fontSize: 13,
                              height: 1.45,
                              fontWeight:
                                  isUser ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        );
                        return Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              _botAvatar(),
                              const SizedBox(width: 8),
                            ],
                            Flexible(child: bubble),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.15);
                      },
                    ),
            ),

            // ── Input box ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardSolid,
                border:
                    const Border(top: BorderSide(color: AppTheme.cardBorder)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.heroAcc.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
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
                    Material(
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      color: state.isChatLoading
                          ? AppTheme.bgAlt
                          : AppTheme.heroAcc,
                      child: IconButton(
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
                                color: Colors.white, size: 20),
                        onPressed:
                            state.isChatLoading ? null : () => _sendMessage(),
                      ),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.heroAcc, AppTheme.internet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.heroAcc.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 32),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.06, duration: 1400.ms),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'COBA TANYAKAN',
              style: GoogleFonts.outfit(
                color: AppTheme.subtext,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._suggestions.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppTheme.cardSolid,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _sendMessage(e.value),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppTheme.heroAcc.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 15,
                                  color: AppTheme.heroAcc),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.outfit(
                                  color: AppTheme.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: AppTheme.subtext),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (120 + e.key * 70).ms, duration: 300.ms)
                    .slideX(begin: 0.08),
              ),
        ],
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.heroAcc, AppTheme.internet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child:
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
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
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.heroAcc,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fade(
                      begin: 0.3, end: 1, delay: (i * 150).ms, duration: 450.ms)
                  .then()
                  .fade(begin: 1, end: 0.3, duration: 450.ms),
            const SizedBox(width: 6),
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
