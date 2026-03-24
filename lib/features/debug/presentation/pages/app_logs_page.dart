import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/local_app_log_store.dart';
import '../../../../l10n/app_localizations.dart';

class AppLogsPage extends StatefulWidget {
  const AppLogsPage({super.key});

  @override
  State<AppLogsPage> createState() => _AppLogsPageState();
}

class _AppLogsPageState extends State<AppLogsPage> {
  bool isLoading = true;
  List<LocalAppLogFileSummary> logFiles = const [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => isLoading = true);
    final files = await LocalAppLogStore.listLogFiles();
    if (!mounted) return;
    setState(() {
      logFiles = files;
      isLoading = false;
    });
  }

  Future<void> _exportToSelectedDirectory(LocalAppLogFileSummary file) async {
    final l10n = AppLocalizations.of(context);
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null || selectedDirectory.isEmpty) return;

    final exportedPath = await LocalAppLogStore.exportSanitizedLogFileToDirectory(
      sourcePath: file.path,
      targetDirectory: selectedDirectory,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.appLogsExported(exportedPath))),
    );
  }

  Future<void> openLog(LocalAppLogFileSummary file) async {
    final l10n = AppLocalizations.of(context);
    final rawText = await LocalAppLogStore.readLogFile(file.path);
    final sanitizedText = LocalAppLogStore.sanitizeLogText(rawText);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isSanitizedExport = file.name.endsWith('.sanitized.txt');
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isSanitizedExport ? Icons.shield_outlined : Icons.description_outlined,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${LocalAppLogStore.formatBytes(file.sizeBytes)} · ${file.modifiedAt.toLocal()}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSanitizedExport
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isSanitizedExport ? l10n.appLogsSanitizedBadge : l10n.appLogsRawBadge,
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.appLogsViewerHint,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: sanitizedText));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.appLogsCopied)),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_all_outlined),
                        label: Text(l10n.appLogsCopySanitized),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final exportedPath = await LocalAppLogStore.exportSanitizedLogFile(file.path);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.appLogsExportedToInternal(exportedPath))),
                            );
                          }
                          await refresh();
                        },
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text(l10n.appLogsExportToLogsDir),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _exportToSelectedDirectory(file);
                        },
                        icon: const Icon(Icons.folder_open_outlined),
                        label: Text(l10n.appLogsExportToDirectory),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await LocalAppLogStore.clearLogFile(file.path);
                          if (context.mounted) Navigator.of(context).pop();
                          await refresh();
                        },
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text(l10n.appLogsDeleteCurrent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Expanded(
                  child: sanitizedText.trim().isEmpty
                      ? Center(child: Text(l10n.appLogsEmptyContent))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: SelectableText(
                              sanitizedText,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.45),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> clearAll() async {
    final l10n = AppLocalizations.of(context);
    await LocalAppLogStore.clearAllLogs();
    await refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.appLogsDeleteAll)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appLogsTitle),
        actions: [
          IconButton(onPressed: isLoading ? null : refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: isLoading ? null : clearAll, icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.receipt_long_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.appLogsTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.appLogsSubtitle,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.appLogsFileCount(logFiles.length),
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: logFiles.isEmpty
                      ? Center(child: Text(l10n.appLogsEmpty))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: logFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final file = logFiles[index];
                            final isSanitizedExport = file.name.endsWith('.sanitized.txt');
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => openLog(file),
                                child: Ink(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSanitizedExport
                                              ? theme.colorScheme.primaryContainer
                                              : theme.colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          isSanitizedExport ? Icons.shield_outlined : Icons.description_outlined,
                                          color: isSanitizedExport
                                              ? theme.colorScheme.onPrimaryContainer
                                              : theme.colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${LocalAppLogStore.formatBytes(file.sizeBytes)} · ${file.modifiedAt.toLocal()}',
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSanitizedExport
                                              ? theme.colorScheme.primaryContainer
                                              : theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          isSanitizedExport ? l10n.appLogsSanitizedBadge : l10n.appLogsRawBadge,
                                          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
