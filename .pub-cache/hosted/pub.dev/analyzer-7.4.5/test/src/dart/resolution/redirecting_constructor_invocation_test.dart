// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectingConstructorInvocationResolutionTest);
  });
}

@reflectiveTest
class RedirectingConstructorInvocationResolutionTest
    extends PubPackageResolutionTest {
  test_named() async {
    await assertNoErrorsInCode(r'''
class C {
  C.named(int a);
  C.other() : this.named(0);
}
''');

    var node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <testLibraryFragment>::@class::C::@constructor::named#element
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::named::@parameter::a#element
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::C::@constructor::named#element
''');
  }

  test_named_unresolved() async {
    await assertErrorsInCode(r'''
class C {
  C.other() : this.named(0);
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 24,
          13),
    ]);

    var node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: <null>
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
''');
  }

  test_unnamed() async {
    await assertNoErrorsInCode(r'''
class C {
  C(int a);
  C.other() : this(0);
}
''');

    var node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibraryFragment>::@class::C::@constructor::new::@parameter::a#element
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::C::@constructor::new#element
''');
  }

  test_unnamed_unresolved() async {
    await assertErrorsInCode(r'''
class C {
  C.named();
  C.other() : this(0);
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 37,
          7),
    ]);

    var node = findNode.singleRedirectingConstructorInvocation;
    assertResolvedNodeText(node, r'''
RedirectingConstructorInvocation
  thisKeyword: this
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
''');
  }
}
