import 'package:flutter/material.dart';

import '../features/payment/payment_controller.dart';
import '../features/payment/payment_state.dart';
import '../features/save_image/sample_image.dart';

const _subtitle =
    'Calls native Pay-with-Paotang via window.JSBridge.openPayment (Android) or webkit observer (iOS). On success native reloads the WebView with the deeplink URL — no success callback.';

class PaymentSection extends StatefulWidget {
  final PaymentController controller;

  const PaymentSection({super.key, required this.controller});

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  final _txnRefId = TextEditingController(text: kSampleTxnId);

  @override
  void initState() {
    super.initState();
    _txnRefId.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _txnRefId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final state = widget.controller.state;
        final isSending = state.status == PaymentStatus.sending;
        final canSend = !isSending && _txnRefId.text.trim().isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Open Payment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(_subtitle),
            const SizedBox(height: 16),
            TextField(
              controller: _txnRefId,
              decoration: const InputDecoration(
                labelText: 'PPOA Transaction Ref ID *',
                helperText: 'txnRefId',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canSend ? () => widget.controller.openPayment(_txnRefId.text) : null,
              child: Text(isSending ? 'Opening...' : 'Open Payment'),
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
  final PaymentState state;

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

String _titleFor(PaymentStatus status) => switch (status) {
      PaymentStatus.idle => 'Idle',
      PaymentStatus.sending => 'Opening payment...',
      PaymentStatus.failure => 'Failure',
    };

String _messageFor(PaymentState state) => switch (state.status) {
      PaymentStatus.idle => 'Enter a txnRefId and tap Open Payment.',
      PaymentStatus.sending =>
        'Native should open the Pay-with-Paotang flow. On success, the WebView will reload — you will not see a success state here.',
      PaymentStatus.failure => state.errorMessage ?? '-',
    };
