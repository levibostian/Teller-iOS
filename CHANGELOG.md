## [0.7.0] - 01-03-2020

### Added 
- Enable or disable automatic refresh in a Repository. [Issue](https://github.com/levibostian/Teller-iOS/issues/83)
- Assert that a cache exists, or refresh. [Issue](https://github.com/levibostian/Teller-iOS/issues/82)

## [0.6.0] - 12-23-19

### Added
- Convert instances of `DataState` to another data type with `convert()`

### Fixed
- Allow `DataSource` instances to define Error type from fetching

## [0.5.1] - 12-20-19

### Fixed
- Cache state machine crash, traveling to incorrect node. [Issue](https://github.com/levibostian/Teller-iOS/issues/64)

### Changed 
- Repository internal refresh calls added to Rx dispose bag to cancel on deinit. 

## [0.5.0] - 11-25-19

### Added 
- Utilities to write integration tests against Teller
- Pre-built mock for Repository for unit testing

### Changed
- **Breaking Change** Changed DataState parsing switch statement to more simple API.
- **Breaking Change** Remove need to subclass Repository in API!
- **Breaking Change** Remove all local functionality. Teller only caches network fetches now. 

## [0.4.0-alpha] - 7-24-19

### Changed 
- **Breaking Change** Switch to using Swift5's Result object in API. This (hopefully) concludes the Swift5 conversion. 

## [0.3.1-alpha] - 7-19-19

### Fixed 
- Fix crash when localdatastate none [#55](https://github.com/levibostian/Teller-iOS/issues/55)

## [0.3.0-alpha] - 7-5-19

### Changed
- Compile Teller with Swift5 and XCode 10.2

## [0.2.2-alpha] - 3-19-2019

Fixed crash when delivering the OnlineCacheState when state of cache is none.

### Fixed 
- Fixed crash when calling `OnlineCacheState.cacheState()` when cache state is none. 

## [0.2.1-alpha] - 2-7-2019

Fixed crash in OnlineRepository after first fetch is completed successfully. Do not use 0.2.0-alpha, use this release instead. 

### Fixed 
- Fixed https://github.com/levibostian/Teller-iOS/issues/45

## [0.2.0-alpha] - 2-3-2019

Changes to the API. Thread safety and bug fixes. 

### Changed
- **Breaking Change** `OnlineRepository`'s `sync()` has been renamed to `refresh()`. 
- **Breaking Change** `OnlineDataState.FetchingFreshDataState` has been renamed to `OnlineDataState.NoCacheState`.
- **Breaking Change** A few of the properties in `OnlineDataState` have been renamed. Even though it's best practice to use `OnlineDatatState.___State` to parse it, you can access the properties manually if you wish. 
- **Breaking Change** `OnlineRepositoryDataSource.observeCachedData()` and `OnlineRepositoryDataSource.isDataEmpty()` gets called on UI thread. `OnlineRepositoryDataSource.saveData()` gets called on background thread. https://github.com/levibostian/Teller-iOS/issues/28
- `OnlineRepository.observe()` and `LocalRepository.observe()` no longer `throws`. Observe anytime you wish and receive event updates through all changes of the repository.
- `OnlineRepository.refresh()` calls are shared in the same `OnlineRepository` instance. This saves on the amount of network calls performed. `OnlineRepository.observe()` observers are all notified when `OnlineRepository.refresh()` actions are performed. https://github.com/levibostian/Teller-iOS/issues/24
- `OnlineRepository` is thread safe. 

### Added 
- `OnlineRepository` now supports observing 2+ queries, as long as it's the same type of data. https://github.com/levibostian/Teller-iOS/issues/38
- Delete Teller data for development purposes or when someone logs out of your app and the data is cleared. https://github.com/levibostian/Teller-iOS/issues/19

# Contributors changelog 

### Changed 
- `OnlineDataState` has been refactored to using a finite state machine implementation. See `OnlineDataStateStateMachine`. It's a immutable object that represents an immutable `OnlineDataState` instance. 
- Fetching fresh cache data and the state of the cache data have been decoupled in `OnlineDataState`. Each of these 2 different states (fetching and cache) are updated independently from each other in the `OnlineRepository` so decoupling them fixes bugs that have been reported. 

### Fixed
- Fixed memory leak's in the Rx observables inside of `LocalRepository` and `OnlineRepository`. This also fixes the repositories being able to `deinit` now which results in the internal observables being disposed (the intended behavior). 
- Fixed https://github.com/levibostian/Teller-iOS/issues/20
- Fixed https://github.com/levibostian/Teller-iOS/issues/41
- Fixed https://github.com/levibostian/Teller-iOS/issues/32
- Fixed https://github.com/levibostian/Teller-iOS/issues/29

## [0.1.0-alpha] - 2018-10-04

First release of Teller! 

### Added
- `LocalRepository` for saving and querying locally cached data.
- `OnlineRepository` for saving, querying, and fetching remote data that is cached locally.
- Unit tests for all parts of the library. 
- README.md documentation on status of project and how to use it.
