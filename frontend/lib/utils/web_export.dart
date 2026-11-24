import 'dart:html' as html;

void openWebUrl(String url) {
  html.window.open(url, '_blank');
}

void downloadWebPdf(String url, String fileName) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..target = '_blank';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}
