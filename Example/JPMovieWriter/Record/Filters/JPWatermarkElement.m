//
//  JPWatermarkElement.m
//  JPBasic
//
//  Created by 周健平 on 2022/4/22.
//  Copyright © 2022 zhoujianping24@hotmail.com. All rights reserved.
//

#import "JPWatermarkElement.h"

@interface JPWatermarkElement ()
{
    CGSize _previousLayerSizeInPixels;
    CMTime _time;
    NSTimeInterval _actualTimeOfLastUpdate;
}
@end

@implementation JPWatermarkElement

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContentView:(UIView *)contentView {
    if (!(self = [super init])) return nil;
    
    _contentView = contentView;
    _previousLayerSizeInPixels = CGSizeZero;
    [self update];
    
    return self;
}

#pragma mark -
#pragma mark Layer management

- (CGSize)layerSizeInPixels {
    CALayer *layer = _contentView.layer;
    CGSize pointSize = layer.bounds.size;
    return CGSizeMake(layer.contentsScale * pointSize.width, layer.contentsScale * pointSize.height);
}

- (void)update {
    [self updateWithTimestamp:kCMTimeIndefinite];
}

- (void)updateUsingCurrentTime {
    if (CMTIME_IS_INVALID(_time)) {
        _time = CMTimeMakeWithSeconds(0, 600);
        _actualTimeOfLastUpdate = [NSDate timeIntervalSinceReferenceDate];
    } else {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval diff = now - _actualTimeOfLastUpdate;
        _time = CMTimeAdd(_time, CMTimeMakeWithSeconds(diff, 600));
        _actualTimeOfLastUpdate = now;
    }
    
    [self updateWithTimestamp:_time];
}

- (void)updateWithTimestamp:(CMTime)frameTime {
    [GPUImageContext useImageProcessingContext];
    
    CALayer *layer = _contentView.layer;
    CGSize layerPixelSize = [self layerSizeInPixels];
    
    GLubyte *imageData = (GLubyte *) calloc(1, (int)layerPixelSize.width * (int)layerPixelSize.height * 4);
    
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)layerPixelSize.width, (int)layerPixelSize.height, 8, (int)layerPixelSize.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    CGContextRotateCTM(imageContext, M_PI_2);
    CGContextTranslateCTM(imageContext, 0.0f, layerPixelSize.height);
    CGContextScaleCTM(imageContext, layer.contentsScale, -layer.contentsScale);
    //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
    
    [layer renderInContext:imageContext];
    
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    
    // TODO: This may not work
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:layerPixelSize textureOptions:self.outputTextureOptions onlyTexture:YES];
    // jp_修改GPUImage：解决<<单次刷新静态水印导致崩溃>>的问题
    [outputFramebuffer disableReferenceCounting]; // Add this line, because GPUImageTwoInputFilter.m frametime updatedMovieFrameOppositeStillImage is YES, but the secondbuffer not lock. 添加此行，因为GPUImageTwoInputFilter.m frametime updatedMovieFrameOppositeStillImage为YES，但第二个缓冲区未锁定。

    glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
    // no need to use self.outputTextureOptions here, we always need these texture options
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)layerPixelSize.width, (int)layerPixelSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    
    free(imageData);
    
    for (id<GPUImageInput> currentTarget in targets) {
        if (currentTarget != self.targetToIgnoreForUpdates)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputSize:layerPixelSize atIndex:textureIndexOfTarget];
            // jp_修改GPUImage：解决<<单次刷新静态水印导致崩溃>>的问题
            [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget]; // add this line, because the outputFramebuffer is update above. 添加此行，因为outputFramebuffer在上面更新。
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndexOfTarget];
        }
    }
}

@end
