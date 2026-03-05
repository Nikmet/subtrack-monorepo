import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/shared/parsers.dart';
import '../../../features/shared/providers.dart';
import 'home_content.dart';
import 'home_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeScreenStatus _status = HomeScreenStatus.loading;
  HomeScreenDataVm? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _status = HomeScreenStatus.loading;
        _errorMessage = null;
      });
    }

    try {
      final raw = await ref.read(apiClientProvider).getData('/home');
      final mapped = HomeScreenDataVm.fromMap(asMap(raw));
      if (!mounted) {
        return;
      }
      setState(() {
        _status = HomeScreenStatus.loaded;
        _data = mapped;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = HomeScreenStatus.error;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreenBody(
      status: _status,
      data: _data,
      errorMessage: _errorMessage,
      onRefresh: _load,
      onRetry: _load,
      onNotificationsTap: () => context.push('/notifications'),
      onProfileTap: () => context.push('/profile'),
      onSearchTap: () => context.push('/search'),
    );
  }
}
