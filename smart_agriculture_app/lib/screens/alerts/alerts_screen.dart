import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/alert.dart';
import '../../services/session_service.dart';
import '../../widgets/alert_style.dart';
import '../../widgets/farm_background.dart';
import '../../widgets/date_formats.dart';
import '../../widgets/empty_state.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = [];
  List<Alert> _filtered = [];
  String _filter = 'All';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SessionService.instance.userId;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final alerts = await DatabaseHelper.instance.getAlerts(userId);
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_filter == 'All') {
      _filtered = List.of(_alerts);
    } else {
      _filtered = _alerts.where((a) => a.type == _filter).toList();
    }
  }

  int get _unreadCount => _alerts.where((a) => !a.isRead).length;

  Future<void> _markRead(Alert alert) async {
    if (alert.isRead) return;
    await DatabaseHelper.instance.markAlertRead(alert.id!);
    _load();
  }

  Future<void> _markAllRead() async {
    await DatabaseHelper.instance.database.then((db) async {
      final userId = SessionService.instance.userId;
      if (userId == null) return;
      await db.update(
        'alerts',
        {'isRead': 1},
        where: 'userId = ? AND isRead = 0',
        whereArgs: [userId],
      );
    });
    _load();
  }

  Future<void> _delete(Alert alert) async {
    await DatabaseHelper.instance.deleteAlert(alert.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Alert deleted')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.sunset,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Smart Alerts'),
          actions: [
            if (_unreadCount > 0)
              IconButton(
                onPressed: _markAllRead,
                tooltip: 'Mark all as read',
                icon: const Icon(Icons.done_all, color: AppColors.green),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: _load,
                child: _alerts.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: const EmptyState(
                            icon: Icons.notifications_active,
                            title: 'No Alerts Yet',
                            message:
                                'Smart alerts will appear here when important '
                                'farming conditions are detected.',
                          ),
                        ),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: [
                          _buildSummary(context),
                          const SizedBox(height: 14),
                          _buildFilterChips(),
                          const SizedBox(height: 14),
                          if (_filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'No alerts of this type.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textGrey),
                              ),
                            )
                          else
                            for (final alert in _filtered)
                              _alertCard(context, alert),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.green],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _unreadCount == 0
                      ? 'All caught up!'
                      : '$_unreadCount unread alert${_unreadCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stay informed about your farm conditions',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', ...AlertStyle.types];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final type in filters) ...[
            ChoiceChip(
              label: Text(type == 'All' ? 'All' : AlertStyle.emoji(type)),
              selected: _filter == type,
              onSelected: (_) {
                setState(() {
                  _filter = type;
                  _applyFilter();
                });
              },
              selectedColor: AppColors.green,
              backgroundColor: AppColors.white,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _filter == type ? AppColors.white : AppColors.textGrey,
              ),
              showCheckmark: false,
              side: BorderSide(
                color: _filter == type
                    ? AppColors.green
                    : const Color(0xFFCFE3D0),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _alertCard(BuildContext context, Alert alert) {
    final color = AlertStyle.color(alert.type);
    return Dismissible(
      key: ValueKey('alert-${alert.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      onDismissed: (_) => _delete(alert),
      child: InkWell(
        onTap: () => _markRead(alert),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: alert.isRead
                ? AppColors.white.withValues(alpha: 0.75)
                : AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: alert.isRead
                  ? Colors.transparent
                  : color.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  AlertStyle.icon(alert.type),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: alert.isRead
                                  ? AppColors.textGrey
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormats.timeAgo(alert.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: alert.isRead
                            ? AppColors.textGrey
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${AlertStyle.emoji(alert.type)} ${alert.type}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!alert.isRead)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
