import 'package:built_collection/built_collection.dart';
import 'package:built_value_basic_basic_tutorial/user.dart';

void updates(UserBuilder b) {
  b.name = 'John Smith';
}

void main(List<String> arguments) {
  print('Built Value Tutorial---------------');
  var user1 = User(updates);
  var user2 = User(updates);

  print(user1 == user2);

  print('Built Collection Tutorial----------');
  var list = BuiltList<int>([1, 2, 3]);
  print(list);

  var newList = list.rebuild((b) => b
    ..add(4)
    ..addAll([7, 6, 5])
    ..sort()
    ..remove(1));
  print(newList);

  var newListVerbose = list.rebuild((b) {
    b.add(4);
    b.addAll([7, 6, 5]);
    b.sort();
    b.remove(1);
  });
  print(newListVerbose);

  var builder = list.toBuilder();
  builder.add(4);
  builder.addAll([7, 6, 5]);
  builder.sort();
  builder.remove(1);
  var newListEvenMoreVerbose = builder.build();
  print(newListEvenMoreVerbose);
}
