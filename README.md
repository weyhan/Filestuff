# Filestuff

A Swift framework for reading and managing directory trees that is suitable for building a Finder-style file browser interface.

## Overview

A Filestuff object lets you read the contents of a directory along with the metadata for the directory and its contents. To build a Finder-style file browser interface, the `Directory` object could be used directly as your data source for the `UITableView` or `UICollectionView` or, if desired, you can create a wrapper around the `Directory` object to format the data for display or manipulate the data in any way necessary. 

If the directory loader is not extended, the default set of metadata will be loaded upon reading the directory's content. To load metadata not included in the default set, you can add additional metadata to be loaded and extend the `FilestuffContainer` to expose the extra metadata for your consumption.

## Getting Started

### Installation

_Note: There are no plans to support Carthage or CocoaPods package managers._

#### Swift Package

[Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code.

##### For Swift Package Project

After you set up your Package.swift manifest file in your project, you can add Filestuff as a dependency by adding it to your Package.swift dependencies value.

```
dependencies: [ .package(url: "https://github.com/weyhan/Filestuff.git", from: "1.0.0") ]
```

##### For Xcode Project

1. Using Xcode 11 or above, go to `File` > `Add Package Dependencies…`.
1. Paste the project URL: `https://github.com/weyhan/Filestuff.git` in the search field.
1. Select the project target from the search result list if not already selected.
1. Configure the dependency rules to your preferences.
1. Click `Add Package` to add Filestuff to your project.

_Note: The `Add Package Dependencies` interface could change from version to version of Xcode._

#### Git Submodule

On the `Terminal.app`, go to the root folder of the git repository you want to add the Filestuff framework and then add the submodule folder.

```
git submodule add https://github.com/weyhan/filestuff.git
git submodule init
git submodule update
```

To add Filestuff to your project, locate the project file `Filestuff.xcodeproj` on Finder and drag it into your project's Xcode Project Navigator pane.

#### Build From Source

On the `Terminal.app`, type the following command to clone the Filestuff repository and build:

```
git clone https://github.com/weyhan/filestuff.git
cd filestuff
source build-xcframework.sh
```

The resulting framework file `Filestuff.xcframework` will be placed in the `build` directory.

To add Filestuff to your project, locate the framework file `Filestuff.xcframework` on Finder and drag it into your project's Xcode Project Navigator pane.

## Usage

#### Importing Filestuff

To start using Filestuff, import the Filestuff framework in the source file.

```
import Filestuff
```

#### Reading Directory Content

There are two modes of reading directories.

* Shallow read (default):

```
let homeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent()

do {
	let directory = try Directory.load(url: homeUrl)
} catch {
	// Handle error
}
```

Example result of shallow read where "…" is not read:

```
.
├── Documents
│   └── …
├── Library
│   └── …
├── SystemData
└── tmp
```

* Deep read:

```
let homeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent()

do {
	let directory = try Directory.load(url: homeUrl, shallow: false)
} catch {
	// Handle error
}
```

Example result of deep read where the whole tree is loaded:

```
.
├── Documents
│   ├── mytext.txt
│   ├── presentation.pdf
│   └── settings.json
├── Library
│   ├── Caches
│   ├── Preferences
│   └── Saved Application State
│       └── com.myapp.savedState
│           └── KnownSceneSessions
│               └── data.data
├── SystemData
└── tmp
```

The deep read will load the whole directory tree with the following exception:

1. Will not follow into Symbolic link to a directory.
2. Will not descend into bundle or package type directories.

#### Iterating Over the Content of a Directory

Print all files and directories in the `Directory` container at the specific `URL`.

```
directory.forEach { file in 
	print("filename: \(file.name)")
}
```

#### File / Directory Attributes

* url: URL<br/> The URL value pointing to the file or directory on the filesystem where this `FilestuffContainer` represents.

* attribute: URLResourceValues<br/>The file's metadata represented as [`URLResourceValues`](https://developer.apple.com/documentation/foundation/urlresourcevalues)

* size: Int?<br/>The file’s size, in bytes.

* type: URLFileResourceType?<br/>The filesystem type as [`URLFileResourceType`](https://developer.apple.com/documentation/foundation/urlfileresourcetype).

* created: Date?<br/>The file's creation date.

* modified: Date?<br/>The file's last modified date.

* name: String<br/>The file's name.

* ext: String<br/>The file's extension.

* displayName: String<br/>The file's name without the file extension.

* path: String<br/>The file's path on the filesystem.

* isRegularFile: Bool?<br/>A `Boolean` value indicating whether the file is a regular file.

* isDirectory: Bool?<br/>A `Boolean` value indicating whether the file is a directory.

* isSymbolicLink: Bool?<br/>A `Boolean` value indicating whether the file is a symbolic link.

* contentType: UTType?<br/>The resource’s type of the file as [`UTType`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype).

* contentTypeIdentifier: String?<br/>A `String` value representation of the file's resource type.


#### Loading More Attribute

There are two ways to ask Filestuff to load additional resources from the filesystem when available.

##### Adding resource keys to the whole session

To load additional attributes while reading directories, add `URLResourceKey` using `addFileResourceKey` convenience method. e.g.:

```
FilestuffUtils.add(resourceKeys: .totalFileAllocatedSizeKey)

```

_Note: The additional keys will persist in the same session but not across sessions. In other words, the keys once added, will immediately take effect and continue to be in effect until the app quits. Any subsequent read will include the additional keys._

##### Adding resource keys to a one-time load method

To load additional attributes on a one-time basis, pass the corresponding keys to the `load` convenience method as the optional argument `extraResourceKeys`. e.g.:

```
	let homeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent()

	do {
		let directory = try Directory.load(url: homeUrl, extraResourceKeys: [isAliasFileKey])
	} catch {
		// Handle error
	}
```
_Note: See below to add access to added extra resource keys_

##### Accessing resource values loaded by adding resource keys

To access the value of the additional attributes, it is necessary to extend the `FilestuffContainer ` by adding computed properties to retrieve the value. e.g.:

```
	extension FilestuffContainer {
		var totalFileAllocatedSize: Int? { attribute.totalFileAllocatedSize } 
	}
```

It's also possible to extend `FilestuffContainer` by adding functions that accept arguments and manipulate attribute values to suit your needs.
