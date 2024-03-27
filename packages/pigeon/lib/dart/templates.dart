// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../generator_tools.dart';

/// Creates the `InstanceManager` with the passed string values.
String instanceManagerTemplate({
  required Iterable<String> allProxyApiNames,
}) {
  final Iterable<String> apiHandlerSetUps = allProxyApiNames.map(
    (String name) {
      return '$name.${classMemberNamePrefix}setUpMessageHandlers(${classMemberNamePrefix}instanceManager: instanceManager);';
    },
  );

  return '''
/// Maintains instances used to communicate with the native objects they
/// represent.
///
/// Added instances are stored as weak references and their copies are stored
/// as strong references to maintain access to their variables and callback
/// methods. Both are stored with the same identifier.
///
/// When a weak referenced instance becomes inaccessible,
/// [onWeakReferenceRemoved] is called with its associated identifier.
///
/// If an instance is retrieved and has the possibility to be used,
/// (e.g. calling [getInstanceWithWeakReference]) a copy of the strong reference
/// is added as a weak reference with the same identifier. This prevents a
/// scenario where the weak referenced instance was released and then later
/// returned by the host platform.
class $instanceManagerClassName {
  /// Constructs a [$instanceManagerClassName].
  $instanceManagerClassName({required void Function(int) onWeakReferenceRemoved}) {
    this.onWeakReferenceRemoved = (int identifier) {
      _weakInstances.remove(identifier);
      onWeakReferenceRemoved(identifier);
    };
    _finalizer = Finalizer<int>(this.onWeakReferenceRemoved);
  }

  // Identifiers are locked to a specific range to avoid collisions with objects
  // created simultaneously by the host platform.
  // Host uses identifiers >= 2^16 and Dart is expected to use values n where,
  // 0 <= n < 2^16.
  static const int _maxDartCreatedIdentifier = 65536;

  /// The default [$instanceManagerClassName] used by ProxyApis.
  ///
  /// On creation, this manager makes a call to clear the native
  /// InstanceManager. This is to prevent identifier conflicts after a host
  /// restart.
  static final $instanceManagerClassName instance = _initInstance();

  // Expando is used because it doesn't prevent its keys from becoming
  // inaccessible. This allows the manager to efficiently retrieve an identifier
  // of an instance without holding a strong reference to that instance.
  //
  // It also doesn't use `==` to search for identifiers, which would lead to an
  // infinite loop when comparing an object to its copy. (i.e. which was caused
  // by calling instanceManager.getIdentifier() inside of `==` while this was a
  // HashMap).
  final Expando<int> _identifiers = Expando<int>();
  final Map<int, WeakReference<$proxyApiBaseClassName>> _weakInstances =
      <int, WeakReference<$proxyApiBaseClassName>>{};
  final Map<int, $proxyApiBaseClassName> _strongInstances = <int, $proxyApiBaseClassName>{};
  late final Finalizer<int> _finalizer;
  int _nextIdentifier = 0;

  /// Called when a weak referenced instance is removed by [removeWeakReference]
  /// or becomes inaccessible.
  late final void Function(int) onWeakReferenceRemoved;

  static $instanceManagerClassName _initInstance() {
    WidgetsFlutterBinding.ensureInitialized();
    final _${instanceManagerClassName}Api api = _${instanceManagerClassName}Api();
    // Clears the native `$instanceManagerClassName` on the initial use of the Dart one.
    api.clear();
    final $instanceManagerClassName instanceManager = $instanceManagerClassName(
      onWeakReferenceRemoved: (int identifier) {
        api.removeStrongReference(identifier);
      },
    );
    _${instanceManagerClassName}Api.setUpMessageHandlers(instanceManager: instanceManager);
    ${apiHandlerSetUps.join('\n\t\t')}
    return instanceManager;
  }

  /// Adds a new instance that was instantiated by Dart.
  ///
  /// In other words, Dart wants to add a new instance that will represent
  /// an object that will be instantiated on the host platform.
  ///
  /// Throws assertion error if the instance has already been added.
  ///
  /// Returns the randomly generated id of the [instance] added.
  int addDartCreatedInstance($proxyApiBaseClassName instance) {
    final int identifier = _nextUniqueIdentifier();
    _addInstanceWithIdentifier(instance, identifier);
    return identifier;
  }

  /// Removes the instance, if present, and call [onWeakReferenceRemoved] with
  /// its identifier.
  ///
  /// Returns the identifier associated with the removed instance. Otherwise,
  /// `null` if the instance was not found in this manager.
  ///
  /// This does not remove the strong referenced instance associated with
  /// [instance]. This can be done with [remove].
  int? removeWeakReference($proxyApiBaseClassName instance) {
    final int? identifier = getIdentifier(instance);
    if (identifier == null) {
      return null;
    }

    _identifiers[instance] = null;
    _finalizer.detach(instance);
    onWeakReferenceRemoved(identifier);

    return identifier;
  }

  /// Removes [identifier] and its associated strongly referenced instance, if
  /// present, from the manager.
  ///
  /// Returns the strong referenced instance associated with [identifier] before
  /// it was removed. Returns `null` if [identifier] was not associated with
  /// any strong reference.
  ///
  /// This does not remove the weak referenced instance associated with
  /// [identifier]. This can be done with [removeWeakReference].
  T? remove<T extends $proxyApiBaseClassName>(int identifier) {
    return _strongInstances.remove(identifier) as T?;
  }

  /// Retrieves the instance associated with identifier.
  ///
  /// The value returned is chosen from the following order:
  ///
  /// 1. A weakly referenced instance associated with identifier.
  /// 2. If the only instance associated with identifier is a strongly
  /// referenced instance, a copy of the instance is added as a weak reference
  /// with the same identifier. Returning the newly created copy.
  /// 3. If no instance is associated with identifier, returns null.
  ///
  /// This method also expects the host `InstanceManager` to have a strong
  /// reference to the instance the identifier is associated with.
  T? getInstanceWithWeakReference<T extends $proxyApiBaseClassName>(int identifier) {
    final $proxyApiBaseClassName? weakInstance = _weakInstances[identifier]?.target;

    if (weakInstance == null) {
      final $proxyApiBaseClassName? strongInstance = _strongInstances[identifier];
      if (strongInstance != null) {
        final $proxyApiBaseClassName copy = strongInstance.${classMemberNamePrefix}copy();
        _identifiers[copy] = identifier;
        _weakInstances[identifier] = WeakReference<$proxyApiBaseClassName>(copy);
        _finalizer.attach(copy, identifier, detach: copy);
        return copy as T;
      }
      return strongInstance as T?;
    }

    return weakInstance as T;
  }

  /// Retrieves the identifier associated with instance.
  int? getIdentifier($proxyApiBaseClassName instance) {
    return _identifiers[instance];
  }

  /// Adds a new instance that was instantiated by the host platform.
  ///
  /// In other words, the host platform wants to add a new instance that
  /// represents an object on the host platform. Stored with [identifier].
  ///
  /// Throws assertion error if the instance or its identifier has already been
  /// added.
  ///
  /// Returns unique identifier of the [instance] added.
  void addHostCreatedInstance($proxyApiBaseClassName instance, int identifier) {
    _addInstanceWithIdentifier(instance, identifier);
  }

  void _addInstanceWithIdentifier($proxyApiBaseClassName instance, int identifier) {
    assert(!containsIdentifier(identifier));
    assert(getIdentifier(instance) == null);
    assert(identifier >= 0);

    _identifiers[instance] = identifier;
    _weakInstances[identifier] = WeakReference<$proxyApiBaseClassName>(instance);
    _finalizer.attach(instance, identifier, detach: instance);

    final $proxyApiBaseClassName copy = instance.${classMemberNamePrefix}copy();
    _identifiers[copy] = identifier;
    _strongInstances[identifier] = copy;
  }

  /// Whether this manager contains the given [identifier].
  bool containsIdentifier(int identifier) {
    return _weakInstances.containsKey(identifier) ||
        _strongInstances.containsKey(identifier);
  }

  int _nextUniqueIdentifier() {
    late int identifier;
    do {
      identifier = _nextIdentifier;
      _nextIdentifier = (_nextIdentifier + 1) % _maxDartCreatedIdentifier;
    } while (containsIdentifier(identifier));
    return identifier;
  }
}
''';
}

