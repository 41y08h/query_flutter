import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

StateNotifierProvider<Query<Data>, QueryStatus<Data>> getAsyncProvider<Data>(
    Future<Data> Function(
            StateNotifierProviderRef<Query<Data>, QueryStatus<Data>> ref)
        getData) {
  return StateNotifierProvider<Query<Data>, QueryStatus<Data>>(
    (ref) => Query(
      () => getData(ref),
    ),
  );
}

@immutable
class QueryStatus<Data> {
  final bool isLoading;
  final bool isFetching;
  final bool isFetched;
  final Data? data;

  const QueryStatus({
    this.isLoading = false,
    this.isFetching = false,
    this.isFetched = false,
    this.data,
  });

  QueryStatus<Data> copyWith({
    bool? isLoading,
    bool? isFetching,
    bool? isFetched,
    Data? data,
  }) {
    return QueryStatus(
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
      isFetched: isFetched ?? this.isFetched,
      data: data ?? this.data,
    );
  }
}

class Query<Data> extends StateNotifier<QueryStatus<Data>> {
  final Future<Data> Function() getData;
  Query(this.getData) : super(QueryStatus<Data>());

  Future<void> fetch() async {
    print("fetch called");
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    final data = await getData();
    state = state.copyWith(
      isLoading: false,
      isFetching: false,
      isFetched: true,
      data: data,
    );
  }

  Future<void> refresh() async {
    print("refresh called");
    if (state.isFetching) return;
    state = state.copyWith(isFetching: true);
    final data = await getData();
    state = state.copyWith(
      isLoading: false,
      isFetching: false,
      isFetched: true,
      data: data,
    );
  }
}

class UseQuery<Data> {
  final QueryStatus<Data> state;
  final Query<Data> fns;
  UseQuery({required this.state, required this.fns});
}

UseQuery<Data> useQuery<Data>(
    StateNotifierProvider<Query<Data>, QueryStatus<Data>> provider,
    WidgetRef ref,
    {bool enabled = true}) {
  final state = ref.watch(provider);
  final fns = ref.read(provider.notifier);

  useEffect(() {
    if (!enabled) return;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      fns.fetch();
    });
  }, [enabled]);

  return UseQuery(state: state, fns: fns);
}

final tenQuery = getAsyncProvider((ref) => Future.value(10));
final summationQuery = getAsyncProvider((ref) {
  int tenData = ref.watch(tenQuery).data as int;
  return Future.value(tenData + 89);
});

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final num1 = useQuery(tenQuery, ref);
    final calculation =
        useQuery(summationQuery, ref, enabled: num1.state.isFetched);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (calculation.state.isLoading)
              const CircularProgressIndicator()
            else
              Text(calculation.state.data.toString()),
            TextButton(
                onPressed: calculation.fns.refresh,
                child: const Text('Refresh')),
            calculation.state.isFetching
                ? Text("Refreshing your data...")
                : Text('Not fetching'),
            TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => Scaffold(
                      // Narendra Modi image from wikipedia in the center
                      body: Center(
                        child: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Narendra_Modi_official_portrait.jpg/220px-Narendra_Modi_official_portrait.jpg',
                        ),
                      ),
                    ),
                  ));
                },
                child: Text('Navigate'))
          ],
        ),
      ),
    );
  }
}
