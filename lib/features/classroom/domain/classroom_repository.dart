import '../../../core/values/nickname.dart';
import 'birth_profile.dart';
import 'classroom.dart';

class CreateClassroomCommand {
  const CreateClassroomCommand({
    required this.ownerName,
    required this.ownerBirth,
  });

  final Nickname ownerName;
  final BirthProfile ownerBirth;
}

class JoinClassroomCommand {
  const JoinClassroomCommand({
    required this.shareCode,
    required this.name,
    required this.birth,
  });

  final String shareCode;
  final Nickname name;
  final BirthProfile birth;
}

class JoinClassroomResult {
  const JoinClassroomResult({
    required this.classroom,
    required this.member,
    this.isDuplicate = false,
  });

  final Classroom classroom;
  final ClassroomMember member;
  final bool isDuplicate;
}

abstract interface class ClassroomRepository {
  Future<Classroom> createClassroom(CreateClassroomCommand command);
  Future<Classroom> getClassroom(String shareCode);
  Future<JoinClassroomResult> joinClassroom(JoinClassroomCommand command);
}

class ClassroomFullException implements Exception {
  const ClassroomFullException();
}

class ClassroomNotFoundException implements Exception {
  const ClassroomNotFoundException(this.shareCode);

  final String shareCode;
}
