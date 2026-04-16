import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// 预览页工具栏：只有复制
class PreviewToolbarController implements SelectionToolbarController {
  const PreviewToolbarController();

  @override
  void hide(BuildContext context) {}

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromSize(
        anchors.primaryAnchor & const Size(150, double.infinity),
        MediaQuery.of(context).size,
      ),
      items: [
        PopupMenuItem<void>(
          onTap: () => controller.copy(),
          child: const Text('复制'),
        ),
      ],
    );
  }
}

/// 编辑器工具栏：剪切/复制/粘贴
class EditorToolbarController implements SelectionToolbarController {
  const EditorToolbarController();

  @override
  void hide(BuildContext context) {}

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromSize(
        anchors.primaryAnchor & const Size(150, double.infinity),
        MediaQuery.of(context).size,
      ),
      items: [
        PopupMenuItem<void>(
          onTap: () => controller.cut(),
          child: const Text('剪切'),
        ),
        PopupMenuItem<void>(
          onTap: () => controller.copy(),
          child: const Text('复制'),
        ),
        PopupMenuItem<void>(
          onTap: () => controller.paste(),
          child: const Text('粘贴'),
        ),
      ],
    );
  }
}
