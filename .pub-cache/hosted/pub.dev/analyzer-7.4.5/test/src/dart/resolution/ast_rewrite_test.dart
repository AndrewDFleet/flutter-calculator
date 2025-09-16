// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstRewriteImplicitCallReferenceTest);
    defineReflectiveTests(AstRewriteMethodInvocationTest);
    defineReflectiveTests(AstRewritePrefixedIdentifierTest);

    // TODO(srawlins): Add AstRewriteInstanceCreationExpressionTest test, likely
    // moving many test cases from ConstructorReferenceResolutionTest,
    // FunctionReferenceResolutionTest, and TypeLiteralResolutionTest.
    // TODO(srawlins): Add AstRewritePropertyAccessTest test, likely
    // moving many test cases from ConstructorReferenceResolutionTest,
    // FunctionReferenceResolutionTest, and TypeLiteralResolutionTest.
  });
}

@reflectiveTest
class AstRewriteImplicitCallReferenceTest extends PubPackageResolutionTest {
  test_assignment_indexExpression() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C c) {
  var map = <int, C>{};
  return map[1] = c;
}
''');

    var node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: AssignmentExpression
    leftHandSide: IndexExpression
      target: SimpleIdentifier
        token: map
        element: map@83
        staticType: Map<int, C>
      leftBracket: [
      index: IntegerLiteral
        literal: 1
        correspondingParameter: ParameterMember
          baseElement: dart:core::<fragment>::@class::Map::@method::[]=::@parameter::key#element
          substitution: {K: int, V: C}
        staticType: int
      rightBracket: ]
      element: <null>
      staticType: null
    operator: =
    rightHandSide: SimpleIdentifier
      token: c
      correspondingParameter: ParameterMember
        baseElement: dart:core::<fragment>::@class::Map::@method::[]=::@parameter::value#element
        substitution: {K: int, V: C}
      element: <testLibraryFragment>::@function::foo::@parameter::c#element
      staticType: C
    readElement2: <null>
    readType: null
    writeElement2: MethodMember
      baseElement: dart:core::<fragment>::@class::Map::@method::[]=#element
      substitution: {K: int, V: C}
    writeType: C
    element: <null>
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_conditional_else() async {
    await assertNoErrorsInCode('''
abstract class A {}
abstract class C extends A {
  void call();
}
void Function() f(A a, bool b, C c, dynamic d) => b ? d : (b ? a : c);
''');
    // `c` is in the "else" position of a conditional expression, so implicit
    // call tearoff logic should not apply to it.
    // Therefore the type of `b ? a : c` should be `A`.
    var expr = findNode.conditionalExpression('b ? a : c');
    assertResolvedNodeText(expr, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  colon: :
  elseExpression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  staticType: A
''');
  }

  test_conditional_then() async {
    await assertNoErrorsInCode('''
abstract class A {}
abstract class C extends A {
  void call();
}
void Function() f(A a, bool b, C c, dynamic d) => b ? d : (b ? c : a);
''');
    // `c` is in the "then" position of a conditional expression, so implicit
    // call tearoff logic should not apply to it.
    // Therefore the type of `b ? c : a` should be `A`.
    var expr = findNode.conditionalExpression('b ? c : a');
    assertResolvedNodeText(expr, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  colon: :
  elseExpression: SimpleIdentifier
    token: a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  staticType: A
''');
  }

  test_explicitTypeArguments() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

void foo() {
  var c = C();
  c<int>;
}
''');

    var node = findNode.implicitCallReference('c<int>');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: c@55
    staticType: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: int Function(int)
  typeArgumentTypes
    int
''');
  }

  test_ifNull_lhs() async {
    await assertErrorsInCode('''
abstract class A {}
abstract class C extends A {
  void call();
}

void Function() f(A a, bool b, C c, dynamic d) => b ? d : c ?? a;
''', [
      error(StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION, 130, 1),
    ]);
    // `c` is on the LHS of an if-null expression, so implicit call tearoff
    // logic should not apply to it.
    // Therefore the type of `c ?? a` should be `A`.
    var expr = findNode.binary('c ?? a');
    assertResolvedNodeText(expr, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: ??
  rightOperand: SimpleIdentifier
    token: a
    correspondingParameter: <null>
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  element: <null>
  staticInvokeType: null
  staticType: A
''');
  }

  test_ifNull_rhs() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C? c1, C c2) {
  return c1 ?? c2;
}
''');

    var node = findNode.implicitCallReference('c1 ?? c2');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: c1
      element: <testLibraryFragment>::@function::foo::@parameter::c1#element
      staticType: C?
    operator: ??
    rightOperand: SimpleIdentifier
      token: c2
      correspondingParameter: <null>
      element: <testLibraryFragment>::@function::foo::@parameter::c2#element
      staticType: C
    element: <null>
    staticInvokeType: null
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_listLiteral_element() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [c];
}
''');

    var node = findNode.implicitCallReference('c]');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_listLiteral_forElement() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [
    for (var _ in [1, 2, 3]) c,
  ];
}
''');

    var node = findNode.implicitCallReference('c,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_listLiteral_ifElement() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c) {
  return [
    if (1==2) c,
  ];
}
''');

    var node = findNode.implicitCallReference('c,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_listLiteral_ifElement_else() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

List<void Function(int)> foo(C c1, C c2) {
  return [
    if (1==2) c1
    else c2,
  ];
}
''');

    var node = findNode.implicitCallReference('c2,');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c2
    element: <testLibraryFragment>::@function::foo::@parameter::c2#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_parenthesized_cascade_target() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call();
  void m();
}
void Function() f(C c) => (c)..m();
''');

    var node = findNode.implicitCallReference('(c)');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: CascadeExpression
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: C
      rightParenthesis: )
      staticType: C
    cascadeSections
      MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: m
          element: <testLibraryFragment>::@class::C::@method::m#element
          staticType: void Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: void Function()
        staticType: void
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function()
''');
  }

  test_prefixedIdentifier() async {
    await assertNoErrorsInCode('''
