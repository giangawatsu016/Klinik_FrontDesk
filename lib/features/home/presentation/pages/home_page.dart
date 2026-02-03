import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/presentation/components/empty_state_widget.dart';
import '../../../profile/presentation/pages/profile_page.dart' as profile;
import '../blocs/home_cubit.dart';
import '../../../auth/presentation/blocs/auth_bloc.dart';
import '../../../profile/presentation/blocs/profile_cubit.dart';
import '../../../appointment/presentation/blocs/appointment_bloc.dart';
import '../../../appointment/presentation/blocs/medical_record_bloc.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';
import '../components/glass_bottom_nav.dart';
import '../components/service_image_carousel.dart';
import '../components/tab_header.dart';
import '../components/search_popup.dart';
import '../blocs/search_cubit.dart';
import 'service_detail_page.dart';
import '../../../../features/appointment/presentation/pages/appointment_list_page.dart';
import '../../../../features/appointment/presentation/pages/medical_record_list_page.dart';
import '../../../../features/appointment/presentation/pages/appointment_detail_page.dart';
import 'package:intl/intl.dart';
import '../../../notification/presentation/blocs/notification_cubit.dart';
import '../../../notification/presentation/pages/notification_list_page.dart';
import '../../../front_desk/presentation/pages/queue_monitor_screen.dart';
import '../../../front_desk/presentation/pages/registration_screen.dart';

