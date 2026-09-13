import 'package:flutter/material.dart';
import 'package:genrevibes_onboarding/genrevibes_onboarding.dart';

/// Real picker screenshots are deliberately not regenerated: button labels and
/// folder locations must remain recognizable. Zoom is available for small text.
class FolderScreenshotGuide extends StatefulWidget {
  const FolderScreenshotGuide({
    super.key,
    this.detailed = false,
    this.business = false,
  });
  final bool detailed;
  final bool business;

  @override
  State<FolderScreenshotGuide> createState() => _FolderScreenshotGuideState();
}

class _FolderScreenshotGuideState extends State<FolderScreenshotGuide> {
  int _index = 0;

  List<(String, String, String?)> get _steps =>
      widget.detailed
          ? [
            ('Tap Android', '', 'storage'),
            ('Tap media', '', 'android'),
            (
              'Tap ${widget.business ? 'com.whatsapp.w4b' : 'com.whatsapp'}',
              '',
              'packages',
            ),
            (
              'Tap ${widget.business ? 'WhatsApp Business' : 'WhatsApp'}',
              '',
              'package',
            ),
            ('Tap Media', '', 'whatsapp'),
            ('Tap ⋮ → Show hidden files', '', 'hidden'),
            ('Tap .Statuses', '', 'statuses'),
            ('Tap Use this folder', 'Then tap Allow.', null),
          ]
          : [
            ('Tap Android', '', 'storage'),
            ('Tap media', '', 'android'),
            ('Tap Use this folder', 'Then tap Allow.', null),
          ];

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final (title, description, asset) = steps[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Picture ${_index + 1} of ${steps.length}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (description.isNotEmpty)
          Text(description, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (asset != null)
          Semantics(
            button: true,
            label: 'Enlarge example: $title',
            child: InkWell(
              onTap:
                  () => showDialog<void>(
                    context: context,
                    builder:
                        (context) => Dialog.fullscreen(
                          child: Scaffold(
                            appBar: AppBar(
                              title: const Text('Example Android screen'),
                            ),
                            body: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/folder_guide/$asset.jpg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ),
              child: SizedBox(
                height: 350,
                child: Image.asset(
                  'assets/images/folder_guide/$asset.jpg',
                  fit: BoxFit.contain,
                  semanticLabel: title,
                ),
              ),
            ),
          )
        else
          FolderAccessPreview(
            folderName: widget.detailed ? '.Statuses' : 'media',
            caption: 'Example',
          ),
        if (asset != null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Tap image to zoom', textAlign: TextAlign.center),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _index == 0 ? null : () => setState(() => _index--),
              child: const Text('Previous'),
            ),
            TextButton(
              onPressed:
                  _index == steps.length - 1
                      ? null
                      : () => setState(() => _index++),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
