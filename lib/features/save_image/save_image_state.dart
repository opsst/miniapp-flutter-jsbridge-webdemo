enum SaveImageStatus { idle, loading, success, failure }

class SaveImageState {
  final SaveImageStatus status;
  final bool? success;
  final String? errorMessage;

  const SaveImageState({
    this.status = SaveImageStatus.idle,
    this.success,
    this.errorMessage,
  });
}
