//
//  DocumentSaveError.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation

public enum DocumentSaveError: Error, CustomStringConvertible {
    case unsupportedType(key: String)
    
    public var description: String {
        switch self {
        case .unsupportedType(let key)  : return "Failed to save document because the type for key `\(key)` is unsupported"
        }
    }
}
