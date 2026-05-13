import 'package:flutter/material.dart';

import '../features/share/share_controller.dart';
import '../features/share/share_state.dart';

const _subtitle =
    'Calls native share via window.JSBridge.shareContent (Android) or webkit observer (iOS).';

const _shareTypes = <String>['TEXT', 'IMAGE'];

class ShareSection extends StatefulWidget {
  final ShareController controller;

  const ShareSection({super.key, required this.controller});

  @override
  State<ShareSection> createState() => _ShareSectionState();
}

class _ShareSectionState extends State<ShareSection> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _content = TextEditingController();
  final _icon = TextEditingController();
  String _type = 'TEXT';

  @override
  void initState() {
    super.initState();
    _content.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _content.dispose();
    _icon.dispose();
    super.dispose();
  }

  void _onShare() {
    widget.controller.share(
      title: _emptyAsNull(_title.text),
      description: _emptyAsNull(_description.text),
      content: _content.text,
      icon: _emptyAsNull(_icon.text),
      type: _type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final state = widget.controller.state;
        final isLoading = state.status == ShareStatus.loading;
        final canShare = !isLoading && _content.text.trim().isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Share Content', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(_subtitle),
            const SizedBox(height: 16),
            _field(_title, label: 'Title (optional)'),
            const SizedBox(height: 8),
            _field(_description, label: 'Description (optional, iOS only)'),
            const SizedBox(height: 8),
            _field(_content, label: 'Content *', maxLines: 3),
            const SizedBox(height: 8),
            _field(_icon, label: 'Icon base64 (optional, iOS thumbnail)', maxLines: 2),
            const SizedBox(height: 12),
            _TypeSelector(value: _type, onChanged: (v) => setState(() => _type = v)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canShare ? _onShare : null,
              child: Text(isLoading ? 'Sharing...' : 'Share'),
            ),
            const SizedBox(height: 16),
            _StatusCard(state: state),
          ],
        );
      },
    );
  }

  Widget _field(TextEditingController controller, {required String label, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: _shareTypes
          .map((t) => ButtonSegment<String>(value: t, label: Text(t)))
          .toList(),
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ShareState state;

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

String? _emptyAsNull(String value) => value.trim().isEmpty ? null : value;

String _titleFor(ShareStatus status) => switch (status) {
      ShareStatus.idle => 'Idle',
      ShareStatus.loading => 'Sending to native...',
      ShareStatus.success => 'Shared',
      ShareStatus.failure => 'Failure',
    };

String _messageFor(ShareState state) => switch (state.status) {
      ShareStatus.idle => 'Fill content and tap Share.',
      ShareStatus.loading => 'Native should call window.bridge.shareContentCallback or shareContentCallbackError.',
      ShareStatus.success => state.packageName == null
          ? 'Shared (no package reported).'
          : 'Shared via ${state.packageName}',
      ShareStatus.failure => state.errorMessage ?? '-',
    };
