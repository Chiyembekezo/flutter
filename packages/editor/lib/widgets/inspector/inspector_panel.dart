import 'package:flutter/material.dart';
import 'package:rive_editor/rive/managers/revision_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';

import 'package:rive_editor/selectable_item.dart';

import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_builders.dart';
import 'package:rive_editor/widgets/inspector/inspector_list_view.dart';
import 'package:rive_editor/widgets/inspector/revision_history_panel.dart';
import 'package:rive_widgets/listenable_builder.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    Key key,
  }) : super(key: key);

  @override
  _InspectorPanelState createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  // Ugh. We could call setState, with no changes too...
  void rebuild() => (context as Element).markNeedsBuild();

  final Set<ChangeNotifier> _changeNotifiers = {};

  void _removeListeners() {
    for (final changeNotifier in _changeNotifiers) {
      changeNotifier.removeListener(rebuild);
    }
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  Widget _revisionHistory(OpenFileContext file, Widget child) {
    return ValueListenableBuilder(
      valueListenable: file.revisionManager,
      builder: (context, RevisionManager revisionManager, _) {
        if (revisionManager == null) {
          return child;
        }
        return RevisionHistoryPanel(manager: revisionManager);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = ActiveFile.of(context);
    return FocusTraversalGroup(
      child: ColoredBox(
        color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
        child: _revisionHistory(
          file,
          ListenableBuilder<SelectionContext<SelectableItem>>(
            listenable: file.selection,
            builder: (context, selection, _) {
              List<InspectorBuilder> inspectorBuilders =
                  file.inspectorBuilders() ?? defaultInspectorBuilders;
              // Let the inspection set whittle down groupings and commonly
              // selected coreTypes for the inspector builders to use to
              // determine if there are things they can help inspect.
              var inspectionSet =
                  InspectionSet.fromSelection(file, selection.items);

              // Remove previous listeners, these listen to inspector builders
              // wanting to change the contents in the full inspection list
              // item. Basically any one of them can request a rebuild of the
              // inspection list.
              _removeListeners();

              // Expand the builders and interleave dividers.
              List<WidgetBuilder> builders = [];

              // Add the top padding
              builders.add(InspectorBuilder.padding);

              for (int i = 0, builderCount = inspectorBuilders.length;
                  i < builderCount;
                  i++) {
                var builder = inspectorBuilders[i];

                builder.clean();

                // Is the builder interested in the current inspection set?
                if (!builder.validate(inspectionSet)) {
                  continue;
                }

                // Check if the builder can re-expand on demand (useful for
                // InspectorGroups).
                if (builder is ChangeNotifier) {
                  var notifier = builder as ChangeNotifier;
                  notifier.addListener(rebuild);
                  _changeNotifiers.add(notifier);
                }

                var dividerBuilder = InspectorBuilder.divider;
                var expand = builder.expand(inspectionSet);
                if (expand != null && expand.isNotEmpty) {
                  builders.addAll(expand);
                  if (i != builderCount - 1) {
                    builders.add(dividerBuilder);
                  }
                }
              }
              if (builders.isNotEmpty) {
                // At this point we've built a list of builders (no real widgets
                // yet). That's to allow the ListView to build them on demand
                // depending on what's scrolled into view. We take care to make
                // list items the same height (or as similar as possible) in
                // order to gaurantee a smooth scrolling experience when
                // virtualizing lots of items. This is why group expansion works
                // by adding more items to the ListView instead of just creating
                // one large item in the ListView.
                return InspectorListView(
                  itemBuilder: (context, index) => builders[index](context),
                  itemCount: builders.length,
                );
              } else {
                // After all our work, no builders were available for this set.
                // Let the user know to select something useful.
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        child: Text(
                          'No Selection',
                          style: RiveTheme.of(context)
                              .textStyles
                              .inspectorWhiteLabel,
                        ),
                      ),
                      Container(height: 10),
                      Container(
                        child: Text(
                          'Select something to view its properties '
                          'and options.',
                          style: RiveTheme.of(context)
                              .textStyles
                              .inspectorPropertyLabel,
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
