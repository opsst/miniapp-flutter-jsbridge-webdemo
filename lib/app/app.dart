import 'package:flutter/material.dart';

import '../config/auth_config.dart';
import '../features/auth/auth_controller.dart';
import '../features/payment/payment_controller.dart';
import '../features/save_image/save_image_controller.dart';
import '../features/share/share_controller.dart';
import 'app_theme.dart';
import 'auth_section.dart';
import 'console_log.dart';
import 'console_panel.dart';
import 'payment_section.dart';
import 'save_image_section.dart';
import 'share_section.dart';

class App extends StatelessWidget {
  final AuthController authController;
  final AuthConfig authDefaults;
  final ShareController shareController;
  final SaveImageController saveImageController;
  final PaymentController paymentController;
  final ConsoleLogService consoleLog;

  const App({
    super.key,
    required this.authController,
    required this.authDefaults,
    required this.shareController,
    required this.saveImageController,
    required this.paymentController,
    required this.consoleLog,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JSBridge Test Console',
      theme: AppTheme.darkTheme,
      home: HomePage(
        authController: authController,
        authDefaults: authDefaults,
        shareController: shareController,
        saveImageController: saveImageController,
        paymentController: paymentController,
        consoleLog: consoleLog,
      ),
    );
  }
}

// ─── Navigation data model ─────────────────────────────────────
// Scales to 20+ methods. Adding a new bridge method only requires
// appending a _NavItem and a Widget builder case in _buildContent().

class _NavItem {
  final String id;
  final IconData icon;
  final String label;
  final String group;

  const _NavItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.group,
  });
}

