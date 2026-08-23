import 'package:flutter/material.dart';

import '../domain/character_gender.dart';

class CharacterGenderSelector extends FormField<CharacterGender> {
  CharacterGenderSelector({
    required ValueChanged<CharacterGender> onChanged,
    super.key,
  }) : super(
         autovalidateMode: AutovalidateMode.onUserInteraction,
         validator: (value) => value == null ? '캐릭터 성별을 선택해 주세요.' : null,
         builder: (field) {
           final selected = field.value == null
               ? <CharacterGender>{}
               : {field.value!};
           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               Text(
                 '캐릭터 성별',
                 style: Theme.of(field.context).textTheme.bodySmall,
               ),
               const SizedBox(height: 6),
               SegmentedButton<CharacterGender>(
                 segments: const [
                   ButtonSegment(
                     value: CharacterGender.male,
                     icon: Icon(Icons.male_rounded),
                     label: Text('남자'),
                   ),
                   ButtonSegment(
                     value: CharacterGender.female,
                     icon: Icon(Icons.female_rounded),
                     label: Text('여자'),
                   ),
                 ],
                 selected: selected,
                 emptySelectionAllowed: true,
                 showSelectedIcon: false,
                 onSelectionChanged: (values) {
                   if (values.isEmpty) return;
                   final value = values.first;
                   field.didChange(value);
                   onChanged(value);
                 },
               ),
               if (field.errorText case final error?) ...[
                 const SizedBox(height: 6),
                 Text(
                   error,
                   style: Theme.of(field.context).textTheme.bodySmall?.copyWith(
                     color: Theme.of(field.context).colorScheme.error,
                   ),
                 ),
               ],
             ],
           );
         },
       );
}
