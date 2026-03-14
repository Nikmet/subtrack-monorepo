import 'package:flutter/material.dart';

import '../../../app/ui_kit/tokens.dart';

Future<bool> showDeleteSubscriptionDialog({
  required BuildContext context,
  required String subscriptionName,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return _DeleteSubscriptionDialog(subscriptionName: subscriptionName);
        },
      ) ??
      false;
}

class _DeleteSubscriptionDialog extends StatelessWidget {
  const _DeleteSubscriptionDialog({
    required this.subscriptionName,
  });

  final String subscriptionName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: UiTokens.radius16,
          border: Border.all(color: const Color(0xFFD4DEEA)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x3309182B),
              blurRadius: 48,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Удалить подписку',
                    style: TextStyle(
                      color: Color(0xFF142B45),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  borderRadius: UiTokens.radius10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9EFF7),
                      borderRadius: UiTokens.radius10,
                    ),
                    child: const Icon(Icons.close, color: Color(0xFF4F627A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FA),
                borderRadius: UiTokens.radius12,
                border: Border.all(color: const Color(0xFFD8E2EE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Сервис',
                    style: TextStyle(
                      color: Color(0xFF9AAABD),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subscriptionName,
                    style: const TextStyle(
                      color: Color(0xFF122842),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Подписка будет удалена с главного экрана. Добавить её снова можно через поиск.',
              style: TextStyle(
                color: Color(0xFF5F748C),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: Color(0xFFD4DEEA)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: UiTokens.radius12,
                      ),
                      foregroundColor: const Color(0xFF26415E),
                    ),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: const Color(0xFFD64545),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: UiTokens.radius12,
                      ),
                    ),
                    child: const Text(
                      'Удалить',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
