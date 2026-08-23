import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hashing/stable_hash.dart';
import '../../../core/values/nickname.dart';
import '../domain/classroom.dart';
import '../domain/classroom_repository.dart';
import '../domain/relationship.dart';
import '../domain/seat_mate_algorithm.dart';

class SupabaseClassroomRepository implements ClassroomRepository {
  SupabaseClassroomRepository(this._client);

  final SupabaseClient _client;
  final _algorithm = const SeatMateAlgorithmV1();

  @override
  Future<Classroom> createClassroom(CreateClassroomCommand command) async {
    final owner = _algorithm.deriveOwner(command.ownerBirthDate);
    final ownerAlgorithmSeed = StableHash.hex(
      'owner|${command.ownerBirthDate.iso}',
    );
    final characterSeed = StableHash.hex(
      '${command.ownerName.normalized}|${command.ownerBirthDate.iso}',
    );
    try {
      final response = await _client.rpc(
        'create_classroom',
        params: {
          'p_owner_name': command.ownerName.display,
          'p_owner_birth_date': command.ownerBirthDate.iso,
          'p_owner_seat': owner.seatIndex,
          'p_owner_profile': owner.profile.name,
          'p_owner_character_seed': characterSeed,
          'p_owner_algorithm_seed': ownerAlgorithmSeed,
          'p_algorithm_version': SeatMateAlgorithmV1.version,
        },
      );
      final row = (response as List).cast<Map<String, dynamic>>().first;
      return getClassroom(row['share_code'] as String);
    } on PostgrestException catch (error) {
      throw _mapException(error, '');
    }
  }

  @override
  Future<Classroom> getClassroom(String shareCode) async {
    try {
      final classroomRow = await _client
          .from('public_classrooms')
          .select()
          .eq('share_code', shareCode)
          .maybeSingle();
      if (classroomRow == null) throw ClassroomNotFoundException(shareCode);
      final classroomId = classroomRow['id'] as String;
      final memberRows = await _client
          .from('public_classroom_members')
          .select()
          .eq('classroom_id', classroomId)
          .order('seat_index');
      return _mapClassroom(
        Map<String, dynamic>.from(classroomRow),
        memberRows.cast<Map<String, dynamic>>(),
      );
    } on PostgrestException catch (error) {
      throw _mapException(error, shareCode);
    }
  }

  @override
  Future<JoinClassroomResult> joinClassroom(
    JoinClassroomCommand command,
  ) async {
    final current = await getClassroom(command.shareCode);
    final calculated = _algorithm.deriveMember(
      classroomCode: current.shareCode,
      ownerAlgorithmSeed: current.ownerAlgorithmSeed,
      ownerSeatIndex: current.ownerSeatIndex,
      memberName: command.name,
      memberBirthDate: command.birthDate,
      occupiedSeats: current.members.map((member) => member.seatIndex).toSet(),
    );
    try {
      final response = await _client.rpc(
        'join_classroom',
        params: {
          'p_share_code': command.shareCode,
          'p_name': command.name.display,
          'p_birth_date': command.birthDate.iso,
          'p_relationship_type': calculated.relationship.code,
          'p_preferred_seats': calculated.preferredSeats,
          'p_character_seed': calculated.characterSeed,
          'p_fun_focus_delta': calculated.focusDelta,
          'p_fun_joy_delta': calculated.joyDelta,
          'p_algorithm_version': SeatMateAlgorithmV1.version,
        },
      );
      final row = (response as List).cast<Map<String, dynamic>>().first;
      final updated = await getClassroom(command.shareCode);
      final memberId = row['member_id'] as String;
      final member = updated.members.firstWhere((item) => item.id == memberId);
      return JoinClassroomResult(
        classroom: updated,
        member: member,
        isDuplicate: row['result_status'] == 'duplicate',
      );
    } on PostgrestException catch (error) {
      throw _mapException(error, command.shareCode);
    }
  }

  Classroom _mapClassroom(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> memberRows,
  ) {
    final ownerProfile = _ownerProfileFromCode(row['owner_profile'] as String);
    final members = memberRows
        .map((memberRow) {
          final isOwner = memberRow['is_owner'] as bool;
          return ClassroomMember(
            id: memberRow['id'] as String,
            name: Nickname(memberRow['name'] as String),
            birthDate: null,
            seatIndex: memberRow['seat_index'] as int,
            characterSeed: memberRow['character_seed'] as String,
            focusDelta: memberRow['fun_focus_delta'] as int,
            joyDelta: memberRow['fun_joy_delta'] as int,
            relationship: isOwner
                ? null
                : _relationshipFromCode(
                    memberRow['relationship_type'] as String,
                  ),
            ownerProfile: isOwner ? ownerProfile : null,
            isOwner: isOwner,
          );
        })
        .toList(growable: false);
    return Classroom(
      id: row['id'] as String,
      shareCode: row['share_code'] as String,
      ownerName: Nickname(row['owner_name'] as String),
      ownerBirthDate: null,
      ownerAlgorithmSeed: row['owner_algorithm_seed'] as String,
      ownerSeatIndex: row['owner_seat'] as int,
      members: members,
      algorithmVersion: row['algorithm_version'] as int,
    );
  }

  Object _mapException(PostgrestException error, String shareCode) {
    if (error.message.contains('CLASSROOM_FULL')) {
      return const ClassroomFullException();
    }
    if (error.message.contains('CLASSROOM_NOT_FOUND') ||
        error.code == 'P0002') {
      return ClassroomNotFoundException(shareCode);
    }
    return error;
  }

  RelationshipType _relationshipFromCode(String code) {
    return RelationshipType.values.firstWhere(
      (relationship) => relationship.code == code,
    );
  }

  OwnerProfileType _ownerProfileFromCode(String code) {
    return OwnerProfileType.values.firstWhere(
      (profile) => profile.name == code,
    );
  }
}
