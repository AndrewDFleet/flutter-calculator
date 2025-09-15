// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithDeclaration);
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(
        ForElementResolutionTest_ForEachPartsWithPattern_await);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithDeclarations);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithPattern);
  });
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest {
  test_withDeclaration_scope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i in [1]) i]; // 1
  <double>[for (var i in [1.1]) i]; // 2
}
''');

    var node_1 = findNode.simple('i]; // 1');
    assertResolvedNodeText(node_1, r'''
SimpleIdentifier
  token: i
  element: i@26
  staticType: int
''');

    var node_2 = findNode.simple('i]; // 2');
    assertResolvedNodeText(node_2, r'''
SimpleIdentifier
  token: i
  element: i@65
  staticType: double
''');
  }

  test_withIdentifier_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
int v = 0;
main() {
  <int>[for (v in [1, 2, 3]) v];
}
''');

    var node = findNode.simple('v];');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: v
  element: <testLibraryFragment>::@getter::v#element
  staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@25
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@25
    staticType: dynamic
''');
  }

  test_iterable_List() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@35
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@35
    staticType: int
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  [for (var (a) in x) a];
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 38, 1),
    ]);
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@32
          type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@32
    staticType: InvalidType
''');
  }

  test_iterableContextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var (int a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: a
        declaredElement: a@28
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@28
    staticType: int
''');
  }

  test_iterableContextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var (a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@24
          type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<Object?> Function()
      staticType: Iterable<Object?>
      typeArgumentTypes
        Iterable<Object?>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@24
    staticType: Object?
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (final (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@37
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@37
    staticType: int
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (num a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        name: a
        declaredElement: a@39
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@39
    staticType: num
''');
  }

  test_topLevelVariableInitializer() async {
    await assertNoErrorsInCode(r'''
final x = [0, 1, 2];
final y = [ for (var (a) in x) a ];
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@43
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@getter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@43
    staticType: int
''');
  }

  test_topLevelVariableInitializer_scope() async {
    await assertNoErrorsInCode(r'''
final x = [0, 1, 2];
final y = [ for (var (x) in x) x ];
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: x
        declaredElement: hasImplicitType x@43
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@getter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: x
    element: x@43
    staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern_await
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) async {
  [await for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@37
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@37
    staticType: dynamic
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) async {
  [await for (var (a) in x) a];
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 50, 1),
    ]);
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@44
          type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@44
    staticType: InvalidType
''');
  }

  test_iterable_Stream() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@49
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@49
    staticType: int
''');
  }

  test_iterableContextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() async {
  [await for (var (int a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: a
        declaredElement: a@40
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<int> Function()
      staticType: Stream<int>
      typeArgumentTypes
        Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@40
    staticType: int
''');
  }

  test_iterableContextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() async {
  [await for (var (a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@36
          type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<Object?> Function()
      staticType: Stream<Object?>
      typeArgumentTypes
        Stream<Object?>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@36
    staticType: Object?
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (final (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@51
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@51
    staticType: int
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (var (num a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        name: a
        declaredElement: a@53
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    element: a@53
    staticType: num
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithDeclarations
    extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  <int>[for (; b(); ) 0];
}
''');

    var node = findNode.functionExpressionInvocation('b()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: bool Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
  staticInvokeType: bool Function()
  staticType: bool
''');
  }

  test_declaredVariableScope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');

    var node_1 = findNode.simple('i]; // 1');
    assertResolvedNodeText(node_1, r'''
SimpleIdentifier
  token: i
  element: i@26
  staticType: int
''');

    var node_2 = findNode.simple('i]; // 2');
    assertResolvedNodeText(node_2, r'''
SimpleIdentifier
  token: i
  element: i@78
  staticType: double
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithPattern
    extends PubPackageResolutionTest {
  test_it() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  [for (var (a, b) = x; b; a--) 0];
}
''');

    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredElement: hasImplicitType a@37
                type: int
              matchedValueType: int
            element2: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredElement: hasImplicitType b@40
                type: bool
              matchedValueType: bool
            element2: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        element: <testLibraryFragment>::@function::f::@parameter::x#element
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@40
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@37
          staticType: null
        operator: --
        readElement2: a@37
        readType: int
        writeElement2: a@37
        writeType: int
        element: dart:core::<fragment>::@class::num::@method::-#element
        staticType: int
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}
