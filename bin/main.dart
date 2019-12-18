import 'package:built_value_basic_basic_tutorial/user.dart';

void updates(UserBuilder b) {
  b = UserBuilder();
  b.name = 'John Smith';
}

void main(List<String> arguments) {
  var user1 = User(updates);
  var user2 = User(updates);

  print(user1 == user2);
}
