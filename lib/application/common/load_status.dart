/// Status shared by every screen state: what a UI should render.
enum LoadStatus { initial, loading, success, failure }

extension LoadStatusX on LoadStatus {
  bool get isLoading =>
      this == LoadStatus.initial || this == LoadStatus.loading;
  bool get isSuccess => this == LoadStatus.success;
  bool get isFailure => this == LoadStatus.failure;
}

/// Monotonic id used to make one-shot UI effects (toasts, dialogs) distinct
/// in otherwise equal states.
int _effectCounter = 0;
int nextEffectId() => ++_effectCounter;
