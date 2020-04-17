import 'package:core/coop/coop_client.dart' as core;
import 'package:flutter/material.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/rive_animation_controller.dart';
import 'package:rive_core/rive_core_field_type.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:core/coop/change.dart';
import 'package:core/coop/player.dart';
import 'package:core/core.dart';
import 'package:core/debounce.dart';

import 'package:rive_api/api.dart';
import 'package:rive_api/artists.dart';
import 'package:rive_core/client_side_player.dart';

import 'package:rive_core/artboard.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'src/generated/rive_core_context.dart';
import 'src/isolated_persist.dart';

class RiveFile extends RiveCoreContext {
  final List<Artboard> artboards = [];
  final Set<RiveFileDelegate> delegates = {};
  int _dirt = 0;
  final IsolatedPersist _isolatedPersist;
  final RiveApi api;
  final Set<ClientSidePlayer> _dirtyPlayers = {};
  Backboard _backboard;
  Backboard get backboard => _backboard;

  /// Track if a property has changed since last advance, force an advance (and
  /// redraw) if any have.
  bool _propertyChanged = false;

  /// An aniation controller that can be attached to mutate the file for
  /// rendering but not for coop changes.
  RiveAnimationController _animationController;
  RiveAnimationController get animationController => _animationController;
  set animationController(RiveAnimationController value) {
    if (_animationController == value) {
      return;
    }
    _animationController?.removeListener(markNeedsAdvance);
    _animationController = value;
    _animationController?.addListener(markNeedsAdvance);
    markNeedsAdvance();
  }

  final ValueNotifier<Iterable<ClientSidePlayer>> allPlayers =
      ValueNotifier<Iterable<ClientSidePlayer>>([]);

  /// Set of components that need to be resorted after the current operation
  /// (undo/redo/capture) completes.
  final Set<ContainerComponent> _needChildSort = {};

  /// Set of components that need to their dependencies re-built.
  final Set<Component> _needDependenciesBuilt = {};

  /// Set of artboards that need their dependencies sorted.
  final Set<Artboard> _needDependenciesOrdered = {};

  /// Set of components that have had dependents changes and should recompute
  /// their dependentIds once the dependencies have been recomputed.
  final Set<Component> _needDependentIdsRebuilt = {};

  /// Generic set of dirty operations that need to be cleaned with the next
  /// clean call.
  final Set<void Function()> _needsCleaning = {};

  SharedPreferences _prefs;

  RiveFile(
    String fileId, {
    @required LocalDataPlatform localDataPlatform,
    this.api,
  })  : _isolatedPersist = IsolatedPersist(localDataPlatform, fileId),
        super(fileId);

  @override
  void abandonChanges(ChangeSet changes) {
    _isolatedPersist.remove(changes);
  }

  bool addDelegate(RiveFileDelegate delegate) => delegates.add(delegate);

  bool _isAnimating = false;
  double _frameElapsed = 0;
  void startDrawStage() {
    if (_animationController == null) {
      return;
    }
    _isAnimating = true;
    if (_animationController.advance(_frameElapsed)) {
      // at this point we only care about advancing again if the aniation
      // controller wants us to, we'll clean up anything it did anyway.
      for (final artboard in artboards) {
        artboard.advance(_frameElapsed);
      }
    }
  }

  void endDrawStage() {
    if (!_isAnimating) {
      return;
    }
// If the animation controller made changes lets revert them.
    if (revertChanges()) {
      // always clean again after animation controller advances. This is
      // presumably to sort draw order changes, right?
      cleanDirt();
      for (final artboard in artboards) {
        artboard.advance(_frameElapsed);
      }
    }
    _isAnimating = false;
    _propertyChanged = false;
  }

  bool advance(double elapsed) {
    _frameElapsed = elapsed;
    cleanDirt();
    bool advanced = _propertyChanged;
    for (final artboard in artboards) {
      if (artboard.advance(elapsed)) {
        advanced = true;
      }
    }
    _propertyChanged = false;

    print("ADVNACED $advanced");
    startDrawStage();

    return advanced;
  }

  @override
  void changeProperty<T>(Core object, int propertyKey, T from, T to) {
    super.changeProperty<T>(object, propertyKey, from, to);
    _propertyChanged = true;
  }

  /// Add a generic operation to be called when the next clean cycle occurs.
  /// Usually use this to debounce an operation before capturing the next
  /// journal entry.
  void dirty(void Function() dirt) {
    if (_needsCleaning.add(dirt)) {
      _dirt |= _RiveDirt.generic;
    }
  }

