//
//  Directory.swift
//  Filestuff
//
//  Created by WeyHan Ng on 03/07/2024.
//

import Foundation

/// # Directory
/// A value that holds `File` and `Directory` containers and the cached metadata representing directories, it's contents and
/// it's structures.
public struct Directory: FilestuffContainer {
    public var url: URL
    public var attribute: URLResourceValues

    /// An array of `FilestuffContainer` that stores the list of files and/or directories belonging to a directory on the
    /// filesystem.
    public var content: [FilestuffContainer]
}

// MARK: - Directory Factory
extension Directory {

    /// Returns a `Directory` container that holds the content of the directory at the specified `URL`.
    ///
    /// - Parameters:
    ///   - url: The location of the directory to load.
    ///       This `URL` must not be a symbolic link that points to the desired directory.
    ///       You can use the [`resolvingSymlinksInPath`](https://developer.apple.com/documentation/foundation/nsurl/1415965-resolvingsymlinksinpath)
    ///       method to resolve any symlinks in the `URL`.
    ///
    ///   - shallow: An optional `Boolean` to determine if this method will perform a shallow or a deep load. Default is to load
    ///       shallowly.
    ///
    /// - Returns: A `Directory` container that contains the list of files in the directory at the specified `URL`.
    ///     The default set of the metadata for the containing directory and the list of files will be loaded at the same time.
    ///     When performing a shallow load, all items in the directory will be captured in a `File` container even if the item
    ///     is a directory.
    ///
    /// When performing a shallow load, the items in the directory will be loaded into `File` containers regardless if the items are
    /// files or a directories. To distinguish files from directories, test the `File` parameters `.isFile`,
    /// `.isDirectory` or examine the `.contentType` property for detailed file type info.
    ///
    /// When performing a deep load, directories will be loaded into `Directory` containers while all other file types will be loaded
    /// into `File` containers. The main difference between `File` containers and `Directory` containers is that `Directory`
    /// containers has an extra property `content` to store an array of `Filestuff` type containers.
    ///
    /// > Note: Files or directories will be skipped if an error occurred when retrieving metadata or loading subdirectories. Other
    ///     unrecoverable error will cause this method to throw and error.
    ///
    ///     Additionally, regardless of loading deeply or shallowly, this method will not decent into packages, i.e. bundles (special
    ///     directories that are treated as a single file by the OS UI).
    public static func load(url: URL, shallow: Bool = true) throws -> Directory {
        return try load(url: url, attribute: nil, shallow: shallow)
    }

    /// Returns a `Directory` container that holds the content of the directory at the specified `URL`.
    ///
    /// - Parameters:
    ///   - url: The location of the directory to load.
    ///       This `URL` must not be a symbolic link that points to the desired directory.
    ///       You can use the [`resolvingSymlinksInPath`](https://developer.apple.com/documentation/foundation/nsurl/1415965-resolvingsymlinksinpath)
    ///       method to resolve any symlinks in the `URL`.
    ///
    ///   - attribute: An optional `URLResourceValues` value that contains the metadata of the directory at the
    ///       specified `URL`.
    ///       If `nil` is specified for this parameter, this method will fetch the metadata from the file system.
    ///       This parameter is not validated for accuracy therefore it is up to the caller to provide the accurate metadata
    ///       set corresponding to the directory at the specified `URL`.
    ///
    ///   - shallow: An optional `Boolean` to determine if this method will perform a shallow or a deep load. Default is to load
    ///       shallowly.
    ///
    /// - Returns: A `Directory` container that contains the list of files in the directory at the specified `URL`.
    ///     The default set of the metadata for the containing directory and the list of files will be loaded at the same time.
    ///     When performing a shallow load, all items in the directory will be captured in a `File` container even if the item
    ///     is a directory.
    ///
    /// When performing a shallow load, the items in the directory will be loaded into `File` containers regardless if the items are
    /// files or a directories. To distinguish files from directories, test the `File` parameters `.isFile`,
    /// `.isDirectory` or examine the `.contentType` property for detailed file type info.
    ///
    /// When performing a deep load, directories will be loaded into `Directory` containers while all other file types will be loaded
    /// into `File` containers. The main difference between `File` containers and `Directory` containers is that `Directory`
    /// containers has an extra property `content` to store an array of `Filestuff` type containers.
    ///
    /// > Note: Files or directories will be skipped if an error occurred when retrieving metadata or loading subdirectories. Other
    ///     unrecoverable error will cause this method to throw and error.
    ///
    ///     Additionally, regardless of loading deeply or shallowly, this method will not decent into packages, i.e. bundles (special
    ///     directories that are treated as a single file by the OS UI).
    fileprivate static func load(url: URL, attribute: URLResourceValues?, shallow: Bool = true) throws -> Directory {
        let fileManager = FileManager.default

        var isDirectory : ObjCBool = false
        let fileExist = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

        guard fileExist else { throw FilestuffError.fileNotFound }
        guard isDirectory.boolValue == true else { throw FilestuffError.isNotDirectory }

        let directoryEnumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: filestuffResourceKeysArray,
            options: filestuffDirectoryEnumerationOptions
        )

        guard let directoryEnumerator = directoryEnumerator else {
            throw FilestuffError.errorReadingDirectoryContent
        }

        // TODO: Insert special error containers in case of errors reading files or directories.
        var content = [FilestuffContainer]()
        for case let fileUrl as URL in directoryEnumerator {
            let resourceValues = try? fileUrl.resourceValues(forKeys: filestuffResourceKeysSet)
            guard let resourceValues = resourceValues else { continue }   // Keep going on error

            // Decide to use File or Directory container based on the following:
            //   * When shallow load, use File container even for directories.
            //   * When deep load, use Directory container for directories, all others use File container.
            if shallow == true || (shallow == false && resourceValues.isDirectory == false) {
                content.append(File(url: fileUrl, attribute: resourceValues))

            } else {
                guard let directory = try? Directory.load(url: fileUrl, attribute: resourceValues) else { continue }   // Keep going on error

                content.append(directory)
            }
        }

        let attribute = try attribute ?? url.resourceValues(forKeys: filestuffResourceKeysSet)

        return Directory(url: url, attribute: attribute, content: content)
    }
}

// MARK: - Convenient Content Access
extension Directory {
    public var contentCount: Int { content.count }
    public subscript(index: Int) -> FilestuffContainer? {
        (0...content.count).contains(index) ? content[index] : nil
    }
}
