/// Documentation exporters for various output formats
library exporters;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'models.dart';

/// Base exporter interface
abstract class Exporter {
  Future<void> export(Documentation doc, String outputPath);
}

/// JSON exporter
class JsonExporter implements Exporter {
  @override
  Future<void> export(Documentation doc, String outputPath) async {
    final file = File(path.join(outputPath, 'documentation.json'));
    await file.parent.create(recursive: true);

    final encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(doc.toJson());

    await file.writeAsString(jsonString);
  }
}

/// Markdown exporter
class MarkdownExporter implements Exporter {
  @override
  Future<void> export(Documentation doc, String outputPath) async {
    final dir = Directory(outputPath);
    await dir.create(recursive: true);

    // Create index
    await _createIndex(doc, outputPath);

    // Create class pages
    for (final cls in doc.classes) {
      await _createClassPage(cls, outputPath);
    }

    // Create enum pages
    for (final enm in doc.enums) {
      await _createEnumPage(enm, outputPath);
    }

    // Create extension pages
    for (final ext in doc.extensions) {
      await _createExtensionPage(ext, outputPath);
    }
  }

  Future<void> _createIndex(Documentation doc, String outputPath) async {
    final buffer = StringBuffer();

    buffer.writeln('# ${doc.projectName} Documentation');
    buffer.writeln();
    buffer.writeln('Generated: ${doc.generatedAt}');
    buffer.writeln();

    if (doc.categories.isNotEmpty) {
      buffer.writeln('## Categories');
      buffer.writeln();

      for (final entry in doc.categories.entries) {
        buffer.writeln('### ${entry.key}');
        buffer.writeln();
        for (final item in entry.value) {
          buffer.writeln('- [$item]($item.md)');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('## Classes');
    buffer.writeln();
    for (final cls in doc.classes) {
      buffer.writeln('- [${cls.name}](${cls.name}.md)');
    }
    buffer.writeln();

    if (doc.enums.isNotEmpty) {
      buffer.writeln('## Enums');
      buffer.writeln();
      for (final enm in doc.enums) {
        buffer.writeln('- [${enm.name}](${enm.name}.md)');
      }
      buffer.writeln();
    }

    if (doc.extensions.isNotEmpty) {
      buffer.writeln('## Extensions');
      buffer.writeln();
      for (final ext in doc.extensions) {
        buffer.writeln(
          '- [${ext.displayName}](${ext.name ?? 'extension_${doc.extensions.indexOf(ext)}'}.md)',
        );
      }
      buffer.writeln();
    }

    final file = File(path.join(outputPath, 'README.md'));
    await file.writeAsString(buffer.toString());
  }

  Future<void> _createClassPage(ClassDoc cls, String outputPath) async {
    final buffer = StringBuffer();

    buffer.writeln('# ${cls.name}');
    buffer.writeln();

    if (cls.category != null) {
      buffer.writeln('**Category:** ${cls.category}');
      if (cls.subCategory != null) {
        buffer.writeln(' > ${cls.subCategory}');
      }
      buffer.writeln();
    }

    buffer.writeln('**File:** ${cls.filePath}');
    buffer.writeln();

    if (cls.description != null) {
      buffer.writeln(cls.description);
      buffer.writeln();
    }

    // Inheritance
    if (cls.superclass != null ||
        cls.mixins.isNotEmpty ||
        cls.interfaces.isNotEmpty) {
      buffer.writeln('## Inheritance');
      buffer.writeln();
      if (cls.superclass != null) {
        buffer.writeln('- **Extends:** ${cls.superclass}');
      }
      if (cls.mixins.isNotEmpty) {
        buffer.writeln('- **Mixins:** ${cls.mixins.join(', ')}');
      }
      if (cls.interfaces.isNotEmpty) {
        buffer.writeln('- **Implements:** ${cls.interfaces.join(', ')}');
      }
      buffer.writeln();
    }

    // Constructors
    if (cls.constructors.isNotEmpty) {
      buffer.writeln('## Constructors');
      buffer.writeln();

      for (final constructor in cls.constructors) {
        buffer.writeln('### ${cls.name}.${constructor.displayName}');
        buffer.writeln();

        if (constructor.description != null) {
          buffer.writeln(constructor.description);
          buffer.writeln();
        }

        if (constructor.parameters.isNotEmpty) {
          buffer.writeln('**Parameters:**');
          buffer.writeln();
          for (final param in constructor.parameters) {
            buffer.write('- `${param.name}` (`${param.type}`)');
            if (param.isRequired) buffer.write(' *required*');
            if (param.defaultValue != null)
              buffer.write(' = `${param.defaultValue}`');
            buffer.writeln();
            if (param.description != null) {
              buffer.writeln('  - ${param.description}');
            }
          }
          buffer.writeln();
        }

        _addCodeExamples(buffer, constructor.codeExamples);
      }
    }

    // Fields
    if (cls.fields.isNotEmpty) {
      buffer.writeln('## Properties');
      buffer.writeln();

      for (final field in cls.fields) {
        buffer.write('### ${field.name}');
        buffer.writeln();
        buffer.writeln('```dart');
        if (field.isStatic) buffer.write('static ');
        if (field.isConst) buffer.write('const ');
        if (field.isFinal) buffer.write('final ');
        if (field.isLate) buffer.write('late ');
        buffer.write('${field.type} ${field.name}');
        if (field.defaultValue != null)
          buffer.write(' = ${field.defaultValue}');
        buffer.writeln(';');
        buffer.writeln('```');
        buffer.writeln();

        if (field.description != null) {
          buffer.writeln(field.description);
          buffer.writeln();
        }
      }
    }

    // Methods
    if (cls.methods.isNotEmpty) {
      buffer.writeln('## Methods');
      buffer.writeln();

      for (final method in cls.methods) {
        buffer.writeln('### ${method.name}');
        buffer.writeln();

        buffer.writeln('```dart');
        if (method.isStatic) buffer.write('static ');
        if (method.isAbstract) buffer.write('abstract ');
        buffer.write('${method.returnType} ${method.name}');

        if (method.isGetter) {
          buffer.write(' => ...');
        } else if (method.isSetter) {
          buffer.write('(value)');
        } else {
          buffer.write('(');
          buffer.write(
            method.parameters
                .map((p) {
                  final prefix = p.isRequired ? 'required ' : '';
                  final suffix = p.defaultValue != null
                      ? ' = ${p.defaultValue}'
                      : '';
                  return '$prefix${p.type} ${p.name}$suffix';
                })
                .join(', '),
          );
          buffer.write(')');
        }

        buffer.writeln(';');
        buffer.writeln('```');
        buffer.writeln();

        if (method.description != null) {
          buffer.writeln(method.description);
          buffer.writeln();
        }

        if (method.parameters.isNotEmpty &&
            !method.isGetter &&
            !method.isSetter) {
          buffer.writeln('**Parameters:**');
          buffer.writeln();
          for (final param in method.parameters) {
            buffer.write('- `${param.name}` (`${param.type}`)');
            if (param.isRequired) buffer.write(' *required*');
            buffer.writeln();
          }
          buffer.writeln();
        }

        _addCodeExamples(buffer, method.codeExamples);
      }
    }

    _addCodeExamples(buffer, cls.codeExamples);

    final file = File(path.join(outputPath, '${cls.name}.md'));
    await file.writeAsString(buffer.toString());
  }

  Future<void> _createEnumPage(EnumDoc enm, String outputPath) async {
    final buffer = StringBuffer();

    buffer.writeln('# ${enm.name}');
    buffer.writeln();

    if (enm.category != null) {
      buffer.writeln('**Category:** ${enm.category}');
      buffer.writeln();
    }

    buffer.writeln('**File:** ${enm.filePath}');
    buffer.writeln();

    if (enm.description != null) {
      buffer.writeln(enm.description);
      buffer.writeln();
    }

    buffer.writeln('## Values');
    buffer.writeln();

    for (final value in enm.values) {
      buffer.writeln('### ${value.name}');
      buffer.writeln();
      if (value.description != null) {
        buffer.writeln(value.description);
        buffer.writeln();
      }
    }

    final file = File(path.join(outputPath, '${enm.name}.md'));
    await file.writeAsString(buffer.toString());
  }

  Future<void> _createExtensionPage(ExtensionDoc ext, String outputPath) async {
    final buffer = StringBuffer();

    buffer.writeln('# ${ext.displayName}');
    buffer.writeln();

    buffer.writeln('**Extends:** ${ext.extendedType}');
    buffer.writeln();
    buffer.writeln('**File:** ${ext.filePath}');
    buffer.writeln();

    if (ext.description != null) {
      buffer.writeln(ext.description);
      buffer.writeln();
    }

    if (ext.methods.isNotEmpty) {
      buffer.writeln('## Methods');
      buffer.writeln();

      for (final method in ext.methods) {
        buffer.writeln('### ${method.name}');
        buffer.writeln();

        if (method.description != null) {
          buffer.writeln(method.description);
          buffer.writeln();
        }
      }
    }

    final fileName =
        ext.name ??
        'extension_on_${ext.extendedType.replaceAll('<', '_').replaceAll('>', '_')}';
    final file = File(path.join(outputPath, '$fileName.md'));
    await file.writeAsString(buffer.toString());
  }

  void _addCodeExamples(StringBuffer buffer, List<CodeBlock> examples) {
    if (examples.isNotEmpty) {
      buffer.writeln('**Examples:**');
      buffer.writeln();

      for (final example in examples) {
        buffer.writeln('```${example.language ?? 'dart'}');
        buffer.writeln(example.code);
        buffer.writeln('```');
        buffer.writeln();
      }
    }
  }
}

/// HTML exporter with rich UI
class HtmlExporter implements Exporter {
  @override
  Future<void> export(Documentation doc, String outputPath) async {
    final dir = Directory(outputPath);
    await dir.create(recursive: true);

    // Create assets
    await _createAssets(outputPath);

    // Create index page
    await _createIndexPage(doc, outputPath);

    // Create class pages
    for (final cls in doc.classes) {
      await _createClassHtmlPage(cls, doc, outputPath);
    }

    // Create enum pages
    for (final enm in doc.enums) {
      await _createEnumHtmlPage(enm, doc, outputPath);
    }
  }

  Future<void> _createAssets(String outputPath) async {
    final cssDir = Directory(path.join(outputPath, 'assets', 'css'));
    await cssDir.create(recursive: true);

    final jsDir = Directory(path.join(outputPath, 'assets', 'js'));
    await jsDir.create(recursive: true);

    final css = '''
/* Dark Mode Theme - Material Design 3 Inspired */
:root {
  --bg-primary: #0d1117;
  --bg-secondary: #161b22;
  --bg-tertiary: #1c2128;
  --bg-hover: #21262d;
  --border: #30363d;
  --text-primary: #e6edf3;
  --text-secondary: #8b949e;
  --text-tertiary: #6e7681;
  --accent: #58a6ff;
  --accent-hover: #79c0ff;
  --success: #3fb950;
  --warning: #d29922;
  --danger: #f85149;
  --code-bg: #161b22;
  --shadow: rgba(0, 0, 0, 0.3);
  --sidebar-width: 280px;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Noto Sans', Helvetica, Arial, sans-serif;
  color: var(--text-primary);
  background: var(--bg-primary);
  line-height: 1.6;
  overflow-x: hidden;
}

/* Header */
header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 64px;
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border);
  padding: 0 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  z-index: 100;
  backdrop-filter: blur(10px);
}

.header-title {
  font-size: 20px;
  font-weight: 600;
  color: var(--text-primary);
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-title .emoji {
  font-size: 24px;
}

/* Sidebar */
.sidebar {
  position: fixed;
  top: 64px;
  left: 0;
  bottom: 0;
  width: var(--sidebar-width);
  background: var(--bg-secondary);
  border-right: 1px solid var(--border);
  overflow-y: auto;
  z-index: 50;
  padding: 20px 0;
}

.sidebar::-webkit-scrollbar {
  width: 8px;
}

.sidebar::-webkit-scrollbar-track {
  background: var(--bg-secondary);
}

.sidebar::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 4px;
}

.sidebar::-webkit-scrollbar-thumb:hover {
  background: var(--text-tertiary);
}

/* Search Box */
.search-container {
  padding: 0 16px 20px 16px;
  position: sticky;
  top: 0;
  background: var(--bg-secondary);
  z-index: 10;
  border-bottom: 1px solid var(--border);
}

.search-box {
  width: 100%;
  padding: 10px 16px 10px 40px;
  background: var(--bg-tertiary);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--text-primary);
  font-size: 14px;
  transition: all 0.2s;
  position: relative;
}

.search-box:focus {
  outline: none;
  border-color: var(--accent);
  background: var(--bg-primary);
}

.search-icon {
  position: absolute;
  left: 28px;
  top: 21px;
  color: var(--text-tertiary);
  pointer-events: none;
}

/* Navigation */
.nav-section {
  margin-bottom: 24px;
}

.nav-section-title {
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--text-tertiary);
}

.nav-category {
  margin-bottom: 16px;
}

.nav-category-title {
  padding: 8px 16px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  transition: all 0.2s;
}

.nav-category-title:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.nav-category-title .arrow {
  font-size: 10px;
  transition: transform 0.2s;
}

.nav-category.collapsed .arrow {
  transform: rotate(-90deg);
}

.nav-subcategory {
  padding-left: 12px;
}

.nav-subcategory-title {
  padding: 6px 16px;
  font-size: 12px;
  font-weight: 500;
  color: var(--text-tertiary);
  text-transform: uppercase;
  letter-spacing: 0.3px;
}

.nav-items {
  max-height: 1000px;
  overflow: hidden;
  transition: max-height 0.3s ease;
}

.nav-category.collapsed .nav-items {
  max-height: 0;
}

.nav-item {
  display: block;
  padding: 8px 16px 8px 28px;
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 14px;
  transition: all 0.2s;
  border-left: 2px solid transparent;
  position: relative;
}

.nav-item:hover {
  color: var(--accent-hover);
  background: var(--bg-hover);
  border-left-color: var(--accent);
}

.nav-item.active {
  color: var(--accent);
  background: var(--bg-tertiary);
  border-left-color: var(--accent);
  font-weight: 500;
}

.nav-item-badge {
  display: inline-block;
  padding: 2px 6px;
  background: var(--bg-tertiary);
  border-radius: 4px;
  font-size: 10px;
  margin-left: 6px;
  color: var(--text-tertiary);
}

/* Main Content */
main {
  margin-left: var(--sidebar-width);
  margin-top: 64px;
  padding: 40px;
  min-height: calc(100vh - 64px);
  max-width: 1200px;
}

.container {
  max-width: 100%;
}

/* Cards */
.card {
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 24px;
  transition: all 0.3s;
}

.card:hover {
  border-color: var(--text-tertiary);
  box-shadow: 0 8px 24px var(--shadow);
}

/* Typography */
h1 {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 8px;
  line-height: 1.2;
}

h2 {
  font-size: 1.8rem;
  font-weight: 600;
  color: var(--text-primary);
  margin: 40px 0 20px;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--border);
}

h3 {
  font-size: 1.4rem;
  font-weight: 600;
  color: var(--text-primary);
  margin: 24px 0 12px;
}

h4 {
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--text-secondary);
  margin: 16px 0 8px;
}

p {
  margin: 12px 0;
  color: var(--text-secondary);
}

/* Code Blocks */
code {
  background: var(--code-bg);
  padding: 3px 8px;
  border-radius: 6px;
  font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Courier New', monospace;
  font-size: 0.9em;
  color: var(--accent);
  border: 1px solid var(--border);
}

pre {
  background: var(--code-bg);
  padding: 20px;
  border-radius: 8px;
  overflow-x: auto;
  margin: 16px 0;
  border: 1px solid var(--border);
}

pre code {
  background: none;
  padding: 0;
  border: none;
  color: var(--text-primary);
  font-size: 14px;
  line-height: 1.6;
}

/* Badges */
.badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 0.85em;
  font-weight: 500;
  margin-right: 8px;
  margin-bottom: 8px;
}

.badge-abstract {
  background: rgba(255, 152, 0, 0.15);
  color: #ffb74d;
  border: 1px solid rgba(255, 152, 0, 0.3);
}

.badge-static {
  background: rgba(33, 150, 243, 0.15);
  color: #64b5f6;
  border: 1px solid rgba(33, 150, 243, 0.3);
}

.badge-const {
  background: rgba(156, 39, 176, 0.15);
  color: #ba68c8;
  border: 1px solid rgba(156, 39, 176, 0.3);
}

.badge-final {
  background: rgba(76, 175, 80, 0.15);
  color: #81c784;
  border: 1px solid rgba(76, 175, 80, 0.3);
}

.badge-async {
  background: rgba(233, 30, 99, 0.15);
  color: #f48fb1;
  border: 1px solid rgba(233, 30, 99, 0.3);
}

.category-badge {
  background: var(--accent);
  color: var(--bg-primary);
  padding: 6px 14px;
  border-radius: 16px;
  display: inline-block;
  margin-bottom: 16px;
  font-weight: 500;
  font-size: 0.9em;
}

/* Breadcrumb */
.breadcrumb {
  color: var(--text-tertiary);
  margin-bottom: 20px;
  font-size: 14px;
}

.breadcrumb a {
  color: var(--accent);
  text-decoration: none;
  transition: color 0.2s;
}

.breadcrumb a:hover {
  color: var(--accent-hover);
  text-decoration: underline;
}

/* Method Signature */
.method-signature {
  background: var(--code-bg);
  padding: 16px 20px;
  border-radius: 8px;
  border-left: 4px solid var(--accent);
  margin: 16px 0;
  font-family: 'SF Mono', Monaco, monospace;
  font-size: 14px;
  color: var(--text-primary);
  overflow-x: auto;
}

/* Parameter List */
.param-list {
  margin: 16px 0;
}

.param-item {
  padding: 12px 16px;
  background: var(--bg-tertiary);
  border-left: 3px solid var(--border);
  margin: 8px 0;
  border-radius: 4px;
  transition: all 0.2s;
}

.param-item:hover {
  border-left-color: var(--accent);
  background: var(--bg-hover);
}

.param-name {
  font-weight: 600;
  color: var(--accent);
  font-family: monospace;
}

.param-type {
  color: var(--text-tertiary);
  font-family: monospace;
  font-size: 0.9em;
}

/* Grid Layout */
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
  margin: 24px 0;
}

.grid-item {
  background: var(--bg-secondary);
  padding: 20px;
  border-radius: 12px;
  border: 1px solid var(--border);
  transition: all 0.3s;
}

.grid-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px var(--shadow);
  border-color: var(--accent);
}

.grid-item h3 {
  margin: 0 0 12px 0;
  font-size: 1.2rem;
}

.grid-item a {
  color: var(--accent);
  text-decoration: none;
  font-weight: 600;
  transition: color 0.2s;
}

.grid-item a:hover {
  color: var(--accent-hover);
}

.grid-item p {
  color: var(--text-tertiary);
  font-size: 0.9em;
  margin-top: 8px;
}

/* Stats */
.stats {
  display: flex;
  gap: 20px;
  margin: 24px 0;
  flex-wrap: wrap;
}

.stat-item {
  background: var(--bg-tertiary);
  padding: 16px 24px;
  border-radius: 8px;
  border: 1px solid var(--border);
  flex: 1;
  min-width: 140px;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: var(--accent);
  display: block;
}

.stat-label {
  font-size: 0.85em;
  color: var(--text-tertiary);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-tertiary);
}

.empty-state-icon {
  font-size: 48px;
  margin-bottom: 16px;
  opacity: 0.5;
}

/* Scrollbar Styling */
::-webkit-scrollbar {
  width: 12px;
  height: 12px;
}

::-webkit-scrollbar-track {
  background: var(--bg-primary);
}

::-webkit-scrollbar-thumb {
  background: var(--border);
  border-radius: 6px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--text-tertiary);
}

/* Mobile Responsive */
@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    transition: transform 0.3s;
  }
  
  .sidebar.active {
    transform: translateX(0);
  }
  
  main {
    margin-left: 0;
    padding: 20px;
  }
  
  .header-title {
    font-size: 16px;
  }
  
  h1 {
    font-size: 2rem;
  }
  
  h2 {
    font-size: 1.5rem;
  }
  
  .grid {
    grid-template-columns: 1fr;
  }
}

/* Animations */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.card, .grid-item {
  animation: fadeIn 0.3s ease;
}

/* Selection */
::selection {
  background: var(--accent);
  color: var(--bg-primary);
}
''';

    await File(path.join(cssDir.path, 'styles.css')).writeAsString(css);

    // Create JavaScript for search and interactions
    final js = '''
// Search functionality
const searchBox = document.getElementById('searchBox');
const navItems = document.querySelectorAll('.nav-item');
const gridItems = document.querySelectorAll('.grid-item');

if (searchBox) {
  searchBox.addEventListener('input', function(e) {
    const query = e.target.value.toLowerCase();
    
    // Search navigation items
    navItems.forEach(item => {
      const text = item.textContent.toLowerCase();
      const category = item.closest('.nav-category');
      
      if (text.includes(query)) {
        item.style.display = 'block';
        if (category) {
          category.classList.remove('collapsed');
        }
      } else {
        item.style.display = query ? 'none' : 'block';
      }
    });
    
    // Search grid items
    gridItems.forEach(item => {
      const text = item.textContent.toLowerCase();
      item.style.display = text.includes(query) ? 'block' : 'none';
    });
    
    // Show all categories if searching
    if (query) {
      document.querySelectorAll('.nav-category').forEach(cat => {
        cat.classList.remove('collapsed');
      });
    }
  });
}

// Category collapse/expand
document.querySelectorAll('.nav-category-title').forEach(title => {
  title.addEventListener('click', function() {
    this.parentElement.classList.toggle('collapsed');
  });
});

// Highlight active page
const currentPath = window.location.pathname.split('/').pop();
navItems.forEach(item => {
  if (item.getAttribute('href') === currentPath) {
    item.classList.add('active');
    
    // Expand parent categories
    let parent = item.closest('.nav-category');
    while (parent) {
      parent.classList.remove('collapsed');
      parent = parent.parentElement.closest('.nav-category');
    }
  }
});

// Mobile menu toggle
const menuButton = document.getElementById('menuButton');
const sidebar = document.querySelector('.sidebar');

if (menuButton) {
  menuButton.addEventListener('click', function() {
    sidebar.classList.toggle('active');
  });
}

// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
});
''';

    await File(path.join(jsDir.path, 'app.js')).writeAsString(js);
  }

  Future<void> _createIndexPage(Documentation doc, String outputPath) async {
    final html =
        '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${doc.projectName} Documentation</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
    <header>
        <div class="header-title">
            <span class="emoji">📚</span>
            <span>${doc.projectName}</span>
        </div>
        <button id="menuButton" style="display: none; background: none; border: none; color: var(--text-primary); font-size: 24px; cursor: pointer;">☰</button>
    </header>
    
    <aside class="sidebar">
        <div class="search-container">
            <span class="search-icon">🔍</span>
            <input type="text" class="search-box" id="searchBox" placeholder="Search documentation...">
        </div>
        
        <nav>
            ${_buildSidebarNavigation(doc)}
        </nav>
    </aside>
    
    <main>
        <div class="container">
            <h1>Welcome to ${doc.projectName}</h1>
            <p style="font-size: 1.1em; color: var(--text-secondary); margin-bottom: 32px;">
                Generated on ${doc.generatedAt.toString().split('.')[0]}
            </p>
            
            <div class="stats">
                <div class="stat-item">
                    <span class="stat-value">${doc.classes.length}</span>
                    <span class="stat-label">Classes</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value">${doc.enums.length}</span>
                    <span class="stat-label">Enums</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value">${doc.extensions.length}</span>
                    <span class="stat-label">Extensions</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value">${doc.typedefs.length}</span>
                    <span class="stat-label">Typedefs</span>
                </div>
            </div>
            
            ${_buildCategoriesSection(doc)}
            
            <h2>📦 All Classes</h2>
            <div class="grid">
                ${doc.classes.map((cls) => '''
                <div class="grid-item">
                    <h3><a href="${cls.name}.html">${cls.name}</a></h3>
                    ${cls.category != null ? '<span class="badge badge-static">${cls.category}</span>' : ''}
                    ${cls.isAbstract ? '<span class="badge badge-abstract">abstract</span>' : ''}
                    <p>${_escapeHtml(cls.description?.split('\n').first ?? 'No description available')}</p>
                </div>
                ''').join()}
            </div>
            
            ${doc.enums.isNotEmpty ? '''
            <h2>🔢 Enumerations</h2>
            <div class="grid">
                ${doc.enums.map((enm) => '''
                <div class="grid-item">
                    <h3><a href="${enm.name}.html">${enm.name}</a></h3>
                    ${enm.category != null ? '<span class="badge badge-static">${enm.category}</span>' : ''}
                    <p>${_escapeHtml(enm.description?.split('\n').first ?? 'No description available')}</p>
                </div>
                ''').join()}
            </div>
            ''' : ''}
            
            ${doc.extensions.isNotEmpty ? '''
            <h2>🔧 Extensions</h2>
            <div class="grid">
                ${doc.extensions.map((ext) => '''
                <div class="grid-item">
                    <h3><a href="${ext.name ?? 'extension_${doc.extensions.indexOf(ext)}'}.html">${ext.displayName}</a></h3>
                    <p>Extends <code>${ext.extendedType}</code></p>
                </div>
                ''').join()}
            </div>
            ''' : ''}
        </div>
    </main>
    
    <script src="assets/js/app.js"></script>
</body>
</html>
''';

    await File(path.join(outputPath, 'index.html')).writeAsString(html);
  }

  String _buildSidebarNavigation(Documentation doc) {
    final buffer = StringBuffer();

    // Group by categories
    if (doc.categories.isNotEmpty) {
      buffer.writeln('<div class="nav-section">');
      buffer.writeln('<div class="nav-section-title">Categories</div>');

      for (final category in doc.categories.entries) {
        buffer.writeln('<div class="nav-category">');
        buffer.writeln('<div class="nav-category-title">');
        buffer.writeln('  <span>📁 ${category.key}</span>');
        buffer.writeln('  <span class="arrow">▼</span>');
        buffer.writeln('</div>');
        buffer.writeln('<div class="nav-items">');

        // Group by subcategories
        final itemsBySubcat = <String, List<String>>{};
        for (final itemName in category.value) {
          final item = doc.classes.firstWhere(
            (c) => c.name == itemName,
            orElse: () => doc.classes.first,
          );
          final subcat = item.subCategory ?? 'Other';
          itemsBySubcat.putIfAbsent(subcat, () => []).add(itemName);
        }

        for (final subcatEntry in itemsBySubcat.entries) {
          if (subcatEntry.key != 'Other') {
            buffer.writeln('<div class="nav-subcategory">');
            buffer.writeln(
              '<div class="nav-subcategory-title">${subcatEntry.key}</div>',
            );
          }

          for (final item in subcatEntry.value) {
            buffer.writeln('<a href="$item.html" class="nav-item">$item</a>');
          }

          if (subcatEntry.key != 'Other') {
            buffer.writeln('</div>');
          }
        }

        buffer.writeln('</div>');
        buffer.writeln('</div>');
      }

      buffer.writeln('</div>');
    }

    // All classes section
    buffer.writeln('<div class="nav-section">');
    buffer.writeln('<div class="nav-section-title">All Classes</div>');
    buffer.writeln('<div class="nav-category">');
    buffer.writeln('<div class="nav-category-title">');
    buffer.writeln('  <span>📦 Classes (${doc.classes.length})</span>');
    buffer.writeln('  <span class="arrow">▼</span>');
    buffer.writeln('</div>');
    buffer.writeln('<div class="nav-items">');
    for (final cls in doc.classes) {
      buffer.writeln(
        '<a href="${cls.name}.html" class="nav-item">${cls.name}</a>',
      );
    }
    buffer.writeln('</div>');
    buffer.writeln('</div>');
    buffer.writeln('</div>');

    // Enums
    if (doc.enums.isNotEmpty) {
      buffer.writeln('<div class="nav-section">');
      buffer.writeln('<div class="nav-category">');
      buffer.writeln('<div class="nav-category-title">');
      buffer.writeln('  <span>🔢 Enums (${doc.enums.length})</span>');
      buffer.writeln('  <span class="arrow">▼</span>');
      buffer.writeln('</div>');
      buffer.writeln('<div class="nav-items">');
      for (final enm in doc.enums) {
        buffer.writeln(
          '<a href="${enm.name}.html" class="nav-item">${enm.name}</a>',
        );
      }
      buffer.writeln('</div>');
      buffer.writeln('</div>');
      buffer.writeln('</div>');
    }

    // Extensions
    if (doc.extensions.isNotEmpty) {
      buffer.writeln('<div class="nav-section">');
      buffer.writeln('<div class="nav-category">');
      buffer.writeln('<div class="nav-category-title">');
      buffer.writeln('  <span>🔧 Extensions (${doc.extensions.length})</span>');
      buffer.writeln('  <span class="arrow">▼</span>');
      buffer.writeln('</div>');
      buffer.writeln('<div class="nav-items">');
      for (final ext in doc.extensions) {
        final name = ext.name ?? 'extension_${doc.extensions.indexOf(ext)}';
        buffer.writeln(
          '<a href="$name.html" class="nav-item">${ext.displayName}</a>',
        );
      }
      buffer.writeln('</div>');
      buffer.writeln('</div>');
      buffer.writeln('</div>');
    }

    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _buildCategoriesSection(Documentation doc) {
    if (doc.categories.isEmpty) return '';

    return '''
    <h2>Categories</h2>
    <div class="grid">
        ${doc.categories.entries.map((entry) => '''
        <div class="grid-item">
            <h3>${entry.key}</h3>
            <ul>
                ${entry.value.map((item) => '<li><a href="$item.html">$item</a></li>').join()}
            </ul>
        </div>
        ''').join()}
    </div>
    ''';
  }

  Future<void> _createClassHtmlPage(
    ClassDoc cls,
    Documentation doc,
    String outputPath,
  ) async {
    final html =
        '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${cls.name} - ${doc.projectName}</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
    <header>
        <div class="header-title">
            <span class="emoji">📚</span>
            <span>${doc.projectName}</span>
        </div>
    </header>
    
    <aside class="sidebar">
        <div class="search-container">
            <span class="search-icon">🔍</span>
            <input type="text" class="search-box" id="searchBox" placeholder="Search documentation...">
        </div>
        
        <nav>
            ${_buildSidebarNavigation(doc)}
        </nav>
    </aside>
    
    <main>
        <div class="container">
            <div class="breadcrumb">
                <a href="index.html">${doc.projectName}</a> / ${cls.name}
            </div>
            
            <h1>${cls.name}</h1>
            
            <div class="card">
                ${cls.isAbstract ? '<span class="badge badge-abstract">abstract</span>' : ''}
                ${cls.category != null ? '<span class="category-badge">${cls.category}${cls.subCategory != null ? ' > ${cls.subCategory}' : ''}</span>' : ''}
                
                <p style="margin-top: 16px;"><strong>📄 File:</strong> <code>${cls.filePath}</code></p>
                
                ${cls.description != null ? '<p style="margin-top: 16px; font-size: 1.05em;">${_escapeHtml(cls.description!)}</p>' : ''}
                
                ${cls.superclass != null || cls.mixins.isNotEmpty || cls.interfaces.isNotEmpty ? '''
                <div style="margin-top: 24px; padding-top: 20px; border-top: 1px solid var(--border);">
                    <h4>Inheritance</h4>
                    ${cls.superclass != null ? '<p><strong>Extends:</strong> <code>${cls.superclass}</code></p>' : ''}
                    ${cls.mixins.isNotEmpty ? '<p><strong>Mixins:</strong> ${cls.mixins.map((m) => '<code>$m</code>').join(', ')}</p>' : ''}
                    ${cls.interfaces.isNotEmpty ? '<p><strong>Implements:</strong> ${cls.interfaces.map((i) => '<code>$i</code>').join(', ')}</p>' : ''}
                </div>
                ''' : ''}
            </div>
            
            ${_buildConstructorsSection(cls)}
            ${_buildFieldsSection(cls)}
            ${_buildMethodsSection(cls)}
        </div>
    </main>
    
    <script src="assets/js/app.js"></script>
</body>
</html>
''';

    await File(path.join(outputPath, '${cls.name}.html')).writeAsString(html);
  }

  String _buildConstructorsSection(ClassDoc cls) {
    if (cls.constructors.isEmpty) return '';

    return '''
    <h2>Constructors</h2>
    ${cls.constructors.map((c) => '''
    <div class="card">
        <h3>${cls.name}.${c.displayName}</h3>
        ${c.isConst ? '<span class="badge badge-const">const</span>' : ''}
        ${c.isFactory ? '<span class="badge">factory</span>' : ''}
        
        ${c.description != null ? '<p>${c.description}</p>' : ''}
        
        ${c.parameters.isNotEmpty ? '''
        <h4>Parameters</h4>
        <div class="param-list">
            ${c.parameters.map((p) => '''
            <div class="param-item">
                <code>${p.name}</code> (<code>${p.type}</code>)
                ${p.isRequired ? '<span class="badge">required</span>' : ''}
                ${p.defaultValue != null ? ' = <code>${p.defaultValue}</code>' : ''}
            </div>
            ''').join()}
        </div>
        ''' : ''}
    </div>
    ''').join()}
    ''';
  }

  String _buildFieldsSection(ClassDoc cls) {
    if (cls.fields.isEmpty) return '';

    return '''
    <h2>Properties</h2>
    ${cls.fields.map((f) => '''
    <div class="card">
        <h3>${f.name}</h3>
        ${f.isStatic ? '<span class="badge badge-static">static</span>' : ''}
        ${f.isConst ? '<span class="badge badge-const">const</span>' : ''}
        ${f.isFinal ? '<span class="badge badge-final">final</span>' : ''}
        
        <div class="method-signature">
            ${f.type} ${f.name}${f.defaultValue != null ? ' = ${f.defaultValue}' : ''}
        </div>
        
        ${f.description != null ? '<p>${f.description}</p>' : ''}
    </div>
    ''').join()}
    ''';
  }

  String _buildMethodsSection(ClassDoc cls) {
    if (cls.methods.isEmpty) return '';

    return '''
    <h2>Methods</h2>
    ${cls.methods.map((m) => '''
    <div class="card">
        <h3>${m.name}</h3>
        ${m.isStatic ? '<span class="badge badge-static">static</span>' : ''}
        ${m.isAbstract ? '<span class="badge badge-abstract">abstract</span>' : ''}
        ${m.isAsync ? '<span class="badge">async</span>' : ''}
        
        <div class="method-signature">
            ${m.returnType} ${m.name}${m.isGetter
        ? ''
        : m.isSetter
        ? '(value)'
        : '(${m.parameters.map((p) => '${p.type} ${p.name}').join(', ')})'}
        </div>
        
        ${m.description != null ? '<p>${m.description}</p>' : ''}
        
        ${m.parameters.isNotEmpty && !m.isGetter && !m.isSetter ? '''
        <h4>Parameters</h4>
        <div class="param-list">
            ${m.parameters.map((p) => '''
            <div class="param-item">
                <code>${p.name}</code> (<code>${p.type}</code>)
                ${p.isRequired ? '<span class="badge">required</span>' : ''}
            </div>
            ''').join()}
        </div>
        ''' : ''}
    </div>
    ''').join()}
    ''';
  }

  Future<void> _createEnumHtmlPage(
    EnumDoc enm,
    Documentation doc,
    String outputPath,
  ) async {
    final html =
        '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${enm.name} - ${doc.projectName}</title>
    <link rel="stylesheet" href="assets/css/styles.css">
</head>
<body>
    <header>
        <div class="header-title">
            <span class="emoji">📚</span>
            <span>${doc.projectName}</span>
        </div>
    </header>
    
    <aside class="sidebar">
        <div class="search-container">
            <span class="search-icon">🔍</span>
            <input type="text" class="search-box" id="searchBox" placeholder="Search documentation...">
        </div>
        
        <nav>
            ${_buildSidebarNavigation(doc)}
        </nav>
    </aside>
    
    <main>
        <div class="container">
            <div class="breadcrumb">
                <a href="index.html">${doc.projectName}</a> / ${enm.name}
            </div>
            
            <h1>🔢 ${enm.name}</h1>
            
            <div class="card">
                ${enm.category != null ? '<span class="category-badge">${enm.category}</span>' : ''}
                <p style="margin-top: 16px;"><strong>📄 File:</strong> <code>${enm.filePath}</code></p>
                ${enm.description != null ? '<p style="margin-top: 16px; font-size: 1.05em;">${_escapeHtml(enm.description!)}</p>' : ''}
            </div>
            
            <h2>Values</h2>
            ${enm.values.map((v) => '''
            <div class="card">
                <h3><code>${v.name}</code></h3>
                ${v.description != null ? '<p>${_escapeHtml(v.description!)}</p>' : ''}
            </div>
            ''').join()}
        </div>
    </main>
    
    <script src="assets/js/app.js"></script>
</body>
</html>
''';

    await File(path.join(outputPath, '${enm.name}.html')).writeAsString(html);
  }
}