  /// Perform any cleanup required due to properties being marked dirty.
  bool cleanDirt([int escapeHatch = 0]) {
    assert(escapeHatch < 1000);
    if (_dirt == 0) {
      return false;
    }
    _dirt = 0;

    if (_needDependenciesBuilt.isNotEmpty) {
      // Copy it in case it is changed during the building (meaning this process
      // needs to recurse).
      Set<Component> needDependenciesBuilt =
          Set<Component>.from(_needDependenciesBuilt);
      _needDependenciesBuilt.clear();

      // First resolve the artboards
      for (final component in needDependenciesBuilt) {
        component.resolveArtboard();
      }

      // Then build the dependencies
      for (final component in needDependenciesBuilt) {
        if (component.artboard != null) {
          _needDependenciesOrdered.add(component.artboard);
        }
        component.buildDependencies();
      }
    }

    if (_needDependentIdsRebuilt.isNotEmpty) {
      // Rebuild any dependent ids that will have changed from building
      // dependencies.
      for (final component in _needDependentIdsRebuilt) {
        component.dependentIds = component.dependents
            .map((other) => other.id)
            .toList(growable: false);
      }
      _needDependentIdsRebuilt.clear();
    }
    if (_needChildSort.isNotEmpty) {
      for (final parent in _needChildSort) {
        parent.children.sortFractional();
      }
      _needChildSort.clear();
    }

    if (_needDependenciesOrdered.isNotEmpty) {
      // finally sort dependencies
      for (final artboard in _needDependenciesOrdered) {
        artboard.sortDependencies();
      }
      _needDependenciesOrdered.clear();
    }

    if (_needsCleaning.isNotEmpty) {
      var cleanup = Set<void Function()>.from(_needsCleaning);
      _needsCleaning.clear();
      for (final clean in cleanup) {
        clean();
      }
    }

    if (_dirt != 0) {
      cleanDirt(escapeHatch + 1);
      return true;
    }

    // Only call dirt cleaned when it's really finally cleaned.
    delegates.forEach((delegate) => delegate.onDirtCleaned());
    return true;
  }

  @override
  void completeChanges() {
    cleanDirt();
  }

  @override
  Future<int> getIntSetting(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs.getInt(key);
  }

  @override
  Future<List<ChangeSet>> getOfflineChanges() => _isolatedPersist.changes();

  @override
  Future<String> getStringSetting(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs.getString(key);
  }

  /// Mark a component as needing its children to be sorted.
  void markChildSortDirty(ContainerComponent component) {
    _dirt |= _RiveDirt.childSort;
    _needChildSort.add(component);
  }

  /// Mark a component as needing its artboard to be resolved.
  bool markDependenciesDirty(Component component) {
    if (!_needDependenciesBuilt.add(component)) {
      return false;
    }
    _dirt |= _RiveDirt.dependencies;
    markNeedsAdvance();
    return true;
  }

  /// Mark an artboard as needing its dependencies sorted.
  void markDependencyOrderDirty(Artboard artboard) {
    assert(artboard != null);
    _dirt |= _RiveDirt.dependencyOrder;
    _needDependenciesOrdered.add(artboard);
  }

  /// Mark a component as needing its dependent ids recalculated.
  void markDependentIdsDirty(Component component) {
    _needDependentIdsRebuilt.add(component);

    /// Note that we don't mark _dirt here as this always happend in response to
    /// a dependency order being marked dirty.
  }

  void markNeedsAdvance() {
    if (_isAnimating) {
      return;
    }
    delegates.forEach((delegate) => delegate.markNeedsAdvance());
  }

  @override
  void onAddedDirty(Core object) {
    object.onAddedDirty();
  }

  @override
  void onAddedClean(Core object) {
    // Remove corrupt objects immediately.
    if (!object.validate()) {
      remove(object);
      return;
    }
    object.onAdded();
    delegates.forEach((delegate) => delegate.onObjectAdded(object));
    if (object is Artboard) {
      artboards.add(object);
      delegates.forEach((delegate) => delegate.onArtboardsChanged());
    }
  }

  @override
  void onRemoved(Core object) {
    object.onRemoved();
    delegates.forEach((delegate) => delegate.onObjectRemoved(object));
    if (object is Artboard) {
      artboards.remove(object);
      delegates.forEach((delegate) => delegate.onArtboardsChanged());
    }
  }

  @override
  void onWipe() {
    artboards.clear();
    delegates.forEach((delegate) => delegate.onWipe());
    _isolatedPersist.wipe();
  }

  @override
  void persistChanges(ChangeSet changes) {
    _isolatedPersist.add(changes);
  }

