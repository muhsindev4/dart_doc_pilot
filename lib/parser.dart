/// Advanced Dart code parser for documentation extraction
library parser;

import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as path;
import 'models.dart';

/// Main parser class that extracts documentation from Dart files
class DartDocParser {
  final String rootPath;
  final List<String> excludePaths;

  DartDocParser({
    required this.rootPath,
    this.excludePaths = const ['build', '.dart_tool', 'test'],
  });

  /// Scans the directory and extracts all documentation
  Future<Documentation> parse() async {
    final files = await _findDartFiles();

    final classes = <ClassDoc>[];
    final enums = <EnumDoc>[];
    final typedefs = <TypedefDoc>[];
    final extensions = <ExtensionDoc>[];
    final categories = <String, List<String>>{};

    for (final file in files) {
      final docs = await _parseFile(file);

      classes.addAll(docs.classes);
      enums.addAll(docs.enums);
      typedefs.addAll(docs.typedefs);
      extensions.addAll(docs.extensions);

      // Build category index
      for (final cls in docs.classes) {
        if (cls.category != null) {
          categories.putIfAbsent(cls.category!, () => []).add(cls.name);
        }
      }
    }

    return Documentation(
      projectName: path.basename(rootPath),
      version: '1.0.0',
      generatedAt: DateTime.now(),
      classes: classes,
      enums: enums,
      typedefs: typedefs,
      extensions: extensions,
      categories: categories,
    );
  }

  /// Finds all Dart files in the directory
  Future<List<File>> _findDartFiles() async {
    final files = <File>[];
    final dir = Directory(rootPath);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final shouldExclude = excludePaths.any(
          (exclude) =>
              entity.path.contains('/$exclude/') ||
              entity.path.contains('\\$exclude\\'),
        );

        if (!shouldExclude) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// Parses a single Dart file
  Future<_FileDocumentation> _parseFile(File file) async {
    final content = await file.readAsString();
    final filePath = path.relative(file.path, from: rootPath);

    try {
      final parseResult = parseString(
        content: content,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      );

      final visitor = _DocumentationVisitor(filePath, content);
      parseResult.unit.accept(visitor);

      return _FileDocumentation(
        classes: visitor.classes,
        enums: visitor.enums,
        typedefs: visitor.typedefs,
        extensions: visitor.extensions,
      );
    } catch (e) {
      print('Warning: Failed to parse $filePath: $e');
      return _FileDocumentation(
        classes: [],
        enums: [],
        typedefs: [],
        extensions: [],
      );
    }
  }
}

/// Visitor that extracts documentation from AST
class _DocumentationVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;

  final classes = <ClassDoc>[];
  final enums = <EnumDoc>[];
  final typedefs = <TypedefDoc>[];
  final extensions = <ExtensionDoc>[];

