import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/app/widgets/app_bottom_menu.dart';

void main() {
  test('bottom menu resolves profile routes to profile index', () {
    expect(AppBottomMenu.resolveIndex('/profile'), 3);
    expect(AppBottomMenu.resolveIndex('/settings/security'), 3);
    expect(AppBottomMenu.resolveIndex('/notifications'), 3);
    expect(AppBottomMenu.resolveIndex('/subscriptions/pending'), 3);
  });
}
