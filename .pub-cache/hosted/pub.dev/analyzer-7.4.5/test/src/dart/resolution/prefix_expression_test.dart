// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixExpressionResolutionTest);
  });
}

@reflectiveTest
class PrefixExpressionResolutionTest extends PubPackageResolutionTest {
  test_bang_bool_context() async {
    await assertNoErrorsInCode(r'''
T f<T>() {
  throw 42;
}

main() {
  !f();
}
''');

    var node = findNode.methodInvocation('f();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_bang_bool_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  !x;
}
''');

    var node = findNode.prefix('!x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: bool
  element: <null>
  staticType: bool
''');
  }

  test_bang_int_localVariable() async {
    await assertErrorsInCode(r'''
void f(int x) {
  !x;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 19, 1),
    ]);

    var node = findNode.prefix('!x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: int
  element: <null>
  staticType: bool
''');
  }

  test_bang_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  bool get foo => true;
}

void f(A? a) {
  !a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION,
          55, 6),
    ]);

    assertResolvedNodeText(findNode.prefix('!a'), r'''
PrefixExpression
  operator: !
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: bool
    staticType: bool?
  element: <null>
  staticType: bool
''');
  }

  test_bang_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    !super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 28, 5),
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 28, 5),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SuperExpression
    superKeyword: super
    staticType: A
  element: <null>
  staticType: bool
''');
  }

  test_formalParameter_inc_inc() async {
    await assertErrorsInCode(r'''
void f(int x) {
  ++ ++ x;
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 24, 1),
    ]);

    var node = findNode.prefix('++ ++ x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: int
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: int
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_formalParameter_inc_unresolved() async {
    await assertErrorsInCode(r'''
class A {}

void f(A a) {
  ++a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 28, 2),
    ]);

    var node = findNode.prefix('++a');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: null
  readElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  readType: A
  writeElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  writeType: A
  element: <null>
  staticType: InvalidType
''');
  }

  test_inc_indexExpression_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  ++a[0];
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index#element
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_inc_indexExpression_super() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    ++super[0];
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index#element
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_inc_indexExpression_this() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    ++this[0];
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index#element
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_inc_unresolvedIdentifier() async {
    await assertErrorsInCode(r'''
void f() {
  ++x;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 15, 1),
    ]);

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_minus_augmentedExpression_augments_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int foo = 0;
}
''');

    await assertNoErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int foo = -augmented;
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@field::foo
    fragment: package:test/a.dart::<fragment>::@class::A::@field::foo
    staticType: int
  staticElement: dart:core::<fragment>::@class::int::@method::unary-
  element: dart:core::<fragment>::@class::int::@method::unary-#element
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_minus_augmentedExpression_augments_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int get foo => 0;
}
''');

    await assertNoErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int get foo {
    return -augmented;
  }
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@getter::foo
    fragment: package:test/a.dart::<fragment>::@class::A::@getter::foo
    staticType: int
  staticElement: dart:core::<fragment>::@class::int::@method::unary-
  element: dart:core::<fragment>::@class::int::@method::unary-#element
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_minus_augmentedExpression_augments_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void foo() {}
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment void foo() {
    -augmented;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR, 65, 9),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@method::foo
    fragment: package:test/a.dart::<fragment>::@class::A::@method::foo
    staticType: A
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_minus_augmentedExpression_augments_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  set foo(int _) {}
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment set foo(int _) {
    -augmented;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER, 69, 9),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@setter::foo
    fragment: package:test/a.dart::<fragment>::@class::A::@setter::foo
    staticType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_minus_augmentedExpression_augments_unaryMinus() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int operator-() => 0;
}
''');

    await assertNoErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int operator-() {
    return -augmented;
  }
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@method::unary-
    fragment: package:test/a.dart::<fragment>::@class::A::@method::unary-
    staticType: A
  staticElement: package:test/a.dart::@fragment::package:test/test.dart::@classAugmentation::A::@methodAugmentation::unary-
  element: package:test/a.dart::<fragment>::@class::A::@method::unary-#element
  staticType: int
''');
  }

  test_minus_dynamicIdentifier() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  -a;
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_minus_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  -a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          50, 1),
    ]);

    assertResolvedNodeText(findNode.prefix('-a'), r'''
PrefixExpression
  operator: -
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: int
    staticType: int?
  element: dart:core::<fragment>::@class::int::@method::unary-#element
  staticType: int