class HomePage extends StatefulWidget {
  final UserTier tier;
  final bool isGuest;
  const HomePage({super.key, this.tier = UserTier.care, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late bool _isGuest;

  @override
  void initState() {
    super.initState();

    // Check if user is a guest by checking AuthBloc state
    final authState = context.read<AuthBloc>().state;
    _isGuest = authState is AuthGuest;

    context.read<HomeCubit>().getServices();

    // Only fetch personalized data if not a guest
    if (!_isGuest) {
      context.read<AppointmentBloc>().add(GetAppointmentsRequested());
      context.read<ProfileCubit>().getProfile();
      context.read<NotificationCubit>().getNotifications();
    }
  }

  void _handleNotificationTap() {
    if (_isGuest) {
      _showLoginRequiredDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationListPage()),
    );
  }

  void _handleSearchTap() {
    // Update SearchCubit with latest data
    final homeState = context.read<HomeCubit>().state;
    final appointmentState = context.read<AppointmentBloc>().state;

    context.read<SearchCubit>().setDataSources(
      services: homeState is HomeLoaded ? homeState.services : [],
      appointments: appointmentState is AppointmentsLoaded
          ? appointmentState.appointments
          : [],
    );

    context.read<SearchCubit>().openSearch(_currentIndex);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.transparent,
      pageBuilder: (context, anim1, anim2) =>
          SearchPopup(tabIndex: _currentIndex, isGuest: _isGuest),
      transitionDuration: Duration.zero,
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: const Color(0xFF2859E2)),
            const SizedBox(width: 12),
            Text(
              'Login Required',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Please login or create an account to access this feature.',
          style: GoogleFonts.outfit(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2859E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Login',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = context.isDesktop || context.isTablet;

    return AdaptiveScaffold(
      enableBlur: true,
      body: Stack(
        children: [
          // Background mesh gradient for glass visibility
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAFF),
                    Color(0xFFFFFFFF),
                    Color(0xFFF2F6FF),
                  ],
                ),
              ),
            ),
          ),
          // Responsive layout: sidebar for desktop/tablet, bottom nav for mobile
          if (isDesktopOrTablet)
            Row(
              children: [
                // Side Navigation Rail
                _buildSideNavigation(context),
                // Content area
                Expanded(child: _buildContentArea()),
              ],
            )
          else
            // Mobile layout with bottom nav
            Column(
              children: [
                Expanded(child: _buildContentArea()),
                // Bottom navigation for mobile
                GlassBottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    if (_isGuest && index != 0) {
                      _showLoginRequiredDialog();
                      return;
                    }
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Side navigation for tablet and desktop
  Widget _buildSideNavigation(BuildContext context) {
    final isDesktop = context.isDesktop;
    final navItems = [
      _NavItem(Icons.layers_outlined, Icons.layers, 'Queue'),
      _NavItem(Icons.person_add_outlined, Icons.person_add, 'Registration'),
      _NavItem(
        Icons.calendar_today_outlined,
        Icons.calendar_today,
        'Appointments',
      ),
      _NavItem(Icons.folder_outlined, Icons.folder, 'Records'),
      _NavItem(Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Container(
      width: isDesktop ? 240 : 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Logo/Brand area
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Row(
                mainAxisAlignment: isDesktop
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2859E2), Color(0xFF4A7DFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Clinic App',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2859E2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Navigation items
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 8),
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isSelected = _currentIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (_isGuest && index != 0) {
                            _showLoginRequiredDialog();
                            return;
                          }
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 16 : 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2859E2).withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: isDesktop
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? const Color(0xFF2859E2)
                                    : Colors.grey[600],
                                size: 24,
                              ),
                              if (isDesktop) ...[
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? const Color(0xFF2859E2)
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom section
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
              child: isDesktop
                  ? Text(
                      'v1.0.0',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// Main content area builder
  Widget _buildContentArea() {
    switch (_currentIndex) {
      case 0:
        // Queue Monitoring
        return const QueueMonitorScreen();
      case 1:
        // Registration
        return const RegistrationScreen();
      case 2:
        // Appointments
        return BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, notifState) {
            final unreadCount = notifState is NotificationLoaded
                ? notifState.unreadCount
                : 0;
            return CustomScrollView(
              slivers: [
                TabHeader(
                  subtitle: 'Cek jadwal kunjungan kamu',
                  onSearchTap: _handleSearchTap,
                  onNotificationTap: _handleNotificationTap,
                  hasNotification: false,
                  unreadNotificationCount: unreadCount,
                  showSearchIcon: true,
                ),
                AppointmentListPage(
                  filterStatus: const ['PAID', 'IN_PROGRESS'],
                  filterPaymentStatus: const ['PAID'],
                  sortAscending: true,
                  title: 'My Schedule',
                  tier: widget.tier,
                  showBackButton: false,
                  sliverMode: true,
                ),
              ],
            );
          },
        );
      case 3:
        // Medical Records
        return BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, notifState) {
            final unreadCount = notifState is NotificationLoaded
                ? notifState.unreadCount
                : 0;
            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent * 0.9) {
                  context.read<MedicalRecordBloc>().add(
                    LoadMoreMedicalRecords(),
                  );
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  TabHeader(
                    subtitle: 'Lihat riwayat kesehatanmu',
                    onSearchTap: _handleSearchTap,
                    onNotificationTap: _handleNotificationTap,
                    hasNotification: false,
                    unreadNotificationCount: unreadCount,
                    showSearchIcon: true,
                  ),
                  MedicalRecordListPage(
                    filterStatus: const ['COMPLETED', 'CANCELLED'],
                    sortAscending: false,
                    title: 'Medical Record',
                    tier: widget.tier,
                    showBackButton: false,
                    sliverMode: true,
                  ),
                ],
              ),
            );
          },
        );
      case 4:
        // Profile
        return BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, notifState) {
            final unreadCount = notifState is NotificationLoaded
                ? notifState.unreadCount
                : 0;
            return CustomScrollView(
              slivers: [
                TabHeader(
                  subtitle: 'Kelola akun dan informasi',
                  onNotificationTap: _handleNotificationTap,
                  hasNotification: false,
                  unreadNotificationCount: unreadCount,
                  showSearchIcon: false,
                ),
                profile.ProfilePage(sliverMode: true),
              ],
            );
          },
        );
      default:
        return const QueueMonitorScreen();
    }
  }

  // ignore: unused_element
  Widget _buildHomeContent() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HomeLoaded) {
          return RefreshIndicator(
            color: const Color(0xFF2859E2),
            backgroundColor: Colors.white,
            onRefresh: () async => context.read<HomeCubit>().getServices(),
            child: BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, notifState) {
                final unreadCount = notifState is NotificationLoaded
                    ? notifState.unreadCount
                    : 0;
                return CustomScrollView(
                  slivers: [
                    TabHeader(
                      subtitle: 'Treatment apa hari ini ?',
                      onSearchTap: _handleSearchTap,
                      onNotificationTap: _handleNotificationTap,
                      hasNotification: false,
                      unreadNotificationCount: unreadCount,
                      showSearchIcon: true,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isGuest) ...[
                              const SizedBox(height: 16),
                              _buildUpcomingAppointmentCard(),
                              const SizedBox(height: 24),
                              _buildHealthMetricsGrid(),
                              const SizedBox(height: 24),
                              _buildPendingPaymentsBanner(),
                            ] else
                              const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Front Desk Operations'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildFrontDeskCard(
                                  context,
                                  'Registration',
                                  Icons.person_add,
                                  const Color(0xFF2859E2),
                                  '/registration',
                                ),
                                const SizedBox(width: 12),
                                _buildFrontDeskCard(
                                  context,
                                  'Queue',
                                  Icons.layers,
                                  Colors.orange,
                                  '/queue-monitor',
                                ),
                                const SizedBox(width: 12),
                                _buildFrontDeskCard(
                                  context,
                                  'Schedule',
                                  Icons.event_note,
                                  Colors.teal,
                                  '/appointments',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Our Services',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1D1E),
                                  ),
                                ),
                                if (state.services.length > 10)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              _AllServicesPage(
                                                services: state.services,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View All (${state.services.length})',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2859E2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    _buildServiceList(_getSortedServices(state.services)),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                );
              },
            ),
          );
        } else if (state is HomeError) {
          final isSessionError = state.message.contains('401');

          // If guest, don't show session expired or whale error for private data failures
          if (_isGuest && isSessionError) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: EmptyStateWidget(
              message: isSessionError
                  ? 'Session Expired'
                  : 'Oops! Something went wrong',
              lottieAsset: 'assets/animations/empty_box.json',
              isCentered: true,
              onRetry: () => context.read<HomeCubit>().getServices(),
            ),
          );
        }
        return const Center(child: Text('Start exploring our services'));
      },
    );
  }

  Widget _buildUpcomingAppointmentCard() {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state is AppointmentLoading) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        AppointmentEntity? nearest;
        if (state is AppointmentsLoaded && state.appointments.isNotEmpty) {
          final now = DateTime.now();
          // Filter: Approved Status (PAID/IN_PROGRESS) AND Future Date
          final upcoming = state.appointments.where((a) {
            final isApproved = ['PAID', 'IN_PROGRESS'].contains(a.status);
            final isFuture = a.date.isAfter(now);
            return isApproved && isFuture;
          }).toList();

          // Sort by date ASC
          upcoming.sort((a, b) => a.date.compareTo(b.date));

          if (upcoming.isNotEmpty) {
            nearest = upcoming.first;
          }
        }

        if (nearest == null) {
          return const SizedBox.shrink();
        }

        final wibDate = nearest.date.toWib();
        final theme = _getCardTimeTheme(wibDate);

        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  // Dynamic Time Theme Header
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme.gradientColors,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F1FF),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 12,
                                              color: Color(0xFF2859E2),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Upcoming',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF2859E2),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (nearest.transactionNumber != null)
                                        Text(
                                          nearest.transactionNumber!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    nearest.serviceName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: const Color(0xFF1A1D1E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getFormattedDoctorName(nearest),
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: theme.gradientColors.first,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${DateFormat('HH:mm').format(wibDate)} WIB',
                                        style: GoogleFonts.outfit(
                                          color: theme.gradientColors.first,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Date Widget (Image 2 style)
                            Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.gradientColors.first.withValues(
                                      alpha: 0.1,
                                    ),
                                    const Color(0xFFF0F4FF),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Pulse(
                                    infinite: true,
                                    duration: const Duration(seconds: 3),
                                    child: Icon(
                                      theme.icon,
                                      size: 28,
                                      color: theme.gradientColors.first,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('dd').format(wibDate),
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2859E2),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMMM').format(wibDate),
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: const Color(0xFF2859E2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              nearest.status.toUpperCase(),
                              'Status',
                            ),
                            _buildStatItem(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(nearest.finalPrice),
                              'Price',
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AppointmentDetailPage(
                                      appointment: nearest!,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2859E2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Details',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFormattedDoctorName(AppointmentEntity appt) {
    final prefix = appt.doctorTitlePrefix ?? '';
    final name = appt.doctorName;
    final suffix = appt.doctorTitleSuffix ?? '';

    String fullName = '';
    if (prefix.isNotEmpty) {
      fullName += '$prefix ';
    }
    fullName += name;
    if (suffix.isNotEmpty) {
      // Add comma if not already there
      if (!fullName.endsWith(',') && !suffix.startsWith(',')) {
        fullName += ', ';
      }
      fullName += suffix;
    }
    return fullName.trim();
  }

  _CardTimeTheme _getCardTimeTheme(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 11) {
      return _CardTimeTheme(
        gradientColors: [const Color(0xFFFF9966), const Color(0xFFFF5E62)],
        icon: Icons.wb_sunny_rounded,
      );
    } else if (hour >= 11 && hour <= 15) {
      return _CardTimeTheme(
        gradientColors: [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
        icon: Icons.wb_sunny_outlined,
      );
    } else if (hour > 15 && hour <= 18) {
      return _CardTimeTheme(
        gradientColors: [const Color(0xFFf2709c), const Color(0xFFff9472)],
        icon: Icons.wb_twilight_rounded,
      );
    } else {
      return _CardTimeTheme(
        gradientColors: [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
        icon: Icons.nights_stay_rounded,
      );
    }
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1D1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildHealthMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Glucose Level',
            '168,93',
            'mg/dL',
            Colors.white,
            content: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final height = [
                    20.0,
                    35.0,
                    15.0,
                    45.0,
                    30.0,
                    25.0,
                  ][index % 6];
                  final isSelected = index == 3;
                  return Container(
                    width: 10,
                    height: height,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2859E2)
                          : const Color(0xFFD6E4FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildMetricCard(
            'Heart Rate',
            '24,32',
            'Bpm',
            Colors.white,
            content: Container(
              height: 50,
              margin: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final height = [
                    15.0,
                    25.0,
                    20.0,
                    30.0,
                    15.0,
                    20.0,
                  ][index % 6];
                  return Container(
                    width: 10,
                    height: height,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E4FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    Color color, {
    Widget? content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1D1E),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'View Details',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2859E2),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1D1E),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Empowering You with Healthy...',
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (content != null) content,
        ],
      ),
    );
  }

  Widget _buildPendingPaymentsBanner() {
    return BlocBuilder<AppointmentBloc, AppointmentState>(
      builder: (context, state) {
        if (state is! AppointmentsLoaded) return const SizedBox.shrink();

        final pendingAppointments = state.appointments
            .where((a) => a.status == 'PENDING' && a.paymentStatus != 'PAID')
            .toList();

        if (pendingAppointments.isEmpty) return const SizedBox.shrink();

        final displayCount = pendingAppointments.length > 5
            ? 5
            : pendingAppointments.length;
        final hasMore = pendingAppointments.length > 5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Awaiting Payment',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1D1E),
                  ),
                ),
                if (hasMore)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentListPage(
                            filterStatus: const ['PENDING'],
                            sortAscending: true,
                            title: 'Pending Payments',
                            tier: widget.tier,
                            showBackButton: true,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View All (${pendingAppointments.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2859E2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayCount,
                itemBuilder: (context, index) {
                  final appt = pendingAppointments[index];
                  return _buildPendingPaymentCard(appt);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildPendingPaymentCard(AppointmentEntity appt) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailPage(appointment: appt),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB800), Color(0xFFFF9500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB800).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appt.serviceName,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(appt.finalPrice),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(appt.date),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AppointmentDetailPage(appointment: appt),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF9500),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Pay Now',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List _getSortedServices(List services) {
    // Sort services: prioritize those with discounts, then limit to 10
    final sortedServices = List.from(services);
    sortedServices.sort((a, b) {
      final aHasDiscount = (a.discountValue != null && a.discountValue > 0)
          ? 0
          : 1;
      final bHasDiscount = (b.discountValue != null && b.discountValue > 0)
          ? 0
          : 1;
      return aHasDiscount.compareTo(bHasDiscount);
    });
    return sortedServices.take(10).toList();
  }

  Widget _buildServiceList(List services) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final service = services[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailPage(service: service),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: ServiceImageCarousel(
                              images: service.posterImages,
                              serviceId: service.id,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    service.name,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: const Color(0xFF1A1D1E),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Available',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF2859E2),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.category ?? 'General',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Price area
                            if (service.discount != null &&
                                service.discount! > 0) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6FFFA),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF00BD7D,
                                        ).withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      service.discountType == 'percentage'
                                          ? '-${service.discountValue?.round()}%'
                                          : '-Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(service.discountValue)}',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF00BD7D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(
                                      service.originalPrice ??
                                          (service.finalPrice! +
                                              service.discount!),
                                    ),
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[700],
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (service.discountUntil != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    _getRemainingDays(service.discountUntil!),
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFE53935),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(service.finalPrice),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    service.discount != null &&
                                        service.discount! > 0
                                    ? const Color(0xFF00897B)
                                    : const Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (service.discount != null && service.discount! > 0)
                  Positioned(
                    top: 10,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BD7D),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        service.discountName?.toUpperCase() ??
                            (service.discountType == 'percentage'
                                ? '-${service.discountValue?.round()}%'
                                : 'PROMO'),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }, childCount: services.length),
    );
  }

  String _getRemainingDays(DateTime until) {
    final now = DateTime.now();
    final diff = until.difference(now);
    if (diff.isNegative) {
      return 'Expired';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} days left';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return 'Ending soon';
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1D1E),
      ),
    );
  }

  Widget _buildFrontDeskCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String route,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// All Services Page for View All functionality
class _AllServicesPage extends StatelessWidget {
  final List services;
  const _AllServicesPage({required this.services});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1D1E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Services',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1D1E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildServiceItem(context, service);
        },
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, dynamic service) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final hasDiscount =
        service.discountValue != null && service.discountValue > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailPage(service: service),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: service.posterImages.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: service.posterImages[0],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF2859E2),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF2859E2),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF1A1D1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category ?? 'Service',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter.format(service.finalPrice ?? 0),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: hasDiscount
                        ? const Color(0xFF00897B)
                        : const Color(0xFF1A237E),
                  ),
                ),
                if (hasDiscount)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      service.discountType == 'percentage'
                          ? '-${service.discountValue?.toStringAsFixed(0)}%'
                          : '-${currencyFormatter.format(service.discountValue ?? 0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00897B),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTimeTheme {
  final List<Color> gradientColors;
  final IconData icon;

  _CardTimeTheme({required this.gradientColors, required this.icon});
}

/// Navigation item for side navigation
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem(this.icon, this.activeIcon, this.label);
}
