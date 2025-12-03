import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

import '../models/documentation.dart';

class DartNewParser {
  Future<Documentation> parseDirectory(String dirPath) async {
    final classes = <ClassDoc>[];
    final enums = <EnumDoc>[];
    final typedefs = <TypedefDoc>[];
    final extensions = <ExtensionDoc>[];

    // fetch all dart files from directory
    _startSpinner("🔎 Scanning .dart files");
    final glob = Glob('**.dart');
    final dir = Directory(dirPath);
    final entities = glob.listSync(root: dir.path);
    _stop();
    print("📄 Found ${entities.length} Dart files\n");

    for (final entity in entities) {
      if (entity is! File) continue;

      final scanWatch = Stopwatch()..start();
      print("➡️ Reading file: ${entity.path}");

      final file = File(entity.path);
      final content = await file.readAsString();

      // Parse
      classes.addAll(_parseClasses(content, entity.path));
      enums.addAll(_parseEnums(content, entity.path));
      typedefs.addAll(_parseTypedefs(content, entity.path));
      extensions.addAll(_parseExtensions(content, entity.path));

      scanWatch.stop();
      print("Completed in ${_ms(scanWatch.elapsedMicroseconds)}");
    }

    return Documentation(
      classes: classes,
      enums: enums,
      typedefs: typedefs,
      extensions: extensions,
    );
  }

  // ============================================================
  //  CLASS PARSER
  // ============================================================

  List<ClassDoc> _parseClasses(String content, String filePath) {
    final classes = <ClassDoc>[];

    final classRegex = RegExp(
      r'(///[\s\S]*?)?\s*(abstract\s+)?class\s+(\w+)(?:\s+extends\s+(\w+))?(?:\s+implements\s+([\w,\s]+))?(?:\s+with\s+([\w,\s]+))?\s*\{([\s\S]*?)\}',
      multiLine: true,
    );

    final matches = classRegex.allMatches(content);

    for (final match in matches) {
      final rawDocs = match.group(1) ?? "";
      final isAbstract = (match.group(2) ?? "").contains("abstract");
      final className = match.group(3) ?? "";

      final extendsClass = match.group(4);
      final implementsList = (match.group(5) ?? "")
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final mixinsList = (match.group(6) ?? "")
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final classBody = match.group(7) ?? "";

      // ---- Docs ----
      String? description;
      String? category;
      String? subCategory;

      if (rawDocs.isNotEmpty) {
        final lines = rawDocs
            .split('\n')
            .map((e) => e.replaceFirst('///', '').trim())
            .toList();

        description = lines.join(' ').trim();

        final categoryMatch = RegExp(
          r'@category\s+([\w\s]+)',
        ).firstMatch(rawDocs);
        if (categoryMatch != null) category = categoryMatch.group(1)?.trim();

        final subMatch = RegExp(
          r'@subCategory\s+([\w\s]+)',
        ).firstMatch(rawDocs);
        if (subMatch != null) subCategory = subMatch.group(1)?.trim();
      }

      // ---- Members ----
      final fields = _parseFields(classBody);
      final constructors = _parseConstructors(classBody, className);
      final methods = _parseMethods(classBody);

      classes.add(
        ClassDoc(
          name: className,
          description: description,
          category: category,
          subCategory: subCategory,
          filePath: filePath,
          methods: methods,
          fields: fields,
          constructors: constructors,
          extendsClass: extendsClass,
          implements: implementsList,
          mixins: mixinsList,
          isAbstract: isAbstract,
        ),
      );
    }

    return classes;
  }

  // ============================================================
  //  FIELD PARSER
  // ============================================================

  List<FieldDoc> _parseFields(String body) {
    final fields = <FieldDoc>[];

    final fieldRegex = RegExp(
      r'(///[^\n]*\n)?\s*(static\s+)?(final\s+)?(const\s+)?([\w?<>]+)\s+(\w+)(?:\s*=\s*([^;]+))?;',
      multiLine: true,
    );

    for (final match in fieldRegex.allMatches(body)) {
      final rawDoc = match.group(1) ?? "";
      final isStatic = match.group(2) != null;
      final isFinal = match.group(3) != null;
      final isConst = match.group(4) != null;
      final type = match.group(5) ?? "";
      final name = match.group(6) ?? "";
      final defaultValue = match.group(7)?.trim();

      final description = rawDoc.isNotEmpty
          ? rawDoc.replaceAll(RegExp(r'///\s?'), '').trim()
          : null;

      fields.add(
        FieldDoc(
          name: name,
          type: type,
          isFinal: isFinal,
          isStatic: isStatic,
          isConst: isConst,
          description: description,
          defaultValue: defaultValue,
        ),
      );
    }

    return fields;
  }

  // ============================================================
  //  CONSTRUCTOR PARSER
  // ============================================================

  List<String> _parseConstructors(String body, String className) {
    final constructors = <String>[];

    final ctorRegex = RegExp(r'$className\s*\([^)]*\)\s*{?', multiLine: true);

    constructors.addAll(
      ctorRegex.allMatches(body).map((e) => e.group(0) ?? ""),
    );

    return constructors;
  }

  // ============================================================
  //  METHOD PARSER
  // ============================================================

