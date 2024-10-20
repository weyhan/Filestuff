# ``Filestuff``

A Swift framework for reading and managing directory trees that is suitable for building a Finder-style file browser interface.

## Overview

A Filestuff object lets you read the contents of a directory along with the metadata for the directory and its contents. To build a Finder-style file browser interface, the `Directory` object could be used directly as your data source for the `UITableView` or `UICollectionView` or, if desired, you can create a wrapper around the `Directory` object to format the data for display or manipulate the data in any way necessary. If the directory loader is not extended, the default set of metadata will be loaded upon reading the directory's content. 

If you need a piece of metadata that is not included in the default set, you can add additional metadata to be loaded and extend the `FilestuffContainer` to expose the extra metadata for your consumption.

## Topics

### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->