''');
  }

  test_minus_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  -x;
}
''');

    var node = findNode.prefix('-x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: int
  element: dart:core::<fragment>::@class::int::@method::unary-#element
  staticType: int
''');
  }

  test_plusPlus_depromote() async {
    await assertNoErrorsInCode(r'''
class A {
  Object operator +(int _) => this;
}

void f(Object x) {
  if (x is A) {
    ++x;
  }
}
''');

    assertResolvedNodeText(findNode.prefix('++x'), r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: A
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: Object
  element: <testLibraryFragment>::@class::A::@method::+#element
  staticType: Object
''');
  }

  test_plusPlus_notLValue_extensionOverride() async {
    await assertErrorsInCode(r'''
class C {}

extension Ext on C {
  int operator +(int _) {
    return 0;
  }
}

void f(C c) {
  ++Ext(c);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 103, 1),
    ]);

    var node = findNode.prefix('++Ext');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: ExtensionOverride
    name: Ext
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: c
          correspondingParameter: <null>
          element: <testLibraryFragment>::@function::f::@parameter::c#element
          staticType: C
      rightParenthesis: )
    element2: <testLibrary>::@extension::Ext
    extendedType: C
    staticType: null
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <testLibraryFragment>::@extension::Ext::@method::+#element
  staticType: InvalidType
''');
  }

  test_plusPlus_notLValue_simpleIdentifier_typeLiteral() async {
    await assertErrorsInCode(r'''
void f() {
  ++int;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 15, 3),
    ]);

    var node = findNode.prefix('++int');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  readElement2: dart:core::@class::int
  readType: InvalidType
  writeElement2: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo = 0;
}

void f(A? a) {
  ++a?.foo;
}
''');

    assertResolvedNodeText(findNode.prefix('++a'), r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@getter::foo#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int?
''');
  }

  test_plusPlus_ofExtensionType() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
  set foo(int _) {}
}

void f(A a) {
  ++a.foo;
}
''');

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@extensionType::A::@getter::foo#element
  readType: int
  writeElement2: <testLibraryFragment>::@extensionType::A::@setter::foo#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f(A a) {
  ++a.x;
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_prefixedIdentifier_topLevel() async {
    newFile('$testPackageLibPath/a.dart', r'''
int x = 0;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  ++p.x;
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  readElement2: package:test/a.dart::<fragment>::@getter::x#element
  readType: int
  writeElement2: package:test/a.dart::<fragment>::@setter::x#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_instance() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}

void f() {
  ++A().x;
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element2: <testLibrary>::@class::A
          type: A
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_super() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++super.x;
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_propertyAccess_this() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;

  void f() {
    ++this.x;
  }
}
''');

    var node = findNode.prefix('++');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_double() async {
    await assertNoErrorsInCode(r'''
void f(double x) {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: double
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: double
  element: dart:core::<fragment>::@class::double::@method::+#element
  staticType: double
''');
  }

  test_plusPlus_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_parameter_num() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: num
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_parameter_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T extends num>(T x) {
  ++x;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 31, 3),
    ]);

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: T
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: T
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: num
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_superSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  int get x => 0;
  void f() {
    ++x;
  }
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@class::B::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_thisGetter_thisSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
  void f() {
    ++x;
  }
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

void f() {
  ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_simpleIdentifier_topGetter_topSetter_fromClass() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(num _) {}

class A {
  void f() {
    ++x;
  }
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  test_plusPlus_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    ++super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 29, 5),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SuperExpression
    superKeyword: super
    staticType: A
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_plusPlus_switchExpression() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  ++switch (x) {
    _ => 0,
  };
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 51, 1),
    ]);

    var node = findNode.prefix('++switch');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Verify that we get all necessary types when building the dependencies
  /// graph during top-level inference.
  test_plusPlus_topLevelInference() async {
    await assertNoErrorsInCode(r'''
var x = 0;

class A {
  final y = ++x;
}
''');

    var node = findNode.prefix('++x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: int
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_tilde_augmentedExpression_augments_unaryMinus() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  int operator-() => 0;
}
''');

    await assertErrorsInCode('''
part of 'a.dart';

augment class A {
  augment int operator-() {
    return ~augmented;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR, 77, 9),
    ]);

    var node = findNode.singlePrefixExpression;
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: AugmentedExpression
    augmentedKeyword: augmented
    element: package:test/a.dart::<fragment>::@class::A::@method::unary-
    fragment: package:test/a.dart::<fragment>::@class::A::@method::unary-
    staticType: A
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_tilde_no_nullShorting() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  ~a?.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          50, 1),
    ]);

    assertResolvedNodeText(findNode.prefix('~a'), r'''
PrefixExpression
  operator: ~
  operand: PropertyAccess
    target: SimpleIdentifier
      token: a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: int
    staticType: int?
  element: dart:core::<fragment>::@class::int::@method::~#element
  staticType: int
''');
  }

  test_tilde_simpleIdentifier_parameter_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  ~x;
}
''');

    var node = findNode.prefix('~x');
    assertResolvedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: int
  element: dart:core::<fragment>::@class::int::@method::~#element
  staticType: int
''');
  }
}
