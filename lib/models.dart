/// Core data models for documentation extraction
library models;

/// Represents the complete documentation of a Dart project
class Documentation {
  final String projectName;
  final String version;
  final DateTime generatedAt;
  final List<ClassDoc> classes;
  final List<EnumDoc> enums;
  final List<TypedefDoc> typedefs;
  final List<ExtensionDoc> extensions;
  final Map<String, List<String>> categories;

  Documentation({
    required this.projectName,
    required this.version,
    required this.generatedAt,
    required this.classes,
    required this.enums,
    required this.typedefs,
    required this.extensions,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
    'projectName': projectName,
    'version': version,
    'generatedAt': generatedAt.toIso8601String(),
    'classes': classes.map((c) => c.toJson()).toList(),
    'enums': enums.map((e) => e.toJson()).toList(),
    'typedefs': typedefs.map((t) => t.toJson()).toList(),
    'extensions': extensions.map((e) => e.toJson()).toList(),
    'categories': categories,
  };
}

/// Represents a documented class
class ClassDoc {
  final String name;
  final String? description;
  final String? category;
  final String? subCategory;
  final String filePath;
  final int lineNumber;
  final bool isAbstract;
  final String? superclass;
  final List<String> mixins;
  final List<String> interfaces;
  final List<String> typeParameters;
  final List<ConstructorDoc> constructors;
  final List<FieldDoc> fields;
  final List<MethodDoc> methods;
  final List<CodeBlock> codeExamples;
  final List<DocLink> links;
  final Map<String, String> macros;
  final Map<String, String> templates;

  ClassDoc({
    required this.name,
    this.description,
    this.category,
    this.subCategory,
    required this.filePath,
    required this.lineNumber,
    this.isAbstract = false,
    this.superclass,
    this.mixins = const [],
    this.interfaces = const [],
    this.typeParameters = const [],
    this.constructors = const [],
    this.fields = const [],
    this.methods = const [],
    this.codeExamples = const [],
    this.links = const [],
    this.macros = const {},
    this.templates = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'subCategory': subCategory,
    'filePath': filePath,
    'lineNumber': lineNumber,
    'isAbstract': isAbstract,
    'superclass': superclass,
    'mixins': mixins,
    'interfaces': interfaces,
    'typeParameters': typeParameters,
    'constructors': constructors.map((c) => c.toJson()).toList(),
    'fields': fields.map((f) => f.toJson()).toList(),
    'methods': methods.map((m) => m.toJson()).toList(),
    'codeExamples': codeExamples.map((c) => c.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
    'macros': macros,
    'templates': templates,
  };
}

/// Represents a constructor
class ConstructorDoc {
  final String? name;
  final String? description;
  final bool isConst;
  final bool isFactory;
  final List<ParameterDoc> parameters;
  final List<CodeBlock> codeExamples;

  ConstructorDoc({
    this.name,
    this.description,
    this.isConst = false,
    this.isFactory = false,
    this.parameters = const [],
    this.codeExamples = const [],
  });

  String get displayName => name == null || name!.isEmpty ? 'default' : name!;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'isConst': isConst,
    'isFactory': isFactory,
    'parameters': parameters.map((p) => p.toJson()).toList(),
    'codeExamples': codeExamples.map((c) => c.toJson()).toList(),
  };
}

/// Represents a field/property
class FieldDoc {
  final String name;
  final String type;
  final String? description;
  final bool isStatic;
  final bool isFinal;
  final bool isConst;
  final bool isLate;
  final String? defaultValue;

  FieldDoc({
    required this.name,
    required this.type,
    this.description,
    this.isStatic = false,
    this.isFinal = false,
    this.isConst = false,
    this.isLate = false,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'description': description,
    'isStatic': isStatic,
    'isFinal': isFinal,
    'isConst': isConst,
    'isLate': isLate,
    'defaultValue': defaultValue,
  };
}

/// Represents a method
class MethodDoc {
  final String name;
  final String returnType;
  final String? description;
  final bool isStatic;
  final bool isAbstract;
  final bool isAsync;
  final bool isGetter;
  final bool isSetter;
  final List<ParameterDoc> parameters;
  final List<CodeBlock> codeExamples;
  final List<DocLink> links;

