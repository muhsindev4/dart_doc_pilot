class Documentation {
  final List<ClassDoc> classes;
  final List<EnumDoc> enums;
  final List<TypedefDoc> typedefs;
  final List<ExtensionDoc> extensions;

  Documentation({
    this.classes = const [],
    this.enums = const [],
    this.typedefs = const [],
    this.extensions = const [],
  });

  List<MethodDoc> getAllMethods() {
    return classes.expand((c) => c.methods).toList();
  }

  List<FieldDoc> getAllFields() {
    return classes.expand((c) => c.fields).toList();
  }

  Map<String, List<ClassDoc>> getClassesByCategory() {
    final map = <String, List<ClassDoc>>{};
    for (final cls in classes) {
      final category = cls.category ?? 'Uncategorized';
      map.putIfAbsent(category, () => []).add(cls);
    }
    return map;
  }

  Map<String, Map<String, List<ClassDoc>>>
  getClassesByCategoryAndSubCategory() {
    final map = <String, Map<String, List<ClassDoc>>>{};
    for (final cls in classes) {
      final category = cls.category ?? 'Uncategorized';
      final subCategory = cls.subCategory ?? 'General';
      map.putIfAbsent(category, () => {});
      map[category]!.putIfAbsent(subCategory, () => []).add(cls);
    }
    return map;
  }
}

class ClassDoc {
  final String name;
  final String? description;
  final String? category;
  final String? subCategory;
  final String filePath;
  final List<MethodDoc> methods;
  final List<FieldDoc> fields;
  final List<String> constructors;
  final String? extendsClass;
  final List<String> implements;
  final List<String> mixins;
  final bool isAbstract;

  ClassDoc({
    required this.name,
    this.description,
    this.category,
    this.subCategory,
    required this.filePath,
    this.methods = const [],
    this.fields = const [],
    this.constructors = const [],
    this.extendsClass,
    this.implements = const [],
    this.mixins = const [],
    this.isAbstract = false,
  });

  String get categoryPath {
    if (category == null) return 'Uncategorized';
    if (subCategory == null) return category!;
    return '$category / $subCategory';
  }
}

class MethodDoc {
  final String name;
  final String? description;
  final String returnType;
  final List<ParameterDoc> parameters;
  final bool isStatic;
  final bool isAsync;
  final String? example;

  MethodDoc({
    required this.name,
    this.description,
    required this.returnType,
    this.parameters = const [],
    this.isStatic = false,
    this.isAsync = false,
    this.example,
  });

  String get signature {
    final params = parameters.map((p) => p.signature).join(', ');
    final asyncMarker = isAsync ? 'async ' : '';
    final staticMarker = isStatic ? 'static ' : '';
    return '$staticMarker$returnType $name($params) $asyncMarker';
  }
}

class ParameterDoc {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final String? description;

  ParameterDoc({
    required this.name,
    required this.type,
    this.isRequired = false,
    this.isNamed = false,
    this.defaultValue,
    this.description,
  });

  String get signature {
    final reqMarker = isRequired ? 'required ' : '';
    final defValue = defaultValue != null ? ' = $defaultValue' : '';
    return '$reqMarker$type $name$defValue';
  }
}

class FieldDoc {
  final String name;
  final String? description;
  final String type;
  final bool isFinal;
  final bool isStatic;
  final bool isConst;
  final String? defaultValue;

  FieldDoc({
    required this.name,
    this.description,
    required this.type,
    this.isFinal = false,
    this.isStatic = false,
    this.isConst = false,
    this.defaultValue,
  });

  String get signature {
    final constMarker = isConst ? 'const ' : '';
    final finalMarker = isFinal && !isConst ? 'final ' : '';
    final staticMarker = isStatic ? 'static ' : '';
    return '$staticMarker$constMarker$finalMarker$type $name';
  }
}

class EnumDoc {
  final String name;
  final String? description;
  final String? category;
  final List<String> values;
  final String filePath;

  EnumDoc({
    required this.name,
    this.description,
    this.category,
    required this.values,
    required this.filePath,
  });
}

class TypedefDoc {
  final String name;
  final String? description;
  final String signature;
  final String filePath;

  TypedefDoc({
    required this.name,
    this.description,
    required this.signature,
    required this.filePath,
  });
}

class ExtensionDoc {
  final String name;
  final String? description;
  final String onType;
  final List<MethodDoc> methods;
  final String filePath;

  ExtensionDoc({
    required this.name,
    this.description,
    required this.onType,
    this.methods = const [],
    required this.filePath,
  });
}
