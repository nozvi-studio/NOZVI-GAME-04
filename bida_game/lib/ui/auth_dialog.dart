import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/progression_service.dart';
import '../services/language_service.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _forceShowAuthForms = false;

  // Controllers cho Đăng nhập
  final _loginAccountController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Controllers cho Đăng ký
  final _regNameController = TextEditingController();
  final _regAccountController = TextEditingController();
  final _regPasswordController = TextEditingController();

  // FocusNodes để tránh bị mất focus và giật bàn phím trên mobile
  final _loginAccountFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  final _regNameFocus = FocusNode();
  final _regAccountFocus = FocusNode();
  final _regPasswordFocus = FocusNode();

  String? _errorMessage;
  String? _successMessage;
  bool _obscureLoginPass = true;
  bool _obscureRegPass = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginAccountController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regAccountController.dispose();
    _regPasswordController.dispose();

    _loginAccountFocus.dispose();
    _loginPasswordFocus.dispose();
    _regNameFocus.dispose();
    _regAccountFocus.dispose();
    _regPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final account = _loginAccountController.text.trim();
    final pass = _loginPasswordController.text;

    if (account.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'auth_fill_account_pass'.tr);
      return;
    }

    final error = await AuthService.instance.login(
      emailOrUsername: account,
      password: pass,
    );

    if (mounted) {
      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        setState(() => _successMessage = 'login_success_welcome'.tr.replaceAll('{name}', AuthService.instance.displayName));
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final name = _regNameController.text.trim();
    final account = _regAccountController.text.trim();
    final pass = _regPasswordController.text;

    if (name.isEmpty || account.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'auth_fill_all'.tr);
      return;
    }

    final error = await AuthService.instance.register(
      emailOrUsername: account,
      password: pass,
      displayName: name,
    );

    if (mounted) {
      if (error != null) {
        setState(() => _errorMessage = error);
      } else {
        setState(() => _successMessage = 'register_success'.tr);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 50;
    final isCompact = screenHeight <= 420;

    // Chiều cao tự thích ứng khi bàn phím mở tránh bị tràn/ép 0px
    final dialogMaxHeight = isKeyboardOpen
        ? (screenHeight - bottomInset - 16).clamp(180.0, 360.0)
        : math.min(screenHeight * 0.94, isCompact ? 340.0 : 460.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isKeyboardOpen ? 4 : 8,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: dialogMaxHeight,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F241C), Color(0xFF132F25), Color(0xFF081410)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF26A69A).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ListenableBuilder(
            listenable: Listenable.merge([auth, LanguageService.instance]),
            builder: (context, _) {
              if (auth.isLoggedIn && !_forceShowAuthForms && !auth.isGuest) {
                return _buildLoggedInView(auth, isCompact);
              }
              if (auth.isLoggedIn && !_forceShowAuthForms && auth.isGuest) {
                return _buildGuestProfileView(auth, isCompact);
              }
              return _buildAuthFormsView(auth, isCompact);
            },
          ),
        ),
      ),
    );
  }

  /// Màn hình khi đã đăng nhập chính thức
  Widget _buildLoggedInView(AuthService auth, bool isCompact) {
    final prog = ProgressionService.instance;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF081410),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_circle, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 8),
              Text(
                'account_info_title'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 10 : 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isCompact ? 26 : 32,
                  backgroundColor: auth.isAdmin ? const Color(0xFFFFB300) : const Color(0xFF00B0FF),
                  child: Icon(
                    auth.isAdmin ? Icons.shield : Icons.person,
                    size: isCompact ? 28 : 34,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (auth.currentUser?.email != null)
                  Text(
                    auth.currentUser!.email!,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                const SizedBox(height: 6),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: auth.isAdmin
                        ? const Color(0xFFFFB300).withValues(alpha: 0.2)
                        : const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: auth.isAdmin ? const Color(0xFFFFB300) : const Color(0xFF00E676),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.isAdmin ? Icons.verified_user : Icons.sports_esports,
                        size: 12,
                        color: auth.isAdmin ? const Color(0xFFFFB300) : const Color(0xFF00E676),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auth.isAdmin ? 'admin_role'.tr : 'member_role'.tr,
                        style: TextStyle(
                          color: auth.isAdmin ? const Color(0xFFFFB300) : const Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Thống kê
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('level'.tr.toUpperCase(), 'Lv.${prog.playerLevel}', Colors.amber),
                      _buildStatColumn('coins'.tr.toUpperCase(), '${prog.coins}', const Color(0xFFFFD54F)),
                      _buildStatColumn('wins'.tr.toUpperCase(), '${prog.totalWins}', const Color(0xFF00E676)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Đăng xuất
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFFFF5252), size: 16),
                    label: Text(
                      'logout'.tr.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF5252)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Màn hình khi đang chơi chế độ Khách (Guest)
  Widget _buildGuestProfileView(AuthService auth, bool isCompact) {
    final prog = ProgressionService.instance;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF081410),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, color: Color(0xFFFFB300), size: 18),
              const SizedBox(width: 8),
              Text(
                'guest_account_title'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 10 : 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isCompact ? 24 : 28,
                  backgroundColor: const Color(0xFF2E4038),
                  child: const Icon(Icons.person_outline, size: 30, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  auth.displayName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  'guest_account_desc'.tr,
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
                const SizedBox(height: 10),

                // Thống kê
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('level'.tr.toUpperCase(), 'Lv.${prog.playerLevel}', Colors.amber),
                      _buildStatColumn('coins'.tr.toUpperCase(), '${prog.coins}', const Color(0xFFFFD54F)),
                      _buildStatColumn('wins'.tr.toUpperCase(), '${prog.totalWins}', const Color(0xFF00E676)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Đăng nhập / Đăng ký để lưu Cloud
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => _forceShowAuthForms = true),
                    icon: const Icon(Icons.cloud_upload, size: 16),
                    label: Text(
                      'login_save_cloud_btn'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Đăng xuất
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: TextButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.logout, color: Colors.white60, size: 15),
                    label: Text(
                      'leave_guest_mode_btn'.tr,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  /// Màn hình biểu mẫu Đăng nhập / Đăng ký trong Dialog
  Widget _buildAuthFormsView(AuthService auth, bool isCompact) {
    return Column(
      children: [
        // Tab Header
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF081410),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 2),
                child: Row(
                  children: [
                    if (_forceShowAuthForms)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                        onPressed: () => setState(() => _forceShowAuthForms = false),
                      ),
                    if (_forceShowAuthForms) const SizedBox(width: 8),
                    const Icon(Icons.sports_esports, color: Color(0xFF00E676), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'firebase_account_title'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00E676),
                labelColor: const Color(0xFF00E676),
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: 'login_tab'.tr),
                  Tab(text: 'register_tab'.tr),
                ],
              ),
            ],
          ),
        ),

        // Message alerts
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            color: const Color(0xFFD32F2F).withValues(alpha: 0.9),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    LanguageService.instance.localizeAuthError(_errorMessage!),
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        if (_successMessage != null)
          Container(
            width: double.infinity,
            color: const Color(0xFF2E7D32).withValues(alpha: 0.9),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Body Tab - dùng AnimatedBuilder thay cho TabBarView để tránh lỗi layout collapse khi bàn phím xuất hiện
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return _tabController.index == 0
                  ? _buildLoginForm(auth)
                  : _buildRegisterForm(auth);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthService auth) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 38),
            child: TextField(
              controller: _loginAccountController,
              focusNode: _loginAccountFocus,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              scrollPadding: const EdgeInsets.only(bottom: 16),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _loginPasswordFocus.requestFocus(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'account_field'.tr,
                hintText: 'player01 / email@gmail.com',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF00E676), size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 38),
            child: TextField(
              controller: _loginPasswordController,
              focusNode: _loginPasswordFocus,
              obscureText: _obscureLoginPass,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              scrollPadding: const EdgeInsets.only(bottom: 16),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'password_field'.tr,
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF00E676), size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                suffixIcon: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _obscureLoginPass ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white54,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: auth.isLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: auth.isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                  : Text('login_now_btn'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthService auth) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 38),
            child: TextField(
              controller: _regNameController,
              focusNode: _regNameFocus,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              autocorrect: false,
              enableSuggestions: false,
              scrollPadding: const EdgeInsets.only(bottom: 16),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _regAccountFocus.requestFocus(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'display_name_field'.tr,
                hintText: 'Pro Player',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                prefixIcon: const Icon(Icons.badge, color: Color(0xFF00B0FF), size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 38),
            child: TextField(
              controller: _regAccountController,
              focusNode: _regAccountFocus,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              scrollPadding: const EdgeInsets.only(bottom: 16),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _regPasswordFocus.requestFocus(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'account_field'.tr,
                hintText: 'player01 / email@gmail.com',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                prefixIcon: const Icon(Icons.person_add, color: Color(0xFF00B0FF), size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 38),
            child: TextField(
              controller: _regPasswordController,
              focusNode: _regPasswordFocus,
              obscureText: _obscureRegPass,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              scrollPadding: const EdgeInsets.only(bottom: 16),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'password_min_chars'.tr,
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00B0FF), size: 16),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                suffixIcon: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _obscureRegPass ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white54,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: auth.isLoading ? null : _handleRegister,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00B0FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: auth.isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('create_account_btn'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
