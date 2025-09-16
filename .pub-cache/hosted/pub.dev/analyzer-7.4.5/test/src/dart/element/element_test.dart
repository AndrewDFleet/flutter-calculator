// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import '../../summary/elements_base.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementAnnotationImplTest);
    defineReflectiveTests(ElementLocationImplTest);
    defineReflectiveTests(FieldElementImplTest);
    defineReflectiveTests(FunctionTypeImplTest);
    defineReflectiveTests(MaybeAugmentedInstanceElementMixinTest);
    defineReflectiveTests(TypeParameterTypeImplTest);
  });
}

@reflectiveTest
class ElementAnnotationImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final String f;
  const A(this.f);
}
void f(@A('x') int p) {}
''');
    await resolveTestCode(r'''
import 'a.dart';
main() {
  f(3);
}
''');
    var argument = findNode.integerLiteral('3');
    var parameter = argument.correspondingParameter!;

    ElementAnnotation annotation = parameter.metadata[0];

    DartObject value = annotation.computeConstantValue()!;
    expect(value.getField('f')!.toStringValue(), 'x');
  }
}

@reflectiveTest
class ElementLocationImplTest {
  void test_create_encoding() {
    String encoding = "a;b;c";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  /// For example unnamed constructor.
  void test_create_encoding_emptyLast() {
    String encoding = "a;b;c;";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_equals_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = ElementLocationImpl.con2(encoding);
    expect(first == second, isTrue);
  }

  void test_equals_notEqual_differentLengths() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = ElementLocationImpl.con2("a;b;c;d");
    expect(first == second, isFalse);
  }

  void test_equals_notEqual_notLocation() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    // ignore: unrelated_type_equality_checks
    expect(first == "a;b;d", isFalse);
  }

  void test_equals_notEqual_sameLengths() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = ElementLocationImpl.con2("a;b;d");
    expect(first == second, isFalse);
  }

  void test_getComponents() {
    String encoding = "a;b;c";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    List<String> components = location.components;
    expect(components, hasLength(3));
    expect(components[0], "a");
    expect(components[1], "b");
    expect(components[2], "c");
  }

  void test_getEncoding() {
    String encoding = "a;b;c;;d";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_hashCode_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = ElementLocationImpl.con2(encoding);
    expect(first.hashCode == second.hashCode, isTrue);
  }
}

@reflectiveTest
class FieldElementImplTest extends PubPackageResolutionTest {
  test_isEnumConstant() async {
    await resolveTestCode(r'''
enum B {B1, B2, B3}
''');
    var B = findElement2.enum_('B');

    var b2Element = B.getField2('B2')!;
    expect(b2Element.isEnumConstant, isTrue);

    var valuesElement = B.getField2('values')!;
    expect(valuesElement.isEnumConstant, isFalse);
  }
}

@reflectiveTest
class FunctionTypeImplTest extends AbstractTypeSystemTest {
  void assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString();
    expect(typeStr, expected);
  }

  void test_getNamedParameterTypes_namedParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
        requiredParameter(name: 'a', type: intNone),
        namedParameter(name: 'b', type: doubleNone),
        namedParameter(name: 'c', type: stringNone),
      ],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(2));
    expect(types['b'], doubleNone);
    expect(types['c'], stringNone);
  }

  void test_getNamedParameterTypes_noNamedParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNamedParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noNormalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
        positionalParameter(type: intNone),
        positionalParameter(type: doubleNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_normalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], intNone);
    expect(types[1], doubleNone);
  }

  void test_getOptionalParameterTypes_noOptionalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
        requiredParameter(name: 'a', type: intNone),
        namedParameter(name: 'b', type: doubleNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_optionalParameters() {
    var type = functionTypeNone(
      typeParameters: [],
      formalParameters: [
        requiredParameter(type: intNone),
        positionalParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], doubleNone);
    expect(types[1], stringNone);
  }
}

@reflectiveTest
class MaybeAugmentedInstanceElementMixinTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_lookUpGetter_declared() async {
    var library = await buildLibrary('''
