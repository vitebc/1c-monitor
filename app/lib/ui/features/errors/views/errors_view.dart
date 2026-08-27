import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/errors_view_model.dart';

/// View — тонкий виджет, только рендер (skill: UI Layer -> Views).
/// Вся логика в ViewModel, слушает через ListenableBuilder/Consumer.
class ErrorsView extends StatelessWidget {
  const ErrorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ErrorsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Ошибки — ${vm.selectedBase}'),
        actions: [
          if (vm.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(label: Text('${vm.unreadCount} новых')),
            ),
          PopupMenuButton<String?>(
            onSelected: vm.setLevelFilter,
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Все уровни')),
              PopupMenuItem(value: 'Информация', child: Text('Информация')),
              PopupMenuItem(value: 'Предупреждение', child: Text('Предупреждение')),
              PopupMenuItem(value: 'Ошибка', child: Text('Ошибка')),
              PopupMenuItem(value: 'Критично', child: Text('Критично')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (context, _) {
          if (vm.isLoading && vm.errors.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.errorMsg != null) {
            return Center(child: Text('Ошибка: ${vm.errorMsg}'));
          }
          if (vm.errors.isEmpty) {
            return const Center(child: Text('Нет ошибок'));
          }
          return RefreshIndicator(
            onRefresh: vm.load,
            child: ListView.builder(
              itemCount: vm.errors.length,
              itemBuilder: (context, i) {
                final e = vm.errors[i];
                return ListTile(
                  leading: Icon(
                    e.isCritical ? Icons.error : Icons.info,
                    color: e.isCritical ? Colors.red : Colors.orange,
                  ),
                  title: Text(e.shortTitle),
                  subtitle: Text(
                    [
                      if (e.metadataObject != null) e.metadataObject!,
                      if (e.commentText != null) e.commentText!,
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${e.createdAt.hour.toString().padLeft(2, '0')}:${e.createdAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  tileColor: e.isRead ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                  onTap: () => vm.markRead(e.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
