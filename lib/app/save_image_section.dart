import 'package:flutter/material.dart';

import '../features/save_image/sample_image.dart';
import '../features/save_image/save_image_controller.dart';
import '../features/save_image/save_image_state.dart';
import 'app_theme.dart';
import 'status_card.dart';

const _subtitle =
    'Calls native gallery save via window.JSBridge.saveImageToGallery (Android) or webkit observer (iOS).';

class SaveImageSection extends StatefulWidget {
  final SaveImageController controller;

  const SaveImageSection({super.key, required this.controller});

  @override
  State<SaveImageSection> createState() => _SaveImageSectionState();
}

class _SaveImageSectionState extends State<SaveImageSection> {
  final _data = TextEditingController(text: kSampleImageBase64);

  @override
  void initState() {
    super.initState();
    _data.addListener(() => setState(() {
    }));

  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final state = widget.controller.state;
        final isLoading = state.status == SaveImageStatus.loading;
        final canSave = !isLoading && _data.text.trim().isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_rounded, size: 22, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save image to gallery',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _data,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Base64 image data *',
                helperText: 'Paste a base64-encoded image string',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canSave ? () => widget.controller.save(_data.text) : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                    )
                  : const Icon(Icons.save_alt_rounded, size: 20),
              label: Text(isLoading ? 'Saving...' : 'Save to gallery'),
            ),
            const SizedBox(height: 20),
            StatusCard(
              type: _statusType(state.status),
              title: _titleFor(state.status),
              message: _messageFor(state),
            ),
          ],
        );
      },
    );
  }
}

StatusType _statusType(SaveImageStatus status) => switch (status) {
      SaveImageStatus.idle => StatusType.idle,
      SaveImageStatus.loading => StatusType.loading,
      SaveImageStatus.success => StatusType.success,
      SaveImageStatus.failure => StatusType.failure,
    };

String _titleFor(SaveImageStatus status) => switch (status) {
      SaveImageStatus.idle => 'Idle',
      SaveImageStatus.loading => 'Saving to gallery...',
      SaveImageStatus.success => 'Saved',
      SaveImageStatus.failure => 'Failure',
    };

String _messageFor(SaveImageState state) => switch (state.status) {
      SaveImageStatus.idle => 'Paste base64 image data and tap Save.',
      SaveImageStatus.loading =>
        'Native should call window.bridge.saveImageToGalleryCallback(true|false) or saveImageToGalleryCallbackError.',
      SaveImageStatus.success => 'Image saved to gallery.',
      SaveImageStatus.failure => state.errorMessage ?? '-',
    };
