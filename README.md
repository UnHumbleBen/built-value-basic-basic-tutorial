# Built Value Basic Basic Tutorial
A dumbed-down tutorial for how to use [Built Values for Dart](https://github.com/google/built_value.dart).
Basically my annotated notes of this [article](https://medium.com/dartlang/darts-built-value-for-immutable-object-models-83e2497922d4?#.48dyezxcl)
by David Morgan.

## Getting Started
Nothing too fancy, just begin with the standard [Stagehand](https://pub.dev/packages/stagehand)
console-full template.

```bash
mkdir built_value_basic_basic_tutorial
cd built_value_basic_basic_tutorial
stagehand console-full
pub get
```

## Value Types

`lib/user.dart`
```dart
class User {
  String name;

  User({this.name});
}
```

`bin/main.dart`
```dart
import 'package:built_value_basic_basic_tutorial/user.dart';

void main(List<String> arguments) {
  var user1 = User(name: 'John Smith');
  var user2 = User(name: 'John Smith');

  print(user1 == user2);
}
```

What do we expect the answer to be? Physically, they should
refer to the same person, but alas the console outputs:
```bash
$ dart bin/main.dart
false
```

In addition to equalities, we want our classes to be immutable.

## The Problem with Value Types
The problem is that this requires too much boilerplate!

## Introducing build_value
You need to add built_value,
[built_value_generator](https://pub.dev/packages/built_value_generator),
and [built_runner](https://pub.dev/packages/build_runner) to `pubspec.yaml`

`pubspec.yaml`
```yaml
dependencies:
  built_value: ^7.0.0

dev_dependencies:
  built_value_generator: ^7.0.0
  build_runner: ^1.7.0
```

Basically the idea is that we write part of the implementation
of `User` and allow `built_value_generator` to generate the
boilerplate we want! Because we are not writing the entire
implementation, a class is too restrictive. Instead, we
write an abstract class and allow the builder to generate
the implementation:

`lib/user.dart`
```dart
import 'package:built_value/built_value.dart';

abstract class User {
  String get name;

  @nullable
  String get nickname;
}
```

The [`@nullable`](https://pub.dev/documentation/built_value/latest/built_value/nullable-constant.html)
annotation tells the generator that this field is allowed to
be null.

Unfortunately, there is still a bit of boilerplate we need to write
ourselves for the builder to generate the code. First, we
need a private constructor so that the generated class
`_$User` can extend `User` (I don't understand why exactly).

We also need a way to specify values for the fields. Using
optional parameters is possible, but forces you to repeat
all the field names in the constructor, and requires you to
have all the pieces together, but likely, you might only have
one piece at a time.

This is where the builder pattern comes in handy.

```dart
factory User([void Function(UserBuilder) updates]) = _$User;
```

Lastly, we want to have methods `rebuild` which creates
a new instance of `User` and `toBuilder`, which creates
an instance of `UserBuilder` from `User`. `built_value`
provides an abstract class `Built` which has these two methods.
Better yet, it generates the implementations for you!
Just implement `Built`. Our final user.dart file is:

`lib/user.dart`
```dart
import 'package:built_value/built_value.dart';

part 'user.g.dart';

abstract class User implements Built<User, UserBuilder> {
  String get name;

  @nullable
  String get nickname;

  User._();
  factory User([void Function(UserBuilder) updates]) = _$User;
}
```

Personal Change Note: Omitted confusing (and frankly useless)
`library` directive. Also used linter on signature (slightly
different from one written in article).

Run `pub run build_runner build` and you will find a
generated `user.g.dart` file:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';
```
This points to the source file.


```dart

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$User extends User {
  @override
  final String name;
  @override
  final String nickname;
```

Here, we see that we have a generated class `_$User` which
is a subclass of the `User` abstract class we defined.
We see that we have the fields `name` and `nickname` defined
for us. Note the `final` keyword, indicating that the fields
are immutable.

```dart
  factory _$User([void Function(UserBuilder) updates]) =>
      (new UserBuilder()..update(updates)).build();
```

Here, we have a factory constructor for generated class `_$User`
which takes in a closure to build a new `_$User`. If you are
wondering why we need a `factory`, the short answer is that
only factories are allowed to have `=` redirection.
Another reason is that we have a implciit `return` statement
from the `=>` arrow and like in Java, constructors cannot
have `return` statements.

```dart
  _$User._({this.name, this.nickname}) : super._() {
    if (name == null) {
      throw new BuiltValueNullFieldError('User', 'name');
    }
  }
```

Here we have the constructor for `_$User`. Notice that this
constructor is only used by the generater. It includes null
checking for `name`, but not `nickname`. (Remember the
`@nullable` annotation we added earlier?)

```dart
  @override
  User rebuild(void Function(UserBuilder) updates) =>
      (toBuilder()..update(updates)).build();
```

We see the `rebuild` function we were discussing earlier.
We briefly discussed the purpose of `rebuild` earlier, but
lets look at it more in depth here. Suppose we already
have an instance of `User` and we want another user but with
just one small change (like changing the nickname). If
we follow the builder pattern, we would need to manually
call `toBuilder` to convert the `User` to a `UserBuilder`,
apply the change, before calling `build`. Here, we have
a `rebuild` function which does the `toBuilder` and
`build` steps for us.

```dart
  @override
  UserBuilder toBuilder() => new UserBuilder()..replace(this);
```

Let's look more closely at how to actually implement
`toBuilder`, which we know is for converting a `User` to
a `UserBuilder`. Essentially, this function creates
a new instance of the builder class and assigns this
instance to the builder's `_$v` field. As a side note,
I looked online for how the builder pattern is used in
other languages, and it seems that it is uncommon to have
a field that points to an actual instance of the object
being built. I guess this is a detail that is specific to
`built_value`. My speculation is that due to the benefits
of immutability, if the objects has the same field, they
must be the same object *always*, so we can cache old
objects we made and keep reusing them.

```dart
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User && name == other.name && nickname == other.nickname;
  }

  @override
  int get hashCode {
    return $jf($jc($jc(0, name.hashCode), nickname.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('User')
          ..add('name', name)
          ..add('nickname', nickname))
        .toString();
  }
}
```

Now the other benefits of `built_value` we were promised: equality
checks, hashing, and to string!

```dart
class UserBuilder implements Builder<User, UserBuilder> {
  _$User _$v;

  String _name;
  String get name => _$this._name;
  set name(String name) => _$this._name = name;

  String _nickname;
  String get nickname => _$this._nickname;
  set nickname(String nickname) => _$this._nickname = nickname;

  UserBuilder();
```

Looking at the builder class now, we see that its members
are all the fields needed to build `_$User`, as well as
a cache for the user that is built `_$v`. It seems that it
is a convention for builders to have a default constructor.

```dart
  UserBuilder get _$this {
    if (_$v != null) {
      _name = _$v.name;
      _nickname = _$v.nickname;
      _$v = null;
    }
    return this;
  }
```

Here we see a getter called `_$this`, which is used privately
for the public getters and setters. Essentially, this getter
keeps itself updated in case there were calls to `update`
in between calls to public getters and setters.

```dart
  @override
  void replace(User other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$User;
  }
```

The replace function simply updates the cached `_$User`.

```dart
  @override
  void update(void Function(UserBuilder) updates) {
    if (updates != null) updates(this);
  }
```

Passes the builder into the closure.

```dart
  @override
  _$User build() {
    final _$result = _$v ?? new _$User._(name: name, nickname: nickname);
    replace(_$result);
    return _$result;
  }
}
```

Uses the fields to build user and caches the user so that
it can be used for future builds while no field has been changed.

## Let's see it in action!
`bin/main.dart`
```dart
import 'package:built_value_basic_basic_tutorial/user.dart';

void main(List<String> arguments) {
  var user1 = User((b) => b..name = 'John Smith');
  var user2 = User((b) => b..name = 'John Smith');

  print(user1 == user2);
}
```

We had to rewrite our code to match the builder pattern.
Here is an equivalent snippet of code that explicitly
declares the closure and unpacks the cascade.

`bin/main.dart`
```dart
import 'package:built_value_basic_basic_tutorial/user.dart';

void updates(UserBuilder b) {
  b.name = 'John Smith';
}

void main(List<String> arguments) {
  var user1 = User(updates);
  var user2 = User(updates);

  print(user1 == user2);
}
```

And now we get the answer we want:
```bash
$ dart bin/main.dart
true
```

Hooray!

There is something about nested builders, but I don't really care
too much at the moment... Stay tuned!

# Built Collections for Dart
## Introduction
A bonus topic of sorts based on [this article](https://medium.com/dartlang/darts-built-collection-for-immutable-collections-db662f705eff?)
again by David Morgan about the
[Built Collections](https://pub.dev/packages/built_collection)
library.
We can also generate immutable collections using the
builder pattern. Each of the [core SDK collections](https://api.dartlang.org/stable/2.7.0/dart-core/dart-core-library.html#collections)
are split in two:
* **mutable** builder class
* **immutable** "built" class

We compute with builders and share the built classes. As you
might have guessed, immutable collections work well with
the immutable values we create with `built_value`.

## Article
We need to install `built_collection`.
`pubspec.yaml`
```yaml
dev_dependencies:
  built_collection: ^4.3.0
```

Let's see it in action!

`main.dart`
```dart
import 'package:built_collection/built_collection.dart';

void main() {
  var list = new BuiltList<int>([1, 2, 3]);
  print(list);
}
```

Suppose we want to add a value to it.

We need to actually create a new list due to immutability.

`main.dart`
```dart
  var builder = list.toBuilder();
  builder.add(4);
  var newList = builder.build();

  print(newList);
```

We can use cascade notation to shorten this:
`main.dart`
```dart
  var newList = (list.toBuilder()..add(4)).build();
```

But wait! We can do even better by using
[anonymous functions](https://dart.dev/guides/language/language-tour#anonymous-functions):

`main.dart`
```dart
  var newList = list.rebuild((b) => b.add(4));
```

We can use [method cascading](https://en.wikipedia.org/wiki/Method_cascading)
to do more complicated things:

`main.dart`
```dart
  var newList = list.rebuild((b) => b
    ..add(4)
    ..addAll([7, 6, 5])
    ..sort()
    ..remove(1));
  print(newList);
```

For those of you unfamiliar with method cascading (I am),
this is equivalent to:

`main.dart`
```dart
  var newListVerbose = list.rebuild((b) {
    b.add(4);
    b.addAll([7, 6, 5]);
    b.sort();
    b.remove(1);
  });
  print(newListVerbose);
```

And if the `rebuild` function is new to you (which it is
for me), we can go
even more verbose:

`main.dart`
```dart
  var builder = list.toBuilder();
  builder.add(4);
  builder.addAll([7, 6, 5]);
  builder.sort();
  builder.remove(1);
  var newListEvenMoreVerbose = builder.build();
  print(newListEvenMoreVerbose);
```

That's it! What a nice and convenient API.
