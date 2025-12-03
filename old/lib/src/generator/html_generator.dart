import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:markdown/markdown.dart' as md;
import '../models/documentation.dart';
import 'templates.dart';

class HtmlGenerator {
  final String projectName;

  HtmlGenerator({required this.projectName});

  Future<void> generate(Documentation documentation, String outputDir) async {
    final dir = Directory(outputDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    // Generate search index
    final searchData = _generateSearchData(documentation);
    await _writeFile(
      path.join(outputDir, 'search.json'),
      jsonEncode(searchData),
    );

    // Generate index page
    await _generateIndexPage(documentation, outputDir);

    // Generate class pages
    for (final cls in documentation.classes) {
      await _generateClassPage(cls, documentation, outputDir);
    }

    // Generate enum pages
    for (final enumDoc in documentation.enums) {
      await _generateEnumPage(enumDoc, outputDir);
    }

    // Generate extension pages
    for (final ext in documentation.extensions) {
      await _generateExtensionPage(ext, outputDir);
    }

    print('📝 Generated ${documentation.classes.length} class pages');
    print('📝 Generated ${documentation.enums.length} enum pages');
    print('📝 Generated ${documentation.extensions.length} extension pages');
  }

  Future<void> _generateIndexPage(
    Documentation documentation,
    String outputDir,
  ) async {
    final categorized = documentation.getClassesByCategoryAndSubCategory();

    final sidebarHtml = _generateSidebar(categorized, documentation);
    final contentHtml = _generateIndexContent(categorized, documentation);

    final html = Templates.indexPage(
      projectName: projectName,
      sidebarHtml: sidebarHtml,
      contentHtml: contentHtml,
    );

    await _writeFile(path.join(outputDir, 'index.html'), html);
  }

  Future<void> _generateClassPage(
    ClassDoc cls,
    Documentation documentation,
    String outputDir,
  ) async {
    final categorized = documentation.getClassesByCategoryAndSubCategory();
    final sidebarHtml = _generateSidebar(
      categorized,
      documentation,
      activeCls: cls,
    );
    final contentHtml = _generateClassContent(cls);

    final html = Templates.classPage(
      projectName: projectName,
      className: cls.name,
      sidebarHtml: sidebarHtml,
      contentHtml: contentHtml,
    );

    final fileName = '${_sanitizeFileName(cls.name)}.html';
    await _writeFile(path.join(outputDir, fileName), html);
  }

  Future<void> _generateEnumPage(EnumDoc enumDoc, String outputDir) async {
    final contentHtml = _generateEnumContent(enumDoc);

    final html = Templates.classPage(
      projectName: projectName,
      className: enumDoc.name,
      sidebarHtml: '<div class="p-4 text-gray-500">Enum</div>',
      contentHtml: contentHtml,
    );

    final fileName = '${_sanitizeFileName(enumDoc.name)}.html';
    await _writeFile(path.join(outputDir, fileName), html);
  }

  Future<void> _generateExtensionPage(
    ExtensionDoc ext,
    String outputDir,
  ) async {
    final contentHtml = _generateExtensionContent(ext);

    final html = Templates.classPage(
      projectName: projectName,
      className: ext.name,
      sidebarHtml: '<div class="p-4 text-gray-500">Extension</div>',
      contentHtml: contentHtml,
    );

    final fileName = '${_sanitizeFileName(ext.name)}.html';
    await _writeFile(path.join(outputDir, fileName), html);
  }

  String _generateSidebar(
    Map<String, Map<String, List<ClassDoc>>> categorized,
    Documentation documentation, {
    ClassDoc? activeCls,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<div class="space-y-2">');

    // Home link
    buffer.writeln('''
      <a href="index.html" class="sidebar-link flex items-center gap-2 px-4 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
        </svg>
        <span class="font-medium">Home</span>
      </a>
    ''');

    for (final category in categorized.keys.toList()..sort()) {
      final subCategories = categorized[category]!;
      final categoryId = _sanitizeId(category);

      buffer.writeln('''
        <div class="category-group">
          <button 
            class="category-toggle w-full flex items-center justify-between px-4 py-2 text-left rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            onclick="toggleCategory('$categoryId')"
          >
            <span class="font-semibold text-gray-900 dark:text-gray-100">$category</span>
            <svg id="arrow-$categoryId" class="w-5 h-5 transform transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
            </svg>
          </button>
          <div id="category-$categoryId" class="category-content ml-4 mt-1 space-y-1 hidden">
      ''');

      for (final subCategory in subCategories.keys.toList()..sort()) {
        final classes = subCategories[subCategory]!;
        final subCategoryId = _sanitizeId('$category-$subCategory');

        buffer.writeln('''
          <div class="subcategory-group">
            <button 
              class="subcategory-toggle w-full flex items-center justify-between px-3 py-1.5 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors text-sm"
              onclick="toggleSubCategory('$subCategoryId')"
            >
              <span class="font-medium text-gray-700 dark:text-gray-300">$subCategory</span>
              <svg id="arrow-$subCategoryId" class="w-4 h-4 transform transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
              </svg>
            </button>
            <div id="subcategory-$subCategoryId" class="subcategory-content ml-3 mt-1 space-y-0.5 hidden">
        ''');

        for (final cls in classes..sort((a, b) => a.name.compareTo(b.name))) {
          final isActive = activeCls?.name == cls.name;
          final activeClass = isActive
              ? 'bg-blue-50 dark:bg-blue-900 text-blue-600 dark:text-blue-300'
              : 'text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-600';

          buffer.writeln('''
            <a 
              href="${_sanitizeFileName(cls.name)}.html" 
              class="block px-3 py-1.5 rounded text-sm transition-colors $activeClass"
            >
              ${cls.name}
            </a>
          ''');
        }

        buffer.writeln('</div></div>');
      }

      buffer.writeln('</div></div>');
    }

    // Add enums section if present
    if (documentation.enums.isNotEmpty) {
      buffer.writeln('''
        <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
          <div class="px-4 py-2 text-sm font-semibold text-gray-500 dark:text-gray-400">ENUMS</div>
          <div class="space-y-0.5">
      ''');

      for (final enumDoc
          in documentation.enums..sort((a, b) => a.name.compareTo(b.name))) {
        buffer.writeln('''
          <a 
            href="${_sanitizeFileName(enumDoc.name)}.html" 
            class="block px-4 py-1.5 text-sm rounded transition-colors text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-600"
          >
            ${enumDoc.name}
          </a>
        ''');
      }

      buffer.writeln('</div></div>');
    }

    // Add extensions section if present
    if (documentation.extensions.isNotEmpty) {
      buffer.writeln('''
        <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
          <div class="px-4 py-2 text-sm font-semibold text-gray-500 dark:text-gray-400">EXTENSIONS</div>
          <div class="space-y-0.5">
      ''');

      for (final ext
          in documentation.extensions
            ..sort((a, b) => a.name.compareTo(b.name))) {
        buffer.writeln('''
          <a 
            href="${_sanitizeFileName(ext.name)}.html" 
            class="block px-4 py-1.5 text-sm rounded transition-colors text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-600"
          >
            ${ext.name}
          </a>
        ''');
      }

      buffer.writeln('</div></div>');
    }

    buffer.writeln('</div>');

    return buffer.toString();
  }

  String _generateIndexContent(
    Map<String, Map<String, List<ClassDoc>>> categorized,
    Documentation documentation,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('''
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-2">$projectName</h1>
        <p class="text-lg text-gray-600 dark:text-gray-400">API Documentation</p>
      </div>
    ''');

    // Stats cards
    buffer.writeln('''
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <div class="stat-card bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800">
          <div class="text-3xl font-bold text-blue-600 dark:text-blue-400">${documentation.classes.length}</div>
          <div class="text-sm text-blue-600 dark:text-blue-400 font-medium">Classes</div>
        </div>
        <div class="stat-card bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800">
          <div class="text-3xl font-bold text-green-600 dark:text-green-400">${documentation.getAllMethods().length}</div>
          <div class="text-sm text-green-600 dark:text-green-400 font-medium">Methods</div>
        </div>
        <div class="stat-card bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800">
          <div class="text-3xl font-bold text-purple-600 dark:text-purple-400">${documentation.enums.length}</div>
          <div class="text-sm text-purple-600 dark:text-purple-400 font-medium">Enums</div>
        </div>
        <div class="stat-card bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800">
          <div class="text-3xl font-bold text-orange-600 dark:text-orange-400">${documentation.extensions.length}</div>
          <div class="text-sm text-orange-600 dark:text-orange-400 font-medium">Extensions</div>
        </div>
      </div>
    ''');

    // Categories
    for (final category in categorized.keys.toList()..sort()) {
      buffer.writeln('''
        <div class="mb-8">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">$category</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      ''');

      final subCategories = categorized[category]!;
      for (final subCategory in subCategories.keys.toList()..sort()) {
        final classes = subCategories[subCategory]!;

        buffer.writeln('''
          <div class="card">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">$subCategory</h3>
            <div class="space-y-1">
        ''');

        for (final cls in classes..sort((a, b) => a.name.compareTo(b.name))) {
          buffer.writeln('''
            <a href="${_sanitizeFileName(cls.name)}.html" class="class-link block">
              <span class="font-medium">${cls.name}</span>
              ${cls.description != null ? '<span class="text-sm text-gray-500 dark:text-gray-400 ml-2">${_truncate(cls.description!, 50)}</span>' : ''}
            </a>
          ''');
        }

        buffer.writeln('</div></div>');
      }

      buffer.writeln('</div></div>');
    }

    return buffer.toString();
  }

  String _generateClassContent(ClassDoc cls) {
    final buffer = StringBuffer();

    // Breadcrumb
    buffer.writeln('''
      <nav class="breadcrumb mb-6">
        <a href="index.html">Home</a>
        <span>/</span>
        ${cls.category != null ? '<span>${cls.category}</span>' : ''}
        ${cls.category != null ? '<span>/</span>' : ''}
        ${cls.subCategory != null ? '<span>${cls.subCategory}</span>' : ''}
        ${cls.subCategory != null ? '<span>/</span>' : ''}
        <span class="text-gray-900 dark:text-white font-semibold">${cls.name}</span>
      </nav>
    ''');

    // Header
    buffer.writeln('''
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-2">${cls.name}</h1>
        ${cls.isAbstract ? '<span class="badge badge-purple">abstract</span>' : ''}
        ${cls.categoryPath != 'Uncategorized' ? '<p class="text-gray-600 dark:text-gray-400 mt-2">${cls.categoryPath}</p>' : ''}
      </div>
    ''');

    // Description
    if (cls.description != null) {
      buffer.writeln('''
        <div class="card mb-6">
          <div class="prose dark:prose-invert max-w-none">
            ${md.markdownToHtml(cls.description!)}
          </div>
        </div>
      ''');
    }

    // Inheritance info
    if (cls.extendsClass != null ||
        cls.implements.isNotEmpty ||
        cls.mixins.isNotEmpty) {
      buffer.writeln('<div class="card mb-6">');

      if (cls.extendsClass != null) {
        buffer.writeln(
          '<div class="mb-2"><span class="font-semibold">Extends:</span> <code>${cls.extendsClass}</code></div>',
        );
      }

      if (cls.implements.isNotEmpty) {
        buffer.writeln(
          '<div class="mb-2"><span class="font-semibold">Implements:</span> <code>${cls.implements.join(', ')}</code></div>',
        );
      }

      if (cls.mixins.isNotEmpty) {
        buffer.writeln(
          '<div><span class="font-semibold">Mixins:</span> <code>${cls.mixins.join(', ')}</code></div>',
        );
      }

      buffer.writeln('</div>');
    }

    // Constructors
    if (cls.constructors.isNotEmpty) {
      buffer.writeln('''
        <div class="card mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Constructors</h2>
          <div class="space-y-2">
      ''');

      for (final constructor in cls.constructors) {
        buffer.writeln(
          '<div class="code-block"><code>$constructor()</code></div>',
        );
      }

      buffer.writeln('</div></div>');
    }

    // Properties
    if (cls.fields.isNotEmpty) {
      buffer.writeln('''
        <div class="card mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Properties</h2>
          <div class="table-container">
            <table class="doc-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Type</th>
                  <th>Description</th>
                </tr>
              </thead>
              <tbody>
      ''');

      for (final field in cls.fields) {
        final badges = <String>[];
        if (field.isStatic)
          badges.add('<span class="badge badge-blue">static</span>');
        if (field.isConst)
          badges.add('<span class="badge badge-purple">const</span>');
        if (field.isFinal)
          badges.add('<span class="badge badge-green">final</span>');

        buffer.writeln('''
          <tr>
            <td><code class="font-semibold">${field.name}</code> ${badges.join(' ')}</td>
            <td><code class="text-blue-600 dark:text-blue-400">${field.type}</code></td>
            <td>${field.description ?? '-'}</td>
          </tr>
        ''');
      }

      buffer.writeln('</tbody></table></div></div>');
    }

    // Methods
    if (cls.methods.isNotEmpty) {
      buffer.writeln('''
        <div class="card mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Methods</h2>
          <div class="space-y-6">
      ''');

      for (final method in cls.methods) {
        final badges = <String>[];
        if (method.isStatic)
          badges.add('<span class="badge badge-blue">static</span>');
        if (method.isAsync)
          badges.add('<span class="badge badge-orange">async</span>');

        buffer.writeln('''
          <div class="method-item">
            <div class="flex items-start gap-3">
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white">${method.name}</h3>
              ${badges.join(' ')}
            </div>
        ''');

        if (method.description != null) {
          buffer.writeln(
            '<div class="mt-2 text-gray-700 dark:text-gray-300">${md.markdownToHtml(method.description!)}</div>',
          );
        }

        buffer.writeln('''
            <div class="code-block mt-3">
              <button class="copy-btn" onclick="copyCode(this)">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
                </svg>
              </button>
              <pre><code class="language-dart">${_escapeHtml(method.signature)}</code></pre>
            </div>
        ''');

        if (method.parameters.isNotEmpty) {
          buffer.writeln(
            '<div class="mt-3"><span class="font-semibold">Parameters:</span><ul class="list-disc list-inside mt-1 space-y-1">',
          );
          for (final param in method.parameters) {
            buffer.writeln(
              '<li><code>${param.name}</code> (<code class="text-blue-600 dark:text-blue-400">${param.type}</code>) ${param.isRequired ? '<span class="badge badge-red">required</span>' : ''}</li>',
            );
          }
          buffer.writeln('</ul></div>');
        }

        buffer.writeln('</div>');
      }

      buffer.writeln('</div></div>');
    }

    // Source file
    buffer.writeln('''
      <div class="card">
        <div class="text-sm text-gray-500 dark:text-gray-400">
          <span class="font-semibold">Source:</span> 
          <code>${cls.filePath}</code>
        </div>
      </div>
    ''');

    return buffer.toString();
  }

  String _generateEnumContent(EnumDoc enumDoc) {
    final buffer = StringBuffer();

    buffer.writeln('''
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-2">${enumDoc.name}</h1>
        <span class="badge badge-purple">enum</span>
      </div>
    ''');

    if (enumDoc.description != null) {
      buffer.writeln('''
        <div class="card mb-6">
          <div class="prose dark:prose-invert max-w-none">
            ${md.markdownToHtml(enumDoc.description!)}
          </div>
        </div>
      ''');
    }

    buffer.writeln('''
      <div class="card">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Values</h2>
        <div class="space-y-2">
    ''');

    for (final value in enumDoc.values) {
      buffer.writeln('<div class="code-block"><code>$value</code></div>');
    }

    buffer.writeln('</div></div>');

    return buffer.toString();
  }

  String _generateExtensionContent(ExtensionDoc ext) {
    final buffer = StringBuffer();

    buffer.writeln('''
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-2">${ext.name}</h1>
        <span class="badge badge-orange">extension</span>
        <p class="text-gray-600 dark:text-gray-400 mt-2">on <code class="text-blue-600 dark:text-blue-400">${ext.onType}</code></p>
      </div>
    ''');

    if (ext.description != null) {
      buffer.writeln('''
        <div class="card mb-6">
          <div class="prose dark:prose-invert max-w-none">
            ${md.markdownToHtml(ext.description!)}
          </div>
        </div>
      ''');
    }

    if (ext.methods.isNotEmpty) {
      buffer.writeln('''
        <div class="card">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">Methods</h2>
          <div class="space-y-4">
      ''');

      for (final method in ext.methods) {
        buffer.writeln('''
          <div class="method-item">
            <h3 class="text-xl font-semibold text-gray-900 dark:text-white">${method.name}</h3>
            ${method.description != null ? '<div class="mt-2 text-gray-700 dark:text-gray-300">${method.description}</div>' : ''}
            <div class="code-block mt-3">
              <pre><code class="language-dart">${_escapeHtml(method.signature)}</code></pre>
            </div>
          </div>
        ''');
      }

      buffer.writeln('</div></div>');
    }

    return buffer.toString();
  }

  List<Map<String, dynamic>> _generateSearchData(Documentation documentation) {
    final data = <Map<String, dynamic>>[];

    for (final cls in documentation.classes) {
      data.add({
        'type': 'class',
        'name': cls.name,
        'description': cls.description ?? '',
        'category': cls.category ?? 'Uncategorized',
        'subCategory': cls.subCategory ?? '',
        'url': '${_sanitizeFileName(cls.name)}.html',
      });

      for (final method in cls.methods) {
        data.add({
          'type': 'method',
          'name': '${cls.name}.${method.name}',
          'description': method.description ?? '',
          'category': cls.category ?? 'Uncategorized',
          'url': '${_sanitizeFileName(cls.name)}.html',
        });
      }
    }

    for (final enumDoc in documentation.enums) {
      data.add({
        'type': 'enum',
        'name': enumDoc.name,
        'description': enumDoc.description ?? '',
        'category': enumDoc.category ?? 'Uncategorized',
        'url': '${_sanitizeFileName(enumDoc.name)}.html',
      });
    }

    for (final ext in documentation.extensions) {
      data.add({
        'type': 'extension',
        'name': ext.name,
        'description': ext.description ?? '',
        'url': '${_sanitizeFileName(ext.name)}.html',
      });
    }

    return data;
  }

  Future<void> _writeFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>]'), '_');
  }

  String _sanitizeId(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }
}
