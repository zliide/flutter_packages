// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'simulated_layout.dart';

void main() {
  testWidgets('Desktop breakpoints do not show on mobile device',
      (WidgetTester tester) async {
    // Pump a small layout on a mobile device. The small slot
    // should give the mobile slot layout, not the desktop layout.
    await tester.pumpWidget(SimulatedLayout.small.slot(tester));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('Breakpoints.smallMobile')), findsOneWidget);
    expect(find.byKey(const Key('Breakpoints.smallDesktop')), findsNothing);

    // Do the same with a medium layout on a mobile
    await tester.pumpWidget(SimulatedLayout.medium.slot(tester));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('Breakpoints.mediumMobile')), findsOneWidget);
    expect(find.byKey(const Key('Breakpoints.mediumDesktop')), findsNothing);

    // Large layout on mobile
    await tester.pumpWidget(SimulatedLayout.large.slot(tester));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('Breakpoints.largeMobile')), findsOneWidget);
    expect(find.byKey(const Key('Breakpoints.largeDesktop')), findsNothing);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('Mobile breakpoints do not show on desktop device',
      (WidgetTester tester) async {
    // Pump a small layout on a desktop device. The small slot
    // should give the mobile slot layout, not the desktop layout.
    await tester.pumpWidget(SimulatedLayout.small.slot(tester));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('Breakpoints.smallDesktop')), findsOneWidget);
    expect(find.byKey(const Key('Breakpoints.smallMobile')), findsNothing);

    // Do the same with a medium layout on a desktop
    await tester.pumpWidget(SimulatedLayout.medium.slot(tester));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('Breakpoints.mediumDesktop')), findsOneWidget);
    expect(find.byKey(const Key('Breakpoints.mediumMobile')), findsNothing);

    // Large layout on desktop
    await tester.pumpWidget(SimulatedLayout.large.slot(tester));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('Breakpoints.largeDesktop')), findsOneWidget);
    expect(find.byKey(const Key('Breakpoints.largeMobile')), findsNothing);
  }, variant: TargetPlatformVariant.desktop());
}
