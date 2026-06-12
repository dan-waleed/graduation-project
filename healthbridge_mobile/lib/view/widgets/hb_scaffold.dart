import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/view/theme/app_theme.dart';
import 'package:healthbridge_mobile/view/widgets/hb_bottom_nav.dart';
import 'package:healthbridge_mobile/view/widgets/hb_university_brand.dart';

class HbScaffold extends StatelessWidget {
  const HbScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final effectiveLeading =
        leading ??
        (canPop
            ? BackButton(onPressed: () => Navigator.maybePop(context))
            : null);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: effectiveLeading,
        title: HbAppBarTitle(title: title),
        actions: actions,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.background, AppTheme.surfaceAlt],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: body,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar ?? const HbBottomNav(),
    );
  }
}
