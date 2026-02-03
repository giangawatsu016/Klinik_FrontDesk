import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../blocs/search_cubit.dart';
import '../../../appointment/presentation/blocs/medical_record_bloc.dart';
import '../../domain/entities/service_entity.dart';
import '../../../appointment/domain/entities/appointment_entity.dart';
import '../pages/service_detail_page.dart';
import '../../../appointment/presentation/pages/appointment_detail_page.dart';
import '../../../../core/presentation/components/empty_state_widget.dart';
import '../../../../core/utils/date_utils.dart';

class SearchPopup extends StatefulWidget {
  final int tabIndex;
  final bool isGuest;

  const SearchPopup({super.key, required this.tabIndex, this.isGuest = false});

  @override
  State<SearchPopup> createState() => _SearchPopupState();
}

class _SearchPopupState extends State<SearchPopup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    if (widget.tabIndex == 2) {
      final state = context.read<MedicalRecordBloc>().state;
      if (state is MedicalRecordLoaded) {
        _searchController.text = state.search;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (widget.tabIndex == 2) {
      context.read<MedicalRecordBloc>().add(SearchMedicalRecords(query));
    } else {
      context.read<SearchCubit>().search(query);
    }
  }

  void _closePopup() async {
    await _animationController.reverse();
    if (mounted) {
      context.read<SearchCubit>().closeSearch();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: _closePopup,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),
          // Search Panel
          SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with search field
                    _buildSearchHeader(),
                    // Results
                    if (widget.tabIndex == 2)
                      BlocBuilder<MedicalRecordBloc, MedicalRecordState>(
                        builder: (context, state) {
                          if (state is MedicalRecordLoading &&
                              state is! MedicalRecordLoaded) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (state is MedicalRecordLoaded) {
                            if (state.search.isNotEmpty) {
                              return _buildMedicalResults(state.medicalRecords);
                            }
                            return _buildEmptyState('Type to search');
                          }
                          return _buildEmptyState('Type to search');
                        },
                      )
                    else
                      BlocBuilder<SearchCubit, SearchState>(
                        builder: (context, state) {
                          if (state is SearchActive) {
                            return _buildResults(state);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    final searchLabel = SearchCubit.getSearchLabel(widget.tabIndex);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  searchLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2859E2),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _closePopup,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearch,
              style: GoogleFonts.outfit(fontSize: 16),
              decoration: InputDecoration(
                hintText: _getHintText(),
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                prefixIcon: const Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 16,
                  color: Colors.grey,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    if (widget.isGuest) {
      return 'Search services...';
    }
    switch (widget.tabIndex) {
      case 0:
        return 'Search by service name...';
      case 1:
        return 'Search by doctor or service...';
      case 2:
        return 'Search past appointments...';
      default:
        return 'Search...';
    }
  }

  Widget _buildResults(SearchActive state) {
    if (state.query.isEmpty) {
      return _buildEmptyState('Type to search');
    }

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.results.isEmpty) {
      return _buildEmptyState('No results found');
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: state.results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = state.results[index];
          if (item is ServiceEntity) {
            return _buildServiceItem(item);
          } else if (item is AppointmentEntity) {
            if (widget.isGuest) return const SizedBox.shrink();
            return _buildAppointmentItem(item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        alignment: Alignment.center,
        child: EmptyStateWidget(
          message: message,
          lottieAsset: 'assets/animations/empty_box.json',
        ),
      ),
    );
  }

  Color _getTimeColor(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 11) return Colors.orange;
    if (hour >= 11 && hour <= 15) return Colors.amber;
    if (hour > 15 && hour <= 18) return Colors.deepOrange;
    return Colors.indigo;
  }

  IconData _getTimeIcon(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 11) return Icons.wb_sunny_outlined;
    if (hour >= 11 && hour <= 15) return Icons.wb_sunny_rounded;
    if (hour > 15 && hour <= 18) return Icons.wb_twilight_rounded;
    return Icons.nights_stay_rounded;
  }

  Widget _buildServiceItem(ServiceEntity service) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.read<SearchCubit>().closeSearch();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailPage(service: service),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: service.posterImages.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        service.posterImages.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          FontAwesomeIcons.syringe,
                          color: Color(0xFF2859E2),
                          size: 20,
                        ),
                      ),
                    )
                  : const Icon(
                      FontAwesomeIcons.syringe,
                      color: Color(0xFF2859E2),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(service.finalPrice ?? 0),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2859E2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (service.originalPrice != null &&
                      service.finalPrice != null &&
                      service.originalPrice! > service.finalPrice!) ...[
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(service.originalPrice),
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  if (service.discountUntil != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Promo until ${DateFormat('d MMM yyyy').format(service.discountUntil!)}',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(AppointmentEntity appt) {
    final wibDate = appt.date.toWib();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.read<SearchCubit>().closeSearch();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailPage(appointment: appt),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 64,
              decoration: BoxDecoration(
                color: _getTimeColor(wibDate),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(wibDate),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(wibDate),
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTimeIcon(wibDate),
                          size: 8,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${DateFormat('HH:mm').format(wibDate)} WIB',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.serviceName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${appt.doctorTitlePrefix != null ? '${appt.doctorTitlePrefix} ' : ''}${appt.doctorName}${appt.doctorTitleSuffix != null ? ', ${appt.doctorTitleSuffix}' : ''}',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (appt.doctorSpecialization != null &&
                      appt.doctorSpecialization!.isNotEmpty)
                    Text(
                      appt.doctorSpecialization!,
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (appt.transactionNumber != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        appt.transactionNumber!,
                        style: GoogleFonts.outfit(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalResults(List<AppointmentEntity> results) {
    if (results.isEmpty) {
      return _buildEmptyState('No results found');
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _buildAppointmentItem(results[index]);
        },
      ),
    );
  }
}
