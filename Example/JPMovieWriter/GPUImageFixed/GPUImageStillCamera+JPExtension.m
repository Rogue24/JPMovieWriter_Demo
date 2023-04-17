//
//  GPUImageStillCamera+JPExtension.m
//  JPMovieWriter
//
//  Created by 周健平 on 2023/3/24.
//

#import "GPUImageStillCamera+JPExtension.h"
#import "JPMovieWriter.h"

@implementation GPUImageStillCamera (JPExtension)

- (void)jp_setAudioEncodingTarget:(JPMovieWriter *)target {
    self.audioEncodingTarget = (GPUImageMovieWriter *)target;
}

@end
