//
//  Directory.swift
//  Filestuff
//
//  Created by WeyHan Ng on 03/07/2024.
//

import Foundation

/// # Directory
/// A container that loads and stores `File` and other `Directory` containers 
/// to represent a given directory and it's contents as it is on the file
/// system.
public struct Directory: FilestuffContainer {
    public var url: URL
    public var attribute: URLResourceValues

    /// An array of `FilestuffContainer` that stores a list of files and/or
    ///  directories containers.
    private var content: [FilestuffContainer]
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
    /// into `File` containers. The main difference between `File` containers and `Directory` containers is the `Directory`
    /// containers has an extra storage for the content of the given directory.
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
    /// into `File` containers. The main difference between `File` containers and `Directory` containers is the `Directory`
    /// containers has an extra storage for the content of the given directory.
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
    public subscript(index: Int) -> FilestuffContainer? {
        (0...content.count).contains(index) ? content[index] : nil
    }

    /// A Boolean value indicating whether the `Directory` is empty.
    ///
    /// When you need to check whether your `Directory` is empty, use the
    /// `isEmpty` property instead of checking that the `count` property is
    /// equal to zero.
    ///
    ///     // Assumes home directory content is:
    ///     //   October Sales Report.pdf
    ///     //   Accounts.numbers
    ///     //   To Do.txt
    ///     let homeUrl = URL(filePath: "/Users/myhome")
    ///     let homeDirectory = try! Directory.load(url: homeUrl)
    ///     if homeDirectory.isEmpty {
    ///         print("My directory is empty")
    ///     } else {
    ///         print("File count: \(homeDirectory.count)")
    ///     }
    ///     // Prints "File count: 3"
    ///
    /// - Complexity: O(1)
    public var isEmpty: Bool { content.isEmpty }

    /// The number of `FilestuffCounter` in the `Directory`.
    public var contentCount: Int { content.count }

    /// Calls the given closure on each `FilestuffContainer` in the `Directory`
    /// in the same order as a `for`-`in` loop.
    ///
    /// Using the `forEach` method is distinct from a `for`-`in` loop in two
    /// important ways:
    ///
    /// 1. You cannot use a `break` or `continue` statement to exit the current
    ///    call of the `body` closure or skip subsequent calls.
    /// 2. Using the `return` statement in the `body` closure will exit only from
    ///    the current call to `body`, not from any outer scope, and won't skip
    ///    subsequent calls.
    ///
    /// - Parameter body: A closure that takes a `FilestuffContainer` of the
    ///   `Directory` as a parameter.
    public func forEach(_ body: (any FilestuffContainer) -> Void) {
        content.forEach(body)
    }

    public func filter(_ isIncluded: (any FilestuffContainer) -> Bool) -> [any FilestuffContainer] {
        content.filter(isIncluded)
    }

    @available(macOS 14, *)
    @available(iOS 17, *)
    public func filter(_ predicate: Predicate<any FilestuffContainer>) throws -> [any FilestuffContainer] {
        try content.filter(predicate)
    }

    /// Returns an array containing the results of mapping the given closure
    /// over the `Directory`'s `FilestuffContainer`s.
    ///
    /// In this example, `map` is used first to convert homeDirectory to the
    /// display name strings and then convert the display names to lower
    /// case names.
    ///
    ///     // Assumes home directory content is:
    ///     //   October Sales Report.pdf
    ///     //   Accounts.numbers
    ///     //   To Do.txt
    ///     let homeUrl = URL(filePath: "/Users/myhome")
    ///     let homeDirectory = try! Directory.load(url: homeUrl)
    ///     let displayNames = homeDirectory.map { $0.displayName }
    ///     // `displayNames` == ["October Sales Report.pdf", "Accounts.numbers", "To Do.txt"]
    ///     let lowerCaseNames = displayNames.map { $0.lowercased() }
    ///     // 'lowerCaseNames == ["october sales report.pdf", "accounts.numbers", "to do.txt"]
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts a
    ///   `FilestuffContainer` of this `Directory` as its parameter and returns
    ///   a transformed value of the same or of a different type.
    /// - Returns: An array containing the transformed elements of this
    ///   `Directory`.
    public func map<T>(_ transform: (any FilestuffContainer) -> T) -> [T] {
        content.map(transform)
    }

    /// Returns an array of `FilestuffContainer`s containing the non-`nil`
    /// results of calling the given transformation with each `FilestuffContainer`
    /// of this sequence.
    ///
    /// Use this method to receive an array of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// - Parameter transform: A closure that accepts a `FilestuffContainer` of
    ///   this `Directory` as its argument and returns an optional value.
    /// - Returns: An array of the non-`nil` `FilestiffContainer` of calling
    ///   `transform` with each `FilestuffContainer` of the `Directory`.
    ///
    /// - Complexity: O(*n*), where *n* is the count of this `Directory`.
    public func compactMap<ElementOfResult>(_ transform: (any FilestuffContainer) -> ElementOfResult?) -> [ElementOfResult] {
        content.compactMap(transform)
    }

    /// Returns a sequence of pairs (*n*, *File*), where *n* represents a
    /// consecutive integer starting at zero and a `FilestuffContainer`
    /// element of the `Directory`.
    ///
    /// - Returns: A sequence of pairs enumerating the `Directory`.
    ///
    /// - Complexity: O(1)
    public func enumerated() -> EnumeratedSequence<[any FilestuffContainer]> {
        content.enumerated()
    }

    /// Returns an array of `FilestuffContainer`s of the `Directory`, sorted
    /// using the given predicate as the comparison between
    /// `FilestuffContainer`s.
    ///
    /// - Parameter areInIncreasingOrder:
    ///     A predicate that returns true if its first argument should be
    ///     ordered before its second argument; otherwise, false.
    ///
    /// - Returns:
    ///    A sorted array of the `Directory`'s `FilestuffContainer`.
    ///
    /// The predicate must be a strict weak ordering over the elements. That 
    /// is, for any elements a, b, and c, the following conditions must hold:
    /// areInIncreasingOrder(a, a) is always false. (Irreflexivity)
    ///
    /// If areInIncreasingOrder(a, b) and areInIncreasingOrder(b, c) are both
    /// true, then areInIncreasingOrder(a, c) is also true.
    /// (Transitive comparability)
    ///
    /// Two `FilestuffContainer` are incomparable if neither is ordered before
    /// the other according to the predicate. If a and b are incomparable, and
    /// b and c are incomparable, then a and c are also incomparable.
    /// (Transitive incomparability)
    ///
    /// The sorting algorithm is guaranteed to be stable. A stable sort 
    /// preserves the relative order of elements for which areInIncreasingOrder 
    /// does not establish an order.
    ///
    /// - Complexity: O(*n* log *n*), where *n* is the length of the sequence.
    public func sorted(by areInIncreasingOrder: (any FilestuffContainer, any FilestuffContainer) throws -> Bool) throws -> [any FilestuffContainer] {
        try content.sorted(by: areInIncreasingOrder)
    }

    /// Returns an array of `FilestuffContainer`s of the `Directory`, sorted
    /// using the given comparator to compare `FilestuffContainer`s.
    ///
    /// - Parameters:
    ///   - comparator: the comparator to use in ordering files
    /// - Returns: an array of the elements sorted using `comparator`.
    public func sorted<Comparator>(using comparator: Comparator) -> [any FilestuffContainer] where Comparator : SortComparator, any FilestuffContainer == Comparator.Compared {
        content.sorted(using: comparator)
    }
}
