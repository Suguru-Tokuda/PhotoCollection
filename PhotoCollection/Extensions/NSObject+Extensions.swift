//
//  NSObject+Extensions.swift
//  SwiftConcurrencyDemo
//
//  Created by Suguru Tokuda on 5/18/25.
//

import Foundation

extension NSObject {
    var className: String {
        get {
            return NSStringFromClass(type(of: self))
        }
    }
}
