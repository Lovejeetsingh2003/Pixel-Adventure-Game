import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  hit,
  fall,
  doubleJumping,
  wallJumping,
  appearing,
  disappearing,
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  String character;

  Player({
    position,
    this.character = "Ninja Frog",
  }) : super(position: position);
  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumping;
  late final SpriteAnimation wallJumping;
  late final SpriteAnimation doubleJumping;
  late final SpriteAnimation hit;
  late final SpriteAnimation fall;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;

  final double gravity = 9.8;
  final double jumpForce = 260;
  final double terminalVelocity = 300;
  late double horizonatallyMovement = 0;
  bool isOnGround = false;
  bool hasJump = false;
  bool gotHit = false;
  bool recahedCkeckpoint = false;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isFacingRight = true;
  List<CollisionBlock> collisionBlock = [];
  Vector2 startingPosition = Vector2.zero();

  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    height: 28,
    width: 14,
  );

  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();

    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !recahedCkeckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisons();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }
    }
    accumulatedTime -= fixedDeltaTime;

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

    hasJump = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!recahedCkeckpoint) {
      if (other is Fruit) other.collidedWithPlayer();
      if (other is Saw) _respawn();
      if (other is Checkpoint) _reachedCheckpoint();
    }

    super.onCollision(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumping = _spriteAnimation('Jump', 1);
    hit = _spriteAnimation('Hit', 7);
    wallJumping = _spriteAnimation('Wall Jump', 5);
    fall = _spriteAnimation('Fall', 5);
    doubleJumping = _spriteAnimation('Double Jump', 5);
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Desappearing', 7);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumping,
      PlayerState.hit: hit,
      PlayerState.wallJumping: wallJumping,
      PlayerState.fall: fall,
      PlayerState.doubleJumping: doubleJumping,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
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

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$state (96x96).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
      ),
    );
  }

  void _updatePlayerMovement(double dt) {
    if (hasJump && isOnGround) _playerJump(dt);

    // if (velocity.y > gravity) isOnGround = false; // for jump

    velocity.x = horizonatallyMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    velocity.y = -jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJump = false;
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

// check if falling
    if (velocity.y > 0) playerState = PlayerState.fall;

// check if jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;
    current = playerState;
  }

  void _checkHorizontalCollisons() {
    for (final block in collisionBlock) {
      //handle collision of charcaters with blocks and ground
      if (!block.isPlatform) {
        if (checkCollisions(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += gravity;
    velocity.y = velocity.y.clamp(-jumpForce, terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlock) {
      if (block.isPlatform) {
        if (checkCollisions(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollisions(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height + hitbox.offsetY;
          }
        }
      }
    }
  }

  void _respawn() {
    const hitDuration = Duration(milliseconds: 350);
    const appearingDuration = Duration(milliseconds: 350);
    const canMoveDuration = Duration(milliseconds: 400);
    gotHit = true;
    current = PlayerState.hit;
    Future.delayed(
      hitDuration,
      () {
        scale.x = 1;
        position = startingPosition - Vector2.all(32);
        current = PlayerState.appearing;
        Future.delayed(appearingDuration, () {
          velocity = Vector2.zero();
          position = startingPosition;
          _updatePlayerState();
        });
        Future.delayed(
          canMoveDuration,
          () => gotHit = false,
        );
      },
    );
  }

  void _reachedCheckpoint() {
    recahedCkeckpoint = true;
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;

    const reachedCheckpointDuration = Duration(milliseconds: 350);

    Future.delayed(
      reachedCheckpointDuration,
      () {
        recahedCkeckpoint = false;
        position = Vector2.all(-640);
        const waitToChangeDuration = Duration(seconds: 3);
        Future.delayed(
          waitToChangeDuration,
          () {
            //switch to next level
            game.loadNextLevel();
          },
        );
      },
    );
  }
}
