import '_utils.dart';

final futureCasters = <Type, Future Function(Future)>{
  // Primitive types
  int: futureCast<int>,
  typeOf<int?>(): futureCast<int?>,
  double: futureCast<double>,
  typeOf<double?>(): futureCast<double?>,
  String: futureCast<String>,
  typeOf<String?>(): futureCast<String?>,
  bool: futureCast<bool>,
  typeOf<bool?>(): futureCast<bool?>,
  num: futureCast<num>,
  typeOf<num?>(): futureCast<num?>,

  // Other base types
  DateTime: futureCast<DateTime>,
  typeOf<DateTime?>(): futureCast<DateTime?>,
  Duration: futureCast<Duration>,
  typeOf<Duration?>(): futureCast<Duration?>,
  Uri: futureCast<Uri>,
  typeOf<Uri?>(): futureCast<Uri?>,
  BigInt: futureCast<BigInt>,
  typeOf<BigInt?>(): futureCast<BigInt?>,

  // Collections (raw/dynamic)
  List: futureCast<List>,
  typeOf<List?>(): futureCast<List?>,
  Map: futureCast<Map>,
  typeOf<Map?>(): futureCast<Map?>,
  Set: futureCast<Set>,
  typeOf<Set?>(): futureCast<Set?>,
  Iterable: futureCast<Iterable>,
  typeOf<Iterable?>(): futureCast<Iterable?>,

  // Core
  Object: futureCast<Object>,
  typeOf<Object?>(): futureCast<Object?>,
};

void registerType<T>() => futureCasters[T] = futureCast<T>;

Future reify(Future f, Type t) => futureCasters[t]?.call(f) ?? f;
