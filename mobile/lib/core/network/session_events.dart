class SessionEvents {
  Future<void> Function()? onSessionExpired;

  Future<void> notifySessionExpired() async {
    final callback = onSessionExpired;
    if (callback != null) {
      await callback();
    }
  }
}
