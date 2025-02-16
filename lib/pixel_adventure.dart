import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/level.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  Color backgroundColor() => const Color(0xFF211F30);
  late CameraComponent cam;
  Player player = Player(character: 'Mask Dude');
  late JoystickComponent joystick;
  bool showControls = true;
  List<String> levelNames = ['level_01', 'level_02'];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {
    // it will load all the images in chache memmory so it takes some long time if the images are large in number.

    await images.loadAllImages();
    _loadLevel();

    if (showControls) {
      addJoystick();
      add(JumpButton());
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      priority: 10,
      margin: const EdgeInsets.only(left: 32, bottom: 32),
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
    );
    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizonatallyMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizonatallyMovement = 1;
        break;

      default:
        player.horizonatallyMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      //no more levels
    }
  }

  void _loadLevel() {
    Future.delayed(
      const Duration(seconds: 1),
      () {
        Level level = Level(
          levelName: levelNames[currentLevelIndex],
          player: player,
        );

        cam = CameraComponent.withFixedResolution(
          world: level,
          width: 640,
          height: 360,
        );
        cam.viewfinder.anchor = Anchor.topLeft;

        addAll([cam, level]);
      },
    );
  }
}
