import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack_mobile/core/models/api_failure.dart';
import 'package:subtrack_mobile/features/settings/presentation/settings_models.dart';

void main() {
  test('formats payment method label', () {
    expect(
      formatPaymentMethodLabel('Т-Банк', '2202************222'),
      'Т-Банк • 2202************222',
    );
  });

  test('validates profile form fields', () {
    expect(
      validateProfileForm(
        name: 'Н',
        email: 'metlov.nm@yandex.ru',
        avatarLink: '',
      ),
      'Проверьте корректность имени, email и ссылки на аватар.',
    );

    expect(
      validateProfileForm(
        name: 'Метлов Никита',
        email: 'metlov.nm@yandex.ru',
        avatarLink: 'https://example.com/avatar.png',
      ),
      isNull,
    );
  });

  test('maps profile failure to message', () {
    expect(
      mapProfileFailureToMessage(
        const ApiFailure(statusCode: 409, code: 'CONFLICT', message: 'Conflict'),
      ),
      'Пользователь с таким email уже существует.',
    );
  });

  test('maps security failure to current password and weak password messages', () {
    expect(
      mapSecurityFailureToMessage(
        const ApiFailure(statusCode: 400, code: 'INVALID', message: 'Текущий пароль неверный'),
        '12345678',
      ),
      'Текущий пароль введен неверно.',
    );

    expect(
      mapSecurityFailureToMessage(
        const ApiFailure(statusCode: 400, code: 'INVALID', message: 'Ошибка'),
        '123',
      ),
      'Новый пароль должен быть не короче 8 символов.',
    );
  });

  test('maps payment method failures by code', () {
    expect(
      mapPaymentMethodFailureToMessage(
        const ApiFailure(statusCode: 409, code: 'PAYMENT_METHOD_EXISTS', message: 'Exists'),
      ),
      'Такой способ оплаты уже есть.',
    );
    expect(
      mapPaymentMethodFailureToMessage(
        const ApiFailure(statusCode: 409, code: 'PAYMENT_METHOD_IN_USE', message: 'Used'),
      ),
      'Нельзя удалить способ оплаты, который используется в подписках.',
    );
    expect(
      mapPaymentMethodFailureToMessage(
        const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'Forbidden'),
      ),
      'Действие недоступно.',
    );
  });
}
