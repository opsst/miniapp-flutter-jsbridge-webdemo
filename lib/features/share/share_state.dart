enum ShareStatus { idle, loading, success, failure }

class ShareState {
  final ShareStatus status;
  final String? packageName;
  final String? errorMessage;

  const ShareState({
    this.status = ShareStatus.idle,
    this.packageName,
    this.errorMessage,
  });
}
