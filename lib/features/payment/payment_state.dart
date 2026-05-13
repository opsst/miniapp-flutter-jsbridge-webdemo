/// No `success` state — on success native reloads the WebView with the
/// deeplink URL, so the user never sees a success indicator in this app.
enum PaymentStatus { idle, sending, failure }

class PaymentState {
  final PaymentStatus status;
  final String? errorMessage;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.errorMessage,
  });
}
