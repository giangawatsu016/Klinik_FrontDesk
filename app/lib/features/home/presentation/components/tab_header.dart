import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../../../auth/domain/entities/auth_entity.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../profile/presentation/blocs/profile_cubit.dart';

class TabHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;
  final bool hasNotification;
  final bool showSearchIcon;
  final bool showNotificationIcon;
  final int unreadNotificationCount;

  const TabHeader({
    super.key,
    required this.subtitle,
    this.onSearchTap,
    this.onNotificationTap,
    this.hasNotification = true,
    this.showSearchIcon = true,
    this.showNotificationIcon = true,
    this.unreadNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFFFAFAFA).withValues(alpha: 0.85),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      elevation: 0,
      toolbarHeight: 90,
      collapsedHeight: 90,
      expandedHeight: 90,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Use ProfileCubit for reactive name updates after profile edit
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, profileState) {
                    String greetingName = 'Guest';

                    // Priority 1: ProfileCubit (Freshest)
                    if (profileState is ProfileLoaded) {
                      greetingName = profileState.user.name.split(' ').first;
                    }
                    // Priority 2: AuthBloc (Baseline/Fallback)
                    else if (authState is AuthAuthenticated) {
                      greetingName = authState.auth.user.name.split(' ').first;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hi, $greetingName',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2859E2),
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Row(
              children: [
                if (showSearchIcon) ...[
                  _buildHeaderIconButton(
                    FontAwesomeIcons.magnifyingGlass,
                    onTap: onSearchTap,
                  ),
                  const SizedBox(width: 12),
                ],
                if (showNotificationIcon) ...[
                  Stack(
                    children: [
                      _buildHeaderIconButton(
                        FontAwesomeIcons.bell,
                        onTap: onNotificationTap,
                      ),
                      if (hasNotification || unreadNotificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: unreadNotificationCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unreadNotificationCount > 99
                                        ? '99+'
                                        : '$unreadNotificationCount',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                // Use ProfileCubit for reactive avatar updates
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    return BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, profileState) {
                        UserEntity? activeUser;

                        // Priority 1: ProfileCubit (Freshest)
                        if (profileState is ProfileLoaded) {
                          activeUser = profileState.user;
                        }
                        // Priority 2: AuthBloc (Baseline/Fallback)
                        else if (authState is AuthAuthenticated) {
                          activeUser = authState.auth.user;
                        }

                        if (activeUser != null) {
                          final hasPhoto =
                              activeUser.photoProfile != null &&
                              activeUser.photoProfile!.isNotEmpty;

                          return Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: hasPhoto
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: activeUser.photoProfile!,
                                      memCacheWidth: 72,
                                      memCacheHeight: 72,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 36,
                                        height: 36,
                                        color: const Color(0xFFE8F1FF),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          _buildInitialsAvatar(
                                            activeUser!.name,
                                          ),
                                    ),
                                  )
                                : _buildInitialsAvatar(activeUser.name),
                          );
                        }
                        return _buildInitialsAvatar('Guest');
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F1FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getUserInitials(name),
          style: GoogleFonts.outfit(
            color: const Color(0xFF2859E2),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) {
      return '??';
    }
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildHeaderIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: FaIcon(icon, color: Colors.black87, size: 18)),
      ),
    );
  }
}
