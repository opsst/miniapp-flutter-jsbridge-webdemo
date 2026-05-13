import 'package:flutter/material.dart';

import '../features/save_image/sample_image.dart';
import '../features/save_image/save_image_controller.dart';
import '../features/save_image/save_image_state.dart';

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
            const Text('Save Image to Gallery', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(_subtitle),
            const SizedBox(height: 16),
            TextField(
              controller: _data,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Base64 image data *',
                helperText: 'Paste a base64-encoded image string',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canSave ? () => widget.controller.save(_data.text) : null,
              child: Text(isLoading ? 'Saving...' : 'Save to Gallery'),
            ),
            const SizedBox(height: 16),
            _StatusCard(state: state),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SaveImageState state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titleFor(state.status), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_messageFor(state)),
          ],
        ),
      ),
    );
  }
}

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
