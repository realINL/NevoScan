//
//  CGFloat+Extensions.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.04.2026.
//

import UIKit

extension CGFloat {
    func toWidth() -> CGFloat {
        return UIScreen.main.bounds.width * self
    }
    
    func toHeight() -> CGFloat {
        return UIScreen.main.bounds.height * self
    }
    
    static func FHeight(_ height: CGFloat) -> CGFloat {
        let fheight = CGFloat(956)
        return height / fheight * UIScreen.main.bounds.height
    }
    
    static func FWidth(_ width: CGFloat) -> CGFloat {
        let fheight = CGFloat(440)
        return width / fheight * UIScreen.main.bounds.width
    }
}
