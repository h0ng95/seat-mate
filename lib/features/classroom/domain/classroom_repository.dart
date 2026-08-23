import '../../../core/values/local_date.dart';
import '../../../core/values/nickname.dart';
import 'classroom.dart';

class CreateClassroomCommand {
  const CreateClassroomCommand({
    required this.ownerName,
    required this.ownerBirthDate,
  });

  final Nickname ownerName;
  final LocalDate ownerBirthDate;
}

abstract interface class ClassroomRepository {
  Future<Classroom> createClassroom(CreateClassroomCommand command);
  Future<Classroom> getClassroom(String shareCode);
}

class ClassroomNotFoundException implements Exception {
  const ClassroomNotFoundException(this.shareCode);

  final String shareCode;
}
