import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/cmake.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/dockerfile.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/graphql.dart';
import 'package:highlight/languages/ini.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/makefile.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/nginx.dart';
import 'package:highlight/languages/objectivec.dart';
import 'package:highlight/languages/perl.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/plaintext.dart';
import 'package:highlight/languages/powershell.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/r.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/scala.dart';
import 'package:highlight/languages/scss.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/vim.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';

/// 文件扩展名 → highlight 语言名
/// 注：highlight 包无单独 C 语言，.c/.h 使用 cpp 高亮（C++ 高亮基本覆盖 C 语法）
const _extToLang = <String, String>{
  'txt': 'plaintext',
  'json': 'json',
  'jsonc': 'json',
  'yaml': 'yaml',
  'yml': 'yaml',
  'xml': 'xml',
  'svg': 'xml',
  'html': 'xml',
  'htm': 'xml',
  'ini': 'ini',
  'conf': 'ini',
  'cfg': 'ini',
  'properties': 'ini',
  'sh': 'bash',
  'bash': 'bash',
  'zsh': 'bash',
  'shell': 'bash',
  'py': 'python',
  'pyw': 'python',
  'js': 'javascript',
  'jsx': 'javascript',
  'mjs': 'javascript',
  'ts': 'typescript',
  'tsx': 'typescript',
  'css': 'css',
  'scss': 'scss',
  'sass': 'scss',
  'less': 'scss',
  'md': 'markdown',
  'mdx': 'markdown',
  'sql': 'sql',
  'dart': 'dart',
  'java': 'java',
  'kt': 'kotlin',
  'kts': 'kotlin',
  'go': 'go',
  'rs': 'rust',
  'php': 'php',
  'rb': 'ruby',
  'c': 'cpp',
  'h': 'cpp',
  'cpp': 'cpp',
  'cc': 'cpp',
  'cxx': 'cpp',
  'hpp': 'cpp',
  'hxx': 'cpp',
  'cs': 'csharp',
  'm': 'objectivec',
  'mm': 'objectivec',
  'swift': 'swift',
  'pl': 'perl',
  'pm': 'perl',
  'r': 'r',
  'scala': 'scala',
  'ps1': 'powershell',
  'psm1': 'powershell',
  'dockerfile': 'dockerfile',
  'nginx': 'nginx',
  'htaccess': 'ini',
  'makefile': 'makefile',
  'cmake': 'cmake',
  'vim': 'vim',
  'toml': 'ini',
  'graphql': 'graphql',
  'gql': 'graphql',
};

/// 语言名 → Mode 映射（highlight 包）
final _langModes = <String, Mode>{
  'plaintext': plaintext,
  'json': json,
  'yaml': yaml,
  'xml': xml,
  'ini': ini,
  'bash': bash,
  'python': python,
  'javascript': javascript,
  'typescript': typescript,
  'css': css,
  'scss': scss,
  'markdown': markdown,
  'sql': sql,
  'dart': dart,
  'java': java,
  'kotlin': kotlin,
  'go': go,
  'rust': rust,
  'php': php,
  'ruby': ruby,
  'cpp': cpp,
  'csharp': cs,
  'objectivec': objectivec,
  'swift': swift,
  'perl': perl,
  'r': r,
  'scala': scala,
  'powershell': powershell,
  'dockerfile': dockerfile,
  'nginx': nginx,
  'makefile': makefile,
  'cmake': cmake,
  'vim': vim,
  'graphql': graphql,
};

Mode _getMode(String name) => _langModes[name] ?? plaintext;

/// 根据文件扩展名获取语言 Mode
Mode getModeByExtension(String ext) {
  final name = _extToLang[ext.toLowerCase()];
  return name != null ? _getMode(name) : plaintext;
}

/// 根据完整文件名获取语言 Mode
Mode getModeByFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) {
    return plaintext;
  }
  return getModeByExtension(filename.substring(dot + 1));
}

/// 根据完整文件名获取语言名称字符串（用于显示）
String getLanguageNameByFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) {
    return 'plaintext';
  }
  return _extToLang[filename.substring(dot + 1).toLowerCase()] ?? 'plaintext';
}

/// 语言显示名
const _displayNames = <String, String>{
  'plaintext': 'Plain Text',
  'json': 'JSON',
  'yaml': 'YAML',
  'xml': 'XML / HTML',
  'ini': 'INI / Properties',
  'bash': 'Shell',
  'python': 'Python',
  'javascript': 'JavaScript',
  'typescript': 'TypeScript',
  'css': 'CSS',
  'scss': 'SCSS',
  'markdown': 'Markdown',
  'sql': 'SQL',
  'dart': 'Dart',
  'java': 'Java',
  'kotlin': 'Kotlin',
  'go': 'Go',
  'rust': 'Rust',
  'php': 'PHP',
  'ruby': 'Ruby',
  'cpp': 'C++',
  'csharp': 'C#',
  'objectivec': 'Objective-C',
  'swift': 'Swift',
  'perl': 'Perl',
  'r': 'R',
  'scala': 'Scala',
  'powershell': 'PowerShell',
  'dockerfile': 'Dockerfile',
  'nginx': 'Nginx',
  'makefile': 'Makefile',
  'cmake': 'CMake',
  'vim': 'Vim',
  'graphql': 'GraphQL',
};

String getLanguageDisplayName(String langName) {
  return _displayNames[langName] ?? langName;
}

/// 支持的语言名列表
const supportedLanguages = [
  'plaintext', 'json', 'yaml', 'xml', 'ini', 'bash', 'python',
  'javascript', 'typescript', 'css', 'scss', 'markdown', 'sql',
  'dart', 'java', 'kotlin', 'go', 'rust', 'php', 'ruby',
  'cpp', 'csharp', 'objectivec', 'swift', 'perl', 'r',
  'scala', 'powershell', 'dockerfile', 'nginx', 'makefile',
  'cmake', 'vim', 'graphql',
];

/// CodeThemeData（flutter_code_editor 使用）
final codeEditorTheme = CodeThemeData(styles: a11yDarkTheme);
