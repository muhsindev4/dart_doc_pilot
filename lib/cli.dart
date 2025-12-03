/// Rich CLI interface for dart_doc_pilot
library cli;

import 'dart:io';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'parser.dart';
import 'exporters.dart';

class DartDocPilotCLI {
  final Logger _logger = Logger();

  Future<void> run(List<String> arguments) async {
    _printBanner();

    final parser = ArgParser()
      ..addCommand('scan')
      ..addCommand('build')
      ..addCommand('serve')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addFlag('version', abbr: 'v', negatable: false, help: 'Show version');

    // Add build subcommand options
    parser.commands['build']!
      ..addOption(
        'format',
        abbr: 'f',
        allowed: ['json', 'markdown', 'html'],
        defaultsTo: 'html',
      )
      ..addOption('output', abbr: 'o', defaultsTo: 'docs');

    parser.commands['serve']!
      ..addOption('port', abbr: 'p', defaultsTo: '8080');

    try {
      final results = parser.parse(arguments);

      if (results['help'] as bool) {
        _printHelp(parser);
        return;
      }

      if (results['version'] as bool) {
        _printVersion();
        return;
      }

      if (results.command == null) {
        _printHelp(parser);
        return;
      }

      final command = results.command!;

      switch (command.name) {
        case 'scan':
          await _handleScan(command.rest);
          break;
        case 'build':
          await _handleBuild(command);
          break;
        case 'serve':
          await _handleServe(command);
          break;
      }
    } catch (e) {
      _logger.err('Error: $e');
      exit(1);
    }
  }

  void _printBanner() {
    final banner = '''
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗  █████╗ ██████╗ ████████╗    ██████╗  ██████╗  ██████╗
║   ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝    ██╔══██╗██╔═══██╗██╔════╝
║   ██║  ██║███████║██████╔╝   ██║       ██║  ██║██║   ██║██║     
║   ██║  ██║██╔══██║██╔══██╗   ██║       ██║  ██║██║   ██║██║     
║   ██████╔╝██║  ██║██║  ██║   ██║       ██████╔╝╚██████╔╝╚██████╗
║   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝       ╚═════╝  ╚═════╝  ╚═════╝
║                                                               ║
║              🚀 Flutter Documentation Generator 🚀             ║
║                    Powered by dart_doc_pilot                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
''';

    print(banner);
  }

  void _printHelp(ArgParser parser) {
    print('''
${'━' * 60}
${'USAGE'}
  dart_doc_pilot <command> [arguments]

${'COMMANDS'}
  ${'scan'} <directory>              Scan and analyze Dart files
  ${'build'} <directory> [options]   Generate documentation
  ${'serve'} <directory> [options]   Start documentation server

${'BUILD OPTIONS'}
  -f, --format=<type>           Output format (json, markdown, html)
  -o, --output=<directory>      Output directory (default: docs)

${'SERVE OPTIONS'}
  -p, --port=<port>             Server port (default: 8080)

${'EXAMPLES'}
  ${'# Scan a Flutter project'}
  dart_doc_pilot scan ./my_flutter_app

  ${'# Generate HTML documentation'}
  dart_doc_pilot build ./my_flutter_app --format html

  ${'# Generate markdown docs to custom directory'}
  dart_doc_pilot build ./my_flutter_app -f markdown -o ./output

  ${'# Serve documentation on custom port'}
  dart_doc_pilot serve ./my_flutter_app --port 3000

${'━' * 60}
''');
  }

  void _printVersion() {
    print('''
${'dart_doc_pilot'} version ${'1.0.0'}
${'A powerful Flutter documentation generator'}
''');
  }