abstract class C {
  C get c;
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c.c;
}
''');

    var node = findNode.implicitCallReference('c.c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      element: <testLibraryFragment>::@function::foo::@parameter::c#element
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: c
      element: <testLibraryFragment>::@class::C::@getter::c#element
      staticType: C
    element: <testLibraryFragment>::@class::C::@getter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_propertyAccess() async {
    await assertNoErrorsInCode('''
abstract class C {
  C get c;
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c.c.c;
}
''');

    var node = findNode.implicitCallReference('c.c.c');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: c
        element: <testLibraryFragment>::@function::foo::@parameter::c#element
        staticType: C
      period: .
      identifier: SimpleIdentifier
        token: c
        element: <testLibraryFragment>::@class::C::@getter::c#element
        staticType: C
      element: <testLibraryFragment>::@class::C::@getter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: c
      element: <testLibraryFragment>::@class::C::@getter::c#element
      staticType: C
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_setOrMapLiteral_element() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Set<void Function(int)> foo(C c) {
  return {c};
}
''');

    var node = findNode.implicitCallReference('c}');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_setOrMapLiteral_mapLiteralEntry_key() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Map<void Function(int), int> foo(C c) {
  return {c: 1};
}
''');

    var node = findNode.implicitCallReference('c:');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_setOrMapLiteral_mapLiteralEntry_value() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

Map<int, void Function(int)> foo(C c) {
  return {1: c};
}
''');

    var node = findNode.implicitCallReference('c}');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_simpleIdentifier() async {
    await assertNoErrorsInCode('''
abstract class C {
  void call(int t) => t;
}

void Function(int) foo(C c) {
  return c;
}
''');

    var node = findNode.implicitCallReference('c;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: c
    element: <testLibraryFragment>::@function::foo::@parameter::c#element
    staticType: C
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticType: void Function(int)
''');
  }

  test_simpleIdentifier_typeAlias() async {
    await assertNoErrorsInCode('''
class A {
  void call() {}
}
typedef B = A;
Function f(B b) => b;
''');

    var node = findNode.implicitCallReference('b;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: A
      alias: <testLibrary>::@typeAlias::B
  element: <testLibraryFragment>::@class::A::@method::call#element
  staticType: void Function()
''');
  }

  test_simpleIdentifier_typeVariable() async {
    await assertNoErrorsInCode('''
class A {
  void call() {}
}
Function f<X extends A>(X x) => x;
''');

    var node = findNode.implicitCallReference('x;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: X
  element: <testLibraryFragment>::@class::A::@method::call#element
  staticType: void Function()
''');
  }

  test_simpleIdentifier_typeVariable2() async {
    await assertNoErrorsInCode('''
class A {
  void call() {}
}
Function f<X extends A, Y extends X>(Y y) => y;
''');

    var node = findNode.implicitCallReference('y;');
    assertResolvedNodeText(node, r'''
ImplicitCallReference
  expression: SimpleIdentifier
    token: y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: Y
  element: <testLibraryFragment>::@class::A::@method::call#element
  staticType: void Function()
''');
  }

  test_simpleIdentifier_typeVariable2_nullable() async {
    await assertErrorsInCode('''
class A {
  void call() {}
}
Function f<X extends A, Y extends X?>(Y y) => y;
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 75, 1),
    ]);

    // Verify that no ImplicitCallReference was inserted.
    var node = findNode.expressionFunctionBody('y;').expression;
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: y
  element: <testLibraryFragment>::@function::f::@parameter::y#element
  staticType: Y
