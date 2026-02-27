//
//  UIFont+Extension.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/02/26.
//

import Foundation
import UIKit

extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