  List<MethodDoc> _parseMethods(String body) {
    final methods = <MethodDoc>[];

    final methodRegex = RegExp(
      r'(///[\s\S]*?)?\s*(static\s+)?([\w?<>,\s]+)\s+(\w+)\s*\(([^)]*)\)\s*(async)?\s*\{',
      multiLine: true,
    );

    for (final m in methodRegex.allMatches(body)) {
      final rawDocs = m.group(1) ?? "";
      final isStatic = m.group(2) != null;
      final returnType = m.group(3)?.trim() ?? "";
      final name = m.group(4) ?? "";
      final paramString = m.group(5) ?? "";
      final isAsync = m.group(6) != null;

      final description = rawDocs.isNotEmpty
          ? rawDocs.replaceAll(RegExp(r'///\s?'), '').trim()
          : null;

      final params = _parseParameters(paramString);

      methods.add(
        MethodDoc(
          name: name,
          description: description,
          returnType: returnType,
          parameters: params,
          isStatic: isStatic,
          isAsync: isAsync,
        ),
      );
    }

    return methods;
  }

  // ============================================================
  //  PARAMETER PARSER
  // ============================================================

  List<ParameterDoc> _parseParameters(String paramString) {
    final params = <ParameterDoc>[];

    if (paramString.trim().isEmpty) return params;

    final parts = paramString.split(',');

    for (var p in parts) {
      p = p.trim();
      if (p.isEmpty) continue;

      final isRequired = p.contains('required ');
      final isNamed = p.contains('{') || p.contains('}');

      var clean = p
          .replaceAll('required', '')
          .replaceAll('{', '')
          .replaceAll('}', '')
          .trim();

      final tokens = clean.split(RegExp(r'\s+'));
      if (tokens.length < 2) continue;

      final type = tokens[0];
      final name = tokens[1].split('=').first.trim();

      String? defaultValue;
      if (clean.contains('=')) {
        defaultValue = clean.split('=').last.trim();
      }

      params.add(
        ParameterDoc(
          name: name,
          type: type,
          isNamed: isNamed,
          isRequired: isRequired,
          defaultValue: defaultValue,
        ),
      );
    }

    return params;
  }

  // ============================================================
  //  ENUM PARSER
  // ============================================================

  List<EnumDoc> _parseEnums(String content, String filePath) {
    final enums = <EnumDoc>[];

    final enumRegex = RegExp(
      r'(///[\s\S]*?)?\s*enum\s+(\w+)\s*\{([\s\S]*?)\}',
      multiLine: true,
    );

    for (final match in enumRegex.allMatches(content)) {
      final docs = match.group(1) ?? "";
      final name = match.group(2) ?? "";
      final body = match.group(3) ?? "";

      final description = docs.isNotEmpty
          ? docs.replaceAll(RegExp(r'///\s?'), '').trim()
          : null;

      final values = body
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      enums.add(
        EnumDoc(
          name: name,
          description: description,
          values: values,
          filePath: filePath,
        ),
      );
    }

    return enums;
  }

  // ============================================================
  //  TYPEDEF PARSER
  // ============================================================

  List<TypedefDoc> _parseTypedefs(String content, String filePath) {
    final typedefs = <TypedefDoc>[];

    final typedefRegex = RegExp(
      r'(///[\s\S]*?)?\s*typedef\s+(\w+)\s*=\s*([^;]+);',
      multiLine: true,
    );

    for (final match in typedefRegex.allMatches(content)) {
      final docs = match.group(1) ?? "";
      final name = match.group(2) ?? "";
      final signature = match.group(3) ?? "";

      final description = docs.isNotEmpty
          ? docs.replaceAll(RegExp(r'///\s?'), '').trim()
          : null;

      typedefs.add(
        TypedefDoc(
          name: name,
          description: description,
          signature: signature.trim(),
          filePath: filePath,
        ),
      );
    }

    return typedefs;
  }

  // ============================================================
  //  EXTENSION PARSER
  // ============================================================

  List<ExtensionDoc> _parseExtensions(String content, String filePath) {
    final extensions = <ExtensionDoc>[];

    final extRegex = RegExp(
      r'(///[\s\S]*?)?\s*extension\s+(\w+)\s+on\s+(\w+)\s*\{([\s\S]*?)\}',
      multiLine: true,
    );

    for (final match in extRegex.allMatches(content)) {
      final docs = match.group(1) ?? "";
      final name = match.group(2) ?? "";
      final onType = match.group(3) ?? "";
      final body = match.group(4) ?? "";

      final description = docs.isNotEmpty
          ? docs.replaceAll(RegExp(r'///\s?'), '').trim()
          : null;

      final methods = _parseMethods(body);

      extensions.add(
        ExtensionDoc(
          name: name,
          description: description,
          onType: onType,
          filePath: filePath,
          methods: methods,
        ),
      );
    }

    return extensions;
  }

  // ============================================================
  //  UTILS (SPINNER)
  // ============================================================

  String _ms(int microseconds) {
    return "${(microseconds / 1000).toStringAsFixed(2)} ms";
  }

  void Function()? _stopSpinner;

  void _startSpinner(String message) {
    const frames = ['|', '/', '-', '\\'];
    int index = 0;

    stdout.write('$message ');
    final timer = Timer.periodic(Duration(milliseconds: 120), (_) {
      stdout.write('\b${frames[index]}');
      index = (index + 1) % frames.length;
    });

    _stopSpinner = () {
      timer.cancel();
      stdout.write('\b✓\n');
    };
  }

  void _stop() {
    _stopSpinner?.call();
    _stopSpinner = null;
  }
}