  Future<void> _handleScan(List<String> args) async {
    if (args.isEmpty) {
      _logger.err('❌ Error: Please provide a directory to scan');
      _logger.info('Usage: dart_doc_pilot scan <directory>');
      exit(1);
    }

    final directory = args[0];
    final dirPath = path.normalize(path.absolute(directory));

    if (!Directory(dirPath).existsSync()) {
      _logger.err('❌ Error: Directory not found: $dirPath');
      exit(1);
    }

    _logger.info('');
    _logger.info('${'━' * 60}');
    _logger.info('🔍 Scanning Project');
    _logger.info('${'━' * 60}');
    _logger.info('📂 Directory: $dirPath');
    _logger.info('');

    final stopwatch = Stopwatch()..start();

    final progress = _logger.progress('🔎 Discovering Dart files');

    try {
      final parser = DartDocParser(rootPath: dirPath);
      final doc = await parser.parse();

      progress.complete('✓ Discovery complete');

      final parseProgress = _logger.progress('📖 Parsing documentation');
      await Future.delayed(Duration(milliseconds: 300)); // Simulate processing
      parseProgress.complete('✓ Parsing complete');

      stopwatch.stop();

      _logger.info('');
      _logger.info('${'━' * 60}');
      _logger.info('✨ Scan Results');
      _logger.info('${'━' * 60}');
      _printStatistics(doc);
      _logger.info('');
      _logger.info('⏱️  Completed in ${stopwatch.elapsedMilliseconds}ms');
      _logger.info('${'━' * 60}');
      _logger.info('');

      _logger.success('✓ Scan completed successfully!');
    } catch (e) {
      progress.fail('✗ Scan failed');
      _logger.err('❌ Error: $e');
      exit(1);
    }
  }

  Future<void> _handleBuild(ArgResults command) async {
    if (command.rest.isEmpty) {
      _logger.err('❌ Error: Please provide a directory to build');
      _logger.info('Usage: dart_doc_pilot build <directory> [options]');
      exit(1);
    }

    final directory = command.rest[0];
    final dirPath = path.normalize(path.absolute(directory));
    final format = command['format'] as String;
    final outputDir = command['output'] as String;

    if (!Directory(dirPath).existsSync()) {
      _logger.err('❌ Error: Directory not found: $dirPath');
      exit(1);
    }

    _logger.info('');
    _logger.info('${'━' * 60}');
    _logger.info('🔨 Building Documentation');
    _logger.info('${'━' * 60}');
    _logger.info('📂 Source: $dirPath');
    _logger.info('📄 Format: ${format.toUpperCase()}');
    _logger.info('📁 Output: $outputDir');
    _logger.info('');

    final stopwatch = Stopwatch()..start();

    try {
      // Parse
      final scanProgress = _logger.progress('🔍 Scanning files');
      final parser = DartDocParser(rootPath: dirPath);
      final doc = await parser.parse();
      scanProgress.complete(
        '✓ Files scanned (${doc.classes.length} classes found)',
      );

      // Parse documentation
      final parseProgress = _logger.progress('📖 Extracting documentation');
      await Future.delayed(Duration(milliseconds: 200));
      parseProgress.complete('✓ Documentation extracted');

      // Export
      final exportProgress = _logger.progress('📦 Generating $format output');

      final exporter = _getExporter(format);
      await exporter.export(doc, outputDir);

      exportProgress.complete('✓ Output generated');

      // Finalize
      final finalizeProgress = _logger.progress('✨ Finalizing');
      await Future.delayed(Duration(milliseconds: 100));
      finalizeProgress.complete('✓ Build complete');

      stopwatch.stop();

      _logger.info('');
      _logger.info('${'━' * 60}');
      _logger.info('📊 Build Statistics');
      _logger.info('${'━' * 60}');
      _printStatistics(doc);
      _logger.info('');
      _logger.info('📂 Output: ${path.absolute(outputDir)}');
      _logger.info('⏱️  Completed in ${stopwatch.elapsedMilliseconds}ms');
      _logger.info('${'━' * 60}');
      _logger.info('');

      _logger.success('✓ Documentation built successfully!');

      if (format == 'html') {
        _logger.info('');
        _logger.info('💡 Tip: Run dart_doc_pilot serve $directory to preview');
      }
    } catch (e) {
      _logger.err('❌ Build failed: $e');
      exit(1);
    }
  }

