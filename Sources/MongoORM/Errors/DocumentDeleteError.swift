//
//  DocumentDeleteError.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation

public enum DocumentDeleteError: Error, CustomStringConvertible {
    case missingObjectId
    case unknown(id: String)
    
    public var description: String {
        switch self {
        case .missingObjectId  : return "Could not delete the document because it is not saved"
        case .unknown(let id)   : return "Failed to delete document \(id) for an unknown reason"
        }
    }
}
