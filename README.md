# Filestuff

Filestuff is a Swift framework to read and manage a directory tree suitable for building a file explorer interface.

## Getting Started

### Installation

Currently there is no plans to support Carthage or CocoaPods package managers.

#### Swift Package

_Currently under development._

#### Git Submodule

On the Terminal.app, go to the root folder of the git repository you want to add Filestuff framework and then add the submodule folder.

```
git submodule add https://github.com/weyhan/filestuff.git
git submodule init
git submodule update
```

To add Filestuff into your project, locate on Finder and drag `Filestuff.xcodeproj` into your project's Xcode Project Navigator pane.

#### Build From Source

On the Terminal.app, type the following command to clone the Filestuff repository and build:

```
git clone https://github.com/weyhan/filestuff.git
cd filestuff
source build-xcframework.sh
```

The `Filestuff.xcframework` is in the `build` directory.

To add Filestuff into your project, locate in Finder and drag `Filestuff.xcframework` into your project's Xcode Project Navigator pane.

## Usage

#### Importing Filestuff

To start using Filestuff, import the Filestuff framework in the source file.

```
import Filestuff
```

#### Reading Directory Content

There are two mode of reading directories.

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
│       └── com.hla.fast.savedState
│           └── KnownSceneSessions
│               └── data.data
├── SystemData
└── tmp
```

The deep read will load the whole directory tree with the following exception:

1. Will not follow into Symbolic link to a directory.
2. Will not descend into Bundle/package type directory.

#### Iterating Over the Content of a Directory

Print all files and directories contained in the `Directory` container at the specific `URL`.

```
	directory.forEach { file in 
		print("filename: \(file.name)")
	}
```

#### File / Directory Attributes



* url: URL<br/> The URL value pointing to the file or directory on the filesystem where this `FilestuffContainer` represents.

* attribute: URLResourceValues<br/>The file's metadata represented as [`URLResourceValues`](https://developer.apple.com/documentation/foundation/urlresourcevalues)

* size: Int?<br/>The file’s size, in bytes.

* type: URLFileResourceType?<br/>The file's filesystem type represented as optional [`URLFileResourceType`](https://developer.apple.com/documentation/foundation/urlfileresourcetype).

* created: Date?<br/>The file's creation date.

* modified: Date?<br/>The file's last modified date.

* name: String<br/>The file's filename.

* ext: String<br/>The file's extension.

* displayName: String<br/>The file's filename without the file extension.

* path: String<br/>The file's path on the filesystem.

* isRegularFile: Bool?<br/>A `Boolean` value indicating whether the file is a regular file.

* isDirectory: Bool?<br/>A `Boolean` value indicating whether the file is a directory.

* isSymbolicLink: Bool?<br/>A `Boolean` value indicating whether the file is a symbolic link.

* contentType: UTType?<br/>The resource’s type of the file represented as optional [`UTType`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype).

* contentTypeIdentifier: String?<br/>A `String` value representation of the file's resource type.


#### Loading More Attribute

##### Extending Filestuff

To load additional attributes while reading directories, add `URLResourceKey` using `addFileResourceKey` convenience method. e.g.:

```
	FilestuffUtils.addFileResourceKey(key: .totalFileAllocatedSizeKey)

```

_Note: The additional keys will persist in the same session but not across session. In other words, the additional keys will take effect right after adding the keys untill the app quits._

To load additional attributes on a one-off basis, pass the additional keys to the `load` convenience method as the optional argument `extraResourceKeys`. e.g.:

```
	let homeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent()

	do {
		let directory = try Directory.load(url: homeUrl, extraResourceKeys: [isAliasFileKey])
	} catch {
		// Handle error
	}
```
_Note: See below to add access to added extra resource keys_


To access the additional attributes values, it is nessary to extend the `FilestuffContainer ` by adding computed properties to retrieve the value. e.g.:

```
	extension FilestuffContainer {
		var totalFileAllocatedSize: Int? { attribute.totalFileAllocatedSize } 
	}
```

It's also possible to extend `FilestuffContainer` by adding functions that accepts arguments and manupelate the attributes values to suite your needs.