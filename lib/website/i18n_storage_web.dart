// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const String _storageKey = 'ghote_lang';

String? loadSaved() {
  return html.window.localStorage[_storageKey];
}

void save(String value) {
  html.window.localStorage[_storageKey] = value;
}

String? browserLang() {
  return html.window.navigator.language;
}

