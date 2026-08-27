import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/error.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/errors_view_model.dart';
import '../widgets/error_detail.dart';

const double _largeScreenMinWidth = 600;

/// View — адаптив по flutter-build-responsive-layout:
/// - LayoutBuilder + constraints.maxWidth (не MediaQuery.orientation)
/// - <600: список на весь экран, тап -> push деталки
/// - >600: Row [список 360 + divider + деталка Expanded], список в ConstrainedBox+Center
/// Constraints go down, Sizes go up — Expanded/Flexible внутри Row.
class ErrorsView extends StatefulWidget {
  const ErrorsView({super.key});

  @override
  State<ErrorsView> createState() => _ErrorsViewState();
}

class _ErrorsViewState extends State<ErrorsView> {
  String? _selectedId; // UI-state (skill: Views держат только UI-логику)
  bool _basesInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_basesInit) {
      _basesInit = true;
      final settingsVm = context.read<SettingsViewModel>();
      final errorsVm = context.read<ErrorsViewModel>();
      // грузим базы если пусто
      if (settingsVm.bases.isEmpty && !settingsVm.isLoading) {
        settingsVm.load().then((_) {
          if (!mounted) return;
          final bases = context.read<SettingsViewModel>().bases;
          if (bases.isNotEmpty && !bases.contains(errorsVm.selectedBase)) {
            errorsVm.setBase(bases.first);
          }
        });
      } else if (settingsVm.bases.isNotEmpty && !settingsVm.bases.contains(errorsVm.selectedBase)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          errorsVm.setBase(settingsVm.bases.first);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ErrorsViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();

    final bases = settingsVm.bases;
    return Scaffold(
      appBar: AppBar(
        title: bases.isEmpty
            ? const Text('Ошибки')
            : DropdownButton<String>(
                value: bases.contains(vm.selectedBase) ? vm.selectedBase : null,
                hint: const Text('Выбери базу'),
                underline: const SizedBox.shrink(),
                items: bases.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedId = null);
                    vm.setBase(v);
                  }
                },
              ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > _largeScreenMinWidth;
          if (isLarge) return _buildLarge(context, vm);
          return _buildSmall(context, vm);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.load,
        tooltip: 'Обновить',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // --- small: список на всю ширину, ConstrainedBox(800) по центру ---
  Widget _buildSmall(BuildContext context, ErrorsViewModel vm) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: _buildList(context, vm, isLarge: false),
      ),
    );
  }

  // --- large: Row [список | деталка] ---
  Widget _buildLarge(BuildContext context, ErrorsViewModel vm) {
    final selected = _selectedId == null ? null : _tryFind(vm.errors, _selectedId!);
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: _buildList(context, vm, isLarge: true),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          // skill: Expanded заставляет деталку занять весь оставшийся width
          child: selected == null
              ? const Center(child: Text('Выбери ошибку слева'))
              : ErrorDetail(
                  error: selected,
                  // на десктопе закрытие = сброс выбора (не pop)
                  onClose: () => setState(() => _selectedId = null),
                ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, ErrorsViewModel vm, {required bool isLarge}) {
    final settingsVm = context.watch<SettingsViewModel>();
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        if (settingsVm.bases.isEmpty && !settingsVm.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Нет подписок на базы'),
                SizedBox(height: 8),
                Text('Добавь базу в Настройках, чтобы видеть ошибки', textAlign: TextAlign.center),
              ]),
            ),
          );
        }
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
            // skill: builder для ленивого рендера
            itemCount: vm.errors.length,
            itemBuilder: (context, i) {
              final e = vm.errors[i];
              final isSelected = e.id == _selectedId;
              return ListTile(
                selected: isLarge && isSelected,
                selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                leading: Icon(
                  e.isCritical ? Icons.error : Icons.info,
                  color: e.isCritical ? Colors.red : Colors.orange,
                ),
                title: Text(e.shortTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                tileColor: !e.isRead && !isSelected ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
                onTap: () {
                  vm.markRead(e.id);
                  if (isLarge) {
                    setState(() => _selectedId = e.id);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ErrorDetail(error: e)),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  ErrorEntry? _tryFind(List<ErrorEntry> list, String id) {
    for (final e in list) {
      if (e.id == id) return e;
    }
    return null;
  }
}
