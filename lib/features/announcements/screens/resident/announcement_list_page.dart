import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/features/announcements/models/announcement_category.dart';
import 'package:homie/features/announcements/models/announcement_priority.dart';
import 'package:homie/features/announcements/models/announcement.dart';
import 'package:homie/features/announcements/controllers/announcement_controller.dart';
import 'package:homie/features/announcements/screens/resident/announcement_detail_page.dart';
import 'package:homie/features/announcements/widgets/resident/announcement_card.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/core/widgets/resident_page_scaffold.dart';

enum _ReadFilter {
  all('Tất cả'),
  unread('Chưa đọc'),
  read('Đã đọc');

  const _ReadFilter(this.label);
  final String label;
}

class AnnouncementListPage extends StatefulWidget {
  const AnnouncementListPage({
    required this.controller,
    required this.user,
    super.key,
  });

  final AnnouncementController controller;
  final User user;

  @override
  State<AnnouncementListPage> createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  final _searchController = TextEditingController();
  AnnouncementCategory? _categoryFilter;
  AnnouncementPriority? _priorityFilter;
  _ReadFilter _readFilter = _ReadFilter.all;
  bool _pinnedOnly = false;
  bool _waitingForFirstLoad = true;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant AnnouncementListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.user.id != widget.user.id) {
      _waitingForFirstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() => setState(() {});

  Future<void> _load() async {
    await widget.controller.load();
    if (!mounted) return;
    setState(() => _waitingForFirstLoad = false);
  }

  @override
  Widget build(BuildContext context) {
    return ResidentPageScaffold(
      title: 'Thông báo',
      subtitle: 'Thông báo và tin tức từ ban quản lý',
      icon: Icons.campaign_outlined,
      accentColor: AppColors.community,
      accentSoftColor: AppColors.communitySoft,
      actions: [
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final unread = widget.controller.unreadCountForUser(widget.user);
            return IconButton(
              tooltip: unread == 0
                  ? 'Không có thông báo chưa đọc'
                  : 'Đánh dấu tất cả đã đọc',
              onPressed: unread == 0 || _markingAll ? null : _markAllAsRead,
              icon: _markingAll
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all_rounded),
            );
          },
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => IconButton(
            tooltip: 'Tải lại thông báo',
            onPressed: widget.controller.isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    final published = controller.publishedForUser(widget.user);

    if (_waitingForFirstLoad || (controller.isLoading && published.isEmpty)) {
      return const LoadingView(message: 'Đang tải thông báo…');
    }

    if (controller.errorMessage != null && published.isEmpty) {
      return ErrorView(
        title: 'Không thể tải thông báo',
        message: controller.errorMessage,
        onRetry: _load,
      );
    }

    final filtered = _filteredAnnouncements(published);
    final unread = controller.unreadCountForUser(widget.user);

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _AnnouncementOverview(
              total: published.length,
              unread: unread,
              pinned: published.where((item) => item.isPinned).length,
              onMarkAllRead: unread > 0 && !_markingAll ? _markAllAsRead : null,
            ),
          ),
          SliverToBoxAdapter(child: _buildFilters(context)),
          if (controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _RefreshWarning(message: controller.errorMessage!),
                  ),
                ),
              ),
            ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: published.isEmpty
                    ? Icons.notifications_none_rounded
                    : Icons.filter_alt_off_outlined,
                title: published.isEmpty
                    ? 'Chưa có thông báo'
                    : 'Không tìm thấy thông báo',
                message: published.isEmpty
                    ? 'Thông báo mới từ ban quản lý sẽ xuất hiện tại đây.'
                    : 'Hãy đổi từ khóa hoặc bộ lọc để xem kết quả khác.',
                actionLabel: published.isEmpty ? 'Tải lại' : 'Xóa bộ lọc',
                onAction: published.isEmpty ? _load : _clearFilters,
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final horizontalPadding = width > 1212
                    ? (width - 1180) / 2
                    : 16.0;
                final columns = width >= 940 ? 2 : 1;
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    36,
                  ),
                  sliver: SliverGrid.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 286,
                    ),
                    itemBuilder: (context, index) {
                      final announcement = filtered[index];
                      return ResidentAnnouncementCard(
                        announcement: announcement,
                        isRead: controller.isRead(
                          announcement.id,
                          widget.user.id,
                        ),
                        onTap: () => _openDetail(announcement),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bộ lọc',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(
                            Icons.filter_alt_off_rounded,
                            size: 18,
                          ),
                          label: Text('Xóa ($_activeFilterCount)'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _FilterGroup(
                    label: 'Danh mục',
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _categoryFilter == null,
                        onSelected: (_) =>
                            setState(() => _categoryFilter = null),
                      ),
                      for (final category in AnnouncementCategory.values)
                        ChoiceChip(
                          label: Text(category.displayName),
                          selected: _categoryFilter == category,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = category),
                        ),
                    ],
                  ),
                  _FilterGroup(
                    label: 'Mức độ',
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _priorityFilter == null,
                        onSelected: (_) =>
                            setState(() => _priorityFilter = null),
                      ),
                      for (final priority in AnnouncementPriority.values)
                        ChoiceChip(
                          label: Text(priority.displayName),
                          selected: _priorityFilter == priority,
                          onSelected: (_) =>
                              setState(() => _priorityFilter = priority),
                        ),
                    ],
                  ),
                  _FilterGroup(
                    label: 'Trạng thái',
                    children: [
                      for (final filter in _ReadFilter.values)
                        ChoiceChip(
                          label: Text(filter.label),
                          selected: _readFilter == filter,
                          onSelected: (_) =>
                              setState(() => _readFilter = filter),
                        ),
                      FilterChip(
                        avatar: const Icon(Icons.push_pin_outlined, size: 17),
                        label: const Text('Chỉ tin đã ghim'),
                        selected: _pinnedOnly,
                        onSelected: (value) =>
                            setState(() => _pinnedOnly = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Announcement> _filteredAnnouncements(List<Announcement> source) {
    final query = _searchController.text.trim().toLowerCase();
    final results = source.where((announcement) {
      if (_categoryFilter != null && announcement.category != _categoryFilter) {
        return false;
      }
      if (_priorityFilter != null && announcement.priority != _priorityFilter) {
        return false;
      }
      if (_pinnedOnly && !announcement.isPinned) return false;

      final isRead = widget.controller.isRead(announcement.id, widget.user.id);
      if (_readFilter == _ReadFilter.unread && isRead) return false;
      if (_readFilter == _ReadFilter.read && !isRead) return false;

      if (query.isEmpty) return true;
      final haystack =
          '${announcement.title} ${announcement.content} ${announcement.authorName}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();

    results.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final priority = b.priority.index.compareTo(a.priority.index);
      if (priority != 0) return priority;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return List<Announcement>.unmodifiable(results);
  }

  int get _activeFilterCount {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_categoryFilter != null) count++;
    if (_priorityFilter != null) count++;
    if (_readFilter != _ReadFilter.all) count++;
    if (_pinnedOnly) count++;
    return count;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _categoryFilter = null;
      _priorityFilter = null;
      _readFilter = _ReadFilter.all;
      _pinnedOnly = false;
    });
  }

  Future<void> _markAllAsRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    final success = await widget.controller.markAllAsRead(widget.user.id);
    if (!mounted) return;
    setState(() => _markingAll = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã đánh dấu tất cả thông báo là đã đọc.'
              : 'Chưa thể cập nhật trạng thái thông báo.',
        ),
      ),
    );
  }

  Future<void> _openDetail(Announcement announcement) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailPage(
          announcement: announcement,
          controller: widget.controller,
          user: widget.user,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _AnnouncementOverview extends StatelessWidget {
  const _AnnouncementOverview({
    required this.total,
    required this.unread,
    required this.pinned,
    required this.onMarkAllRead,
  });

  final int total;
  final int unread;
  final int pinned;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông báo cư dân',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Cập nhật thông tin mới nhất từ ban quản lý tòa nhà.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 650) return heading;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: heading),
                      OutlinedButton.icon(
                        onPressed: onMarkAllRead,
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('Đánh dấu tất cả đã đọc'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OverviewChip(
                    icon: Icons.notifications_outlined,
                    value: total,
                    label: 'Tổng thông báo',
                    color: AppColors.info,
                    background: AppColors.infoContainer,
                  ),
                  _OverviewChip(
                    icon: Icons.mark_email_unread_outlined,
                    value: unread,
                    label: 'Chưa đọc',
                    color: AppColors.error,
                    background: AppColors.errorContainer,
                  ),
                  _OverviewChip(
                    icon: Icons.push_pin_outlined,
                    value: pinned,
                    label: 'Đã ghim',
                    color: AppColors.warning,
                    background: AppColors.warningContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(spacing: 7, runSpacing: 7, children: children),
        ],
      ),
    );
  }
}

class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
