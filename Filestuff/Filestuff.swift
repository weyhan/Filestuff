//
//  Filestuff.swift
//  Filestuff
//
//  Created by WeyHan Ng on 03/07/2024.
//

import Foundation
import UniformTypeIdentifiers

// MARK: - FilestuffConfiguration Class

/// Internal `Filestuff` configuration object not exposed to  the other
/// parts of the `Filestuff` framework.
final fileprivate class FilestuffConfiguration: @unchecked Sendable {
    static let shared = FilestuffConfiguration()
    private init() { }

    private let lock = NSLock()

    // MARK: resourceKeys

    // Private defaults
    private static let resourceKeysDefaultSet: Set<URLResourceKey> = [
        .fileSizeKey,
        .totalFileSizeKey,
        .fileResourceTypeKey,
        .creationDateKey,
        .contentModificationDateKey,
        .isRegularFileKey,
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .contentTypeKey
    ]

    // Private storage
    private var _resourceKeys: Set<URLResourceKey> = resourceKeysDefaultSet

    /// Get only active resource keys `Set` that is thread safe to access.
    var resourceKeysSet: Set<URLResourceKey> {
        lock.withLock { _resourceKeys }
    }

    /// Get only active resource keys `Array` that is thread safe to access.
    var resourceKeysArray: [URLResourceKey] {
        lock.withLock { Array(resourceKeysSet) }
    }

    /// Thread safe convenience method to add resource keys to the active `Set`.
    func insert(resourceKeys: [URLResourceKey]) {
        lock.withLock { resourceKeys.forEach { _resourceKeys.insert($0) } }
    }

    // MARK: FileManager.DirectoryEnumerationOptions

    // Private defaults
    private static let directoryEnumerationOptionsDefault: FileManager.DirectoryEnumerationOptions = [
        .skipsSubdirectoryDescendants,
        .skipsPackageDescendants
    ]

    // Private storage
    private var _directoryEnumerationOptions = directoryEnumerationOptionsDefault

    /// Get only active enumeration options `Array` that is thread safe to access.
    var directoryEnumerationOptions: FileManager.DirectoryEnumerationOptions {
        lock.withLock { _directoryEnumerationOptions }
    }
}

// MARK: - Filestuff Class

/// Filestuff namespace to collect `Filestuff` convenience methods.
///
/// The classname is now `FilestuffUtils` because of the bug in Swift now.
/// See [Bug SR-14195](https://github.com/apple/swift/issues/56573).
///
/// - Note: When this bug is fixed in the future release of Swift,
/// `FilestuffUtils` will be renamed to `Filestuff` as it is originally
/// intended.

// TODO: Migrate FilestuffUtils to Filestuff
//   Replace FilestuffUtils class line with below to migrate to final name.
//
//@available(*, unavailable, renamed: "Filestuff")
//public class FilestuffUtils {
//    public static func addFileResourceKey(keys: [URLResourceKey]) {}
//    public static var filestuffResourceKeys: [URLResourceKey] = []
//}
//
//public class Filestuff {

public class FilestuffUtils {
    private init() {}

    /// Adds `URLResourceKey` to default set of keys for loading file
    /// attributes.
    ///
    /// - Parameters:
    ///   - resourceKeys: Array of `URLResourceKey` to add
    ///
    /// Keys added will persist until the app exits. While the app is
    /// still running, the additional keys will take effect for all
    /// `Directory.load(url:)` calls to read directories.
    public static func add(resourceKeys keys: [URLResourceKey]) {
        FilestuffConfiguration.shared.insert(resourceKeys: keys)
    }

    // TODO: Add reset and/or remove methods to remove additional keys added.

    /// The `Set` of resource keys to tell `Filestuff` which metadata to cache when
    /// reading file or directory.
    ///
    /// This `Set` of
    /// [`URLResourceKey`](https://developer.apple.com/documentation/foundation/urlresourcekey)
    /// tells `Filestuff` which metadata to cache when reading files or directories.
    public static var resourceKeysSet: Set<URLResourceKey> { FilestuffConfiguration.shared.resourceKeysSet }

