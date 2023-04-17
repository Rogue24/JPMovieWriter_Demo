//
//  GPUImageStillCamera+JPExtension.h
//  JPMovieWriter
//
//  Created by 周健平 on 2023/3/24.
//

#import "GPUImage.h"
@class JPMovieWriter;

@interface GPUImageStillCamera (JPExtension)

- (void)jp_setAudioEncodingTarget:(JPMovieWriter *)target;

@end

