/// Unified file operations infrastructure for Fly CLI
/// 
/// Provides consistent file I/O operations that can be used across
/// all packages in the Fly CLI ecosystem.
/// 
/// Features:
/// - Streaming support for large files
/// - Atomic writes for safe file operations
/// - Caching with TTL
/// - Directory management utilities
/// - Checksum calculation
library file_operations;

export 'checksum_calculator.dart';
export 'directory_manager.dart';
export 'file_cache.dart';
export 'file_reader.dart';
export 'file_writer.dart';

