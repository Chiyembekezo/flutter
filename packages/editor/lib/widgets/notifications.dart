import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';

import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/utils.dart';

import 'package:rive_api/apis/changelog.dart';
import 'package:rive_api/models/notification.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

enum PanelTypes { personal, announcements }

/// Panel showing all notifications including 'For You' and 'Announcements'
/// This is stateful as we track here which of the sections to display
class NotificationsPanel extends StatefulWidget {
  @override
  _NotificationsPanelState createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  var _displayPanel = PanelTypes.personal;

  void _changePanel(PanelTypes type) => setState(() => _displayPanel = type);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // theme.colors.panelBackgroundLightGrey,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 680,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 680,
                    maxWidth: 680,
                    child: _displayPanel == PanelTypes.personal
                        ? PersonalPanel(_changePanel)
                        : AnnouncementsPanel(_changePanel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the header containing 'For You' and 'Announcements'
class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader(this.type, this.onTap);
  final PanelTypes type;

  /// Callback to handle tapping the panel headers
  final Function(PanelTypes) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Underline(
      color: theme.colors.panelBackgroundLightGrey,
      thickness: 1,
      offset: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            child: Text(
              'For You',
              style: type == PanelTypes.personal
                  ? theme.textStyles.notificationHeaderSelected
                  : theme.textStyles.notificationHeader,
            ),
            onTap: () => onTap(PanelTypes.personal),
          ),
          const SizedBox(width: 30),
          GestureDetector(
            child: Text(
              'Announcements',
              style: type == PanelTypes.announcements
                  ? theme.textStyles.notificationHeaderSelected
                  : theme.textStyles.notificationHeader,
            ),
            onTap: () => onTap(PanelTypes.announcements),
          ),
        ],
      ),
    );
  }
}

/// Displayed when panel data is loading
class PanelLoading extends StatelessWidget {
  const PanelLoading(this.type, this.onTap);
  final PanelTypes type;

  /// Callback to handle tapping the panel headers
  final Function(PanelTypes) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 30),
        NotificationsHeader(type, onTap),
        const SizedBox(height: 50),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}

class PersonalPanel extends StatelessWidget {
  const PersonalPanel(this.onTap);
  final Function(PanelTypes) onTap;

  List<Widget> _buildNotificationsList(
      Iterable<RiveNotification> notifications, RiveThemeData theme) {
    if (notifications.isEmpty) {
      return [
        const SizedBox(height: 30),
        Center(
            child: Text(
          'No notifications for you ...',
          style: theme.textStyles.notificationHeader,
        )),
      ];
    } else {
      return [
        for (final notification in notifications) ...[
          const SizedBox(height: 30),
          NotificationCard(child: NotificationContent(notification))
        ],
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Column(
      children: [
        StreamBuilder<Iterable<RiveNotification>>(
          stream: NotificationProvider.of(context).notificationsStream,
          builder: (context, snapshot) => snapshot.hasData
              ? Expanded(
                  child: ListView(
                  children: [
                    const SizedBox(height: 30),
                    NotificationsHeader(PanelTypes.personal, onTap),
                    ..._buildNotificationsList(snapshot.data, theme)
                  ],
                ))
              : Expanded(child: PanelLoading(PanelTypes.personal, onTap)),
        ),
        StreamBuilder<HttpException>(
          stream: NotificationProvider.of(context).notificationErrorStream,
          builder: (context, snapshot) => snapshot.hasData
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                      'There has been an error accessing '
                      'your notifications: ${snapshot.data}',
                      style: theme.textStyles.textFieldInputValidationError),
                )
              : Container(),
        )
      ],
    );
  }
}

class AnnouncementsPanel extends StatefulWidget {
  const AnnouncementsPanel(this.onTap);
  final Function(PanelTypes) onTap;

  @override
  _AnnouncementsPanelState createState() => _AnnouncementsPanelState();
}

