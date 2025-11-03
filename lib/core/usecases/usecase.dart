import 'package:ai_rewards_system/core/errors/failures.dart';
import 'package:ai_rewards_system/core/utils/either.dart';

/// Base class for all use cases in the application.
/// 
/// Use cases represent application-specific business rules and orchestrate
/// the flow of data between entities and repositories. Each use case should
/// have a single responsibility and be independent of other use cases.
/// 
/// Type parameters:
/// - [Type]: The return type of the use case
/// - [Params]: The parameters required by the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters.
  /// 
  /// Returns [Either<Failure, Type>]:
  /// - Left: [Failure] if the operation fails
  /// - Right: [Type] if the operation succeeds
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require any parameters.
/// 
/// Type parameters:
/// - [Type]: The return type of the use case
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters.
  /// 
  /// Returns [Either<Failure, Type>]:
  /// - Left: [Failure] if the operation fails
  /// - Right: [Type] if the operation succeeds
  Future<Either<Failure, Type>> call();
}

/// Stream-based use case for operations that return streams.
/// 
/// Type parameters:
/// - [Type]: The stream element type
/// - [Params]: The parameters required by the use case
abstract class StreamUseCase<Type, Params> {
  /// Execute the use case and return a stream of results.
  /// 
  /// The stream should handle errors internally and emit appropriate
  /// success or failure states through the stream mechanism.
  Stream<Type> call(Params params);
}

/// Stream-based use case that doesn't require parameters.
/// 
/// Type parameters:
/// - [Type]: The stream element type
abstract class NoParamsStreamUseCase<Type> {
  /// Execute the use case and return a stream of results.
  /// 
  /// The stream should handle errors internally and emit appropriate
  /// success or failure states through the stream mechanism.
  Stream<Type> call();
}