  bool removeDelegate(RiveFileDelegate delegate) => delegates.remove(delegate);

  @override
  Future<void> setIntSetting(String key, int value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs.setInt(key, value);
  }

  @override
  Future<void> setStringSetting(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs.setString(key, value);
  }

  @override
  Player makeClientSidePlayer(Player serverPlayer, bool isSelf) =>
      ClientSidePlayer(serverPlayer, isSelf);

  @override
  void onPlayerAdded(ClientSidePlayer player) {
    _dirtyPlayers.add(player);

    // TODO: find a nicer way to get the index, then clean any remaining vomit.
    // we use this to pick a color from the palette, we could alternatively just
    // use the ownerId or something, but this gives better pallette spread for
    // the local session.
    player.index = players.toList(growable: false).indexOf(player);

    delegates.forEach((delegate) => delegate.onPlayerAdded(player));
  }

  Future<void> _loadDirtyPlayers() async {
    // TODO: make the api non-nullable, which means mocking it out for tests
    if (_dirtyPlayers.isEmpty || api == null) {
      return;
    }
    var artists = RiveArtists(api);

    var loadingPlayers = _dirtyPlayers.toList(growable: false);
    // make a unique set of owner ids (owners can have multiple players).
    var loadList = Set<int>.from(
        loadingPlayers.map((player) => player.ownerId).toList(growable: false));

    // Make sure to clear dirty players before awaiting so no async op changes
    // this list before we clear it.
    _dirtyPlayers.clear();

    var users = await artists.list(loadList);
    if (users != null) {
      for (final user in users) {
        // Could build up a map above if this gets prohibitive.
        for (final player in loadingPlayers) {
          if (player.ownerId == user.ownerId) {
            player.user = user;
          }
        }
      }
    }
  }

  @override
  void onPlayerRemoved(ClientSidePlayer player) {
    _dirtyPlayers.remove(player);
    delegates.forEach((delegate) => delegate.onPlayerRemoved(player));
  }

  @override
  void onPlayersChanged() {
    allPlayers.value = players.cast<ClientSidePlayer>();

    // Loading the active player list is low priority compared to other stuff
    // happening (like loading assets or content for the file) so we debounce it
    // pretty heavily.
    debounce(_loadDirtyPlayers, duration: const Duration(milliseconds: 300));
  }

  @override
  void onConnected() {
    // Find backboard.
    var backboards = objects.whereType<Backboard>();

    if (backboards.isEmpty) {
      // Don't have one? Patch up the file and make one...
      batchAdd(() {
        _backboard = Backboard();
        add(_backboard);
      });
      // Save the creation of the backboard.
      captureJournalEntry();
      // Don't allow undoing it.
      clearJournal();
    } else {
      if (backboards.length > 1) {
        do {
          remove(backboards.last);
        } while (backboards.length > 1);
        // Save the creation of the backboard.
        captureJournalEntry();
        // Don't allow undoing it.
        clearJournal();
      }
      _backboard = backboards.first;
    }
    assert(objects.whereType<Backboard>().length == 1,
        'File should contain exactly one backboard.');
  }

  @override
  void connectionStateChanged(core.ConnectionState state) =>
      delegates.forEach((delegate) => delegate.onConnectionStateChanged(state));

  @override
  CoreIdType get idType => RiveIdType.instance;

  @override
  CoreIntType get intType => RiveIntType.instance;

  @override
  CoreStringType get stringType => RiveStringType.instance;

  @override
  CoreDoubleType get doubleType => RiveDoubleType.instance;

  @override
  CoreBoolType get boolType => RiveBoolType.instance;

  @override
  CoreListIdType get listIdType => RiveListIdType.instance;

  @override
  CoreFractionalIndexType get fractionalIndexType =>
      RiveFractionalIndexType.instance;
}

/// Delegate type that can be passed to [RiveFile] to listen to events.
abstract class RiveFileDelegate {
  void markNeedsAdvance();
  void onArtboardsChanged() {}
  void onDirtCleaned();
  void onObjectAdded(Core object) {}
  void onObjectRemoved(Core object) {}
  void onPlayerAdded(ClientSidePlayer player) {}
  void onPlayerRemoved(ClientSidePlayer player) {}

  /// Called when the entire file is wiped as data is about to load/reload.
  void onWipe();

  /// Let the delegate know the connection state somehow changed.
  void onConnectionStateChanged(core.ConnectionState state);
}

class _RiveDirt {
  static const int dependencies = 1 << 0;
  static const int childSort = 1 << 1;
  static const int dependencyOrder = 1 << 2;
  static const int generic = 1 << 3;
}
