import 'package:flutter/material.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/plaintext.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/graphql.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/makefile.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/nginx.dart';
import 'package:re_highlight/languages/objectivec.dart';
import 'package:re_highlight/languages/perl.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/powershell.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/r.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scala.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/languages/cmake.dart';
import 'package:re_highlight/languages/vim.dart';
import 'package:re_highlight/styles/all.dart';
import 'package:re_editor/re_editor.dart';

/// 文件扩展名 → 语言名
/// 注：html/htm 无原生高亮，用 xml 代替（结构相近）
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
  'c': 'c',
  'h': 'c',
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

/// 语言名 → Mode 映射
final _langModes = <String, Mode>{
  'plaintext': langPlaintext,
  'json': langJson,
  'yaml': langYaml,
  'xml': langXml,
  'ini': langIni,
  'bash': langBash,
  'python': langPython,
  'javascript': langJavascript,
  'typescript': langTypescript,
  'css': langCss,
  'scss': langScss,
  'markdown': langMarkdown,
  'sql': langSql,
  'dart': langDart,
  'java': langJava,
  'kotlin': langKotlin,
  'go': langGo,
  'rust': langRust,
  'php': langPhp,
  'ruby': langRuby,
  'c': langC,
  'cpp': langCpp,
  'csharp': langCsharp,
  'objectivec': langObjectivec,
  'swift': langSwift,
  'perl': langPerl,
  'r': langR,
  'scala': langScala,
  'powershell': langPowershell,
  'dockerfile': langDockerfile,
  'nginx': langNginx,
  'makefile': langMakefile,
  'cmake': langCmake,
  'vim': langVim,
  'graphql': langGraphql,
};

Mode _getMode(String name) => _langModes[name] ?? langPlaintext;

/// 根据文件扩展名获取语言 mode
Mode getModeByExtension(String ext) {
  final name = _extToLang[ext.toLowerCase()];
  return name != null ? _getMode(name) : langPlaintext;
}

/// 根据完整文件名获取语言 mode
Mode getModeByFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) {
    return langPlaintext;
  }
  return getModeByExtension(filename.substring(dot + 1));
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
  'c': 'C',
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
  'c', 'cpp', 'csharp', 'objectivec', 'swift', 'perl', 'r',
  'scala', 'powershell', 'dockerfile', 'nginx', 'makefile',
  'cmake', 'vim', 'graphql',
];

/// 主题样式
final _themeStyles = builtThemes['a11y-dark']!;

/// 构建 CodeHighlightTheme（单语言，用于编辑器）
CodeHighlightTheme buildSingleLanguageTheme(String langName) {
  final mode = _getMode(langName);
  return CodeHighlightTheme(
    languages: {langName: mode.themeMode},
    theme: _themeStyles,
  );
}

/// 全量主题（所有语言，用于预览自动检测）
final codeEditorTheme = CodeHighlightTheme(
  languages: {
    for (final name in supportedLanguages) name: _getMode(name).themeMode,
  },
  theme: _themeStyles,
);

/// 默认编辑器样式
final codeEditorStyle = CodeEditorStyle(
  fontSize: 14,
  codeTheme: codeEditorTheme,
);
