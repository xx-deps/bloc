// ignore_for_file: prefer_file_naming_conventions
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MyThemeApp extends StatefulWidget {
  const MyThemeApp({
    required Cubit<ThemeData> themeCubit,
    required void Function() onBuild,
    Key? key,
  })  : _themeCubit = themeCubit,
        _onBuild = onBuild,
        super(key: key);

  final Cubit<ThemeData> _themeCubit;
  final void Function() _onBuild;

  @override
  State<MyThemeApp> createState() => MyThemeAppState();
}

class MyThemeAppState extends State<MyThemeApp> {
  MyThemeAppState();

  @override
  void initState() {
    super.initState();
    _themeCubit = widget._themeCubit;
    _onBuild = widget._onBuild;
  }

  late Cubit<ThemeData> _themeCubit;
  late final void Function() _onBuild;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Cubit<ThemeData>, ThemeData>(
      bloc: _themeCubit,
      builder: (context, theme) {
        _onBuild();
        return MaterialApp(
          key: const Key('material_app'),
          theme: theme,
          home: Column(
            children: [
              ElevatedButton(
                key: const Key('raised_button_1'),
                child: const SizedBox(),
                onPressed: () {
                  setState(() => _themeCubit = DarkThemeCubit());
                },
              ),
              ElevatedButton(
                key: const Key('raised_button_2'),
                child: const SizedBox(),
                onPressed: () {
                  // ignore: no_self_assignments
                  setState(() => _themeCubit = _themeCubit);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(ThemeData.light());

  void setDarkTheme() => emit(ThemeData.dark());
  void setLightTheme() => emit(ThemeData.light());
}

class DarkThemeCubit extends Cubit<ThemeData> {
  DarkThemeCubit() : super(ThemeData.dark());

  void setLightTheme() => emit(ThemeData.light());
}

class MyCounterApp extends StatefulWidget {
  const MyCounterApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MyCounterAppState();
}

class MyCounterAppState extends State<MyCounterApp> {
  final CounterCubit _cubit = CounterCubit();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: const Key('myCounterApp'),
        body: Column(
          children: <Widget>[
            BlocBuilder<CounterCubit, int>(
              bloc: _cubit,
              buildWhen: (previousState, state) {
                return (previousState + state) % 3 == 0;
              },
              builder: (context, count) {
                return Text(
                  '$count',
                  key: const Key('myCounterAppTextCondition'),
                );
              },
            ),
            BlocBuilder<CounterCubit, int>(
              bloc: _cubit,
              builder: (context, count) {
                return Text(
                  '$count',
                  key: const Key('myCounterAppText'),
                );
              },
            ),
            ElevatedButton(
              key: const Key('myCounterAppIncrementButton'),
              onPressed: _cubit.increment,
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterCubit extends Cubit<int> {
  CounterCubit({int seed = 0}) : super(seed);

  void increment() => emit(state + 1);
}

class EqualCounterCubit extends Cubit<int> {
  EqualCounterCubit({int seed = 0}) : super(seed);

  void increment() => emit(state + 1);

  @override
  // 故意让不同实例在 `==` 判断时也算相等，
  // 用来验证 bloc 切换应该基于实例身份，而不是基于 `==`。
  bool operator ==(Object other) => other is EqualCounterCubit;

  @override
  int get hashCode => runtimeType.hashCode;
}

void main() {
  group('BlocBuilder', () {
    testWidgets('passes initial state to widget', (tester) async {
      final themeCubit = ThemeCubit();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubit, onBuild: () => numBuilds++),
      );

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);
    });

    testWidgets('receives events and sends state updates to widget',
        (tester) async {
      final themeCubit = ThemeCubit();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubit, onBuild: () => numBuilds++),
      );

      themeCubit.setDarkTheme();

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets(
        'infers the cubit from the context if the cubit is not provided',
        (tester) async {
      final themeCubit = ThemeCubit();
      var numBuilds = 0;
      await tester.pumpWidget(
        BlocProvider.value(
          value: themeCubit,
          child: BlocBuilder<ThemeCubit, ThemeData>(
            builder: (context, theme) {
              numBuilds++;
              return MaterialApp(
                key: const Key('material_app'),
                theme: theme,
                home: const SizedBox(),
              );
            },
          ),
        ),
      );

      themeCubit.setDarkTheme();

      await tester.pumpAndSettle();

      var materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeCubit.setLightTheme();

      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 3);
    });

    testWidgets('updates cubit and performs new lookup when widget is updated',
        (tester) async {
      final themeCubit = ThemeCubit();
      var numBuilds = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => BlocProvider.value(
            value: themeCubit,
            child: BlocBuilder<ThemeCubit, ThemeData>(
              builder: (context, theme) {
                numBuilds++;
                return MaterialApp(
                  key: const Key('material_app'),
                  theme: theme,
                  home: ElevatedButton(
                    child: const SizedBox(),
                    onPressed: () => setState(() {}),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 2);
    });

    testWidgets(
        'updates when the cubit is changed at runtime to a different cubit and '
        'unsubscribes from old cubit', (tester) async {
      final themeCubit = ThemeCubit();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubit, onBuild: () => numBuilds++),
      );

      await tester.pumpAndSettle();

      var materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 1);

      await tester.tap(find.byKey(const Key('raised_button_1')));
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeCubit.setLightTheme();
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);
    });

    testWidgets(
        'does not update when the cubit is changed at runtime to same cubit '
        'and stays subscribed to current cubit', (tester) async {
      final themeCubit = DarkThemeCubit();
      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubit, onBuild: () => numBuilds++),
      );

      await tester.pumpAndSettle();

      var materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);

      await tester.tap(find.byKey(const Key('raised_button_2')));
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 2);

      themeCubit.setLightTheme();
      await tester.pumpAndSettle();

      materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.light());
      expect(numBuilds, 3);
    });

    testWidgets('shows latest state instead of initial state', (tester) async {
      final themeCubit = ThemeCubit()..setDarkTheme();
      await tester.pumpAndSettle();

      var numBuilds = 0;
      await tester.pumpWidget(
        MyThemeApp(themeCubit: themeCubit, onBuild: () => numBuilds++),
      );

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('material_app')),
      );

      expect(materialApp.theme, ThemeData.dark());
      expect(numBuilds, 1);
    });

    testWidgets('with buildWhen only rebuilds when buildWhen evaluates to true',
        (tester) async {
      await tester.pumpWidget(const MyCounterApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('myCounterApp')), findsOneWidget);

      final incrementButtonFinder =
          find.byKey(const Key('myCounterAppIncrementButton'));
      expect(incrementButtonFinder, findsOneWidget);

      final counterText1 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText1.data, '0');

      final conditionalCounterText1 = tester
          .widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText1.data, '0');

      await tester.tap(incrementButtonFinder);
      await tester.pumpAndSettle();

      final counterText2 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText2.data, '1');