  Future<void> _handleServe(ArgResults command) async {
    if (command.rest.isEmpty) {
      _logger.err('❌ Error: Please provide a directory to serve');
      _logger.info('Usage: dart_doc_pilot serve <directory> [options]');
      exit(1);
    }

    final directory = command.rest[0];
    final dirPath = path.normalize(path.absolute(directory));
    final port = int.parse(command['port'] as String);

    if (!Directory(dirPath).existsSync()) {
      _logger.err('❌ Error: Directory not found: $dirPath');
      exit(1);
    }

    _logger.info('');
    _logger.info('${'━' * 60}');
    _logger.info('🌐 Starting Documentation Server');
    _logger.info('${'━' * 60}');
    _logger.info('');

    try {
      // Build docs first if they don't exist
      final docsDir = Directory('docs');
      if (!docsDir.existsSync() || docsDir.listSync().isEmpty) {
        _logger.info('📦 Building documentation first...');
        final parser = DartDocParser(rootPath: dirPath);
        final doc = await parser.parse();
        final exporter = HtmlExporter();
        await exporter.export(doc, 'docs');
        _logger.success('✓ Documentation built');
        _logger.info('');
      }

      // Start server
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

      _logger.info('${'━' * 60}');
      _logger.info('✅ Server Running');
      _logger.info('${'━' * 60}');
      _logger.info('');
      _logger.info('🌐 URL: http://localhost:$port');
      _logger.info('📂 Serving: ${path.absolute('docs')}');
      _logger.info('');
      _logger.info('Press Ctrl+C to stop');
      _logger.info('${'━' * 60}');
      _logger.info('');

      await for (HttpRequest request in server) {
        _handleRequest(request);
      }
    } catch (e) {
      _logger.err('❌ Server error: $e');
      exit(1);
    }
  }

  void _handleRequest(HttpRequest request) {
    final filePath = request.uri.path == '/'
        ? 'docs/index.html'
        : 'docs${request.uri.path}';

    final file = File(filePath);

    if (file.existsSync()) {
      final contentType = _getContentType(filePath);
      request.response
        ..headers.contentType = contentType
        ..add(file.readAsBytesSync())
        ..close();

      final timestamp = DateTime.now().toString().substring(11, 19);
      final method = request.method;
      final path = request.uri.path;

      _logger.info('[$timestamp] $method $path - 200');
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('404 - Not Found')
        ..close();

      final timestamp = DateTime.now().toString().substring(11, 19);
      final path = request.uri.path;

      _logger.warn('[$timestamp] GET $path - 404');
    }
  }

  ContentType _getContentType(String path) {
    if (path.endsWith('.html')) return ContentType.html;
    if (path.endsWith('.css')) return ContentType('text', 'css');
    if (path.endsWith('.js')) return ContentType('application', 'javascript');
    if (path.endsWith('.json')) return ContentType.json;
    if (path.endsWith('.png')) return ContentType('image', 'png');
    if (path.endsWith('.jpg') || path.endsWith('.jpeg'))
      return ContentType('image', 'jpeg');
    return ContentType.text;
  }

  Exporter _getExporter(String format) {
    switch (format) {
      case 'json':
        return JsonExporter();
      case 'markdown':
        return MarkdownExporter();
      case 'html':
        return HtmlExporter();
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }

  void _printStatistics(doc) {
    final methodsCount = doc.classes.fold<int>(
      0,
      (int sum, dynamic cls) => sum + (cls.methods.length as int),
    );
    final fieldsCount = doc.classes.fold<int>(
      0,
      (int sum, dynamic cls) => sum + (cls.fields.length as int),
    );
    final constructorsCount = doc.classes.fold<int>(
      0,
      (int sum, dynamic cls) => sum + (cls.constructors.length as int),
    );

    final stats = [
      ('Classes', doc.classes.length),
      ('Enums', doc.enums.length),
      ('Extensions', doc.extensions.length),
      ('Typedefs', doc.typedefs.length),
      ('Methods', methodsCount),
      ('Fields', fieldsCount),
      ('Constructors', constructorsCount),
    ];

    for (final stat in stats) {
      final icon = _getStatIcon(stat.$1);
      final label = stat.$1.padRight(15);
      final value = stat.$2.toString().padLeft(5);
      _logger.info('  $icon $label $value');
    }
  }

  String _getStatIcon(String label) {
    switch (label) {
      case 'Classes':
        return '📦';
      case 'Enums':
        return '🔢';
      case 'Extensions':
        return '🔧';
      case 'Typedefs':
        return '📝';
      case 'Methods':
        return '⚡';
      case 'Fields':
        return '💎';
      case 'Constructors':
        return '🏗️';
      default:
        return '•';
    }
  }
}
