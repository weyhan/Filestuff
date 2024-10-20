//
//  File.swift
//  Filestuff
//
//  Created by WeyHan Ng on 03/07/2024.
//

import Foundation

/// A value that stores metadata of a file.
public struct File: FilestuffContainer {
    public let url: URL
    public let attribute: URLResourceValues
}
