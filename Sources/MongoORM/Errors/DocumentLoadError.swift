//
//  DocumentLoadError.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation

public enum DocumentLoadError: Error, CustomStringConvertible {
    case documentNotFound
    case missingObjectId
    
    public var description: String {
        switch self {
        case .documentNotFound:
            return "Document not found."
            
        case .missingObjectId:
            return "Object ID is missing on the document."
        }
    }
}
