//
//  View.Extension.swift
//  Neves
//
//  Created by 周健平 on 2022/6/20.
//

import SwiftUI

extension View {
    func intoVC() -> UIHostingController<Self> {
        UIHostingController(rootView: self)
    }
}
