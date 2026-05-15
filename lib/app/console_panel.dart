import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'console_log.dart';

/// A collapsible bottom panel that displays bridge I/O logs.
///
/// Performance: uses ListView.builder for lazy rendering and avoids
/// any animations on the log items themselves.
class ConsolePanel extends StatelessWidget {
  final ConsoleLogService logService;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ConsolePanel({
    super.key,
    required this.logService,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: logService,
      builder: (_, __) {
        final entries = logService.entries;
        final count = entries.length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header bar ──
            GestureDetector(
              onTap: onToggle,
              child: Container(
                color: AppTheme.surfaceAlt,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.terminal_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Console',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (count > 0)
                      GestureDetector(
                        onTap: logService.clear,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            // ── Log entries ──
            if (isExpanded)
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0D12), // darker than background for console feel
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: count == 0
                    ? const Center(
                        child: Text(
                          'No logs yet. Tap a bridge method to see requests & callbacks.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: count,
                        itemBuilder: (_, index) => _LogEntryTile(entry: entries[index]),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isRequest = entry.direction == LogDirection.request;
    final dirColor = isRequest ? AppTheme.primary : (entry.isError ? AppTheme.error : AppTheme.success);
    final dirLabel = isRequest ? '▶ REQ' : (entry.isError ? '✕ ERR' : '◀ CB');
    final time = '${_pad(entry.timestamp.hour)}:${_pad(entry.timestamp.minute)}:${_pad(entry.timestamp.second)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 52,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppTheme.textMuted,
              ),
            ),
          ),
          // Direction badge
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              dirLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: dirColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Method + params
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: entry.method,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (entry.params.isNotEmpty) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: _formatParams(entry.params),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String _formatParams(Map<String, String> params) {
    final parts = params.entries.map((e) => '${e.key}=${e.value}');
    return parts.join(', ');
  }
}
