//
//  UIConfig.swift
//  JPMovieWriter_Example
//
//  Created by 周健平 on 2023/3/9.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

enum UIConfig {

    static let mainBgColor: UIColor = .rgb(30, 30, 36)
    static let secBgColor: UIColor = .rgb(41, 43, 51)
    static let itemBgColor: UIColor = .clear
    static let imageBgColor: UIColor = .rgb(41, 43, 51)
    static let titleColor: UIColor = .label
    static let subtitleColor: UIColor = .secondaryLabel
    
    static let videoSize: CGSize = [720, 1280]
    static let videoRatio = videoSize.width / videoSize.height
    static let videoViewSize: CGSize = [PortraitScreenWidth, PortraitScreenWidth / videoRatio]
    
    static let videoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "YYYY年MM月dd日 HH:mm:ss"
        return f
    }()
    
    static let titles: [String] = [
        "我只是不想再失去他——哪怕是仅存在一瞬的幻影！",
        "人与人的相遇，不是恩赐就是劫。",
        "我们的学生会长，比高达还强。",
        "想要让每一天重新来过，又不想让仔细回味每一天。",
        "因为痛苦太有价值，因为回忆太珍贵，所以我们更要继续往前走。",
        "开始的敌人和最后一个敌人，都是你自己。",
        "报君黄金台上意，提携玉龙为君死。",
        "趁着年轻，好好犯病。",
        "如果忘记你那么容易，那我爱你干嘛！",
        "读懂第一个字后，世界便有了心跳。",
        "你要不会唠嗑能不能别硬唠。",
        "越是困难，越要抬起头，地上可找不到任何希望！",
        "因为太害怕失去，所以才将苦痛剥离。",
        "无论乌云有多浓厚，星星也一定还在，只是暂时看不到了而已。",
        "人经历风浪是会变得更强，可是船不同，日积月累的只有伤痛。",
        "相遇不一定有结果，但一定有意义。",
        "停下脚步才注意到 世界被染得雪白。",
        "因为你喜欢海，所以我一直浪。",
        "我和你，可以做朋友吗？",
        "亲眼所见，亦非真实。",
        "今天不想做，所以才要做。",
        "以智者之名，为愚者代辩。",
        "空山新雨后，天气晚来秋。",
        "人生就像一杯茶，不会苦一辈子，但会苦一阵子。",
        "蒹葭苍苍，白露为霜。所谓伊人，在水一方。",
        "其实美丽的故事都是没有结局的，只因为它没有结局所以才会美丽。",
        "一定要爱着点什么，恰似草木对光阴的钟情。",
        "要保持希望在每天清晨太阳升起。",
        "成熟的人眼里满是前途，稚嫩的人眼里满是爱恨情仇。",
        "我们是独立的个体，却不是孤独的存在。",
    ]
}