    /// The `Array` of resource keys to tell `Filestuff` which metadata to cache
    /// when reading file or directory.
    ///
    /// Converts `FilestuffUtils.resourceKeysSet` to an `Array` of `URLResourceKey` for
    /// convenience when calling methods or functions that requires an `Array` of
    /// [`URLResourceKey`](https://developer.apple.com/documentation/foundation/urlresourcekey)
    /// as its argument.
    public static var resourceKeysArray: [URLResourceKey] { FilestuffConfiguration.shared.resourceKeysArray }

    /// An `Array` of `DirectoryEnumerationOptions` that `Filestuff` enumeration
    /// uses when enumerating directories content.
    ///
    /// The `filestuffDirectoryEnumerationOptions` `Array` contains the
    /// following options:
    ///   - [`skipsSubdirectoryDescendants`](https://developer.apple.com/documentation/foundation/filemanager/directoryenumerationoptions/1410021-skipssubdirectorydescendants)
    ///   - [`skipsPackageDescendants`](https://developer.apple.com/documentation/foundation/filemanager/directoryenumerationoptions/1410344-skipspackagedescendants)
    ///
    /// - Note: `Filestuff` will not decend into any packages and treats packages as one file.
    ///
    /// - Note: Future consideration to allow changing the enumeration options.
    public static var directoryEnumerationOptions: FileManager.DirectoryEnumerationOptions {
        FilestuffConfiguration.shared.directoryEnumerationOptions
    }
}

// MARK: - Firestuff Throw Targets

/// The throw targets for all `Filestuff` methods that throws.
public enum FilestuffError: Error {
    /// No file were found at the location provided.
    case fileNotFound

    /// The file is found in the provided location but it is not a directory
    /// where a directory is expected for the operation.
    case isNotDirectory

    /// The file is found in the provided location but it is not a regular file
    /// where a regular file is expected for the operation.
    case isNotFile

    /// An unspecified error occurred while reading the content of a directory.
    case errorReadingDirectoryContent
}

// MARK: - Firestuff Protocol
/// Properties that represents a file metadata for all `Firestuff` type
/// containers.
public protocol FilestuffContainer {
    /// The URL value pointing to the file or directory on the filesystem
    /// where this `FilestuffContainer` represents.
    var url: URL { get }

    /// The file's metadata represented as [`URLResourceValues`](https://developer.apple.com/documentation/foundation/urlresourcevalues)
    var attribute: URLResourceValues { get }

    /// The file’s size, in bytes.
    var size: Int? { get }

    /// The filesystem type as [`URLFileResourceType`](https://developer.apple.com/documentation/foundation/urlfileresourcetype).
    var type: URLFileResourceType? { get }

    /// The file's creation date.
    var created: Date? { get }

    /// The file's last modified date.
    var modified: Date? { get }

    /// The file's name.
    var name: String { get }

    /// The file's extension.
    var ext: String { get }

    /// The file's name without the file extension.
    var displayName: String { get }

    /// The file's path on the filesystem.
    var path: String { get }

    /// A `Boolean` value indicating whether the file is a regular file.
    var isRegularFile: Bool? { get }

    /// A `Boolean` value indicating whether the file is a directory.
    var isDirectory: Bool? { get }

    /// A `Boolean` value indicating whether the file is a symbolic link.
    var isSymbolicLink: Bool? { get }

    /// The resource’s type of the file as [`UTType`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype).
    var contentType: UTType? { get }

    /// A `String` value representation of the file's resource type.
    var contentTypeIdentifier: String? { get }
}

// MARK: - Filestuff Default (Common) Implementation
public extension FilestuffContainer {
    var size: Int? { attribute.totalFileSize }
    var type: URLFileResourceType? { attribute.fileResourceType }
    var created: Date? { attribute.creationDate }
    var modified: Date? { attribute.contentModificationDate }
    var ext: String { url.pathExtension }
    var name: String { url.lastPathComponent }
    var displayName: String { url.deletingPathExtension().lastPathComponent }
    var path: String { url.path() }

    var isRegularFile: Bool? { attribute.isRegularFile }
    var isDirectory: Bool? { attribute.isDirectory }
    var isSymbolicLink: Bool? { attribute.isSymbolicLink }

    var contentType: UTType? { attribute.contentType }
    var contentTypeIdentifier: String? {
        guard let type = attribute.contentType else { return nil }
        return "\(type)"
    }
}