class _AnnouncementsPanelState extends State<AnnouncementsPanel> {
  Future<List<Changelog>> _changelogs;

  @override
  void initState() {
    _changelogs = fetchChangelogs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _changelogs,
        builder: (context, AsyncSnapshot<List<Changelog>> snapshot) =>
            snapshot.hasData
                ? ListView(children: [
                    const SizedBox(height: 30),
                    NotificationsHeader(PanelTypes.announcements, widget.onTap),
                    for (final changelog in snapshot.data) ...[
                      const SizedBox(height: 30),
                      NotificationCard(
                        child: ChangelogNotification(changelog),
                      )
                    ]
                  ])
                : PanelLoading(PanelTypes.announcements, widget.onTap),
      );
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({this.notification, this.child});
  final Notification notification;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.panelBackgroundLightGrey,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class ChangelogNotification extends StatelessWidget {
  const ChangelogNotification(this.changelog);
  final Changelog changelog;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Rive ${changelog.version} Changelog',
          style: theme.textStyles.notificationTitle,
        ),
        const SizedBox(height: 10),
        for (final item in changelog.items) ...[
          Text(
            item.title,
            style: theme.textStyles.notificationTitle,
          ),
          const SizedBox(height: 5),
          Text(
            item.description,
            style: theme.textStyles.notificationText,
          ),
          const SizedBox(height: 5),
        ]
      ],
    );
  }
}

class NotificationContent extends StatelessWidget {
  const NotificationContent(this.notification);
  final RiveNotification notification;

  @override
  Widget build(BuildContext context) {
    if (notification is RiveFollowNotification) {
      return FollowNotification(notification as RiveFollowNotification);
    } else if (notification is RiveTeamInviteNotification) {
      return TeamInviteNotification(notification as RiveTeamInviteNotification);
    } else {
      return UnknownNotification(notification);
    }
  }
}

class FollowNotification extends StatelessWidget {
  const FollowNotification(this.notification);
  final RiveFollowNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${notification.followerName} started following you.'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedIcon(
              icon: 'tool-create',
              color: theme.colors.commonButtonTextColor,
            ),
            const SizedBox(width: 10),
            Text(
              '${notification.dateTime.howLongAgo}',
              style: theme.textStyles.tooltipDisclaimer,
            ),
          ],
        )
      ],
    );
  }
}

class TeamInviteNotification extends StatelessWidget {
  const TeamInviteNotification(this.notification);
  final RiveTeamInviteNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final manager = NotificationProvider.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${notification.senderName} invited you to join'
                  ' the ${notification.teamName} team.'),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TintedIcon(
                    icon: 'tool-create',
                    color: theme.colors.commonButtonTextColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${notification.dateTime.howLongAgo}',
                    style: theme.textStyles.tooltipDisclaimer,
                  ),
                ],
              )
            ],
          ),
        ),
        SizedBox(
          width: 93,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FlatIconButton(
                label: 'Accept',
                color: theme.colors.commonDarkGrey,
                textColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.center,
                elevation: flatButtonIconElevation,
                onTap: () => manager.acceptTeamInvite.add(notification),
              ),
              const SizedBox(height: 10),
              FlatIconButton(
                label: 'Ignore',
                color: theme.colors.buttonLight,
                mainAxisAlignment: MainAxisAlignment.center,
                textColor: theme.colors.commonButtonTextColorDark,
                onTap: () => manager.declineTeamInvite.add(notification),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class UnknownNotification extends StatelessWidget {
  const UnknownNotification(this.notification);
  final RiveNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Unknown type of notification received.'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedIcon(
              icon: 'tool-create',
              color: theme.colors.commonButtonTextColor,
            ),
            const SizedBox(width: 10),
            Text(
              '${notification.dateTime.howLongAgo}',
              style: theme.textStyles.tooltipDisclaimer,
            ),
          ],
        )
      ],
    );
  }
}
