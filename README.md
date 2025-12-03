# 🚀 dart_doc_pilot

[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Banner](https://raw.githubusercontent.com/muhsindev4/dart_doc_pilot/main/img.png)](https://flutter.dev)


**A powerful, feature-rich Flutter project documentation generator with a beautiful UI and impressive CLI experience.**

dart_doc_pilot extracts comprehensive documentation from your Dart/Flutter projects and generates beautiful, searchable documentation in multiple formats.


---

## ✨ Features

### 📚 Comprehensive Documentation Extraction

- **Classes**: Full class documentation with inheritance, mixins, and interfaces
- **Methods**: All methods including getters, setters, async, static, and abstract
- **Fields**: Properties with type information, modifiers, and default values
- **Constructors**: Default, named, const, and factory constructors
- **Enums**: Enum declarations with value documentation
- **Extensions**: Extension methods and properties
- **Typedefs**: Type aliases with full context
- **Parameters**: Complete parameter information with types, defaults, and nullability

### 📝 Flutter Documentation Syntax Support

Full support for Flutter-style documentation tags:

```dart
/// {@category Widgets}
/// {@subCategory Buttons}
/// 
/// {@template button_example}
/// Example usage...
/// {@endtemplate}
/// 
/// {@macro button_example}
/// 
/// See also: [TextButton], [IconButton]
```

### 🎨 Rich Output Formats

- **HTML**: Beautiful, Material Design-inspired static website
- **Markdown**: Clean, readable documentation files
- **JSON**: Structured data for custom integrations

### 💎 Beautiful UI Features

- 🔍 **Live Search**: Instant search with suggestions
- 📂 **Category Navigation**: Organized by categories and subcategories
- 🎯 **Breadcrumb Navigation**: Easy navigation hierarchy
- 💅 **Syntax Highlighting**: Beautiful code blocks
- 📱 **Responsive Design**: Works on all screen sizes
- ✨ **Smooth Animations**: Polished user experience

### 🖥️ Impressive CLI Experience

- 🎨 **ASCII Banner**: Beautiful startup screen
- ⏳ **Loading Animations**: Spinners and progress bars
- 📊 **Statistics**: Detailed parsing and generation stats
- ⚡ **Fast Performance**: Optimized for large projects
- 🎭 **Colored Output**: Easy-to-read terminal output
- ✅ **Success/Error Icons**: Clear visual feedback

---

## 📦 Installation

### Global Installation

```bash
dart pub global activate dart_doc_pilot
```

### Project Dependency

```yaml
dev_dependencies:
  dart_doc_pilot: ^1.0.0
```

---

## 🚀 Quick Start

### 1. Scan Your Project

```bash
dart_doc_pilot scan ./my_flutter_app
```

Output:
```
╔═══════════════════════════════════════════════════════════════╗
║                     🚀 Flutter Documentation Generator 🚀      ║
╚═══════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Scanning Project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Directory: /path/to/my_flutter_app

🔎 Discovering Dart files... ✓
📖 Parsing documentation... ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Scan Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📦 Classes           42
  🔢 Enums             8
  🔧 Extensions        5
  📝 Typedefs          3
  ⚡ Methods           156
  💎 Fields            89
  🏗️  Constructors      67

⏱️  Completed in 234ms
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. Generate Documentation

#### HTML (Recommended)

```bash
dart_doc_pilot build ./my_flutter_app --format html --output docs
```

#### Markdown

```bash
dart_doc_pilot build ./my_flutter_app --format markdown --output md_docs
```

#### JSON

```bash
dart_doc_pilot build ./my_flutter_app --format json --output api_docs
```

### 3. Serve Documentation

```bash
dart_doc_pilot serve ./my_flutter_app --port 8080
```

Then open: `http://localhost:8080`

---

## 📖 Documentation Features

### Class Documentation

```dart
/// A custom button widget with various styles.
/// 
/// {@category Widgets}
/// {@subCategory Buttons}
/// 
/// The [CustomButton] provides a flexible button implementation.
/// 
/// Example:
/// ```dart
/// CustomButton(
///   text: 'Click Me',
///   onPressed: () => print('Pressed!'),
/// );
/// ```
class CustomButton {
  // ...
}
```

**Extracted Information:**
- ✅ Description
- ✅ Category & Subcategory
- ✅ Code examples
- ✅ Cross-references ([CustomButton])
- ✅ Inheritance tree
- ✅ All members (fields, methods, constructors)

### Method Documentation

```dart
/// Handles user login with email and password.
/// 
/// Returns a [User] object on success.
/// Throws [AuthException] on failure.
/// 
/// Example:
/// ```dart
/// final user = await login(
///   email: 'user@example.com',
///   password: 'password',
/// );
/// ```
Future<User> login({
  required String email,
  required String password,
}) async {
  // ...
}
```

**Extracted Information:**
- ✅ Description
- ✅ Return type (Future<User>)
- ✅ Parameters with types
- ✅ Required/optional status
- ✅ Async/await support
- ✅ Code examples
- ✅ Exception documentation

---

## 🎯 CLI Commands

### `scan`

Scan and analyze Dart files in a project.

```bash
dart_doc_pilot scan <directory>
```

**Options:**
- None

**Example:**
```bash
dart_doc_pilot scan ./my_app
```

### `build`

Generate documentation in specified format.

```bash
dart_doc_pilot build <directory> [options]
```

**Options:**
- `-f, --format` - Output format: `html`, `markdown`, `json` (default: `html`)
- `-o, --output` - Output directory (default: `docs`)

**Examples:**
```bash
# HTML documentation
dart_doc_pilot build ./my_app -f html -o docs

# Markdown documentation
dart_doc_pilot build ./my_app -f markdown -o md_docs

# JSON export
dart_doc_pilot build ./my_app -f json -o api.json
```

### `serve`

Start a local documentation server.

```bash
dart_doc_pilot serve <directory> [options]
```

**Options:**
- `-p, --port` - Server port (default: `8080`)

**Example:**
```bash
dart_doc_pilot serve ./my_app --port 3000
```

---

## 🏗️ Project Structure

```
dart_doc_pilot/
├── bin/
│   └── dart_doc_pilot.dart      # CLI entry point
├── lib/
│   ├── models.dart               # Data models
│   ├── parser.dart               # Documentation parser
│   ├── exporters.dart            # Output generators
│   ├── cli.dart                  # CLI interface
│   └── dart_doc_pilot.dart       # Library exports
├── example/
│   └── lib/
│       ├── custom_button.dart    # Example file
│       └── auth_service.dart     # Example file
├── pubspec.yaml
└── README.md
```

---

## 🎨 HTML Output Features

The generated HTML documentation includes:

### Navigation
- **Sidebar**: Organized by categories
- **Search Bar**: Live filtering
- **Breadcrumbs**: Clear hierarchy

### Content Display
- **Class Overview**: Description, inheritance, members
- **Method Signatures**: Syntax-highlighted code blocks
- **Parameter Lists**: Detailed parameter information
- **Code Examples**: Formatted with syntax highlighting

### Design
- **Material Design 3**: Modern, clean aesthetic
- **Responsive Layout**: Mobile-friendly
- **Dark/Light Support**: System preference detection
- **Smooth Animations**: Polished interactions

---

## 🔧 Advanced Usage

### Programmatic API

```dart
import 'package:dart_doc_pilot/dart_doc_pilot.dart';

void main() async {
  // Parse documentation
  final parser = DartDocParser(rootPath: './my_app');
  final documentation = await parser.parse();
  
  // Export to HTML
  final htmlExporter = HtmlExporter();
  await htmlExporter.export(documentation, './docs');
  
  // Export to JSON
  final jsonExporter = JsonExporter();
  await jsonExporter.export(documentation, './api.json');
  
  // Export to Markdown
  final mdExporter = MarkdownExporter();
  await mdExporter.export(documentation, './md_docs');
}
```

### Custom Exclusions

```dart
final parser = DartDocParser(
  rootPath: './my_app',
  excludePaths: ['build', '.dart_tool', 'test', 'generated'],
);
```

---

## 📊 Supported Documentation Tags

| Tag | Description | Example |
|-----|-------------|---------|
| `{@category X}` | Category classification | `{@category Widgets}` |
| `{@subCategory Y}` | Subcategory | `{@subCategory Buttons}` |
| `{@template name}` | Reusable template | `{@template example}...{@endtemplate}` |
| `{@macro name}` | Template reference | `{@macro example}` |
| `[ClassName]` | Cross-reference | `See [Button]` |
| Code blocks | Syntax highlighting | ` ```dart\n...\n``` ` |

---

## 🎯 Use Cases

- 📚 **Public Packages**: Generate beautiful API documentation
- 👥 **Team Projects**: Share consistent documentation
- 📖 **Open Source**: Professional documentation sites
- 🏢 **Enterprise**: Internal API documentation
- 🎓 **Education**: Teaching materials with examples

---

## 🔮 Roadmap

- [ ] Custom themes for HTML output
- [ ] PDF export support
- [ ] Dark mode toggle in UI
- [ ] Search result highlighting
- [ ] API documentation versioning
- [ ] Diagram generation (class hierarchy)
- [ ] Multi-language support
- [ ] IDE plugins (VS Code, IntelliJ)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 🌟 Acknowledgments

- Inspired by Flutter.dev documentation
- Built with the Dart analyzer package
- UI design influenced by Material Design 3
- CLI experience powered by mason_logger

---

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/dart_doc_pilot/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/dart_doc_pilot/discussions)
- 📧 **Email**: support@example.com

---

**Made with ❤️ by the Flutter community**
