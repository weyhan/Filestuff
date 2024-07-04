//
//  FilestuffContainer.swift
//  Filestuff
//
//  Created by WeyHan Ng on 03/07/2024.
//

import Foundation
import UniformTypeIdentifiers

/// A `Set` of `URLResourceKey` that will be cached in `Filestuff` containers.
///
/// This `Set` of `URLResourceKey` is the only file metadata that will be cached for now.
///
/// > Note: Current there is no way to extend this set without releasing a new version of the `Filestuff` framework.
internal let filestuffResourceKeysSet: Set<URLResourceKey> = [
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

/// Convert `Set` value `filestuffResourceKeysSet` to `Array` value of `filestuffResourceKeys` for convenience
/// when calling methods that requires an `Array` of `URLResourceKey` as argument.
internal var filestuffResourceKeysArray: Array<URLResourceKey> { Array(filestuffResourceKeysSet) }

/// An `Array` of `DirectoryEnumerationOptions` that `Filestuff` enumeration uses where enumerating directories
/// content. These options are included in the array:
///   - [`skipsSubdirectoryDescendants`]{https://developer.apple.com/documentation/foundation/filemanager/directoryenumerationoptions/1410021-skipssubdirectorydescendants}
///   - [`skipsPackageDescendants`](https://developer.apple.com/documentation/foundation/filemanager/directoryenumerationoptions/1410344-skipspackagedescendants)
///
/// The enumeration operation in `Filestuff` will skips subdirectory descendants and skips package descendants.
internal let filestuffDirectoryEnumerationOptions: FileManager.DirectoryEnumerationOptions = [
    .skipsSubdirectoryDescendants,
    .skipsPackageDescendants
]

// MARK: - Firestuff Throw Targets
/// A `Error` `enum` that is the throw targets for all `Filestuff` methods that throws.
public enum FilestuffError: Error {
    /// The no file were found at the location provided.
    case fileNotFound

    /// The file is found in the provided location but it is not a directory where a directory is required for the operation.
    case isNotDirectory

    /// The file is found in the provided location but it is not a regular file where a regular file is required for the operation.
    case isNotFile

    /// An error occurred while reading the content of a directory.
    case errorReadingDirectoryContent
}

// MARK: - Firestuff Protocol
/// Properties that represents a file metadata for all `Firestuff`type  containers.
public protocol FilestuffContainer {
    /// The URL value pointing to the file or directory on the filesystem where this `FilestuffContainer` represents.
    var url: URL { get }

    /// The file's metadata represented as [`URLResourceValues`](https://developer.apple.com/documentation/foundation/urlresourcevalues)
    var attribute: URLResourceValues { get }

    /// The file’s size, in bytes.
    var size: Int? { get }

    /// The file's filesystem type represented as optional [`URLFileResourceType`](https://developer.apple.com/documentation/foundation/urlfileresourcetype).
    var type: URLFileResourceType? { get }

    /// The file's creation date.
    var created: Date? { get }

    /// The file's last modified date.
    var modified: Date? { get }

    /// The file's filename.
    var name: String { get }

    /// The file's extension.
    var ext: String { get }

    /// The file's filename without the file extension.
    var displayName: String { get }

    /// The file's path on the filesystem.
    var path: String { get }

    /// A Boolean value indicating whether the file is a regular file.
    var isRegularFile: Bool? { get }

    /// A Boolean value indicating whether the file is a directory.
    var isDirectory: Bool? { get }

    /// A Boolean value indicating whether the file is a symbolic link.
    var isSymbolicLink: Bool? { get }

    /// The resource’s type of the file represented as optional [`UTType`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype).
    var contentType: UTType? { get }

    /// A String value representation of the file's resource type.
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