class A {
  int get g {}
}
''');
    var elementA = library.getClass2('A')!;
    var getter = elementA.getGetter2('g');
    expect(elementA.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpGetter_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int get g {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
''');
    var elementA = library.getClass2('A')!;
    var getter = elementA.getGetter2('g')!;
    expect(elementA.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_inherited() async {
    var library = await buildLibrary('''
class A {
  int get g {}
}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var getter = classA.getGetter2('g');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_inherited_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int get g {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var getter = classA.getGetter2('g');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_inherited_fromMixin() async {
    var library = await buildLibrary('''
mixin A {
  int get g {}
}
class B with A {}
''');
    var mixinA = library.getMixin2('A')!;
    var getter = mixinA.getGetter2('g');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpGetter2(name: 'g', library: library), same(getter));
  }

  test_lookUpGetter_undeclared() async {
    var library = await buildLibrary('''
class A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpGetter2(name: 'g', library: library), isNull);
  }

  test_lookUpGetter_undeclared_recursive() async {
    var library = await buildLibrary('''
class A extends B {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpGetter2(name: 'g', library: library), isNull);
  }

  test_lookUpMethod_declared() async {
    var library = await buildLibrary('''
class A {
  int m() {}
}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), same(method));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpMethod_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int m() {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_inherited() async {
    var library = await buildLibrary('''
class A {
  int m() {}
}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_inherited_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  int m() {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var method = classA.getMethod2('m');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_inherited_fromMixin() async {
    var library = await buildLibrary('''
mixin A {
  int m() {}
}
class B with A {}
''');
    var mixinA = library.getMixin2('A')!;
    var method = mixinA.getMethod2('m');
    var classB = library.getClass2('B')!;
    expect(classB.lookUpMethod2(name: 'm', library: library), same(method));
  }

  test_lookUpMethod_undeclared() async {
    var library = await buildLibrary('''
class A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), isNull);
  }

  test_lookUpMethod_undeclared_recursive() async {
    var library = await buildLibrary('''
class A extends B {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpMethod2(name: 'm', library: library), isNull);
  }

  test_lookUpSetter_declared() async {
    var library = await buildLibrary('''
class A {
  set s(x) {}
}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    expect(classA.lookUpSetter2(name: 's', library: library), same(setter));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpSetter_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  set s(x) {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    expect(classA.lookUpSetter2(name: 's', library: library), same(setter));
  }

  test_lookUpSetter_inherited() async {
    var library = await buildLibrary('''
class A {
  set s(x) {}
}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    var classB = library.getClass2('B')!;
    expect(classB.lookUpSetter2(name: 's', library: library), same(setter));
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_lookUpSetter_inherited_fromAugmentation() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class A {
  set s(x) {}
}
''');
    var library = await buildLibrary('''
part 'a.dart';

class A {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    var setter = classA.getSetter2('s')!;
    var classB = library.getClass2('B')!;
    expect(classB.lookUpSetter2(name: 's', library: library), same(setter));
  }

  test_lookUpSetter_inherited_fromMixin() async {
    var library = await buildLibrary('''
mixin A {
  set s(x) {}
}
class B with A {}
''');
    var mixinA = library.getMixin2('A')!;
    var setter = mixinA.getSetter2('s')!;
    var classB = library.getClass2('B')!;
    expect(classB.lookUpSetter2(name: 's', library: library), same(setter));
  }

  test_lookUpSetter_undeclared() async {
    var library = await buildLibrary('''
class A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpSetter2(name: 's', library: library), isNull);
  }

  test_lookUpSetter_undeclared_recursive() async {
    var library = await buildLibrary('''
class A extends B {}
class B extends A {}
''');
    var classA = library.getClass2('A')!;
    expect(classA.lookUpSetter2(name: 's', library: library), isNull);
  }
}

@reflectiveTest
class TypeParameterTypeImplTest extends AbstractTypeSystemTest {
  void test_asInstanceOf_hasBound_element() {
    var T = typeParameter('T', bound: listNone(intNone));
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement2,
      'Iterable<int>',
    );
  }

  void test_asInstanceOf_hasBound_element_noMatch() {
    var T = typeParameter('T', bound: numNone);
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement2,
      null,
    );
  }

  void test_asInstanceOf_hasBound_promoted() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(
        T,
        promotedBound: listNone(intNone),
      ),
      typeProvider.iterableElement2,
      'Iterable<int>',
    );
  }

  void test_asInstanceOf_hasBound_promoted_noMatch() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(
        T,
        promotedBound: numNone,
      ),
      typeProvider.iterableElement2,
      null,
    );
  }

  void test_asInstanceOf_noBound() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement2,
      null,
    );
  }

  void test_creation() {
    var element = typeParameter('E');
    expect(typeParameterTypeNone(element), isNotNull);
  }

  void test_getElement() {
    var element = typeParameter('E');
    TypeParameterTypeImpl type = typeParameterTypeNone(element);
    expect(type.element3, element);
  }

  void _assert_asInstanceOf(
    TypeImpl type,
    ClassElement2 element,
    String? expected,
  ) {
    var result = type.asInstanceOf2(element);
    expect(
      result?.getDisplayString(),
      expected,
    );
  }
}
