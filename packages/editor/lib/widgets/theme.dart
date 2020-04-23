import 'dart:ui';
import 'package:flutter/widgets.dart';

import 'theme/theme_native.dart' if (dart.library.html) 'theme/theme_web.dart';

// General colors
const lightGrey = Color(0xFF8C8C8C);
const white = Color(0xFFFFFFFF);
const red = Color(0xFFFF5678);
const purple = Color(0xFFD041AB);

/// Colors used in the Rive Theme
/// Define them as getters and keep them const
class RiveColors {
  factory RiveColors() => _instance;
  const RiveColors._();
  static const RiveColors _instance = RiveColors._();

  // Tabs
  Color get tabText => lightGrey;
  Color get tabBackground => const Color(0xFF323232);
  Color get tabTextSelected => const Color(0xFFFDFDFD);
  Color get tabBackgroundSelected => const Color(0xFF3c3c3c);
  Color get tabBackgroundHovered => const Color(0xFF363636);

  Color get tabRiveText => lightGrey;
  Color get tabRiveBackground => const Color(0xFF323232);
  Color get tabRiveTextSelected => const Color(0xFF323232);
  Color get tabRiveBackgroundSelected => const Color(0xFFF1F1F1);
  Color get tabRiveSeparator => const Color(0xFF555555);

  // Toolbar
  Color get toolbarBackground => const Color(0xFF3c3c3c);
  Color get toolbarButton => lightGrey;
  Color get toolbarButtonSelected => const Color(0xFF57A5E0);
  Color get toolbarButtonHover => white;
  Color get toolbarButtonBackGroundHover => const Color(0xFF444444);
  Color get toolbarButtonBackGroundPressed => const Color(0xFF262626);

  // Popups
  Color get separator => const Color(0xFF262626);
  Color get separatorActive => const Color(0xFFAEAEAE);
  Color get popupIconSelected => const Color(0xFF57A5E0);
  Color get popupIcon => const Color(0xFF707070);
  Color get popupIconHover => white;

  // Stage
  Color get toolTip => const Color(0x7F000000);
  Color get toolTipText => white;
  Color get shapeBounds => const Color(0xFF000000);

  // Accents
  Color get accentBlue => const Color(0xFF57A5E0);
  Color get accentMagenta => const Color(0xFFFF5678);
  Color get accentDarkMagenta => const Color(0xFFD041AB);

  // Backgrounds
  Color get panelBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get panelBackgroundDarkGrey => const Color(0xFF323232);
  Color get stageBackground => const Color(0xFF1D1D1D);
  Color get popupBackground => const Color(0xFFF1F1F1);

  // Buttons
  Color get buttonLight => const Color(0xFFE3E3E3);
  Color get buttonLightHover => const Color(0xFFDEDEDE);
  Color get buttonLightText => const Color(0xFF666666);
  Color get buttonLightDisabled => const Color(0xFFF8F8F8);
  Color get buttonLightTextDisabled => const Color(0xFFD9D9D9);

  Color get iconButtonLightIcon => const Color(0xFF888888);
  Color get iconButtonLightDisabled => const Color(0xFFEBEBEB);
  Color get iconButtonLightTextDisabled => const Color(0xFFCECECE);
  Color get iconButtonLightIconDisabled => const Color(0xFFD7D7D7);

  Color get buttonDark => const Color(0xFF444444);
  Color get textButtonDark => const Color(0xFF333333);
  Color get buttonDarkText => white;
  Color get buttonDarkDisabled => const Color(0xFFCCCCCC);
  Color get buttonDarkTextHovered => white;
  Color get buttonDarkDisabledText => white;

  Color get buttonNoHover => const Color(0xFF707070);
  Color get buttonHover => white;

  // Cursors
  Color get cursorGreen => const Color(0xFF16E6B3);
  Color get cursorRed => const Color(0xFFFF929F);
  Color get cursoYellow => const Color(0xFFFFF1BE);
  Color get cursorBlue => const Color(0xFF57A5E0);

  Color get animateToggleButton => const Color(0xFF444444);
  Color get inactiveText => const Color(0xFF888888);
  Color get inactiveButtonText => const Color(0xFFB3B3B3);
  Color get activeText => white;

