import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 70, // Increased height for better proportions
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double itemWidth = totalWidth / 5;
              final double indicatorWidth =
                  itemWidth * 0.55; // 55% of slot for compact 5 items
              final double leftOffset =
                  (currentIndex * itemWidth) + (itemWidth - indicatorWidth) / 2;

              return Stack(
                children: [
                  // Perfect Sliding Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut, // Liquid-like bounce
                    left: leftOffset,
                    top: 10,
                    child: Container(
                      width: indicatorWidth,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Centered Icons
                  Row(
                    children: [
                      _buildNavItem(
                        0,
                        FontAwesomeIcons.userGroup,
                        FontAwesomeIcons.users,
                      ),
                      _buildNavItem(
                        1,
                        FontAwesomeIcons.userPlus,
                        FontAwesomeIcons.userPlus,
                      ),
                      _buildNavItem(
                        2,
                        FontAwesomeIcons.solidCalendarCheck,
                        FontAwesomeIcons.calendar,
                      ),
                      _buildNavItem(
                        3,
                        FontAwesomeIcons.fileMedical,
                        FontAwesomeIcons.file,
                      ),
                      _buildNavItem(
                        4,
                        FontAwesomeIcons.solidUser,
                        FontAwesomeIcons.user,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          color: Colors.transparent, // Ensure full hit area
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: FaIcon(
              isSelected ? activeIcon : inactiveIcon,
              key: ValueKey<bool>(isSelected),
              color: isSelected ? const Color(0xFF2859E2) : Colors.black45,
              size: 20, // FaIcon usually looks better slightly smaller
            ),
          ),
        ),
      ),
    );
  }
}
