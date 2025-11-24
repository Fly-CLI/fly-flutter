import 'package:fly_cli/src/cli/domain/interfaces/i_service_container.dart';
import 'package:fly_cli/src/generation/application/ports/icache_manager.dart';
import 'package:fly_cli/src/generation/application/ports/igeneration_engine.dart';
import 'package:fly_cli/src/generation/application/ports/ivariable_processor.dart';
import 'package:fly_cli/src/generation/application/ports/iworkflow_orchestrator.dart';
import 'package:fly_cli/src/generation/domain/repositories/ibrick_repository.dart';
import 'package:fly_cli/src/generation/domain/repositories/itemplate_repository.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/ifile_system_adapter.dart';
import 'package:fly_cli/src/generation/infrastructure/adapters/imason_adapter.dart';

/// Service container specifically for generation module dependencies.
///
/// Extends the base service container with generation-specific
/// registration and retrieval methods.
class GenerationServiceContainer {
  GenerationServiceContainer(this._baseContainer);

  final IServiceContainer _baseContainer;

  /// Register brick repository implementation.
  void registerBrickRepository(IBrickRepository repository) {
    _baseContainer.registerSingleton<IBrickRepository>(repository);
  }

  /// Register template repository implementation.
  void registerTemplateRepository(ITemplateRepository repository) {
    _baseContainer.registerSingleton<ITemplateRepository>(repository);
  }

  /// Register generation engine implementation.
  void registerGenerationEngine(IGenerationEngine engine) {
    _baseContainer.registerSingleton<IGenerationEngine>(engine);
  }

  /// Register variable processor implementation.
  void registerVariableProcessor(IVariableProcessor processor) {
    _baseContainer.registerSingleton<IVariableProcessor>(processor);
  }

  /// Register workflow orchestrator implementation.
  void registerWorkflowOrchestrator(IWorkflowOrchestrator orchestrator) {
    _baseContainer.registerSingleton<IWorkflowOrchestrator>(orchestrator);
  }

  /// Register cache manager implementation.
  void registerCacheManager<T>(ICacheManager<T> cacheManager) {
    _baseContainer.registerSingleton<ICacheManager<T>>(cacheManager);
  }

  /// Register Mason adapter implementation.
  void registerMasonAdapter(IMasonAdapter adapter) {
    _baseContainer.registerSingleton<IMasonAdapter>(adapter);
  }

  /// Register file system adapter implementation.
  void registerFileSystemAdapter(IFileSystemAdapter adapter) {
    _baseContainer.registerSingleton<IFileSystemAdapter>(adapter);
  }

  /// Get brick repository.
  IBrickRepository getBrickRepository() {
    return _baseContainer.get<IBrickRepository>();
  }

  /// Get template repository.
  ITemplateRepository getTemplateRepository() {
    return _baseContainer.get<ITemplateRepository>();
  }

  /// Get generation engine.
  IGenerationEngine getGenerationEngine() {
    return _baseContainer.get<IGenerationEngine>();
  }

  /// Get variable processor.
  IVariableProcessor getVariableProcessor() {
    return _baseContainer.get<IVariableProcessor>();
  }

  /// Get workflow orchestrator.
  IWorkflowOrchestrator getWorkflowOrchestrator() {
    return _baseContainer.get<IWorkflowOrchestrator>();
  }

  /// Get cache manager.
  ICacheManager<T> getCacheManager<T>() {
    return _baseContainer.get<ICacheManager<T>>();
  }

  /// Get Mason adapter.
  IMasonAdapter getMasonAdapter() {
    return _baseContainer.get<IMasonAdapter>();
  }

  /// Get file system adapter.
  IFileSystemAdapter getFileSystemAdapter() {
    return _baseContainer.get<IFileSystemAdapter>();
  }

  /// Check if a service is registered.
  bool isRegistered<T>() => _baseContainer.isRegistered<T>();
}

