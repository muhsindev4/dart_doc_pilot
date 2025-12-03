// import 'dart:io';
// import 'package:args/args.dart';
// import 'package:dart_doc_pilot/src/generator/html_generator.dart';
// import 'package:dart_doc_pilot/src/parser/dart_new_parser.dart';
// import 'package:dart_doc_pilot/src/parser/dart_parser.dart';
// import 'package:path/path.dart' as path;
//
// void main(List<String> arguments) async {
//   final parser = ArgParser()
//     ..addOption('input',
//         abbr: 'i',
//         defaultsTo: 'lib',
//         help: 'Input directory containing Dart files')
//     ..addOption('output',
//         abbr: 'o',
//         defaultsTo: 'doc',
//         help: 'Output directory for generated documentation')
//     ..addOption('name',
//         abbr: 'n',
//         defaultsTo: 'Documentation',
//         help: 'Project name')
//     ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage information');
//
//   try {
//     final results = parser.parse(arguments);
//
//     if (results['help'] as bool) {
//       _printUsage(parser);
//       return;
//     }
//
//     final inputDir = results['input'] as String;
//     final outputDir = results['output'] as String;
//     final projectName = results['name'] as String;
//
//     print('🚀 Starting documentation generation...');
//     print('📂 Input: $inputDir');
//     print('📁 Output: $outputDir');
//     print('');
//
//     // Parse all Dart files
//     final dartParser = DartNewParser();
//     final documentation = await dartParser.parseDirectory(inputDir);
//
//     print('✅ Parsed ${documentation.classes.length} classes');
//     print('✅ Found ${documentation.getAllMethods().length} methods');
//     print('✅ Found ${documentation.getAllFields().length} fields');
//     print('');
//
//     // Generate HTML documentation
//     final generator = HtmlGenerator(projectName: projectName);
//     await generator.generate(documentation, outputDir);
//
//     print('');
//     print('✨ Documentation generated successfully!');
//     print('📖 Open: ${path.join(outputDir, 'index.html')}');
//     print('');
//   } catch (e) {
//     print('❌ Error: $e');
//     exit(1);
//   }
// }
//
// void _printUsage(ArgParser parser) {
//   print('Dart Documentation Generator');
//   print('');
//   print('Usage: dart_doc_pilot [options]');
//   print('');
//   print(parser.usage);
//   print('');
//   print('Example:');
//   print('  dart_doc_pilot -i lib -o docs -n "My Project"');
// }
