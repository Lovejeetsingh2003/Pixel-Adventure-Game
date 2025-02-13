import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  hit,
  fall,
  doubleJumping,
  wallJumping
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler {
  String character;

  Player({
    position,
    this.character = "Ninja Frog",
  }) : super(position: position);

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumping;
  late final SpriteAnimation wallJumping;
  late final SpriteAnimation doubleJumping;
  late final SpriteAnimation hit;
  late final SpriteAnimation fall;
  final double stepTime = 0.05;

  late double horizonatallyMovement;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isFacingRight = true;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    updatePlayerState();
    updatePlayerMovement(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizonatallyMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);

    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizonatallyMovement += isLeftKeyPressed ? -1 : 0;
    horizonatallyMovement += isRightKeyPressed ? 1 : 0;

    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumping = _spriteAnimation('Jump', 1);
    hit = _spriteAnimation('Hit', 7);
    wallJumping = _spriteAnimation('Wall Jump', 5);
    fall = _spriteAnimation('Fall', 5);
    doubleJumping = _spriteAnimation('Double Jump', 5);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumping,
      PlayerState.hit: hit,
      PlayerState.wallJumping: wallJumping,
      PlayerState.fall: fall,
      PlayerState.doubleJumping: doubleJumping,
    };

    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  void updatePlayerMovement(double dt) {
    velocity.x = horizonatallyMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void updatePlayerState() {
    PlayerState playerState = PlayerState.idle;
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;
    current = playerState;
  }
}
