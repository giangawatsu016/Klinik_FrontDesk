import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../payment/presentation/pages/payment_book_page.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../blocs/profile_cubit.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import 'edit_profile_page.dart';
import 'reset_password_page.dart';
import 'account_settings_page.dart';

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

  void _launchWhatsApp() async {
    final phone = "6287778102233";
    final message = "Hi Intimedicare, I need help with...";
    final whatsappUrl = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
    );
    final universalUrl = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else if (await canLaunchUrl(universalUrl)) {
        await launchUrl(universalUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    } catch (e) {
      // Fallback to browser if everything else fails
      await launchUrl(universalUrl, mode: LaunchMode.externalApplication);
    }
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
            final tier = _getTier(user.tier);
            final isSerenity = tier == UserTier.serenity;

            if (widget.sliverMode) {
              return _buildSliverContent(user, tier, isSerenity);
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
              body: _buildListContent(user, tier, isSerenity),
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

  Widget _buildSliverContent(dynamic user, UserTier tier, bool isSerenity) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildProfileInfo(user),
          const SizedBox(height: 32),
          _buildTierCard(user, isSerenity),
          const SizedBox(height: 32),
          _buildMenuSection(),
          const SizedBox(height: 24),
          _buildLogoutButton(),
          const SizedBox(height: 120),
        ]),
      ),
    );
  }

  Widget _buildListContent(dynamic user, UserTier tier, bool isSerenity) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildProfileHeader(user),
        const SizedBox(height: 24),
        _buildProfileInfo(user),
        const SizedBox(height: 32),
        _buildTierCard(user, isSerenity),
        const SizedBox(height: 32),
        _buildMenuSection(),
        const SizedBox(height: 24),
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
                backgroundColor: Colors.grey[200],
                backgroundImage: user.photoProfile != null
                    ? NetworkImage(user.photoProfile!)
                    : null,
                child: user.photoProfile == null
                    ? Icon(
                        CupertinoIcons.person_fill,
                        size: 60,
                        color: Colors.grey[400],
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

  Widget _buildTierCard(dynamic user, bool isSerenity) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: isSerenity
          ? LiquidGlassCard(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTierInfo(user.tier, isSerenity),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _buildTierInfo(user.tier, isSerenity),
            ),
    );
  }

  Widget _buildMenuSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
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
          children: [
            _buildMenuTile(
              CupertinoIcons.clock,
              'Payment Book',
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const PaymentBookPage(),
                ),
              ),
            ),
            _buildDivider(),
            _buildMenuTile(
              CupertinoIcons.lock,
              'Reset Password',
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const ResetPasswordPage(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuTile(
              CupertinoIcons.gear,
              'Account Settings',
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const AccountSettingsPage(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuTile(
              CupertinoIcons.question_circle,
              'Help & Support',
              onTap: () => _launchWhatsApp(),
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
        child: _buildMenuTile(
          CupertinoIcons.square_arrow_right,
          'Logout',
          isDestructive: true,
          onTap: _handleLogout,
        ),
      ),
    );
  }

  UserTier _getTier(String tierStr) {
    if (tierStr == 'MEDIUM') return UserTier.comfort;
    if (tierStr == 'PREMIUM') return UserTier.serenity;
    return UserTier.care;
  }

  Widget _buildTierInfo(String tier, bool isSerenity) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.star_fill,
          color: isSerenity ? const Color(0xFFFBBF24) : _primaryBlue,
          size: 40,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$tier TIER',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isSerenity ? const Color(0xFFFBBF24) : _primaryBlue,
              ),
            ),
            Text(
              'Enjoy exclusive benefits',
              style: GoogleFonts.outfit(
                color: isSerenity ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
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
}
