#!/bin/bash

rm -rf build/*

xcodebuild archive \
-scheme Filestuff \
-configuration Release \
-destination 'generic/platform=iOS' \
-archivePath './build/Filestuff.framework-iphoneos.xcarchive' || return 1

xcodebuild archive \
-scheme Filestuff \
-configuration Release \
-destination 'generic/platform=iOS Simulator' \
-archivePath './build/Filestuff.framework-iphonesimulator.xcarchive'  || return 1

xcodebuild -create-xcframework \
-framework './build/Filestuff.framework-iphonesimulator.xcarchive/Products/Library/Frameworks/Filestuff.framework' \
-framework './build/Filestuff.framework-iphoneos.xcarchive/Products/Library/Frameworks/Filestuff.framework' \
-output './build/Filestuff.xcframework' || return 1
