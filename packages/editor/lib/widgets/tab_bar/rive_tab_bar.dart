import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'tab_decoration.dart';

/// Describes a Rive tab item.
class RiveTabItem {
  const RiveTabItem({
    this.name,
    this.icon,
    this.closeable = true,
  });
  final String name;
  final Widget icon;
  final bool closeable;
}

typedef TabSelectedCallback = void Function(RiveTabItem item);

class _TabBarItem extends StatefulWidget {
  final RiveTabItem tab;
  final bool isSelected;
  final TabSelectedCallback select, close;
  final bool invertLeft, invertRight;

  const _TabBarItem({
    Key key,
    this.tab,
    this.isSelected,
    this.select,
    this.close,
    this.invertLeft = false,
    this.invertRight = false,
  }) : super(key: key);

  @override
  _TabBarItemState createState() => _TabBarItemState();
}

class _TabBarItemState extends State<_TabBarItem> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.select?.call(widget.tab),
        child: Container(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          child: Row(
            children: [
              Text(
                widget.tab.name,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isSelected
                      ? RiveTheme.of(context).colors.tabTextSelected
                      : _hover
                          ? RiveTheme.of(context).colors.tabTextSelected
                          : RiveTheme.of(context).colors.tabText,
                ),
              ),
              if (widget.tab.closeable) const SizedBox(width: 10),
              if (widget.tab.closeable)
                GestureDetector(
                  onTap: widget.close == null
                      ? null
                      : () => widget.close(widget.tab),
                  child: const CloseIcon(),
                )
            ],
          ),
          decoration: widget.isSelected
              ? TabDecoration(
                  color: RiveTheme.of(context).colors.tabBackgroundSelected)
              : _hover
                  ? TabDecoration(
                      color: RiveTheme.of(context).colors.tabBackgroundHovered,
                      invertLeft: widget.invertLeft,
                      invertRight: widget.invertRight,
                    )
                  : null,
        ),
      ),
    );
  }
}

class _UserTabBarItem extends StatefulWidget {
  final RiveTabItem tab;
  final bool isSelected;
  final TabSelectedCallback select, close;
  final bool invertLeft, invertRight;

  const _UserTabBarItem({
    Key key,
    this.tab,
    this.isSelected,
    this.select,
    this.close,
    this.invertLeft = false,
    this.invertRight = false,
  }) : super(key: key);

  @override
  _UserTabBarItemState createState() => _UserTabBarItemState();
}

class _UserTabBarItemState extends State<_UserTabBarItem> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.select?.call(widget.tab),
        child: Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: [
              TintedIcon(
                  color: widget.isSelected
                      ? RiveTheme.of(context).colors.tabRiveTextSelected
                      : _hover
                          ? RiveTheme.of(context).colors.tabTextSelected
                          : RiveTheme.of(context).colors.tabRiveText,
                  icon: 'rive'),
              if (widget.tab.closeable) const SizedBox(width: 10),
              if (widget.tab.closeable)
                GestureDetector(
                  onTap: widget.close == null
                      ? null
                      : () => widget.close(widget.tab),
                  child: const CloseIcon(),
                )
            ],
          ),
          decoration: widget.isSelected
              ? TabDecoration(
                  color: RiveTheme.of(context).colors.tabRiveBackgroundSelected)
              : _hover
                  ? TabDecoration(
                      color: RiveTheme.of(context).colors.tabBackgroundHovered,
                      invertLeft: widget.invertLeft,
                      invertRight: widget.invertRight,
                    )
                  : null,
        ),
      ),
    );
  }
}

class _ChangeLogTabBarItem extends StatefulWidget {
  final RiveTabItem tab;
  final bool isSelected;
  final TabSelectedCallback select, close;
  final bool invertLeft, invertRight;

  const _ChangeLogTabBarItem({
    Key key,
    this.tab,
    this.isSelected,
    this.select,
    this.close,
    this.invertLeft = true,
    this.invertRight = false,
  }) : super(key: key);

  @override
  _ChangeLogTabBarItemState createState() => _ChangeLogTabBarItemState();
}

class _ChangeLogTabBarItemState extends State<_ChangeLogTabBarItem> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.select?.call(widget.tab),
        child: Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            children: [
              TintedIcon(
                  color: widget.isSelected
                      ? RiveTheme.of(context).colors.tabRiveTextSelected
                      : _hover
                          ? RiveTheme.of(context).colors.tabTextSelected
                          : RiveTheme.of(context).colors.tabRiveText,
                  icon: 'changelog'),
              if (widget.tab.closeable) const SizedBox(width: 10),
              if (widget.tab.closeable)
                GestureDetector(
                  onTap: widget.close == null
                      ? null
                      : () => widget.close(widget.tab),
                  child: const CloseIcon(),
                )
            ],
          ),
          decoration: widget.isSelected
              ? TabDecoration(
                  color: RiveTheme.of(context).colors.tabRiveBackgroundSelected)
              : _hover
                  ? TabDecoration(
                      color: RiveTheme.of(context).colors.tabBackgroundHovered,
                      invertLeft: widget.invertLeft,
                      invertRight: widget.invertRight,
                    )
                  : null,
        ),
      ),
    );
  }
}

class RiveTabBar extends StatelessWidget {
  final List<RiveTabItem> tabs;
  final RiveTabItem selected;
  final double offset;
  final TabSelectedCallback select, close;

  const RiveTabBar(
      {Key key,
      this.tabs,
      this.offset = 0,
      this.selected,
      this.select,
      this.close})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    // Work out the tabs to the left and right
    // of the selected
    var selectedIdx = -1;
    for (var i = 0; i < tabs.length; i++) {
      if (selected == tabs[i]) {
        selectedIdx = i;
      }
    }

    List<Widget> _buildTabItems() {
      final tabItems = <Widget>[];
      for (var i = 0; i < tabs.length; i++) {
        switch (i) {
          case 0: // user tab
            tabItems.add(_UserTabBarItem(
              tab: tabs[i],
              isSelected: selectedIdx == i,
              select: select,
              close: close,
            ));
            break;

          case 1: // changelog tab
            tabItems.add(_ChangeLogTabBarItem(
              tab: tabs[i],
              isSelected: selectedIdx == i,
              select: select,
              close: close,
            ));
            break;
          default:
            tabItems.add(_TabBarItem(
              tab: tabs[i],
              isSelected: selectedIdx == i,
              // Invert the left curve if next to selected
              invertLeft: selectedIdx == i - 1,
              select: select,
              close: close,
            ));
            break;
        }
      }
      return tabItems;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: offset),
        ..._buildTabItems(),
      ],
    );
  }
}
