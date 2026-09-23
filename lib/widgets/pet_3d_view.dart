// Web-only widget — direct <model-viewer> via HtmlElementView.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

const _kViewType = 'pet-model-viewer';

// Static reference so we can update the element's CSS from outside.
html.HtmlElement? _modelEl;
bool _registered = false;

/// Call when the pet enters conversation mode (bouncing heart effect).
void setPetConversationMode(bool active) {
  final el = _modelEl;
  if (el == null) return;
  if (active) {
    el.style.animation = 'petBob 1.8s ease-in-out infinite';
    el.style.opacity = '1';
  } else {
    el.style.animation = 'petPulse 4s ease-in-out infinite';
    el.style.opacity = '0.75';
  }
}

class Pet3DView extends StatelessWidget {
  final String glbUrl;
  final bool conversationMode;

  const Pet3DView({super.key, required this.glbUrl, this.conversationMode = false});

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      _registered = true;
      ui_web.platformViewRegistry.registerViewFactory(_kViewType, (int viewId) {
        final el = html.Element.tag('model-viewer') as html.HtmlElement;
        el.setAttribute('src', glbUrl);
        el.setAttribute('auto-play', '');
        // No auto-rotate — face forward
        el.setAttribute('camera-orbit', '0deg 75deg 90%');
        el.setAttribute('min-camera-orbit', 'auto auto auto');
        el.setAttribute('max-camera-orbit', 'auto auto auto');
        el.setAttribute('shadow-intensity', '0');
        el.setAttribute('exposure', '1.2');
        el.setAttribute('camera-controls', 'false');
        el.style.width = '100%';
        el.style.height = '100%';
        el.style.background = 'transparent';
        el.style.animation = conversationMode
            ? 'petBob 1.8s ease-in-out infinite'
            : 'petPulse 4s ease-in-out infinite';
        el.style.opacity = conversationMode ? '1' : '0.75';
        _modelEl = el;
        return el;
      });
    } else {
      // Update animation without re-registering
      setPetConversationMode(conversationMode);
    }
    return const HtmlElementView(viewType: _kViewType);
  }
}
