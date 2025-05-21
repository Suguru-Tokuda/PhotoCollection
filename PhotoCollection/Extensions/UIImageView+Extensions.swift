//
//  UIImageView+Extensions.swift
//  PhotoCollection
//
//  Created by Suguru Tokuda on 5/20/25.
//

import UIKit

extension UIImageView {
    func setImage(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
