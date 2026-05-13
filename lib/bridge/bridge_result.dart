sealed class BridgeResult<T> {
  const BridgeResult();
}

class BridgeSuccess<T> extends BridgeResult<T> {
  final T data;

  const BridgeSuccess(this.data);
}

class BridgeFailure<T> extends BridgeResult<T> {
  final String code;
  final String message;

  const BridgeFailure({
    required this.code,
    required this.message,
  });
}
