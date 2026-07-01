import 'package:flutter/widgets.dart';

import '../viewmodels/fotogest_view_model.dart';

class AppScope extends InheritedNotifier<FotogestViewModel> {
  const AppScope({
    super.key,
    required FotogestViewModel viewModel,
    required super.child,
  }) : super(notifier: viewModel);

  static FotogestViewModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
