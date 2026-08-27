import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/settings_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';

/// Экран настроек: подписки на Базы + выход
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Пользователь: ${auth.user?.email ?? '—'}', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),
                Text('Подписки на Базы', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'Имя базы (как в errors.base)',
                          border: OutlineInputBorder(),
                          hintText: 'DEMO',
                        ),
                        onSubmitted: (_) => _add(vm),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => _add(vm), child: const Text('Добавить')),
                  ],
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 8),
                  Text(vm.error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                if (vm.isLoading) const LinearProgressIndicator(),
                Expanded(
                  child: vm.bases.isEmpty
                      ? const Center(child: Text('Нет подписок — добавь базу, чтобы получать ошибки'))
                      : ListView.builder(
                          itemCount: vm.bases.length,
                          itemBuilder: (context, i) {
                            final base = vm.bases[i];
                            return ListTile(
                              leading: const Icon(Icons.storage),
                              title: Text(base),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => vm.removeBase(base),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(SettingsViewModel vm) async {
    final ok = await vm.addBase(_controller.text);
    if (ok) _controller.clear();
    if (mounted && !ok && vm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('База уже добавлена или пустая')));
    }
  }
}
