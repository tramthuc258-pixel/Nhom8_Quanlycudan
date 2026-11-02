import 'package:flutter/material.dart';

import 'package:homie/core/theme/app_colors.dart';
import 'package:homie/core/widgets/empty_view.dart';
import 'package:homie/core/widgets/error_view.dart';
import 'package:homie/core/widgets/loading_view.dart';
import 'package:homie/features/housing/controllers/housing_controller.dart';
import 'package:homie/features/housing/models/housing_listing.dart';
import 'package:homie/features/housing/models/housing_transaction_type.dart';
import 'package:homie/features/housing/widgets/housing_listing_widgets.dart';

class PublicHousingPage extends StatefulWidget {
  const PublicHousingPage({
    required this.controller,
    required this.onResidentLogin,
    super.key,
  });

  final HousingController controller;
  final VoidCallback onResidentLogin;

  @override
  State<PublicHousingPage> createState() => _PublicHousingPageState();
}

class _PublicHousingPageState extends State<PublicHousingPage> {
  final TextEditingController _searchController = TextEditingController();
  HousingTransactionType? _transactionType;
  bool _waitingForFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant PublicHousingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _waitingForFirstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    await widget.controller.loadPublic();
    if (mounted) setState(() => _waitingForFirstLoad = false);
  }

  List<HousingListing> _filteredListings() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.publicListings
        .where((listing) {
          if (_transactionType != null &&
              listing.transactionType != _transactionType) {
            return false;
          }
          if (query.isEmpty) return true;
          return listing.apartmentCode.toLowerCase().contains(query) ||
              listing.buildingName.toLowerCase().contains(query) ||
              listing.title.toLowerCase().contains(query) ||
              listing.description.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.home_work_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Homie'),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              key: const ValueKey<String>('resident-login-button'),
              onPressed: widget.onResidentLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập cư dân'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (_waitingForFirstLoad ||
              (widget.controller.isLoading &&
                  widget.controller.allListings.isEmpty)) {
            return const LoadingView(message: 'Đang tải căn hộ nổi bật…');
          }
          if (widget.controller.errorMessage != null &&
              widget.controller.allListings.isEmpty) {
            return ErrorView(
              title: 'Không thể tải danh sách căn hộ',
              message: widget.controller.errorMessage,
              onRetry: _load,
            );
          }
          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final listings = _filteredListings();
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverToBoxAdapter(child: _buildFilters(context)),
          if (widget.controller.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          if (listings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.apartment_outlined,
                title: 'Chưa tìm thấy căn hộ phù hợp',
                message: 'Hãy thay đổi từ khóa hoặc loại giao dịch.',
                actionLabel: 'Xóa bộ lọc',
                onAction: () {
                  _searchController.clear();
                  setState(() => _transactionType = null);
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent >= 1120
                      ? 3
                      : constraints.crossAxisExtent >= 720
                      ? 2
                      : 1;
                  return SliverGrid.builder(
                    itemCount: listings.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 550,
                    ),
                    itemBuilder: (context, index) {
                      final listing = listings[index];
                      return HousingListingCard(
                        listing: listing,
                        onView: () => showHousingListingDetailSheet(
                          context,
                          listing: listing,
                        ),
                        onApply: () => _openInquiry(listing),
                        applyLabel: 'Gửi yêu cầu',
                        applyIcon: Icons.contact_phone_outlined,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF174EB8), Color(0xFF2877EC)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 18,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Khám phá không gian sống tại Homie',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Khách có thể xem các căn hộ đang bán hoặc cho thuê mà không cần tạo tài khoản.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFDDEAFF),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: widget.onResidentLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            icon: const Icon(Icons.badge_outlined),
            label: const Text('Tôi là cư dân'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 360,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm theo căn hộ, tòa nhà hoặc tiêu đề',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: _transactionType == null,
            onSelected: (_) => setState(() => _transactionType = null),
          ),
          ChoiceChip(
            label: const Text('Cho thuê'),
            selected: _transactionType == HousingTransactionType.rent,
            onSelected: (_) =>
                setState(() => _transactionType = HousingTransactionType.rent),
          ),
          ChoiceChip(
            label: const Text('Đang bán'),
            selected: _transactionType == HousingTransactionType.purchase,
            onSelected: (_) => setState(
              () => _transactionType = HousingTransactionType.purchase,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInquiry(HousingListing listing) async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _GuestInquiryDialog(controller: widget.controller, listing: listing),
    );
    if (!mounted || sent != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu. Ban quản lý sẽ liên hệ qua thông tin bạn cung cấp.',
          ),
        ),
      );
  }
}

class _GuestInquiryDialog extends StatefulWidget {
  const _GuestInquiryDialog({required this.controller, required this.listing});

  final HousingController controller;
  final HousingListing listing;

  @override
  State<_GuestInquiryDialog> createState() => _GuestInquiryDialogState();
}

class _GuestInquiryDialogState extends State<_GuestInquiryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final success = await widget.controller.submitPublicInquiry(
      listingId: widget.listing.id,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      message: _messageController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _errorMessage =
          widget.controller.errorMessage ?? 'Không thể gửi yêu cầu lúc này.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gửi yêu cầu tư vấn'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${widget.listing.apartmentCode} • ${widget.listing.title}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  key: const ValueKey<String>('guest-inquiry-full-name'),
                  controller: _fullNameController,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Vui lòng nhập họ và tên.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('guest-inquiry-phone'),
                  controller: _phoneController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    return RegExp(r'^[0-9+\s.-]{8,20}$').hasMatch(phone)
                        ? null
                        : 'Số điện thoại chưa đúng định dạng.';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('guest-inquiry-email'),
                  controller: _emailController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (không bắt buộc)',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return null;
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                        ? null
                        : 'Email chưa đúng định dạng.';
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey<String>('guest-inquiry-message'),
                  controller: _messageController,
                  enabled: !_submitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung muốn trao đổi',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('submit-guest-inquiry'),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_submitting ? 'Đang gửi…' : 'Gửi yêu cầu'),
        ),
      ],
    );
  }
}
