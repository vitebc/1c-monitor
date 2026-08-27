import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/error.dart';

/// Панель деталки — показывает все 6 полей ТЗ 1С + data jsonb.
/// На десктопе (<600 → отдельный экран, >600 → правый pane).
class ErrorDetail extends StatelessWidget {
  const ErrorDetail({super.key, required this.error, this.onClose});
  final ErrorEntry error;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm:ss');
    return Scaffold(
      appBar: AppBar(
        title: Text(error.eventName),
        leading: onClose != null ? IconButton(icon: const Icon(Icons.close), onPressed: onClose) : null,
        automaticallyImplyLeading: onClose == null,
      ),
      body: Center(
        // skill: Constrain width on large screens (800) + Center
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row('Уровень', error.level, icon: error.isCritical ? Icons.error : Icons.info, color: error.isCritical ? Colors.red : Colors.orange),
              _row('ИмяСобытия', error.eventName),
              _row('ОбъектМетаданных', error.metadataObject ?? '—'),
              _row('База', error.base),
              _row('Дата', df.format(error.createdAt)),
              _row('Прочитано', error.isRead ? 'Да' : 'Нет'),
              const Divider(height: 32),
              Text('Комментарий', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SelectableText(error.commentText?.isNotEmpty == true ? error.commentText! : '—'),
              const SizedBox(height: 16),
              Text('Данные (jsonb)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  error.data.isEmpty ? '{}' : error.data.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text('id: ${error.id}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
