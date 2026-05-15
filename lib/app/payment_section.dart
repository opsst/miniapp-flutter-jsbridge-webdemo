import 'package:flutter/material.dart';

import '../features/payment/payment_controller.dart';
import '../features/payment/payment_state.dart';
import '../features/save_image/sample_image.dart';
import 'app_theme.dart';
import 'status_card.dart';

const _subtitle =
    'Calls native Pay-with-Paotang via window.JSBridge.openPayment (Android) or webkit observer (iOS). On success, native reloads the WebView — no success callback.';

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment_rounded, size: 22, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open payment',
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
              controller: _txnRefId,
              decoration: const InputDecoration(
                labelText: 'PPOA Transaction Ref ID *',
                helperText: 'txnRefId',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canSend ? () => widget.controller.openPayment(_txnRefId.text) : null,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 20),
              label: Text(isSending ? 'Opening...' : 'Open payment'),
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

StatusType _statusType(PaymentStatus status) => switch (status) {
      PaymentStatus.idle => StatusType.idle,
      PaymentStatus.sending => StatusType.loading,
      PaymentStatus.failure => StatusType.failure,
    };

String _titleFor(PaymentStatus status) => switch (status) {
      PaymentStatus.idle => 'Idle',
      PaymentStatus.sending => 'Opening payment...',
      PaymentStatus.failure => 'Failure',
    };

String _messageFor(PaymentState state) => switch (state.status) {
      PaymentStatus.idle => 'Enter a txnRefId and tap Open Payment.',
      PaymentStatus.sending =>
        'Native should open the Pay-with-Paotang flow. On success, the WebView will reload.',
      PaymentStatus.failure => state.errorMessage ?? '-',
    };