// ─── Home page ─────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  final AuthController authController;
  final AuthConfig authDefaults;
  final ShareController shareController;
  final SaveImageController saveImageController;
  final PaymentController paymentController;
  final ConsoleLogService consoleLog;

  const HomePage({
    super.key,
    required this.authController,
    required this.authDefaults,
    required this.shareController,
    required this.saveImageController,
    required this.paymentController,
    required this.consoleLog,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedId = 'initAuth';
  bool _consoleExpanded = false;

  // ── Registry: add new bridge methods here ──
  static const _items = <_NavItem>[
    // Auth group
    _NavItem(id: 'initAuth', icon: Icons.key_rounded, label: 'initAuth', group: 'Authentication'),

    // Content group
    _NavItem(id: 'shareContent', icon: Icons.share_rounded, label: 'shareContent', group: 'Content'),
    _NavItem(id: 'saveImageToGallery', icon: Icons.image_rounded, label: 'saveImageToGallery', group: 'Content'),

    // Payment group
    _NavItem(id: 'openPayment', icon: Icons.payment_rounded, label: 'openPayment', group: 'Payment'),
  ];

  /// Builds content lazily — only the selected section is mounted.
  Widget _buildContent() {
    return switch (_selectedId) {
      'initAuth' => AuthSection(controller: widget.authController, defaults: widget.authDefaults),
      'shareContent' => ShareSection(controller: widget.shareController),
      'saveImageToGallery' => SaveImageSection(controller: widget.saveImageController),
      'openPayment' => PaymentSection(controller: widget.paymentController),
      _ => const Center(child: Text('Select a bridge method', style: TextStyle(color: AppTheme.textMuted))),
    };
  }

  void _selectItem(String id) {
    setState(() => _selectedId = id);
  }

  // Group items by their group name, preserving insertion order.
  // Cached so it doesn't recompute on every build.
  late final Map<String, List<_NavItem>> _groupedItems = () {
    final groups = <String, List<_NavItem>>{};
    for (final item in _items) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }
    return groups;
  }();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Desktop/tablet: sidebar. Mobile WebView (<720): dropdown picker.
    final isWide = screenWidth >= 720;

    return Scaffold(
      appBar: AppBar(
        // No hamburger on narrow screens — we use a dropdown instead.
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cable_rounded, size: 20, color: AppTheme.primary),
            const SizedBox(width: 10),
            const Text('JSBridge'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primary.withAlpha(60)),
              ),
              child: const Text(
                'Test Console',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Method count badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${_items.length} methods',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: isWide ? _buildWideLayout() : _buildNarrowLayout()),
          ConsolePanel(
            logService: widget.consoleLog,
            isExpanded: _consoleExpanded,
            onToggle: () => setState(() => _consoleExpanded = !_consoleExpanded),
          ),
        ],
      ),
    );
  }

  // ── Desktop / tablet: sidebar + content ──
  Widget _buildWideLayout() {
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceAlt,
              border: Border(right: BorderSide(color: AppTheme.border)),
            ),
            child: _SidebarContent(
              groupedItems: _groupedItems,
              selectedId: _selectedId,
              onSelect: _selectItem,
            ),
          ),
        ),
        Expanded(
          child: _ContentBody(
            key: ValueKey(_selectedId),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  // ── Mobile WebView: method picker dropdown + content ──
  //
  // Why a dropdown instead of Drawer/tabs:
  //  • 1-tap switch (no open+tap+close = 3 taps)
  //  • Scales to 20+ items with grouped popup menu
  //  • No overlay/animation = less GPU work in WebView
  //  • No Drawer scaffold overhead in the widget tree
  Widget _buildNarrowLayout() {
    final current = _items.firstWhere((i) => i.id == _selectedId, orElse: () => _items.first);

    return Column(
      children: [
        // ── Method picker bar ──
        Container(
          color: AppTheme.surfaceAlt,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showMethodPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Icon(current.icon, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      current.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Text(
                    current.group,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.unfold_more_rounded, size: 18, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        // ── Content ──
        Expanded(
          child: _ContentBody(
            key: ValueKey(_selectedId),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  /// Opens a bottom sheet with search + grouped method list.
  void _showMethodPicker(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      builder: (_) => _MethodPickerSheet(
        items: _items,
        selectedId: _selectedId,
      ),
    ).then((id) {
      if (id != null) _selectItem(id);
    });
  }
}

// ─── Bottom sheet with search ──────────────────────────────────

class _MethodPickerSheet extends StatefulWidget {
  final List<_NavItem> items;
  final String selectedId;

  const _MethodPickerSheet({
    required this.items,
    required this.selectedId,
  });

  @override
  State<_MethodPickerSheet> createState() => _MethodPickerSheetState();
}

class _MethodPickerSheetState extends State<_MethodPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters items by query, matching against label and group.
  Map<String, List<_NavItem>> get _filteredGroups {
    final q = _query.toLowerCase();
    final groups = <String, List<_NavItem>>{};
    for (final item in widget.items) {
      if (q.isNotEmpty &&
          !item.label.toLowerCase().contains(q) &&
          !item.group.toLowerCase().contains(q)) {
        continue;
      }
      groups.putIfAbsent(item.group, () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _filteredGroups;
    final totalMatches = groups.values.fold<int>(0, (sum, list) => sum + list.length);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search methods...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 1),
          // Results
          if (totalMatches == 0)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No methods matching "$_query"',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    for (final item in entry.value)
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          item.icon,
                          size: 18,
                          color: item.id == widget.selectedId ? AppTheme.primary : AppTheme.textMuted,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.id == widget.selectedId ? FontWeight.w600 : FontWeight.w400,
                            color: item.id == widget.selectedId ? AppTheme.primary : AppTheme.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        trailing: item.id == widget.selectedId
                            ? const Icon(Icons.check_rounded, size: 18, color: AppTheme.primary)
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () => Navigator.pop(context, item.id),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sidebar (desktop/tablet only) ─────────────────────────────

class _SidebarContent extends StatefulWidget {
  final Map<String, List<_NavItem>> groupedItems;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _SidebarContent({
    required this.groupedItems,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_SidebarContent> createState() => _SidebarContentState();
}

class _SidebarContentState extends State<_SidebarContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<_NavItem>> get _filteredGroups {
    if (_query.isEmpty) return widget.groupedItems;
    final q = _query.toLowerCase();
    final groups = <String, List<_NavItem>>{};
    for (final entry in widget.groupedItems.entries) {
      final matches = entry.value
          .where((item) =>
              item.label.toLowerCase().contains(q) ||
              item.group.toLowerCase().contains(q))
          .toList();
      if (matches.isNotEmpty) groups[entry.key] = matches;
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _filteredGroups;

    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const Divider(height: 1),
        // Grouped list
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No matches for "$_query"',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      for (final item in entry.value)
                        _SidebarItem(
                          item: item,
                          isSelected: item.id == widget.selectedId,
                          onTap: () => widget.onSelect(item.id),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected ? AppTheme.primary.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: AppTheme.primary.withAlpha(40)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Content wrapper ───────────────────────────────────────────

class _ContentBody extends StatelessWidget {
  final Widget child;

  const _ContentBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: child,
        ),
      ),
    );
  }
}
