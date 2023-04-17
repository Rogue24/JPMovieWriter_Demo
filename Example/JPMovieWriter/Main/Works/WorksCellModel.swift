//
//  WorksCellModel.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/7.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import YYText

struct WorksCellModel {
    let works: Works
    
    var imageURL: URL { works.imageURL }
    var durationStr: String { works.durationStr }
    let titleLayout: YYTextLayout
    var subtitle: String { works.subtitle }
    
    let imageFrame: CGRect
    let durationFrame: CGRect
    let titleFrame: CGRect
    let subtitleFrame: CGRect
    let cellSize: CGSize
    
    init(_ works: Works) {
        self.works = works
        self.titleLayout = TextTool.buildTextLayout(with: works.title,
                                                    font: WorksCell.titleFont,
                                                    color: UIConfig.titleColor,
                                                    space: WorksCell.titleSpace,
                                                    maxSize: [WorksCell.titleMaxWidth, 999])
        
        let cellW = WorksCell.cellWidth
        
        self.imageFrame = CGRect(origin: .zero, size: [cellW, cellW / works.imageRatio])
        
        var durationFrame = CGRect(origin: .zero, size: works.durationStr.size(withAttributes: [.font: WorksCell.durationFont])).insetBy(dx: -4.px, dy: -2.px)
        durationFrame.origin = [imageFrame.maxX - durationFrame.width - 4.px,
                                imageFrame.maxY - durationFrame.height - 4.px]
        self.durationFrame = durationFrame
        
        var titleFrame: CGRect = [0, 0, WorksCell.titleMaxWidth, titleLayout.textBoundingSize.height]
        titleFrame.origin = [HalfDiffValue(cellW, titleFrame.width), imageFrame.maxY + 10.px]
        self.titleFrame = titleFrame
        
        self.subtitleFrame = CGRect(origin: [titleFrame.origin.x, titleFrame.maxY + (titleFrame.height > 0 ? 5.px : 0)],
                                    size: works.subtitle.size(withAttributes: [.font: WorksCell.subtitleFont]))
        
        self.cellSize = [cellW, subtitleFrame.maxY + 10.px]
    }
}
