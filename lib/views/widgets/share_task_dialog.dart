import 'package:flutter/material.dart';
import 'package:buildables_neu_todo/core/app_colors.dart';
import 'package:buildables_neu_todo/services/email_service.dart';

enum ShareType { authenticated, anyone }

class ShareTaskDialog extends StatefulWidget {
  final Future<void> Function(
    String identifier,
    String name,
    ShareType type,
    String message,
  )
  onShare;
  final String taskTitle;

  const ShareTaskDialog({
    super.key,
    required this.onShare,
    required this.taskTitle,
  });

  @override
  State<ShareTaskDialog> createState() => _ShareTaskDialogState();
}

class _ShareTaskDialogState extends State<ShareTaskDialog>
    with TickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  ShareType _selectedShareType = ShareType.authenticated;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedShareType = _tabController.index == 0
            ? ShareType.authenticated
            : ShareType.anyone;
        _identifierController.clear();
        _nameController.clear();
        _messageController.clear();
      });
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final identifier = _identifierController.text.trim();
      final name = _nameController.text.trim();
      final message = _messageController.text.trim();

      await widget.onShare(
        identifier,
        name.isNotEmpty ? name : identifier,
        _selectedShareType,
        message,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar(identifier);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String identifier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✅ Task shared successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _selectedShareType == ShareType.anyone
                        ? '📧 Email sent to $identifier'
                        : '👤 Shared with app user: $identifier',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.error, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '❌ Failed to share task',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    error,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight - keyboardHeight - 100; // 100px for margins

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxWidth: 500, maxHeight: availableHeight),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: const Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SHARE TASK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.taskTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'App Users',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: const Icon(
                            Icons.email,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Anyone',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                indicator: BoxDecoration(
                  color: _selectedShareType == ShareType.authenticated
                      ? AppColors.accentGreen.withOpacity(0.2)
                      : AppColors.accentOrange.withOpacity(0.2),
                  border: const Border(
                    bottom: BorderSide(color: Colors.black, width: 3),
                  ),
                ),
              ),
            ),

            // Tab Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedShareType == ShareType.authenticated
                              ? AppColors.accentGreen.withOpacity(0.1)
                              : AppColors.accentOrange.withOpacity(0.1),
                          border: Border.all(
                            color: _selectedShareType == ShareType.authenticated
                                ? AppColors.accentGreen
                                : AppColors.accentOrange,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedShareType == ShareType.authenticated
                                  ? Icons.info_outline
                                  : Icons.email_outlined,
                              size: 16,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedShareType == ShareType.authenticated
                                    ? 'Share with existing app users by username or email'
                                    : 'Send email invitation to anyone, even non-users',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main input field
                      Text(
                        _selectedShareType == ShareType.authenticated
                            ? 'USERNAME OR EMAIL *'
                            : 'EMAIL ADDRESS *',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _identifierController,
                        keyboardType: _selectedShareType == ShareType.anyone
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        decoration: InputDecoration(
                          hintText:
                              _selectedShareType == ShareType.authenticated
                              ? 'john_doe or john@example.com'
                              : 'anyone@example.com',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  _selectedShareType == ShareType.authenticated
                                  ? AppColors.accentGreen
                                  : AppColors.accentOrange,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Icon(
                              _selectedShareType == ShareType.authenticated
                                  ? Icons.person
                                  : Icons.email,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _selectedShareType == ShareType.authenticated
                                ? 'Please enter a username or email'
                                : 'Please enter an email address';
                          }
                          if (_selectedShareType == ShareType.anyone &&
                              !EmailService().isValidEmail(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Name field (optional for anyone, not shown for authenticated)
                      if (_selectedShareType == ShareType.anyone) ...[
                        const Text(
                          'RECIPIENT NAME (OPTIONAL)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'John Doe',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accentPink,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 3,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],

                      // Message field
                      const Text(
                        'MESSAGE (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add a personal message...',
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(
                              Icons.message,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleShare,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? Colors.grey
                                      : (_selectedShareType ==
                                                ShareType.authenticated
                                            ? AppColors.accentGreen
                                            : AppColors.accentOrange),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isLoading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black,
                                            offset: const Offset(3, 3),
                                            blurRadius: 0,
                                          ),
                                        ],
                                ),
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'SHARING...',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _selectedShareType ==
                                                    ShareType.authenticated
                                                ? Icons.person_add
                                                : Icons.send,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedShareType ==
                                                    ShareType.authenticated
                                                ? 'SHARE TASK'
                                                : 'SEND INVITE',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
