import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/billing.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_choice.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/wizard_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// The first panel in the teams sign-up wizard
class TeamWizardPanelOne extends StatelessWidget {
  const TeamWizardPanelOne(this.sub, {Key key}) : super(key: key);
  final TeamSubscriptionPackage sub;

  @override
  Widget build(BuildContext context) {
    const double targetPadding = 30;
    const double subscriptionBorderThickness = 3;
    final colors = RiveTheme.of(context).colors;
    final textStyles = RiveTheme.of(context).textStyles;
    final options = [
      BillingFrequency.yearly,
      BillingFrequency.monthly,
    ];
    return SizedBox(
      width: 452,
      height: 364,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: targetPadding - subscriptionBorderThickness,
            vertical: targetPadding),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: subscriptionBorderThickness),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: WizardTextFormField(
                      onChanged: (name) => sub.name = name,
                      enabled: !sub.processing,
                      initialValue: sub.name,
                      fontSize: 16,
                      hintText: 'Team name',
                      errorText: sub.nameValidationError,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: SizedBox(
                      width: 71,
                      child: ComboBox<BillingFrequency>(
                        popupWidth: 100,
                        sizing: ComboSizing.sized,
                        underline: true,
                        underlineColor: colors.inputUnderline,
                        valueColor: textStyles.fileGreyTextLarge.color,
                        options: options,
                        value: sub.billing,
                        toLabel: (option) => describeEnum(option).capsFirst,
                        contentPadding: const EdgeInsets.only(bottom: 3),
                        change: (billing) => sub.billing = billing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: sub.nameValidationError == null
                  ? const EdgeInsets.only(top: 27, bottom: 24)
                  : const EdgeInsets.only(top: 5, bottom: 24),
              child: Row(
                children: <Widget>[
                  TeamSubscriptionChoiceWidget(
                      label: 'Team',
                      costLabel: '\$$basicMonthlyCost',
                      explanation:
                          'A space where you and your team can share files.',
                      onTap: () => sub.option = TeamsOption.basic,
                      borderThickness: subscriptionBorderThickness),
                  const SizedBox(width: 24),
                  TeamSubscriptionChoiceWidget(
                      label: 'Premium Team',
                      costLabel: '\$$premiumMonthlyCost',
                      explanation: '1 day support.',
                      onTap: () => sub.option = TeamsOption.premium,
                      borderThickness: subscriptionBorderThickness),
                ],
              ),
            ),
            RichText(
                text: TextSpan(
              children: [
                const TextSpan(
                    text: 'You\'ll only be billed for users as'
                        ' you add them. Read more about our '),
                TextSpan(
                    text: 'fair billing policy',
                    style: textStyles.tooltipHyperlink,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (await canLaunch(billingPolicyUrl)) {
                          await launch(billingPolicyUrl);
                        }
                      }),
                const TextSpan(text: '.'),
              ],
              style: textStyles.tooltipDisclaimer,
            )),
          ],
        ),
      ),
    );
  }
}
