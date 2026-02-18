import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../blocs/profile_cubit.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../../core/utils/logger.dart';
import 'edit_profile_page.dart';

const Color _primaryBlue = Color(0xFF2859E2);

class ProfilePage extends StatefulWidget {
  final bool sliverMode;
  const ProfilePage({super.key, this.sliverMode = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().getProfile();
  }

  void _handleLogout() {
    final authBloc = context.read<AuthBloc>();
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Logout'),
            onPressed: () {
              Navigator.pop(dialogContext);
              authBloc.add(LogoutRequested());
            },
          ),
        ],
      ),
    );
  }

  void _handleLogoutAllDevices() {
    final authBloc = context.read<AuthBloc>();
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Logout from all devices'),
        content: const Text(
          'This will invalidate all active sessions. You will need to login again on all devices.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Logout All'),
            onPressed: () {
              Navigator.pop(dialogContext);
              authBloc.add(LogoutAllDevicesRequested());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return widget.sliverMode
                ? const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                : const Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: CupertinoActivityIndicator()),
                  );
          }
          if (state is ProfileError) {
            return widget.sliverMode
                ? SliverFillRemaining(child: Center(child: Text(state.message)))
                : Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(child: Text(state.message)),
                  );
          }
          if (state is ProfileLoaded) {
            final user = state.user;
            if (widget.sliverMode) {
              return _buildSliverContent(user);
            }

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'My Profile',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body: _buildListContent(user),
            );
          }
          return widget.sliverMode
              ? const SliverFillRemaining(
                  child: Center(child: Text('Loading profile...')),
                )
              : const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(child: Text('Loading profile...')),
                );
        },
      ),
    );
  }

  Widget _buildSliverContent(dynamic user) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildProfileInfo(user),
          const SizedBox(height: 16),
          _buildStaffDetailsCard(user),
          const SizedBox(height: 32),
          _buildLogoutButton(),
          const SizedBox(height: 120),
        ]),
      ),
    );
  }

  Widget _buildListContent(dynamic user) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildProfileHeader(user),
        const SizedBox(height: 24),
        _buildProfileInfo(user),
        const SizedBox(height: 16),
        _buildStaffDetailsCard(user),
        const SizedBox(height: 32),
        _buildLogoutButton(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return FadeInDown(
      child: Center(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryBlue, width: 3),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFE8F1FF),
                backgroundImage: user.photoProfile != null
                    ? NetworkImage(user.photoProfile!)
                    : null,
                onBackgroundImageError: user.photoProfile != null
                    ? (exception, stackTrace) {
                        AppLogger.error(
                          'Failed to load profile image',
                          exception,
                        );
                      }
                    : null,
                child: user.photoProfile == null
                    ? Text(
                        _getUserInitials(user.name),
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2859E2),
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => EditProfilePage(user: user),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(dynamic user) {
    return FadeInDown(
      delay: const Duration(milliseconds: 100),
      child: Center(
        child: Column(
          children: [
            Text(
              user.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: GoogleFonts.outfit(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuTile(
              CupertinoIcons.device_phone_portrait,
              'Logout from all devices',
              isDestructive: true,
              onTap: _handleLogoutAllDevices,
            ),
            _buildDivider(),
            _buildMenuTile(
              CupertinoIcons.square_arrow_right,
              'Logout',
              isDestructive: true,
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200], indent: 56);
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : _primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : _primaryBlue,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: isDestructive ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: Colors.grey[400],
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildStaffDetailsCard(dynamic user) {
    return FadeInDown(
      delay: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDetailInfoRow(CupertinoIcons.person, 'Full Name', user.name),
            _buildDividerDetail(),
            _buildDetailInfoRow(
              _getRoleIcon(user.role),
              'Role',
              user.role.toUpperCase(),
              valueColor: _primaryBlue,
            ),
            _buildDividerDetail(),
            _buildDetailInfoRow(
              CupertinoIcons.number,
              'Staff ID / NIP',
              user.staffId ?? 'STF-001',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryBlue, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDividerDetail() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey[100], indent: 44),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return CupertinoIcons.shield_fill;
      case 'doctor':
        return CupertinoIcons.person_badge_plus;
      default:
        return CupertinoIcons.briefcase;
    }
  }
}