  // Files
  Color get fileBackgroundDarkGrey => const Color(0xFF666666);
  Color get fileBackgroundLightGrey => const Color(0xFFF1F1F1);
  Color get fileSelectedBlue => const Color(0xFF57A5E0);
  Color get fileLineGrey => const Color(0xFFD8D8D8);
  Color get fileTextLightGrey => lightGrey;
  Color get fileSelectedFolderIcon => white;
  Color get fileUnselectedFolderIcon => const Color(0xFFA9A9A9);
  Color get fileIconColor => const Color(0xFFA9A9A9);
  Color get fileBorder => const Color(0xFFD8D8D8);
  Color get fileSearchBorder => const Color(0xFFE3E3E3);
  Color get fileSearchIcon => const Color(0xFF999999);
  Color get filesTreeStroke => const Color(0xFFCCCCCC);

  // Common
  Color get commonLightGrey => const Color(0xFF888888);
  Color get commonDarkGrey => const Color(0xFF333333);
  Color get commonButtonColor => const Color(0x19000000);
  Color get commonButtonTextColor => commonLightGrey;
  Color get commonButtonTextColorDark => const Color(0xFF666666);
  Color get commonButtonInactiveGrey => const Color(0xFFE7E7E7);

  // Inspector
  Color get inspectorTextColor => const Color(0xFF8C8C8C);
  Color get inspectorSeparator => const Color(0xFF444444);

  // TextField
  Color get textSelection => lightGrey;
  Color get inputUnderline => const Color(0xFFCCCCCC);
  Color get input => const Color(0xFFBBBBBB);

  // Tree
  Color get darkTreeLines => const Color(0x33FFFFFF);

  // Hierarchy
  Color get editorTreeHover => const Color(0x20AAAAAA);
  Color get animationSelected => const Color(0x24888888);

  Color get shadow25 => const Color(0x44000000);

  Color get lightTreeLines => const Color(0x27666666);
  Color get selectedTreeLines => const Color(0xFF79B7E6);
  Color get toggleBackground => const Color(0xFF252525);
  Color get toggleInactiveBackground => const Color(0xFFF1F1F1);
  Color get toggleForeground => white;
  Color get toggleForegroundDisabled => const Color(0xFF444444);

  Color get treeHover => const Color(0x32AAAAAA);

  // Mode button
  Color get modeBackground => const Color(0xFF2F2F2F);
  Color get modeForeground => const Color(0xFF444444);

  // Aniation panel
  Color get animationPanelBackground => const Color(0xFF282828);
}

/// TextStyles used in the Rive Theme
/// Define them as getters and keep them const
class TextStyles {
  const TextStyles();