/// Creates the `InstanceManagerApi` with the passed string values.
String instanceManagerApiTemplate({
  required String dartPackageName,
  required String pigeonChannelCodecVarName,
}) {
  const String apiName = '${instanceManagerClassName}Api';

  final String removeStrongReferenceName = makeChannelNameWithStrings(
    apiName: apiName,
    methodName: 'removeStrongReference',
    dartPackageName: dartPackageName,
  );

  final String clearName = makeChannelNameWithStrings(
    apiName: apiName,
    methodName: 'clear',
    dartPackageName: dartPackageName,
  );

  return '''
/// Generated API for managing the Dart and native `$instanceManagerClassName`s.
class _$apiName {
  /// Constructor for [_$apiName].
  _$apiName({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;

  final BinaryMessenger? _binaryMessenger;
  
  static const MessageCodec<Object?> $pigeonChannelCodecVarName =
     StandardMessageCodec();

  static void setUpMessageHandlers({
    BinaryMessenger? binaryMessenger,
    $instanceManagerClassName? instanceManager,
  }) {
    const String channelName =
        r'$removeStrongReferenceName';
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      channelName,
      $pigeonChannelCodecVarName,
      binaryMessenger: binaryMessenger,
    );
    channel.setMessageHandler((Object? message) async {
      assert(
        message != null,
        'Argument for \$channelName was null.',
      );
      final int? identifier = message as int?;
      assert(
        identifier != null,
        r'Argument for \$channelName, expected non-null int.',
      );
      (instanceManager ?? $instanceManagerClassName.instance).remove(identifier!);
      return;
    });
  }

  Future<void> removeStrongReference(int identifier) async {
    const String channelName =
        r'$removeStrongReferenceName';
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      channelName,
      $pigeonChannelCodecVarName,
      binaryMessenger: _binaryMessenger,
    );
    final List<Object?>? replyList =
        await channel.send(identifier) as List<Object?>?;
    if (replyList == null) {
      throw _createConnectionError(channelName);
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// Clear the native `$instanceManagerClassName`.
  ///
  /// This is typically called after a hot restart.
  Future<void> clear() async {
    const String channelName =
        r'$clearName';
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
      channelName,
      $pigeonChannelCodecVarName,
      binaryMessenger: _binaryMessenger,
    );
    final List<Object?>? replyList = await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw _createConnectionError(channelName);
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}''';
}

