import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:watchiot/core/app_theme.dart';
import 'package:watchiot/features/emergency/domain/entities/family_contact.dart';
import 'package:watchiot/features/emergency/presentation/providers/emergency_monitor_provider.dart';

class EmergencySettingsView extends StatefulWidget {
  const EmergencySettingsView({super.key, required this.onTargetChanged});

  final Future<bool> Function(String databaseUrl, String deviceUid)
  onTargetChanged;

  @override
  State<EmergencySettingsView> createState() => _EmergencySettingsViewState();
}

class _EmergencySettingsViewState extends State<EmergencySettingsView> {
  late final TextEditingController _databaseUrlController;
  late final TextEditingController _deviceUidController;
  bool _hideUid = true;
  bool _savingTarget = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<EmergencyMonitorProvider>().settings;
    _databaseUrlController = TextEditingController(text: settings.databaseUrl);
    _deviceUidController = TextEditingController(text: settings.deviceUid);
  }

  @override
  void dispose() {
    _databaseUrlController.dispose();
    _deviceUidController.dispose();
    super.dispose();
  }

  Future<void> _saveTarget() async {
    setState(() => _savingTarget = true);
    final saved = await widget.onTargetChanged(
      _databaseUrlController.text,
      _deviceUidController.text,
    );
    if (!mounted) return;
    setState(() => _savingTarget = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Đã lưu cấu hình Firebase và DEVICE_UID.'
              : context.read<EmergencyMonitorProvider>().settingsError ??
                    'Không lưu được cấu hình. Hãy kiểm tra lại thông tin.',
        ),
      ),
    );
  }

  Future<void> _addContact() async {
    final contact = await showDialog<FamilyContact>(
      context: context,
      builder: (_) => const _ContactEditorDialog(),
    );
    if (contact == null || !mounted) return;
    final provider = context.read<EmergencyMonitorProvider>();
    await provider.updateContacts([...provider.settings.contacts, contact]);
  }

  Future<void> _editContact(FamilyContact contact) async {
    final edited = await showDialog<FamilyContact>(
      context: context,
      builder: (_) => _ContactEditorDialog(initialContact: contact),
    );
    if (edited == null || !mounted) return;
    final provider = context.read<EmergencyMonitorProvider>();
    final contacts = provider.settings.contacts
        .map((current) => current.id == edited.id ? edited : current)
        .toList(growable: false);
    await provider.updateContacts(contacts);
  }

  Future<void> _removeContact(FamilyContact contact) async {
    final provider = context.read<EmergencyMonitorProvider>();
    final contacts = provider.settings.contacts
        .where((current) => current.id != contact.id)
        .toList(growable: false);
    await provider.updateContacts(contacts);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyMonitorProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt an toàn')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            const _SettingsIntro(),
            const SizedBox(height: 16),
            _SettingsSection(
              icon: Icons.storage_rounded,
              title: 'Firebase Realtime Database',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _databaseUrlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Database URL',
                      hintText: 'https://project-default-rtdb.firebaseio.com/',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deviceUidController,
                    obscureText: _hideUid,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: 'DEVICE_UID của firmware',
                      hintText: 'Nhập UID tài khoản Firebase trên ESP32',
                      prefixIcon: const Icon(Icons.watch_rounded),
                      suffixIcon: IconButton(
                        tooltip: _hideUid ? 'Hiện UID' : 'Ẩn UID',
                        onPressed: () => setState(() => _hideUid = !_hideUid),
                        icon: Icon(
                          _hideUid
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'DEVICE_UID là UID Firebase mà ESP32 dùng để ghi dữ liệu; không tự lấy UID tài khoản đang đăng nhập app.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _ConnectionStatus(
                    connected: provider.isFirebaseConnected,
                    isLoading: provider.isAlertLoading,
                    error: provider.databaseError,
                  ),
                  if (provider.settingsError != null) ...[
                    const SizedBox(height: 8),
                    _InlineMessage(
                      message: provider.settingsError!,
                      color: AppColors.danger,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Đường dẫn theo dõi: ${provider.alertPath}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _savingTarget ? null : _saveTarget,
                      icon: _savingTarget
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Lưu cấu hình'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              icon: Icons.people_alt_rounded,
              title: 'Người thân cần liên hệ',
              trailing: IconButton.filledTonal(
                tooltip: 'Thêm người thân',
                onPressed: _addContact,
                icon: const Icon(Icons.add_rounded),
              ),
              child: settings.contacts.isEmpty
                  ? const _InlineMessage(
                      message: 'Thêm ít nhất một người thân trước khi bật gọi.',
                      color: AppColors.warning,
                    )
                  : Column(
                      children: [
                        for (final contact in settings.contacts)
                          _ContactTile(
                            contact: contact,
                            onEdit: () => _editContact(contact),
                            onRemove: () => _removeContact(contact),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              icon: Icons.call_rounded,
              title: 'Quyền gọi người thân',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: settings.allowCallWhenConfirmed,
                    onChanged: provider.canEnableCalls
                        ? provider.setAllowCallWhenConfirmed
                        : null,
                    title: const Text(
                      'Cho phép gọi khi xác nhận té ngã',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      settings.allowCallWhenConfirmed
                          ? 'Bật: app sẽ hiện nút gọi sau cảnh báo hợp lệ.'
                          : 'Đang tắt. App không tự thực hiện cuộc gọi.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (!provider.canEnableCalls)
                    const _InlineMessage(
                      message:
                          'Hoàn tất URL Firebase, DEVICE_UID và ít nhất một người thân để bật tính năng này.',
                      color: AppColors.warning,
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Khi nhấn gọi, Android mở trình quay số; iOS yêu cầu xác nhận trước khi gọi. App không gọi âm thầm.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _BackgroundNotice(),
          ],
        ),
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thiết lập nơi nhận cảnh báo và số liên hệ trước khi bật tính năng gọi.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: AppColors.outline),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.warning, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({
    required this.connected,
    required this.isLoading,
    required this.error,
  });

  final bool? connected;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final color = error != null
        ? AppColors.danger
        : connected == true
        ? AppColors.success
        : AppColors.warning;
    final label = error != null
        ? 'Không đọc được dữ liệu'
        : connected == true
        ? 'Đã kết nối'
        : isLoading
        ? 'Đang kết nối…'
        : 'Mất kết nối';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            connected == true && error == null
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isLoading && connected != true)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onRemove,
  });

  final FamilyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 9, 4, 9),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, color: AppColors.muted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    contact.phoneNumber,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sửa người thân',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 17),
            ),
            IconButton(
              tooltip: 'Xóa người thân',
              onPressed: onRemove,
              color: AppColors.danger,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 17, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: color, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _BackgroundNotice extends StatelessWidget {
  const _BackgroundNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Text(
        'Theo dõi Realtime Database hoạt động khi app đang chạy. Khi app bị hệ điều hành dừng hoặc đưa xuống nền lâu, cần thêm Cloud Functions gửi FCM để nhận thông báo ổn định. Android/iOS vẫn có thể giới hạn xử lý nền.',
        style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.45),
      ),
    );
  }
}

class _ContactEditorDialog extends StatefulWidget {
  const _ContactEditorDialog({this.initialContact});

  final FamilyContact? initialContact;

  @override
  State<_ContactEditorDialog> createState() => _ContactEditorDialogState();
}

class _ContactEditorDialogState extends State<_ContactEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialContact?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialContact?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = normalizePhoneNumber(_phoneController.text);
    if (name.isEmpty) {
      setState(() => _validationMessage = 'Nhập tên người thân.');
      return;
    }
    if (!isValidPhoneNumber(phone)) {
      setState(() => _validationMessage = 'Nhập số điện thoại hợp lệ.');
      return;
    }
    Navigator.pop(
      context,
      FamilyContact(
        id:
            widget.initialContact?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        phoneNumber: phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      scrollable: true,
      title: Text(
        widget.initialContact == null ? 'Thêm người thân' : 'Sửa người thân',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tên người thân',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              hintText: '+84…',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_validationMessage != null) ...[
            const SizedBox(height: 9),
            _InlineMessage(
              message: _validationMessage!,
              color: AppColors.danger,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}