''');
  }

  test_simpleIdentifier_typeVariable_nullable() async {
    await assertErrorsInCode('''
class A {
  void call() {}
}
Function f<X extends A>(X? x) => x;
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 62, 1),
    ]);

    // Verify that no ImplicitCallReference was inserted.
    var node = findNode.expressionFunctionBody('x;').expression;
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: x
  element: <testLibraryFragment>::@function::f::@parameter::x#element
  staticType: X?
''');
  }
}

@reflectiveTest
class AstRewriteMethodInvocationTest extends PubPackageResolutionTest
    with AstRewriteMethodInvocationTestCases {}

mixin AstRewriteMethodInvocationTestCases on PubPackageResolutionTest {
  test_targetNull_cascade() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

f(A a) {
  a..foo();
}
''');

    var node = findNode.methodInvocation('foo();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_targetNull_class() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int a);
}

f() {
  A<int, String>(0);
}
''');

    var node = findNode.instanceCreation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          NamedType
            name: String
            element2: dart:core::@class::String
            type: String
        rightBracket: >
      element2: <testLibrary>::@class::A
      type: A<int, String>
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::A::@constructor::new#element
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetNull_extension() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E<T> on A {
  void foo() {}
}

f(A a) {
  E<int>(a).foo();
}
''');

    var node = findNode.extensionOverride('E<int>(a)');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: <null>
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
    rightParenthesis: )
  element2: <testLibrary>::@extension::E
  extendedType: A
  staticType: null
  typeArgumentTypes
    int
''');
  }

  test_targetNull_function() async {
    await assertNoErrorsInCode(r'''
void A<T, U>(int a) {}

f() {
  A<int, String>(0);
}
''');

    var node = findNode.methodInvocation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: A
    element: <testLibrary>::@function::A
    staticType: void Function<T, U>(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@function::A::@parameter::a#element
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
    String
''');
  }

  test_targetNull_typeAlias_interfaceType() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(int _);
}

typedef X<T, U> = A<T, U>;

void f() {
  X<int, String>(0);
}
''');

    var node = findNode.instanceCreation('X<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          NamedType
            name: String
            element2: dart:core::@class::String
            type: String
        rightBracket: >
      element2: <testLibrary>::@typeAlias::X
      type: A<int, String>
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::A::@constructor::new#element
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::_#element
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetNull_typeAlias_Never() async {
    await assertErrorsInCode(r'''
typedef X = Never;

void f() {
  X(0);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION, 33, 1),
    ]);

    // Not rewritten.
    findNode.methodInvocation('X(0)');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(T a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named(0);
}
''');

    var node = findNode.instanceCreation('A.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named::@parameter::a#element
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(int a);
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.named<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 50,
          5,
          messageContains: ["The constructor 'prefix.A.named'"]),
    ]);

    var node = findNode.instanceCreation('named<int>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named::@parameter::a#element
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetPrefixedIdentifier_prefix_class_constructor_typeArguments_new() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.new(int a);
}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A.new<int>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 48,
          5,
          messageContains: ["The constructor 'prefix.A.new'"]),
    ]);

    var node = findNode.instanceCreation('new<int>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: new
      element: ConstructorMember
        baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::new::@parameter::a#element
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetPrefixedIdentifier_prefix_getter_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
A get foo => A();

class A {
  void bar(int a) {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.foo.bar(0);
}
''');

    var node = findNode.methodInvocation('bar(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::<fragment>::@getter::foo#element
      staticType: A
    element: package:test/a.dart::<fragment>::@getter::foo#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: bar
    element: package:test/a.dart::<fragment>::@class::A::@method::bar#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::<fragment>::@class::A::@method::bar::@parameter::a#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_targetPrefixedIdentifier_typeAlias_interfaceType_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

void f() {
  prefix.X.named(0);
}
''');

    var node = findNode.instanceCreation('X.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: X
      element2: package:test/a.dart::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::named::@parameter::a#element
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetSimpleIdentifier_class_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

f() {
  A.named(0);
}
''');

    var node = findNode.instanceCreation('A.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibraryFragment>::@class::A::@constructor::named#element
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::A::@constructor::named#element
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::A::@constructor::named::@parameter::a#element
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.named(int a);
}

