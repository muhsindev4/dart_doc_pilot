import 'dart:async';
import 'dart:io';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import '../models/documentation.dart';

class DartParser {
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

  Future<Documentation> parseDirectory(String dirPath) async {
    final totalWatch = Stopwatch()..start();

    print("🔍 Starting DartParser...");
    print("📁 Directory: $dirPath");
    _startSpinner("🔎 Scanning .dart files");
    final classes = <ClassDoc>[];
    final enums = <EnumDoc>[];
    final typedefs = <TypedefDoc>[];
    final extensions = <ExtensionDoc>[];

    final glob = Glob('**.dart');
    final dir = Directory(dirPath);

    final entities = glob.listSync(root: dir.path);

    _stop(); // stop scanning spinner
    print("📄 Found ${entities.length} Dart files\n");

    for (final entity in entities) {
      if (entity is! File) continue;

      final scanWatch = Stopwatch()..start();
      print("➡️ Reading file: ${entity.path}");

      final file = File(entity.path);
      final content = await file.readAsString();
      final filePath = path.relative(entity.path, from: dirPath);

      _startSpinner("Processing ${path.basename(entity.path)}");

      final c = _parseClasses(content, filePath);
      final e = _parseEnums(content, filePath);
      final t = _parseTypedefs(content, filePath);
      final x = _parseExtensions(content, filePath);

      _stop();
      scanWatch.stop();
      print(
        "   ✔ Classes: ${c.length}, Enums: ${e.length}, Typedefs: ${t.length}, Extensions: ${x.length}  (${_ms(scanWatch.elapsedMicroseconds)})\n",
      );

      classes.addAll(c);
      enums.addAll(e);
      typedefs.addAll(t);
      extensions.addAll(x);
    }

    totalWatch.stop();
    print("⏱️ Total time: ${_ms(totalWatch.elapsedMicroseconds)}");
    print("🏁 Parsing completed.");
    print("""
=========================================
📊 Summary
-----------------------------------------
🧱 Classes:     ${classes.length}
🎌 Enums:       ${enums.length}
🔗 Typedefs:    ${typedefs.length}
🧩 Extensions:  ${extensions.length}
=========================================
""");

    return Documentation(
      classes: classes,
      enums: enums,
      typedefs: typedefs,
      extensions: extensions,
    );
  }

