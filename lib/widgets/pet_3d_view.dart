// Web-only widget — creates a <model-viewer> element directly via HtmlElementView.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _registered = false;

class Pet3DView extends StatelessWidget {
  final String glbUrl;

  const Pet3DView({super.key, required this.glbUrl});

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      _registered = true;
      ui_web.platformViewRegistry.registerViewFactory(
        'pet-model-viewer',
        (int viewId) {
          final el = html.Element.tag('model-viewer') as html.HtmlElement;
          el.setAttribute('src', glbUrl);
          el.setAttribute('auto-play', '');
          el.setAttribute('auto-rotate', '');
          el.setAttribute('auto-rotate-delay', '0');
          el.setAttribute('rotation-per-second', '20deg');
          el.setAttribute('camera-orbit', '0deg 80deg auto');
          el.setAttribute('shadow-intensity', '0');
          el.setAttribute('exposure', '1');
          el.style.width = '100%';
          el.style.height = '100%';
          el.style.background = 'transparent';
          return el;
        },
      );
    }
    return const HtmlElementView(viewType: 'pet-model-viewer');
  }
}
