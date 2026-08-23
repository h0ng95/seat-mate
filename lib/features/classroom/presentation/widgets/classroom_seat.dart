import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../models/classroom_scene_member.dart';

class ClassroomSeat extends StatelessWidget {
  const ClassroomSeat({
    required this.seatIndex,
    required this.member,
    required this.onTap,
    super.key,
  });

  final int seatIndex;
  final ClassroomSceneMember? member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final person = member;
    return Semantics(
      button: person != null,
      label: person == null
          ? '빈 자리'
          : '${person.name}, ${person.seatDescription}, ${person.relationshipTitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('seat-$seatIndex'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 7,
                    left: 3,
                    right: 3,
                    height: constraints.maxHeight * 0.38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.wood,
                        border: Border.all(color: AppColors.woodDark, width: 2),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332B211B),
                            offset: Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (person != null)
                    Positioned(
                      top: 2,
                      width: constraints.maxWidth * 0.63,
                      height: constraints.maxHeight * 0.55,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: person.color,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.chalk,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 2,
                    right: 2,
                    bottom: 0,
                    height: 22,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: person == null
                            ? AppColors.paper.withValues(alpha: 0.65)
                            : AppColors.chalk,
                        border: Border.all(color: AppColors.woodDark),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Text(
                          person?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (person != null)
                    Positioned(
                      right: 1,
                      top: 0,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.chalk,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            person.isOwner
                                ? Icons.star_rounded
                                : Icons.favorite_rounded,
                            size: 13,
                            color: person.isOwner
                                ? AppColors.yellow
                                : AppColors.coral,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
