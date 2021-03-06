import 'package:flutter/material.dart';

import '../../graphx.dart';

/// Entry point of GraphX world.
/// A [SceneController] manages (up to) 2 [SceneRoot]s: `back` and `front`
/// which correlates to [CustomPainter.painter] and
/// [CustomPainter.foregroundPainter]. It takes care of the initialization
/// and holding the references of the Painters used by [SceneBuilderWidget].
class SceneController {
  ScenePainter backScene;

  ScenePainter frontScene;

  /// Access the `ticker` (if any) created by this SceneController.
  GxTicker get ticker {
    if (_ticker == null) {
      throw 'You need to enable ticker usage with '
          'SceneBuilderWidget( useTicker=true ) or '
          'RootScene::setup(useTicker: true), or '
          'RootScene::setup(autoUpdateAndRender: true)';
    }
    return _ticker;
  }

  /// Access the keyboard manager instance associated with this
  /// [SceneController].
  KeyboardManager get keyboard => _keyboard;

  /// Access the pointer manager instance associated with this
  /// [SceneController].
  PointerManager get pointer => _pointer;

  KeyboardManager _keyboard;

  PointerManager _pointer;

  GxTicker _ticker;

  InputConverter $inputConverter;

  SceneConfig get config => _config;

  final _config = SceneConfig();

  int id = -1;

  bool _isInited = false;

  set config(SceneConfig sceneConfig) {
    _config.autoUpdateRender = sceneConfig.autoUpdateRender ?? true;
    _config.isPersistent = sceneConfig.isPersistent ?? false;
    _config.painterWillChange = sceneConfig.painterWillChange ?? true;
    _config.useKeyboard = sceneConfig.useKeyboard ?? false;
    _config.usePointer = sceneConfig.usePointer ?? false;
    _config.useTicker = sceneConfig.useTicker ?? false;
  }

  Juggler get juggler => Graphx.juggler;

  /// constructor.
  SceneController({
    Sprite back,
    Sprite front,
    SceneConfig config,
  }) {
    assert(back != null || front != null);
    if (back != null) {
      backScene = ScenePainter(this, back);
    }
    if (front != null) {
      frontScene = ScenePainter(this, front);
    }
    this.config = config ?? SceneConfig.defaultConfig;
  }

  /// WARNING: Internal method
  /// called internally from [SceneBuilderWidget].
  void $init() {
    if (_isInited) {
      return;
    }
    setup();
    if (_hasTicker()) {
      _ticker = GxTicker();
      _ticker.onFrame.add(_onTick);
      if (_anySceneAutoUpdate()) {
        _ticker.resume();
      }
    }
    _initInput();
    _isInited = true;
  }

  void setup() {
    backScene?.$setup();
    frontScene?.$setup();
  }

  /// [GxTicker] that runs the `enterFrame`.
  /// Is independent from the rendering pipeline.
  void _onTick(double elapsed) {
    Graphx.juggler.update(elapsed);
    frontScene?.tick(elapsed);
    backScene?.tick(elapsed);
  }

  void resumeTicker() {
    ticker?.resume();
  }

  void dispose() {
    if (_config.isPersistent) {
      return;
    }
    frontScene?.dispose();
    backScene?.dispose();
    _ticker?.dispose();
    _ticker = null;
  }

  CustomPainter buildBackPainter() => backScene?.buildPainter();

  CustomPainter buildFrontPainter() => frontScene?.buildPainter();

  void _initInput() {
    if (_config.useKeyboard) {
      _keyboard ??= KeyboardManager();
    }
    if (_config.usePointer) {
      _pointer ??= PointerManager();
    }
    if (_config.useKeyboard || _config.usePointer) {
      $inputConverter ??= InputConverter(_pointer, _keyboard);
    }
  }

  bool _sceneAutoUpdate(ScenePainter scene) =>
      scene?.autoUpdateAndRender ?? false;

  bool _anySceneAutoUpdate() =>
      _sceneAutoUpdate(backScene) || _sceneAutoUpdate(frontScene);

  bool _hasTicker() => _anySceneAutoUpdate() || _config.useTicker;
}