  // Default style
  TextStyle get basic =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  // Hierarchy panel
  TextStyle get hierarchyTabActive => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFAAAAAA), fontSize: 11);

  TextStyle get hierarchyTabInactive => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF656565), fontSize: 11);

  TextStyle get hierarchyTabHovered => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFF888888), fontSize: 11);

  // Inspector panel
  TextStyle get inspectorPropertyLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 13);

  TextStyle get inspectorPropertySubLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: lightGrey, fontSize: 11);

  TextStyle get inspectorPropertyValue => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFFE3E3E3), fontSize: 12.5);

  TextStyle get inspectorSectionHeader => const TextStyle(
      fontFamily: 'Roboto-Medium', fontSize: 11, color: lightGrey);

  TextStyle get inspectorButton =>
      const TextStyle(fontFamily: 'Roboto-Regular', fontSize: 13);

  TextStyle get inspectorWhiteLabel => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFC8C8C8), fontSize: 13);

  // Popup Menus
  TextStyle get popupHovered =>
      const TextStyle(fontFamily: 'Roboto-Light', color: white, fontSize: 13);

  TextStyle get popupText => const TextStyle(
      fontFamily: 'Roboto-Light', color: lightGrey, fontSize: 13);

  TextStyle get popupShortcutText => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFF666666), fontSize: 13);

  TextStyle get tooltipText => const TextStyle(
      fontFamily: 'Roboto-Light', color: Color(0xFFCCCCCC), fontSize: 13);

  TextStyle get tooltipDisclaimer => const TextStyle(
        fontFamily: 'Roboto-Light',
        color: Color(0xFF888888),
        fontSize: 13,
      );

  TextStyle get tooltipBold => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF333333),
      fontSize: 13,
      fontWeight: FontWeight.bold);

  TextStyle get tooltipHyperlink => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF333333),
      fontSize: 13,
      decoration: TextDecoration.underline);

  TextStyle get tooltipHyperlinkHovered => const TextStyle(
      fontFamily: 'Roboto-Light',
      color: Color(0xFF57A5E0),
      fontSize: 13,
      decoration: TextDecoration.underline);

  TextStyle get hyperLinkSubtext => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF888888),
      fontSize: 13,
      letterSpacing: 0,
      decoration: TextDecoration.underline);

  TextStyle get buttonTextStyle => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF888888),
        fontSize: 13,
      );

  TextStyle get loginText => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF888888),
      fontSize: 13,
      letterSpacing: 0);

  // Notifications
  TextStyle get notificationTitle => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF333333),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      );

  TextStyle get notificationText => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF666666),
        height: 1.6,
        fontSize: 13,
      );

  TextStyle get notificationHeader => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF888888),
        fontSize: 16,
      );

  TextStyle get notificationHeaderSelected => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF333333),
        fontSize: 16,
      );

  // Files
  TextStyle get fileBlueText => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF57A5E0),
        fontSize: 13,
      );
  TextStyle get fileGreyTextSmall => const TextStyle(
        fontFamily: 'Roboto-Regular',
        color: Color(0xFF333333),
        fontSize: 11,
        fontWeight: FontWeight.w300,
      );
  TextStyle get fileGreyTextLarge => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF333333),
      fontSize: 16,
      fontWeight: FontWeight.w400);
  TextStyle get fileLightGreyText => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF666666),
      fontSize: 13,
      fontWeight: FontWeight.w300);
  TextStyle get fileWhiteText => const TextStyle(
      fontFamily: 'Roboto-Medium',
      color: white,
      fontSize: 13,
      fontWeight: FontWeight.w300);

  TextStyle get fileSearchText => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF999999), fontSize: 13);

  // Common
  TextStyle get greyText => const TextStyle(
      fontFamily: 'Roboto-Medium', color: Color(0xFF333333), fontSize: 13);

  // Wizard TextField
  // Common
  TextStyle get textFieldInputHint => const TextStyle(
      fontFamily: 'Roboto-Regular', color: Color(0xFFBBBBBB), fontSize: 16);

  TextStyle get textFieldInputValidationError =>
      const TextStyle(fontFamily: 'Roboto-Medium', color: red, fontSize: 13);

  TextStyle get buttonUnderline => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: Color(0xFF333333),
      fontSize: 12,
      height: 1.6,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.underline);

  TextStyle get regularText => const TextStyle(
        fontFamily: 'Roboto-Regular',
        fontSize: 13,
        height: 1.15,
        fontWeight: FontWeight.normal,
      );

  // Mode button
  TextStyle get modeLabel => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFF888888),
        fontSize: 13,
      );
  TextStyle get modeLabelSelected => const TextStyle(
        fontFamily: 'Roboto-Medium',
        color: Color(0xFFFFFFFF),
        fontSize: 13,
      );

  // Tree
  TextStyle get treeDragItem => const TextStyle(
      fontFamily: 'Roboto-Regular',
      color: white,
      fontSize: 13,
      decoration: TextDecoration.none);
}

/// Gradients used in the Rive Theme
/// Define them as getters and keep them const
class Gradients {
  const Gradients();

  Gradient get magenta => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          red,
          purple,
        ],
      );

  Gradient get redPurpleBottomCenter => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          red,
          purple,
        ],
      );
}

/// Holds instances of various sub theme classes
/// This is used by the RiveTheme InheritedWidget
class RiveThemeData {
  factory RiveThemeData() {
    return _instance;
  }
  const RiveThemeData._();
  static const RiveThemeData _instance = RiveThemeData._();

  RiveColors get colors => RiveColors();
  Gradients get gradients => const Gradients();
  TextStyles get textStyles => const TextStyles();
  PlatformSpecific get platform => PlatformSpecific();
}
