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