  List<ClassDoc> _parseClasses(String content, String filePath) {
    final classes = <ClassDoc>[];
    final classPattern = RegExp(
      r'(?:///[^\n]*\n)*\s*(abstract\s+)?class\s+(\w+)(?:<[^>]+>)?(?:\s+extends\s+(\w+(?:<[^>]+>)?))?(?:\s+implements\s+([\w\s,<>]+))?(?:\s+with\s+([\w\s,<>]+))?\s*\{',
      multiLine: true,
    );

    final matches = classPattern.allMatches(content);

    for (final match in matches) {
      final isAbstract = match.group(1) != null;
      final className = match.group(2)!;
      final extendsClass = match.group(3);
      final implementsList =
          match.group(4)?.split(',').map((e) => e.trim()).toList() ?? [];
      final mixinsList =
          match.group(5)?.split(',').map((e) => e.trim()).toList() ?? [];

      // Extract documentation comment BEFORE the class
      final docComment = _extractDocComment(content, match.start);
      final description = _parseDocComment(docComment);
      final category = _extractTag(docComment, 'category');
      final subCategory = _extractTag(docComment, 'subCategory');

      // Find class body - OPTIMIZED VERSION
      final classEnd = _findMatchingBraceFast(content, match.end - 1);
      final classBody = content.substring(match.end, classEnd);

      // Parse methods and fields - LIMIT REGEX BACKTRACKING
      final methods = _parseMethods(classBody, className);
      final fields = _parseFields(classBody);
      final constructors = _parseConstructors(classBody, className);

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

  // MUCH FASTER - Uses simple character counting
  int _findMatchingBraceFast(String content, int openBracePos) {
    var depth = 1;

    for (var i = openBracePos + 1; i < content.length; i++) {
      final char = content[i];

      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return content.length;
  }

  // Optimize method parsing to skip constructor-like patterns
  List<MethodDoc> _parseMethods(String classBody, String className) {
    final methods = <MethodDoc>[];

    // Split by lines first to reduce regex complexity
    final lines = classBody.split('\n');
    final methodLines = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('(') && (line.contains('=>') || line.contains('{'))) {
        // Potential method line - collect surrounding context
        final start = i > 5 ? i - 5 : 0;
        final end = i + 1 < lines.length ? i + 1 : lines.length;
        methodLines.add(lines.sublist(start, end).join('\n'));
      }
    }

    // Now run regex only on potential method sections
    for (final section in methodLines) {
      final methodPattern = RegExp(
        r'(?:///[^\n]*\n)*\s*(static\s+)?(Future<[^>]+>|[\w<>?,\s]+)\s+(\w+)\s*\(([^)]*)\)\s*(async\s*)?(?:=>|{)',
        multiLine: false, // Changed to false for performance
      );

      final match = methodPattern.firstMatch(section);
      if (match == null) continue;

      final isStatic = match.group(1) != null;
      final returnType = match.group(2)!.trim();
      final methodName = match.group(3)!;
      final paramsStr = match.group(4)!;
      final isAsync = match.group(5) != null;

      // Skip private methods and constructors
      if (methodName.startsWith('_') || methodName == className) {
        continue;
      }

      final docComment = _extractDocComment(section, match.start);
      final description = _parseDocComment(docComment);
      final parameters = _parseParameters(paramsStr);

      methods.add(
        MethodDoc(
          name: methodName,
          description: description,
          returnType: returnType,
          parameters: parameters,
          isStatic: isStatic,
          isAsync: isAsync,
        ),
      );
    }

    return methods;
  }

  List<FieldDoc> _parseFields(String classBody) {
    final fields = <FieldDoc>[];

    // Better field pattern that requires a type before the field name
    // This pattern requires: [modifiers] Type fieldName [= value];
    final fieldPattern = RegExp(
      r'(?:///[^\n]*\n)*\s*(static\s+)?(const\s+|final\s+)?([\w<>?,\s]+?)\s+(\w+)\s*(?:=\s*([^;]+?))?\s*;',
      multiLine: true,
    );

    final matches = fieldPattern.allMatches(classBody);

    for (final match in matches) {
      final isStatic = match.group(1) != null;
      final modifier = match.group(2)?.trim();
      var type = match.group(3)!.trim();
      final fieldName = match.group(4)!;
      final defaultValue = match.group(5)?.trim();

      // Skip if type is empty or looks invalid
      if (type.isEmpty || type.contains('(')) {
        continue;
      }

      // If modifier is present but type looks like 'final' or 'const', skip
      if (type == 'final' || type == 'const' || type == 'static') {
        continue;
      }

      final docComment = _extractDocComment(classBody, match.start);
      final description = _parseDocComment(docComment);

      fields.add(
        FieldDoc(
          name: fieldName,
          description: description,
          type: type,
          isFinal: modifier == 'final',
          isConst: modifier == 'const',
          isStatic: isStatic,
          defaultValue: defaultValue,
        ),
      );
    }

    return fields;
  }

  List<String> _parseConstructors(String classBody, String className) {
    final constructors = <String>[];
    final constructorPattern = RegExp(
      r'(?:///[^\n]*\n)*\s*(?:const\s+)?$className(?:\.(\w+))?\s*\([^)]*\)',
      multiLine: true,
    );

    final matches = constructorPattern.allMatches(classBody);

    for (final match in matches) {
      final constructorName = match.group(1);
      if (constructorName != null) {
        constructors.add('$className.$constructorName');
      } else {
        constructors.add(className);
      }
    }

    return constructors;
  }

  List<ParameterDoc> _parseParameters(String paramsStr) {
    if (paramsStr.trim().isEmpty) return [];

    final parameters = <ParameterDoc>[];

    // Handle positional and named parameters separately
    var positionalStr = paramsStr;
    var namedStr = '';

    if (paramsStr.contains('{')) {
      final braceIndex = paramsStr.indexOf('{');
      positionalStr = paramsStr.substring(0, braceIndex);
      namedStr = paramsStr.substring(
        braceIndex + 1,
        paramsStr.lastIndexOf('}'),
      );
    }

    // Parse positional parameters
    if (positionalStr.trim().isNotEmpty) {
      final parts = _splitParameters(positionalStr);
      for (final part in parts) {
        final param = _parseParameter(part, false);
        if (param != null) parameters.add(param);
      }
    }

    // Parse named parameters
    if (namedStr.trim().isNotEmpty) {
      final parts = _splitParameters(namedStr);
      for (final part in parts) {
        final param = _parseParameter(part, true);
        if (param != null) parameters.add(param);
      }
    }

    return parameters;
  }

  ParameterDoc? _parseParameter(String paramStr, bool isNamed) {
    final trimmed = paramStr.trim();
    if (trimmed.isEmpty) return null;

    final isRequired = trimmed.startsWith('required ');
    final withoutRequired = isRequired ? trimmed.substring(9).trim() : trimmed;

    final equalIndex = withoutRequired.indexOf('=');
    final paramPart = equalIndex >= 0
        ? withoutRequired.substring(0, equalIndex).trim()
        : withoutRequired;
    final defaultValue = equalIndex >= 0
        ? withoutRequired.substring(equalIndex + 1).trim()
        : null;

    // Better parameter parsing: handle "Type name" format
    final spaceIndex = paramPart.lastIndexOf(' ');
    if (spaceIndex <= 0) return null;

    final type = paramPart.substring(0, spaceIndex).trim();
    final name = paramPart.substring(spaceIndex + 1).trim();

    if (type.isEmpty || name.isEmpty) return null;

    return ParameterDoc(
      name: name,
      type: type,
      isRequired: isRequired,
      isNamed: isNamed,
      defaultValue: defaultValue,
    );
  }

  List<String> _splitParameters(String paramsStr) {
    final result = <String>[];
    var current = StringBuffer();
    var depth = 0;
    var inString = false;
    var stringChar = '';

    for (var i = 0; i < paramsStr.length; i++) {
      final char = paramsStr[i];

      if ((char == '"' || char == "'") &&
          (i == 0 || paramsStr[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
        }
      }

      if (!inString) {
        if (char == '<' || char == '(' || char == '[' || char == '{') {
          depth++;
        } else if (char == '>' || char == ')' || char == ']' || char == '}') {
          depth--;
        } else if (char == ',' && depth == 0) {
          result.add(current.toString());
          current = StringBuffer();
          continue;
        }
      }

      current.write(char);
    }

    if (current.isNotEmpty) {
      result.add(current.toString());
    }

    return result;
  }

  List<EnumDoc> _parseEnums(String content, String filePath) {
    final enums = <EnumDoc>[];
    final enumPattern = RegExp(
      r'(?:///[^\n]*\n)*\s*enum\s+(\w+)\s*\{([^}]+)\}',
      multiLine: true,
    );

    final matches = enumPattern.allMatches(content);

    for (final match in matches) {
      final enumName = match.group(1)!;
      final valuesStr = match.group(2)!;

      final docComment = _extractDocComment(content, match.start);
      final description = _parseDocComment(docComment);
      final category = _extractTag(docComment, 'category');

      final values = valuesStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('//'))
          .map((e) => e.split(RegExp(r'[\s(;]'))[0])
          .where((e) => e.isNotEmpty)
          .toList();

      enums.add(
        EnumDoc(
          name: enumName,
          description: description,
          category: category,
          values: values,
          filePath: filePath,
        ),
      );
    }

    return enums;
  }

  List<TypedefDoc> _parseTypedefs(String content, String filePath) {
    final typedefs = <TypedefDoc>[];
    final typedefPattern = RegExp(
      r'(?:///[^\n]*\n)*\s*typedef\s+(\w+)\s*=\s*([^;]+);',
      multiLine: true,
    );

    final matches = typedefPattern.allMatches(content);

    for (final match in matches) {
      final name = match.group(1)!;
      final signature = match.group(2)!.trim();

      final docComment = _extractDocComment(content, match.start);
      final description = _parseDocComment(docComment);

      typedefs.add(
        TypedefDoc(
          name: name,
          description: description,
          signature: signature,
          filePath: filePath,
        ),
      );
    }

    return typedefs;
  }

  List<ExtensionDoc> _parseExtensions(String content, String filePath) {
    final extensions = <ExtensionDoc>[];

    // First pass: find all extension declarations
    final extensionStarts = <int>[];
    final extensionPattern = RegExp(
      r'extension\s+(\w+)\s+on\s+([\w<>]+)\s*\{',
      multiLine: true,
    );

    for (final match in extensionPattern.allMatches(content)) {
      extensionStarts.add(match.start);
    }

    // Second pass: extract each extension with its doc comments
    for (var i = 0; i < extensionStarts.length; i++) {
      final startPos = extensionStarts[i];

      // Find the extension match at this position
      final substring = content.substring(startPos);
      final match = extensionPattern.firstMatch(substring);
      if (match == null) continue;

      final name = match.group(1)!;
      final onType = match.group(2)!;

      // Extract doc comment from original content
      final docComment = _extractDocComment(content, startPos);
      final description = _parseDocComment(docComment);

      // Find extension body end using fast brace matching
      final bracePos = startPos + match.end - 1;
      final extensionEnd = _findMatchingBraceFast(content, bracePos);
      final extensionBody = content.substring(
        startPos + match.end,
        extensionEnd,
      );

      // Parse methods within extension - use extension name to avoid confusion
      final methods = _parseMethodsInExtension(extensionBody);

      extensions.add(
        ExtensionDoc(
          name: name,
          description: description,
          onType: onType,
          methods: methods,
          filePath: filePath,
        ),
      );
    }

    return extensions;
  }

  // Optimized method parser for extensions (no constructor checks needed)
  List<MethodDoc> _parseMethodsInExtension(String extensionBody) {
    final methods = <MethodDoc>[];

    // Split by lines and pre-filter
    final lines = extensionBody.split('\n');
    final potentialMethods = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // Look for method signatures
      if (line.contains('(') && (line.contains('=>') || line.contains('{'))) {
        // Get context (5 lines before, 1 after)
        final start = i > 5 ? i - 5 : 0;
        final end = i + 2 < lines.length ? i + 2 : lines.length;
        potentialMethods.add(lines.sublist(start, end).join('\n'));
      }
    }

    // Process each potential method section
    for (final section in potentialMethods) {
      final methodPattern = RegExp(
        r'(static\s+)?(Future<[^>]+>|[\w<>?,\s]+)\s+(\w+)\s*\(([^)]*)\)\s*(async\s*)?(?:=>|{)',
      );

      final match = methodPattern.firstMatch(section);
      if (match == null) continue;

      final isStatic = match.group(1) != null;
      final returnType = match.group(2)!.trim();
      final methodName = match.group(3)!;
      final paramsStr = match.group(4)!;
      final isAsync = match.group(5) != null;

      // Skip private methods
      if (methodName.startsWith('_')) continue;

      // Extract doc comment from this section
      final docComment = _extractDocComment(section, match.start);
      final description = _parseDocComment(docComment);
      final parameters = _parseParameters(paramsStr);

      methods.add(
        MethodDoc(
          name: methodName,
          description: description,
          returnType: returnType,
          parameters: parameters,
          isStatic: isStatic,
          isAsync: isAsync,
        ),
      );
    }

    return methods;
  }