  MethodDoc({
    required this.name,
    required this.returnType,
    this.description,
    this.isStatic = false,
    this.isAbstract = false,
    this.isAsync = false,
    this.isGetter = false,
    this.isSetter = false,
    this.parameters = const [],
    this.codeExamples = const [],
    this.links = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'returnType': returnType,
    'description': description,
    'isStatic': isStatic,
    'isAbstract': isAbstract,
    'isAsync': isAsync,
    'isGetter': isGetter,
    'isSetter': isSetter,
    'parameters': parameters.map((p) => p.toJson()).toList(),
    'codeExamples': codeExamples.map((c) => c.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
  };
}

/// Represents a method/constructor parameter
class ParameterDoc {
  final String name;
  final String type;
  final String? description;
  final bool isRequired;
  final bool isNamed;
  final bool isPositional;
  final String? defaultValue;

  ParameterDoc({
    required this.name,
    required this.type,
    this.description,
    this.isRequired = false,
    this.isNamed = false,
    this.isPositional = true,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'description': description,
    'isRequired': isRequired,
    'isNamed': isNamed,
    'isPositional': isPositional,
    'defaultValue': defaultValue,
  };
}

/// Represents an enum
class EnumDoc {
  final String name;
  final String? description;
  final String? category;
  final String? subCategory;
  final String filePath;
  final int lineNumber;
  final List<EnumValueDoc> values;
  final List<MethodDoc> methods;
  final List<FieldDoc> fields;

  EnumDoc({
    required this.name,
    this.description,
    this.category,
    this.subCategory,
    required this.filePath,
    required this.lineNumber,
    this.values = const [],
    this.methods = const [],
    this.fields = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'subCategory': subCategory,
    'filePath': filePath,
    'lineNumber': lineNumber,
    'values': values.map((v) => v.toJson()).toList(),
    'methods': methods.map((m) => m.toJson()).toList(),
    'fields': fields.map((f) => f.toJson()).toList(),
  };
}

/// Represents an enum value
class EnumValueDoc {
  final String name;
  final String? description;
  final String? value;

  EnumValueDoc({required this.name, this.description, this.value});

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'value': value,
  };
}

/// Represents a typedef
class TypedefDoc {
  final String name;
  final String type;
  final String? description;
  final String? category;
  final String filePath;
  final int lineNumber;

  TypedefDoc({
    required this.name,
    required this.type,
    this.description,
    this.category,
    required this.filePath,
    required this.lineNumber,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'description': description,
    'category': category,
    'filePath': filePath,
    'lineNumber': lineNumber,
  };
}

/// Represents an extension
class ExtensionDoc {
  final String? name;
  final String extendedType;
  final String? description;
  final String? category;
  final String filePath;
  final int lineNumber;
  final List<MethodDoc> methods;
  final List<FieldDoc> fields;

  ExtensionDoc({
    this.name,
    required this.extendedType,
    this.description,
    this.category,
    required this.filePath,
    required this.lineNumber,
    this.methods = const [],
    this.fields = const [],
  });

  String get displayName => name ?? 'Extension on $extendedType';

  Map<String, dynamic> toJson() => {
    'name': name,
    'extendedType': extendedType,
    'description': description,
    'category': category,
    'filePath': filePath,
    'lineNumber': lineNumber,
    'methods': methods.map((m) => m.toJson()).toList(),
    'fields': fields.map((f) => f.toJson()).toList(),
  };
}

/// Represents a code block in documentation
class CodeBlock {
  final String code;
  final String? language;
  final String? description;

  CodeBlock({required this.code, this.language, this.description});

  Map<String, dynamic> toJson() => {
    'code': code,
    'language': language,
    'description': description,
  };
}

/// Represents a documentation link
class DocLink {
  final String text;
  final String? target;
  final bool isImage;
  final String? url;

  DocLink({required this.text, this.target, this.isImage = false, this.url});

  Map<String, dynamic> toJson() => {
    'text': text,
    'target': target,
    'isImage': isImage,
    'url': url,
  };
}
