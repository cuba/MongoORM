//
//  DocumentSaveError.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation

public enum DocumentSaveError: Error, CustomStringConvertible {
    case unsupportedType(key: String)
    case recievedMessage(_ message: String)
    case unknown
    
    public var description: String {
        switch self {
        case .unsupportedType(let key):
            return "Failed to save document because the type for key `\(key)` is unsupported"
            
        case .recievedMessage(let message):
            return message
            
        case .unknown:
            return "Failed to save due to an unknown reason."
        }
    }
}
