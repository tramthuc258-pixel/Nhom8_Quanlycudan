import 'package:flutter/material.dart';

import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/controllers/announcement_controller.dart';
import 'package:homie/features/announcements/widgets/management/announcement_editor_dialog.dart';
import 'package:homie/features/announcements/widgets/management/announcement_management_widgets.dart';
import 'package:homie/core/widgets/confirm_dialog.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/features/staff_assignments/controllers/staff_assignment_controller.dart';

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({
    required this.controller,
    required this.staffAssignmentController,
    super.key,
  });

  final AnnouncementController controller;
  final StaffAssignmentController staffAssignmentController;

  @override
  State<AnnouncementManagementPage> createState() =>
      _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState
    extends State<AnnouncementManagementPage> {
  final _searchController = TextEditingController();
  final Set<String> _busyAnnouncementIds = <String>{};
  AnnouncementCategory? _categoryFilter;
  _AnnouncementStatusFilter _statusFilter = _AnnouncementStatusFilter.all;
  late final Listenable _pageListenable;

  @override
  void initState() {
    super.initState();
    _pageListenable = Listenable.merge([
      widget.controller,
      widget.staffAssignmentController,
    ]);
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thông báo'),
        actions: [
          if (compact)
            IconButton(
              tooltip: 'Tạo thông báo',
              onPressed: widget.controller.isLoading ? null : _create,
              icon: const Icon(Icons.add_alert_rounded),
            ),
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: widget.controller.isLoading ? null : _loadAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _pageListenable,
          builder: (context, _) {
            if (widget.controller.isLoading &&
                widget.controller.announcements.isEmpty) {
              return const LoadingView(
                message: 'Đang tải danh sách thông báo…',
              );
            }
            if (widget.controller.errorMessage != null &&
                widget.controller.announcements.isEmpty) {
              return ErrorView(
                message: widget.controller.errorMessage,
                onRetry: _loadAll,
              );
            }

            final announcements = _filteredAnnouncements();
            return RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _PageHeader(showAction: !compact, onCreate: _create),
                  ),
                  SliverToBoxAdapter(
                    child: AnnouncementManagementOverview(
                      announcements: widget.controller.announcements,
                    ),
                  ),
                  if (widget.controller.errorMessage != null)
                    SliverToBoxAdapter(
                      child: _InlineError(
                        message: widget.controller.errorMessage!,
                        onClose: widget.controller.clearError,
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildFilters()),
                  if (announcements.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        title: widget.controller.announcements.isEmpty
                            ? 'Chưa có thông báo'
                            : 'Không tìm thấy thông báo',
                        message: widget.controller.announcements.isEmpty
                            ? 'Tạo thông báo đầu tiên để gửi thông tin đến cư dân.'
                            : 'Hãy đổi từ khóa hoặc bộ lọc để xem kết quả khác.',
                        icon: Icons.notifications_none_rounded,
                        actionLabel: widget.controller.announcements.isEmpty
                            ? 'Tạo thông báo'
                            : 'Xóa bộ lọc',
                        onAction: widget.controller.announcements.isEmpty
                            ? _create
                            : _clearFilters,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final columns = width >= 1120
                              ? 3
                              : width >= 720
                              ? 2
                              : 1;
                          return SliverGrid.builder(
                            itemCount: announcements.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: columns == 1 ? 350 : 365,
                                ),
                            itemBuilder: (context, index) {
                              final announcement = announcements[index];
                              return AnnouncementManagementCard(
                                announcement: announcement,
                                busy: _busyAnnouncementIds.contains(
                                  announcement.id,
                                ),
                                onPreview: () => showAnnouncementPreviewDialog(
                                  context,
                                  announcement,
                                ),
                                onTogglePublished: () =>
                                    _togglePublished(announcement),
                                onDelete: () => _delete(announcement),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final search = TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Tìm thông báo',
                      hintText: 'Tiêu đề, nội dung hoặc người đăng',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa từ khóa',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  );
                  final category =
                      DropdownButtonFormField<AnnouncementCategory?>(
                        initialValue: _categoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<AnnouncementCategory?>(
                            value: null,
                            child: Text('Tất cả danh mục'),
                          ),
                          for (final value in AnnouncementCategory.values)
                            DropdownMenuItem<AnnouncementCategory?>(
                              value: value,
                              child: Text(value.displayName),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryFilter = value),
                      );

                  if (constraints.maxWidth < 650) {
                    return Column(
                      children: [search, const SizedBox(height: 12), category],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 3, child: search),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: category),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final status in _AnnouncementStatusFilter.values) ...[
                      ChoiceChip(
                        label: Text(status.label),
                        selected: _statusFilter == status,
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                      ),
                      if (status != _AnnouncementStatusFilter.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Announcement> _filteredAnnouncements() {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final results = widget.controller.announcements.where((item) {
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      if (!_statusFilter.matches(item, now)) return false;
      if (query.isEmpty) return true;

      final searchText = [
        item.title,
        item.content,
        item.authorName,
        item.category.displayName,
        item.audience.displayName,
        item.buildingName ?? 'Toàn hệ thống',
      ].join(' ').toLowerCase();
      return searchText.contains(query);
    }).toList();

    results.sort((first, second) {
      if (first.isPinned != second.isPinned) {
        return first.isPinned ? -1 : 1;
      }
      return second.publishedAt.compareTo(first.publishedAt);
    });
    return results;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _categoryFilter = null;
      _statusFilter = _AnnouncementStatusFilter.all;
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([
      widget.controller.load(),
      widget.staffAssignmentController.loadMyScope(),
    ]);
  }

  Future<void> _create() async {
    final scope = widget.staffAssignmentController;
    if (!scope.globalAccess && scope.myBuildings.isEmpty) {
      _showResult(
        false,
        'Tài khoản chưa được phân công tòa nhà nên không thể gửi thông báo.',
      );
      return;
    }
    final data = await showAnnouncementEditorDialog(
      context,
      buildings: scope.myBuildings,
      allowGlobal: scope.globalAccess,
    );
    if (data == null || !mounted) return;

    final success = await widget.controller.createAnnouncement(
      title: data.title,
      content: data.content,
      category: data.category,
      priority: data.priority,
      audience: data.audience,
      publishedAt: data.publishedAt,
      expiresAt: data.expiresAt,
      isPinned: data.isPinned,
      isPublished: data.isPublished,
      authorName: 'Ban quản lý Homie',
      buildingId: data.buildingId,
    );
    if (!mounted) return;
    _showResult(
      success,
      success
          ? data.isPublished
                ? 'Đã tạo và phát hành thông báo.'
                : 'Đã lưu thông báo dưới dạng bản nháp.'
          : widget.controller.errorMessage ?? 'Không thể tạo thông báo.',
    );
  }

  Future<void> _togglePublished(Announcement announcement) async {
    if (_busyAnnouncementIds.contains(announcement.id)) return;
    setState(() => _busyAnnouncementIds.add(announcement.id));
    final success = await widget.controller.togglePublished(announcement.id);
    if (!mounted) return;
    setState(() => _busyAnnouncementIds.remove(announcement.id));
    _showResult(
      success,
      success
          ? announcement.isPublished
                ? 'Đã chuyển thông báo về bản nháp.'
                : 'Đã phát hành thông báo.'
          : widget.controller.errorMessage ??
                'Không thể cập nhật trạng thái thông báo.',
    );
  }

  Future<void> _delete(Announcement announcement) async {
    if (_busyAnnouncementIds.contains(announcement.id)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xóa thông báo?',
      message:
          'Thông báo “${announcement.title}” sẽ bị xóa khỏi hệ thống. '
          'Thao tác này không thể hoàn tác.',
      confirmLabel: 'Xóa thông báo',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyAnnouncementIds.add(announcement.id));
    final success = await widget.controller.deleteAnnouncement(announcement.id);
    if (!mounted) return;
    setState(() => _busyAnnouncementIds.remove(announcement.id));
    _showResult(
      success,
      success
          ? 'Đã xóa thông báo.'
          : widget.controller.errorMessage ?? 'Không thể xóa thông báo.',
    );
  }

  void _showResult(bool success, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.showAction, required this.onCreate});

  final bool showAction;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trung tâm thông báo',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Soạn, lên lịch và quản lý nội dung gửi đến cư dân.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (showAction) ...[
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('Tạo thông báo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: colors.onErrorContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AnnouncementStatusFilter {
  all('Tất cả'),
  active('Đang hiển thị'),
  scheduled('Đã lên lịch'),
  draft('Bản nháp'),
  expired('Đã hết hạn');

  const _AnnouncementStatusFilter(this.label);

  final String label;

  bool matches(Announcement item, DateTime now) => switch (this) {
    _AnnouncementStatusFilter.all => true,
    _AnnouncementStatusFilter.active =>
      item.isPublished &&
          !item.publishedAt.isAfter(now) &&
          (item.expiresAt == null || item.expiresAt!.isAfter(now)),
    _AnnouncementStatusFilter.scheduled =>
      item.isPublished && item.publishedAt.isAfter(now),
    _AnnouncementStatusFilter.draft => !item.isPublished,
    _AnnouncementStatusFilter.expired =>
      item.isPublished &&
          item.expiresAt != null &&
          !item.expiresAt!.isAfter(now),
  };
}
