//
//  String+append.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 9/20/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//



import UIKit

extension String {
    func appendLine(to fileURL: URL) throws {
        try (self + "\n").append(to: fileURL)
    }
    
    func append(to fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}


extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
