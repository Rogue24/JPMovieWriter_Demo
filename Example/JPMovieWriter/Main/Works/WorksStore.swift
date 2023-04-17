//
//  WorksStore.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/2/24.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI
import Combine

class WorksStore: ObservableObject {
    static let shared = WorksStore()
    
    @Published var worksList: [Works] = []
    
    func fetchWorks()  {
        let caches = RecordCacheTool.qurey(asOrder: .descending)
        worksList = caches.map { Works($0) }
    }
    
    func asyncFetchWorks()  {
        Asyncs.async {
//            JPrint("------")
//            JPrint("asyncFetchWorks", Thread.current)
            let caches = RecordCacheTool.qurey(asOrder: .descending)
            self.worksList = caches.map { Works($0) }
        }
    }
    
    func asyncFetchWorksOnMainBack()  {
        var worksList: [Works] = []
        Asyncs.async {
            let caches = RecordCacheTool.qurey(asOrder: .descending)
            worksList = caches.map { Works($0) }
        } mainTask: {
            self.worksList = worksList
        }
    }
}