f() {
  A.named<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 52,
          13,
          messageContains: ["The constructor 'A.named'"]),
    ]);

    // TODO(scheglov): Move type arguments
    var node = findNode.instanceCreation('named<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<dynamic, dynamic>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibraryFragment>::@class::A::@constructor::named#element
        substitution: {T: dynamic, U: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::A::@constructor::named#element
      substitution: {T: dynamic, U: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::A::@constructor::named::@parameter::a#element
          substitution: {T: dynamic, U: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic, dynamic>
''');
  }

  test_targetSimpleIdentifier_class_constructor_typeArguments_new() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  A.new(int a);
}

f() {
  A.new<int, String>(0);
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 48,
          13,
          messageContains: ["The constructor 'A.new'"]),
    ]);

    // TODO(scheglov): Move type arguments
    var node = findNode.instanceCreation('new<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element2: <testLibrary>::@class::A
      type: A<dynamic, dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      element: ConstructorMember
        baseElement: <testLibraryFragment>::@class::A::@constructor::new#element
        substitution: {T: dynamic, U: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::A::@constructor::new#element
      substitution: {T: dynamic, U: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a#element
          substitution: {T: dynamic, U: dynamic}
        staticType: int
    rightParenthesis: )
  staticType: A<dynamic, dynamic>
''');
  }

  test_targetSimpleIdentifier_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int a) {}
}

f() {
  A.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibraryFragment>::@class::A::@method::foo::@parameter::a#element
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_targetSimpleIdentifier_prefix_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T, U> {
  A(int a);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var node = findNode.instanceCreation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element2: <testLibraryFragment>::@prefix2::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          NamedType
            name: String
            element2: dart:core::@class::String
            type: String
        rightBracket: >
      element2: package:test/a.dart::@class::A
      type: A<int, String>
    element: ConstructorMember
      baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::<fragment>::@class::A::@constructor::new::@parameter::a#element
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_targetSimpleIdentifier_prefix_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}

extension E<T> on A {
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f(prefix.A a) {
  prefix.E<int>(a).foo();
}
''');

    var node = findNode.extensionOverride('E<int>(a)');
    assertResolvedNodeText(node, r'''
ExtensionOverride
  importPrefix: ImportPrefixReference
    name: prefix
    period: .
    element2: <testLibraryFragment>::@prefix2::prefix
  name: E
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: a
        correspondingParameter: <null>
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
    rightParenthesis: )
  element2: package:test/a.dart::@extension::E
  extendedType: A
  staticType: null
  typeArgumentTypes
    int
''');
  }

  test_targetSimpleIdentifier_prefix_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void A<T, U>(int a) {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

f() {
  prefix.A<int, String>(0);
}
''');

    var node = findNode.methodInvocation('A<int, String>(0);');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    element: <testLibraryFragment>::@prefix2::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: A
    element: package:test/a.dart::@function::A
    staticType: void Function<T, U>(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: package:test/a.dart::<fragment>::@function::A::@parameter::a#element
          substitution: {T: int, U: String}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
    String
''');
  }

  test_targetSimpleIdentifier_typeAlias_interfaceType_constructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T a);
}

typedef X<T> = A<T>;

void f() {
  X.named(0);
}
''');

    var node = findNode.instanceCreation('X.named(0);');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element2: <testLibrary>::@typeAlias::X
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibraryFragment>::@class::A::@constructor::named#element
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibraryFragment>::@class::A::@constructor::named#element
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: ParameterMember
          baseElement: <testLibraryFragment>::@class::A::@constructor::named::@parameter::a#element
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }
}

@reflectiveTest
class AstRewritePrefixedIdentifierTest extends PubPackageResolutionTest {
  test_constructorReference_inAssignment_onLeftSide() async {
    await assertErrorsInCode('''
class C {}

void f() {
  C.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 3),
    ]);

    var identifier = findNode.prefixed('C.new');
    // The left side of the assignment is resolved by
    // [PropertyElementResolver._resolveTargetClassElement], which looks for
    // getters and setters on `C`, and does not recover with other elements
    // (methods, constructors). This prefixed identifier can have a real
    // `staticElement` if we add such recovery.
    expect(identifier.element, isNull);
  }

  test_constructorReference_inAssignment_onRightSide() async {
    await assertNoErrorsInCode('''
class C {}

Function? f;
void g() {
  f = C.new;
}
''');

    var node = findNode.constructorReference('C.new');
    assertResolvedNodeText(node, r'''
ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: C
      element2: <testLibrary>::@class::C
      type: null
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
      staticType: null
    element: <testLibraryFragment>::@class::C::@constructor::new#element
  correspondingParameter: <testLibraryFragment>::@setter::f::@parameter::_f#element
  staticType: C Function()
''');
  }

  // TODO(srawlins): Complete tests of all cases of rewriting (or not) a
  // prefixed identifier.
}