  String _extractDocComment(String content, int position) {
    // Find the actual start of the declaration (skip the doc comments)
    // We need to find where "class", "enum", "extension", etc. actually starts
    var adjustedPosition = position;

    // Move forward to find the actual keyword (class, enum, etc.)
    while (adjustedPosition < content.length) {
      final substring = content.substring(adjustedPosition);
      if (substring.trimLeft().startsWith(
        RegExp(r'(abstract\s+)?(class|enum|extension|typedef)'),
      )) {
        break;
      }
      adjustedPosition++;
    }

    // Now go backwards from this position to find doc comments
    final beforePosition = content.substring(0, adjustedPosition);
    final lines = beforePosition.split('\n');
    final docLines = <String>[];

    // Start from the last line and go backwards
    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('///')) {
        // Extract content after ///
        var docContent = trimmed.substring(3);
        // Remove leading single space if present
        if (docContent.startsWith(' ')) {
          docContent = docContent.substring(1);
        }
        docLines.insert(0, docContent);
      } else if (trimmed.isEmpty && docLines.isNotEmpty) {
        // Empty line within doc comment block - keep it
        docLines.insert(0, '');
      } else if (trimmed.isNotEmpty) {
        // Hit non-doc-comment content - stop
        break;
      }
    }

    return docLines.join('\n');
  }

  String? _parseDocComment(String docComment) {
    if (docComment.isEmpty) return null;

    // Split into lines and filter out tag-only lines
    final lines = docComment.split('\n');
    final cleanLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      // Skip lines that are ONLY tags (starts with {@)
      if (trimmed.startsWith('{@') && trimmed.contains('}')) {
        // Check if entire line is just the tag
        final tagEnd = trimmed.indexOf('}');
        final afterTag = trimmed.substring(tagEnd + 1).trim();
        if (afterTag.isEmpty) {
          continue; // Skip this line, it's just a tag
        }
      }
      cleanLines.add(line);
    }

    final result = cleanLines.join('\n').trim();
    return result.isEmpty ? null : result;
  }

  String? _extractTag(String docComment, String tagName) {
    if (docComment.isEmpty) return null;

    // Match {@tagName value}
    final pattern = RegExp(
      r'\{@' + RegExp.escape(tagName) + r'\s+([^}]+)\}',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(docComment);
    return match?.group(1)?.trim();
  }

  int _findMatchingBrace(String content, int openBracePos) {
    var depth = 1;
    var inString = false;
    var stringChar = '';
    var inComment = false;
    var inMultiLineComment = false;

    for (var i = openBracePos + 1; i < content.length; i++) {
      final char = content[i];
      final prevChar = i > 0 ? content[i - 1] : '';
      final nextChar = i < content.length - 1 ? content[i + 1] : '';

      // Handle multi-line comments /* */
      if (!inString && !inComment && char == '/' && nextChar == '*') {
        inMultiLineComment = true;
        i++; // skip next char
        continue;
      }
      if (inMultiLineComment && char == '*' && nextChar == '/') {
        inMultiLineComment = false;
        i++; // skip next char
        continue;
      }

      // Handle single-line comments //
      if (!inString && !inMultiLineComment && char == '/' && nextChar == '/') {
        inComment = true;
        continue;
      }
      if (inComment && char == '\n') {
        inComment = false;
        continue;
      }

      // Skip if in comment
      if (inComment || inMultiLineComment) continue;

      // Handle strings
      if ((char == '"' || char == "'") && prevChar != '\\') {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
        }
      }

      if (!inString) {
        if (char == '{')
          depth++;
        else if (char == '}') {
          depth--;
          if (depth == 0) return i;
        }
      }
    }
    return content.length;
  }
}