  _DocumentationVisitor(this.filePath, this.source);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    final constructors = <ConstructorDoc>[];
    final fields = <FieldDoc>[];
    final methods = <MethodDoc>[];

    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        constructors.add(_parseConstructor(member));
      } else if (member is FieldDeclaration) {
        fields.addAll(_parseFields(member));
      } else if (member is MethodDeclaration) {
        methods.add(_parseMethod(member));
      }
    }

    classes.add(
      ClassDoc(
        name: node.name.lexeme,
        description: parsedDoc.description,
        category: parsedDoc.category,
        subCategory: parsedDoc.subCategory,
        filePath: filePath,
        lineNumber: node.offset,
        isAbstract: node.abstractKeyword != null,
        superclass: node.extendsClause?.superclass.toString(),
        mixins:
            node.withClause?.mixinTypes.map((t) => t.toString()).toList() ?? [],
        interfaces:
            node.implementsClause?.interfaces
                .map((t) => t.toString())
                .toList() ??
            [],
        typeParameters:
            node.typeParameters?.typeParameters
                .map((t) => t.name.lexeme)
                .toList() ??
            [],
        constructors: constructors,
        fields: fields,
        methods: methods,
        codeExamples: parsedDoc.codeExamples,
        links: parsedDoc.links,
        macros: parsedDoc.macros,
        templates: parsedDoc.templates,
      ),
    );

    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    final values = <EnumValueDoc>[];
    final methods = <MethodDoc>[];
    final fields = <FieldDoc>[];

    for (final constant in node.constants) {
      final valueDoc = _extractDocumentation(
        constant.documentationComment,
        source,
      );
      final valueParsed = _parseDocumentation(valueDoc);

      values.add(
        EnumValueDoc(
          name: constant.name.lexeme,
          description: valueParsed.description,
        ),
      );
    }

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        methods.add(_parseMethod(member));
      } else if (member is FieldDeclaration) {
        fields.addAll(_parseFields(member));
      }
    }

    enums.add(
      EnumDoc(
        name: node.name.lexeme,
        description: parsedDoc.description,
        category: parsedDoc.category,
        subCategory: parsedDoc.subCategory,
        filePath: filePath,
        lineNumber: node.offset,
        values: values,
        methods: methods,
        fields: fields,
      ),
    );

    super.visitEnumDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    typedefs.add(
      TypedefDoc(
        name: node.name.lexeme,
        type: node.returnType?.toString() ?? 'dynamic',
        description: parsedDoc.description,
        category: parsedDoc.category,
        filePath: filePath,
        lineNumber: node.offset,
      ),
    );

    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    typedefs.add(
      TypedefDoc(
        name: node.name.lexeme,
        type: node.type.toString(),
        description: parsedDoc.description,
        category: parsedDoc.category,
        filePath: filePath,
        lineNumber: node.offset,
      ),
    );

    super.visitGenericTypeAlias(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    final methods = <MethodDoc>[];
    final fields = <FieldDoc>[];

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        methods.add(_parseMethod(member));
      } else if (member is FieldDeclaration) {
        fields.addAll(_parseFields(member));
      }
    }

    extensions.add(
      ExtensionDoc(
        name: node.name?.lexeme,
        extendedType: node.extendedType.toString(),
        description: parsedDoc.description,
        category: parsedDoc.category,
        filePath: filePath,
        lineNumber: node.offset,
        methods: methods,
        fields: fields,
      ),
    );

    super.visitExtensionDeclaration(node);
  }

  ConstructorDoc _parseConstructor(ConstructorDeclaration node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    return ConstructorDoc(
      name: node.name?.lexeme,
      description: parsedDoc.description,
      isConst: node.constKeyword != null,
      isFactory: node.factoryKeyword != null,
      parameters: _parseParameters(node.parameters),
      codeExamples: parsedDoc.codeExamples,
    );
  }

  List<FieldDoc> _parseFields(FieldDeclaration node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    return node.fields.variables.map((variable) {
      return FieldDoc(
        name: variable.name.lexeme,
        type: node.fields.type?.toString() ?? 'dynamic',
        description: parsedDoc.description,
        isStatic: node.isStatic,
        isFinal: node.fields.isFinal,
        isConst: node.fields.isConst,
        isLate: node.fields.isLate,
        defaultValue: variable.initializer?.toString(),
      );
    }).toList();
  }

  MethodDoc _parseMethod(MethodDeclaration node) {
    final docComment = _extractDocumentation(node.documentationComment, source);
    final parsedDoc = _parseDocumentation(docComment);

    return MethodDoc(
      name: node.name.lexeme,
      returnType: node.returnType?.toString() ?? 'void',
      description: parsedDoc.description,
      isStatic: node.isStatic,
      isAbstract: node.isAbstract,
      isAsync: node.body is BlockFunctionBody
          ? (node.body as BlockFunctionBody).keyword?.lexeme == 'async'
          : false,
      isGetter: node.isGetter,
      isSetter: node.isSetter,
      parameters: node.parameters != null
          ? _parseParameters(node.parameters!)
          : [],
      codeExamples: parsedDoc.codeExamples,
      links: parsedDoc.links,
    );
  }

  List<ParameterDoc> _parseParameters(FormalParameterList paramList) {
    final params = <ParameterDoc>[];

    for (final param in paramList.parameters) {
      String type = 'dynamic';
      String name = '';
      bool isRequired = false;
      bool isNamed = false;
      String? defaultValue;

      if (param is DefaultFormalParameter) {
        final innerParam = param.parameter;
        if (innerParam is SimpleFormalParameter) {
          type = innerParam.type?.toString() ?? 'dynamic';
          name = innerParam.name?.lexeme ?? '';
        } else if (innerParam is FieldFormalParameter) {
          type = innerParam.type?.toString() ?? 'dynamic';
          name = innerParam.name.lexeme;
        }
        isNamed = param.isNamed;
        isRequired = param.isRequired;
        defaultValue = param.defaultValue?.toString();
      } else if (param is SimpleFormalParameter) {
        type = param.type?.toString() ?? 'dynamic';
        name = param.name?.lexeme ?? '';
        isRequired = param.isRequired;
        isNamed = param.isNamed;
      } else if (param is FieldFormalParameter) {
        type = param.type?.toString() ?? 'dynamic';
        name = param.name.lexeme;
        isRequired = param.isRequired;
        isNamed = param.isNamed;
      }

      params.add(
        ParameterDoc(
          name: name,
          type: type,
          isRequired: isRequired,
          isNamed: isNamed,
          isPositional: !isNamed,
          defaultValue: defaultValue,
        ),
      );
    }

    return params;
  }

  String? _extractDocumentation(Comment? comment, String source) {
    if (comment == null) return null;

    final buffer = StringBuffer();
    for (final token in comment.tokens) {
      var line = token.lexeme;

      // Remove comment markers
      line = line.replaceFirst(RegExp(r'^\s*///\s?'), '');
      line = line.replaceFirst(RegExp(r'^\s*/\*\*\s?'), '');
      line = line.replaceFirst(RegExp(r'\s?\*/\s*$'), '');
      line = line.replaceFirst(RegExp(r'^\s*\*\s?'), '');

      buffer.writeln(line);
    }

    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  _ParsedDocumentation _parseDocumentation(String? docText) {
    if (docText == null || docText.isEmpty) {
      return _ParsedDocumentation(
        description: null,
        category: null,
        subCategory: null,
        codeExamples: [],
        links: [],
        macros: {},
        templates: {},
      );
    }

    String? category;
    String? subCategory;
    final codeExamples = <CodeBlock>[];
    final links = <DocLink>[];
    final macros = <String, String>{};
    final templates = <String, String>{};

    final descriptionLines = <String>[];
    final lines = docText.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Extract category tags
      final categoryMatch = RegExp(
        r'\{?@category\s+([^}]+)\}?',
      ).firstMatch(line);
      if (categoryMatch != null) {
        category = categoryMatch.group(1)?.trim();
        continue;
      }

      final subCategoryMatch = RegExp(
        r'\{?@subCategory\s+([^}]+)\}?',
      ).firstMatch(line);
      if (subCategoryMatch != null) {
        subCategory = subCategoryMatch.group(1)?.trim();
        continue;
      }

      // Extract code blocks
      if (line.trim().startsWith('```')) {
        final language = line.trim().substring(3).trim();
        final codeLines = <String>[];
        i++;

        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }

        codeExamples.add(
          CodeBlock(
            code: codeLines.join('\n'),
            language: language.isEmpty ? null : language,
          ),
        );
        continue;
      }

      // Extract image links
      final imgMatch = RegExp(r'\{@img\s+([^}]+)\}').firstMatch(line);
      if (imgMatch != null) {
        links.add(
          DocLink(text: 'Image', url: imgMatch.group(1)?.trim(), isImage: true),
        );
      }

      // Extract macros
      final macroMatch = RegExp(r'\{@macro\s+([^}]+)\}').firstMatch(line);
      if (macroMatch != null) {
        macros[macroMatch.group(1)?.trim() ?? ''] = '';
        continue;
      }

      // Extract templates
      if (line.contains('{@template')) {
        final templateMatch = RegExp(
          r'\{@template\s+([^}]+)\}',
        ).firstMatch(line);
        if (templateMatch != null) {
          final templateName = templateMatch.group(1)?.trim() ?? '';
          final templateLines = <String>[];
          i++;

          while (i < lines.length && !lines[i].contains('{@endtemplate}')) {
            templateLines.add(lines[i]);
            i++;
          }

          templates[templateName] = templateLines.join('\n');
        }
        continue;
      }

      // Extract inline links
      final linkMatches = RegExp(r'\[([^\]]+)\]').allMatches(line);
      for (final match in linkMatches) {
        links.add(DocLink(text: match.group(1) ?? '', target: match.group(1)));
      }

      descriptionLines.add(line);
    }

    final description = descriptionLines.join('\n').trim();

    return _ParsedDocumentation(
      description: description.isEmpty ? null : description,
      category: category,
      subCategory: subCategory,
      codeExamples: codeExamples,
      links: links,
      macros: macros,
      templates: templates,
    );
  }
}

class _FileDocumentation {
  final List<ClassDoc> classes;
  final List<EnumDoc> enums;
  final List<TypedefDoc> typedefs;
  final List<ExtensionDoc> extensions;

  _FileDocumentation({
    required this.classes,
    required this.enums,
    required this.typedefs,
    required this.extensions,
  });
}

class _ParsedDocumentation {
  final String? description;
  final String? category;
  final String? subCategory;
  final List<CodeBlock> codeExamples;
  final List<DocLink> links;
  final Map<String, String> macros;
  final Map<String, String> templates;

  _ParsedDocumentation({
    required this.description,
    required this.category,
    required this.subCategory,
    required this.codeExamples,
    required this.links,
    required this.macros,
    required this.templates,
  });
}