/// The base class for all ProxyApis.
///
/// All Dart classes generated as a ProxyApi extends this one.
const String proxyApiBaseClass = '''
/// An immutable object that serves as the base class for all ProxyApis and
/// can provide functional copies of itself.
///
/// All implementers are expected to be [immutable] as defined by the annotation
/// and override [${classMemberNamePrefix}copy] returning an instance of itself.
@immutable
abstract class $proxyApiBaseClassName {
  /// Construct a [$proxyApiBaseClassName].
  $proxyApiBaseClassName({
    this.$_proxyApiBaseClassMessengerVarName,
    $instanceManagerClassName? $_proxyApiBaseClassInstanceManagerVarName,
  }) : $_proxyApiBaseClassInstanceManagerVarName =
            $_proxyApiBaseClassInstanceManagerVarName ?? $instanceManagerClassName.instance;

  /// Sends and receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used, which routes to
  /// the host platform.
  @protected
  final BinaryMessenger? $_proxyApiBaseClassMessengerVarName;

  /// Maintains instances stored to communicate with native language objects.
  @protected
  final $instanceManagerClassName $_proxyApiBaseClassInstanceManagerVarName;

  /// Instantiates and returns a functionally identical object to oneself.
  ///
  /// Outside of tests, this method should only ever be called by
  /// [$instanceManagerClassName].
  ///
  /// Subclasses should always override their parent's implementation of this
  /// method.
  @protected
  $proxyApiBaseClassName ${classMemberNamePrefix}copy();
}
''';

/// The base codec for ProxyApis.
///
/// All generated Dart proxy apis should use this codec or extend it. This codec
/// adds support to convert instances to their corresponding identifier from an
/// `InstanceManager` and vice versa.
const String proxyApiBaseCodec = '''
class $_proxyApiCodecName extends StandardMessageCodec {
 const $_proxyApiCodecName(this.instanceManager);
 final $instanceManagerClassName instanceManager;
 @override
 void writeValue(WriteBuffer buffer, Object? value) {
   if (value is $proxyApiBaseClassName) {
     buffer.putUint8(128);
     writeValue(buffer, instanceManager.getIdentifier(value));
   } else {
     super.writeValue(buffer, value);
   }
 }
 @override
 Object? readValueOfType(int type, ReadBuffer buffer) {
   switch (type) {
     case 128:
       return instanceManager
           .getInstanceWithWeakReference(readValue(buffer)! as int);
     default:
       return super.readValueOfType(type, buffer);
   }
 }
}
''';

/// Name of the base class of all ProxyApis.
const String proxyApiBaseClassName = '${classNamePrefix}ProxyApiBaseClass';
const String _proxyApiBaseClassMessengerVarName =
    '${classMemberNamePrefix}binaryMessenger';
const String _proxyApiBaseClassInstanceManagerVarName =
    '${classMemberNamePrefix}instanceManager';
const String _proxyApiCodecName = '_${classNamePrefix}ProxyApiBaseCodec';