      final conditionalCounterText2 = tester
          .widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText2.data, '0');

      await tester.tap(incrementButtonFinder);
      await tester.pumpAndSettle();

      final counterText3 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText3.data, '2');

      final conditionalCounterText3 = tester
          .widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText3.data, '2');

      await tester.tap(incrementButtonFinder);
      await tester.pumpAndSettle();

      final counterText4 =
          tester.widget<Text>(find.byKey(const Key('myCounterAppText')));
      expect(counterText4.data, '3');

      final conditionalCounterText4 = tester
          .widget<Text>(find.byKey(const Key('myCounterAppTextCondition')));
      expect(conditionalCounterText4.data, '2');
    });

    testWidgets('calls buildWhen and builder with correct state',
        (tester) async {
      final buildWhenPreviousState = <int>[];
      final buildWhenCurrentState = <int>[];
      final states = <int>[];
      final counterCubit = CounterCubit();
      await tester.pumpWidget(
        BlocBuilder<CounterCubit, int>(
          bloc: counterCubit,
          buildWhen: (previous, state) {
            if (state.isEven) {
              buildWhenPreviousState.add(previous);
              buildWhenCurrentState.add(state);
              return true;
            }
            return false;
          },
          builder: (_, state) {
            states.add(state);
            return const SizedBox();
          },
        ),
      );
      await tester.pump();
      counterCubit
        ..increment()
        ..increment()
        ..increment();
      await tester.pumpAndSettle();

      expect(states, [0, 2]);
      expect(buildWhenPreviousState, [1]);
      expect(buildWhenCurrentState, [2]);
    });

    testWidgets(
        'does not rebuild with latest state when '
        'buildWhen is false and widget is updated', (tester) async {
      const key = Key('__target__');
      final states = <int>[];
      final counterCubit = CounterCubit();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) => BlocBuilder<CounterCubit, int>(
              bloc: counterCubit,
              buildWhen: (previous, state) => state.isEven,
              builder: (_, state) {
                states.add(state);
                return ElevatedButton(
                  key: key,
                  child: const SizedBox(),
                  onPressed: () => setState(() {}),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      counterCubit
        ..increment()
        ..increment()
        ..increment();
      await tester.pumpAndSettle();
      expect(states, [0, 2]);

      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(states, [0, 2, 2]);
    });

    testWidgets('rebuilds when provided bloc is changed', (tester) async {
      final firstCounterCubit = CounterCubit();
      final secondCounterCubit = CounterCubit(seed: 100);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlocProvider.value(
            value: firstCounterCubit,
            child: BlocBuilder<CounterCubit, int>(
              builder: (context, state) => Text('Count $state'),
            ),
          ),
        ),
      );

      expect(find.text('Count 0'), findsOneWidget);

      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
      expect(find.text('Count 0'), findsNothing);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BlocProvider.value(
            value: secondCounterCubit,
            child: BlocBuilder<CounterCubit, int>(
              builder: (context, state) => Text('Count $state'),
            ),
          ),
        ),
      );

      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 1'), findsNothing);

      secondCounterCubit.increment();
      await tester.pumpAndSettle();

      expect(find.text('Count 101'), findsOneWidget);
    });

    testWidgets(
        'switches explicit bloc instances even when the blocs are equal',
        (tester) async {
      // 创建两个不同的 bloc 实例。
      // 第二个实例从 100 开始，方便观察 BlocBuilder 是否真的切换过去了。
      final firstCounterCubit = EqualCounterCubit();
      final secondCounterCubit = EqualCounterCubit(seed: 100);

      // 当前通过 `bloc:` 参数传给 BlocBuilder 的实例。
      // 后面会修改这个变量，模拟 bloc 切换。
      var currentCubit = firstCounterCubit;

      // 用 StatefulBuilder 拿到一个局部 setState，
      // 这样测试里就可以主动重建 widget，并切换到另一个 bloc 实例。
      late StateSetter setState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, localSetState) {
              setState = localSetState;
              return BlocBuilder<EqualCounterCubit, int>(
                // 显式把当前要测试的 bloc 传给 BlocBuilder。
                bloc: currentCubit,
                builder: (context, state) => Text('Count $state'),
              );
            },
          ),
        ),
      );

      // 初次渲染时，页面应该显示第一个 bloc 的初始 state。
      expect(find.text('Count 0'), findsOneWidget);

      // 让第一个 bloc 发出新状态，确认 UI 会跟着它刷新。
      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);

      // 重建 BlocBuilder，并把 bloc 切换成第二个实例。
      setState(() => currentCubit = secondCounterCubit);
      await tester.pumpAndSettle();

      // 切换后，UI 应该立刻显示第二个 bloc 当前的 state，
      // 而不是继续停留在旧 bloc 的 state。
      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 1'), findsNothing);

      // 切换完成后，再让旧 bloc 发状态。
      // 如果 BlocBuilder 还错误地订阅着旧 bloc，页面就会变成 Count 2。
      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 2'), findsNothing);

      // 再让新 bloc 发状态，确认新的订阅已经生效。
      secondCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 101'), findsOneWidget);

      // 关闭测试里创建的 bloc，避免资源泄漏。
      await firstCounterCubit.close();
      await secondCounterCubit.close();
    });

    testWidgets(
        'does not rebuild from the old bloc after context lookup switches '
        'to another instance', (tester) async {
      // 和上面的切换场景类似，
      // 但这次 BlocBuilder 不是通过 `bloc:` 参数拿 bloc，
      // 而是通过 BlocProvider 从 context 中查找。
      final firstCounterCubit = CounterCubit();
      final secondCounterCubit = CounterCubit(seed: 100);
      var currentCubit = firstCounterCubit;
      late StateSetter setState;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, localSetState) {
              setState = localSetState;
              return BlocProvider.value(
                // 通过重建 BlocProvider，切换它向下提供的 bloc 实例。
                value: currentCubit,
                child: BlocBuilder<CounterCubit, int>(
                  builder: (context, state) => Text('Count $state'),
                ),
              );
            },
          ),
        ),
      );

      // 初次渲染应来自第一个 provider 提供的 bloc。
      expect(find.text('Count 0'), findsOneWidget);

      // 先验证第一个 bloc 的状态变化可以正常驱动 UI。
      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);

      // 重建 provider，并切换成第二个 bloc。
      setState(() => currentCubit = secondCounterCubit);
      await tester.pumpAndSettle();

      // 此时 BlocBuilder 应该已经读取到第二个 bloc 的当前 state。
      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 1'), findsNothing);

      // 旧 bloc 此时不应该再有能力刷新 UI。
      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 2'), findsNothing);

      // 新 bloc 仍然应该可以正常驱动 UI 刷新。
      secondCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 101'), findsOneWidget);

      await firstCounterCubit.close();
      await secondCounterCubit.close();
    });

    testWidgets('rebuilds when bloc is changed via Stream', (tester) async {
      final firstCounterCubit = CounterCubit();
      final secondCounterCubit = CounterCubit(seed: 100);
      final cubitStreamController = StreamController<CounterCubit>.broadcast()
        ..add(firstCounterCubit);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StreamBuilder<CounterCubit>(
            stream: cubitStreamController.stream,
            initialData: firstCounterCubit,
            builder: (context, snapshot) {
              final currentCubit = snapshot.data!;
              return BlocProvider.value(
                value: currentCubit,
                child: BlocBuilder<CounterCubit, int>(
                  builder: (context, state) => Text('Count $state'),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Count 0'), findsOneWidget);

      firstCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
      expect(find.text('Count 0'), findsNothing);

      cubitStreamController.add(secondCounterCubit);
      await tester.pumpAndSettle();
      expect(find.text('Count 100'), findsOneWidget);
      expect(find.text('Count 1'), findsNothing);

      secondCounterCubit.increment();
      await tester.pumpAndSettle();
      expect(find.text('Count 101'), findsOneWidget);

      await cubitStreamController.close();
      await firstCounterCubit.close();
      await secondCounterCubit.close();
    });

    testWidgets('overrides debugFillProperties', (tester) async {
      final builder = DiagnosticPropertiesBuilder();

      BlocBuilder(
        bloc: CounterCubit(),
        builder: (context, state) => const SizedBox(),
        buildWhen: (previous, current) => previous != current,
      ).debugFillProperties(builder);

      final description = builder.properties
          .where((node) => !node.isFiltered(DiagnosticLevel.info))
          .map((node) => node.toString())
          .toList();

      expect(
        description,
        <String>[
          'has buildWhen',
          "bloc: Instance of 'CounterCubit'",
          'has builder',
        ],
      );
    });
    
  });
}
