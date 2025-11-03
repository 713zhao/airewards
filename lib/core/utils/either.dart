/// Functional programming Either type for error handling
abstract class Either<L, R> {
  const Either();

  /// Create a Left (error) instance
  factory Either.left(L value) = Left<L, R>;

  /// Create a Right (success) instance
  factory Either.right(R value) = Right<L, R>;

  /// Check if this is a Left (error) instance
  bool get isLeft => this is Left<L, R>;

  /// Check if this is a Right (success) instance
  bool get isRight => this is Right<L, R>;

  /// Get the Left value (throws if Right)
  L get left {
    if (this is Left<L, R>) {
      return (this as Left<L, R>).value;
    }
    throw StateError('Either is Right, not Left');
  }

  /// Get the Right value (throws if Left)
  R get right {
    if (this is Right<L, R>) {
      return (this as Right<L, R>).value;
    }
    throw StateError('Either is Left, not Right');
  }

  /// Transform the right value if present
  Either<L, T> map<T>(T Function(R) mapper) {
    if (isRight) {
      return Either.right(mapper(right));
    }
    return Either.left(left);
  }

  /// Transform the left value if present
  Either<T, R> mapLeft<T>(T Function(L) mapper) {
    if (isLeft) {
      return Either.left(mapper(left));
    }
    return Either.right(right);
  }

  /// Chain operations on the right value
  Either<L, T> flatMap<T>(Either<L, T> Function(R) mapper) {
    if (isRight) {
      return mapper(right);
    }
    return Either.left(left);
  }

  /// Fold both sides into a single value
  T fold<T>(T Function(L) leftMapper, T Function(R) rightMapper) {
    if (isLeft) {
      return leftMapper(left);
    }
    return rightMapper(right);
  }

  /// Execute action on right value (returns this)
  Either<L, R> onRight(void Function(R) action) {
    if (isRight) {
      action(right);
    }
    return this;
  }

  /// Execute action on left value (returns this)
  Either<L, R> onLeft(void Function(L) action) {
    if (isLeft) {
      action(left);
    }
    return this;
  }

  /// Get right value or return default
  R getOrElse(R defaultValue) {
    return isRight ? right : defaultValue;
  }

  /// Get right value or compute default
  R getOrElseGet(R Function() defaultValueProvider) {
    return isRight ? right : defaultValueProvider();
  }
}

/// Left (error) side of Either
class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left<L, R> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

/// Right (success) side of Either
class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right<L, R> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}