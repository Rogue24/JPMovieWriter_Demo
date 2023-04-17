//
//  JPWatermarkElement.h
//  JPBasic
//
//  Created by 周健平 on 2022/4/22.
//  Copyright © 2022 zhoujianping24@hotmail.com. All rights reserved.
//
//  基于`GPUImageUIElement`，修复<<单次刷新静态水印导致崩溃>>的问题。

#import "GPUImageOutput.h"

@interface JPWatermarkElement : GPUImageOutput

@property (nonatomic, strong, readonly) UIView *contentView;

// Initialization and teardown
- (id)initWithContentView:(UIView *)contentView;

// Layer management
- (CGSize)layerSizeInPixels;
- (void)update;
- (void)updateUsingCurrentTime;
- (void)updateWithTimestamp:(CMTime)frameTime;

@end
