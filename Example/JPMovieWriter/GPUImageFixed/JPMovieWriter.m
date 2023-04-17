//
//  JPMovieWriter.m
//  JPMovieWriter
//
//  Created by 周健平 on 2023/3/10.
//  Copyright © 2023 zhoujianping24@hotmail.com. All rights reserved.
//

#import "JPMovieWriter.h"
#import "GPUImageContext.h"
#import "GLProgram.h"
#import "GPUImageFilter.h"
#import "GPUImageMovieWriter.h"

typedef NS_ENUM(NSInteger, JPMovieWriterStopType) {
    JPMovieWriterStopType_Finish = 0,
    JPMovieWriterStopType_Cancel = 1,
    JPMovieWriterStopType_Clean = 2
};

@interface JPMovieWriter ()
{
    GLuint _movieFramebuffer;
    GLuint _movieRenderbuffer;
    
    GLProgram *_colorSwizzlingProgram;
    GLint _colorSwizzlingPositionAttribute;
    GLint _colorSwizzlingTextureCoordinateAttribute;
    GLint _colorSwizzlingInputTextureUniform;

    GPUImageFramebuffer *_firstInputFramebuffer;
    
    CMTime _startTime;
    CMTime _previousFrameTime;
    CMTime _previousAudioTime;

    dispatch_queue_t _audioQueue;
    dispatch_queue_t _videoQueue;
    
    BOOL _audioEncodingIsFinished;
    BOOL _videoEncodingIsFinished;
    
    BOOL _allowWriteAudio; // jp_用于解决<<视频第一帧会黑屏>>的问题
    
    NSDictionary *_videoOutputSettings;
    NSDictionary *_audioOutputSettings;
    
    NSTimeInterval _currentDuration;
    
    NSString *_fileName;
    NSString *_pathExtension;
    
    NSArray<NSURL *> *_originRecordedURLs;
    NSMutableArray<NSURL *> *_recordedURLs;
}
@end

@implementation JPMovieWriter

static BOOL isAlive_;

#pragma mark - Setter

- (void)setEncodingLiveVideo:(BOOL)value {
    _encodingLiveVideo = value;
    if (_isRecording) {
        NSAssert(NO, @"Can not change Encoding Live Video while recording");
    } else {
        _assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
        _assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    }
}

- (void)setHasAudioTrack:(BOOL)hasAudioTrack {
    [self setHasAudioTrack:hasAudioTrack audioSettings:_audioOutputSettings];
}

- (void)setMetaData:(NSArray *)metaData {
    _assetWriter.metadata = metaData;
}

- (void)setTransform:(CGAffineTransform)transform {
    _assetWriterVideoInput.transform = transform;
}

#pragma mark - Getter

+ (BOOL)isAlive {
    return isAlive_;
}

- (NSArray*)metaData {
    return _assetWriter.metadata;
}

- (CGAffineTransform)transform {
    return _assetWriterVideoInput.transform;
}

- (NSArray<NSURL *> *)originRecordedURLs {
    return _originRecordedURLs.copy;
}

- (NSArray<NSURL *> *)recordedURLs {
    if (!_recordedURLs) _recordedURLs = [NSMutableArray array];
    return _recordedURLs.copy;
}

- (NSTimeInterval)recordDuration {
    return _currentDuration + CMTimeGetSeconds(self.duration);
}

- (CMTime)duration {
    if(!CMTIME_IS_VALID(_startTime)) return kCMTimeZero;
    if(!CMTIME_IS_NEGATIVE_INFINITY(_previousFrameTime)) return CMTimeSubtract(_previousFrameTime, _startTime);
    if(!CMTIME_IS_NEGATIVE_INFINITY(_previousAudioTime)) return CMTimeSubtract(_previousAudioTime, _startTime);
    return kCMTimeZero;
}

#pragma mark - AssetWrite Reset

- (void)jp_resetVideoInput {
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:_videoOutputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
    
    NSDictionary *sourcePixelBufferAttributesDictionary = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (NSString *)kCVPixelBufferWidthKey: @(_videoSize.width),
        (NSString *)kCVPixelBufferHeightKey: @(_videoSize.height),
    };
    _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
}

- (void)jp_resetAudioInput {
    _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:_audioOutputSettings];
    _assetWriterAudioInput.expectsMediaDataInRealTime = _encodingLiveVideo;
}

- (BOOL)jp_resetAssetWriter {
    _allowWriteAudio = NO;
    _videoEncodingIsFinished = NO;
    _audioEncodingIsFinished = NO;
    _startTime = kCMTimeInvalid;
    _previousFrameTime = kCMTimeNegativeInfinity;
    _previousAudioTime = kCMTimeNegativeInfinity;
    
    NSString *fileFullName = [NSString stringWithFormat:@"%@_%zd.%@", _fileName, _recordedURLs.count, _pathExtension];
    NSString *fileFullPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileFullName];
    NSLog(@"jpjpjp fileFullName: %@", fileFullName);
    
    NSURL *recordURL = [NSURL fileURLWithPath:fileFullPath];
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:recordURL fileType:_fileType error:&error];
    if (error) {
        [self jp_removeAssetWriter];
        NSLog(@"jpjpjp Reset AssetWriter Error: %@", error);
        if (self.delegate && [self.delegate respondsToSelector:@selector(movieWriter:resetFailed:error:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate movieWriter:self resetFailed:self.recordedURLs error:error];
            });
        }
        return NO;
    }
    
    [_recordedURLs addObject:recordURL];
    
    // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
//    assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);
    
    // MP4格式需要设置这个
    _assetWriter.movieFragmentInterval = kCMTimeInvalid;
    
    [self jp_resetVideoInput];
    if (_assetWriterVideoInput && [_assetWriter canAddInput:_assetWriterVideoInput]) {
        [_assetWriter addInput:_assetWriterVideoInput];
    }
    
    [self jp_resetAudioInput];
    if (_assetWriterAudioInput && [_assetWriter canAddInput:_assetWriterAudioInput]) {
        [_assetWriter addInput:_assetWriterAudioInput];
    }
    
    return YES;
}

- (void)jp_removeAssetWriter {
    _isRecording = NO;
    _assetWriter = nil;
    _assetWriterPixelBufferInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriterAudioInput = nil;
}

#pragma mark - Initialization and teardown

- (instancetype)initWithFileType:(AVFileType)fileType
                       videoSize:(CGSize)videoSize
                   videoSettings:(NSDictionary *)videoSettings
                    recordedURLs:(NSArray<NSURL *> *)recordedURLs {
    if (isAlive_ || !(self = [super init])) return nil;
    NSAssert(videoSize.width && videoSize.height, @"videoSize cannot be empty.");
    
    //    NSString *tmpFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[cacheURL lastPathComponent]];
    //    tmpURL = [NSURL fileURLWithPath:tmpFilePath];
    
    _fileName = [NSString stringWithFormat:@"JPMovie_%.0lf", [[NSDate date] timeIntervalSince1970]];
    _fileType = fileType ? fileType : AVFileTypeMPEG4;
    _videoSize = videoSize;
    _originRecordedURLs = recordedURLs.copy;
    _recordedURLs = recordedURLs.mutableCopy;
    _shouldInvalidateAudioSampleWhenDone = NO;
    _inputRotation = kGPUImageNoRotation;
    
    [self __initializePathExtension];
    [self __initializeWriterContext];
    [self __initializeColorSwizzling];
    [self __initializeVideoOutputSettings:videoSettings];
    
    [self __updateCurrentDuration];
    
    isAlive_ = YES;
    return self;
}

- (void)__initializePathExtension {
    if (_fileType == AVFileTypeAppleM4A) {
        _pathExtension = @"m4a";
    } else if (_fileType == AVFileTypeAppleM4V) {
        _pathExtension = @"m4v";
    } else if (_fileType == AVFileTypeQuickTimeMovie) {
        _pathExtension = @"mov";
    } else {
        _pathExtension = @"mp4";
    }
}

- (void)__initializeWriterContext {
    _movieWriterContext = [[GPUImageContext alloc] init];
    [_movieWriterContext useSharegroup:[[[GPUImageContext sharedImageProcessingContext] context] sharegroup]];
}

- (void)__initializeColorSwizzling {
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->_movieWriterContext useAsCurrentContext];
        
        if ([GPUImageContext supportsFastTextureUpload]) {
            self->_colorSwizzlingProgram = [self->_movieWriterContext programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        } else {
            self->_colorSwizzlingProgram = [self->_movieWriterContext programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageColorSwizzlingFragmentShaderString];
        }
        
        if (!self->_colorSwizzlingProgram.initialized) {
            [self->_colorSwizzlingProgram addAttribute:@"position"];
            [self->_colorSwizzlingProgram addAttribute:@"inputTextureCoordinate"];
            
            if (![self->_colorSwizzlingProgram link]) {
                NSString *progLog = [self->_colorSwizzlingProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                
                NSString *fragLog = [self->_colorSwizzlingProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                
                NSString *vertLog = [self->_colorSwizzlingProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                
                self->_colorSwizzlingProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        self->_colorSwizzlingPositionAttribute = [self->_colorSwizzlingProgram attributeIndex:@"position"];
        self->_colorSwizzlingTextureCoordinateAttribute = [self->_colorSwizzlingProgram attributeIndex:@"inputTextureCoordinate"];
        self->_colorSwizzlingInputTextureUniform = [self->_colorSwizzlingProgram uniformIndex:@"inputImageTexture"];
        
        [self->_movieWriterContext setContextShaderProgram:self->_colorSwizzlingProgram];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        glEnableVertexAttribArray(self->_colorSwizzlingPositionAttribute);
        glEnableVertexAttribArray(self->_colorSwizzlingTextureCoordinateAttribute);
#pragma clang diagnostic pop
    });
}

- (void)__initializeVideoOutputSettings:(NSDictionary *)videoSettings {
    _encodingLiveVideo = YES;
    
    if (videoSettings == nil) {
        videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey: @(_videoSize.width),
            AVVideoHeightKey: @(_videoSize.height),
        };
    } else {
        // custom output settings specified
        __unused NSString *videoCodec = videoSettings[AVVideoCodecKey];
        __unused NSNumber *width = videoSettings[AVVideoWidthKey];
        __unused NSNumber *height = videoSettings[AVVideoHeightKey];
        NSAssert(videoCodec && width && height, @"OutputSettings is missing required parameters.");
        
        if (videoSettings[@"EncodingLiveVideo"]) {
            _encodingLiveVideo = [videoSettings[@"EncodingLiveVideo"] boolValue];
            
            NSMutableDictionary *tmp = videoSettings.mutableCopy;
            tmp[@"EncodingLiveVideo"] = nil;
            videoSettings = tmp;
        }
    }
    
    _videoOutputSettings = videoSettings;
}

- (void)dealloc {
    [_assetWriter cancelWriting];
    [self destroyDataFBO];
    // 延迟一点再确定销毁吧
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isAlive_ = NO;
        NSLog(@"JPMovieWriter is destroy.");
    });
}

#pragma mark - <GPUImageInput Protocol>

#pragma mark JP_视频采样
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    if (!_isRecording) {
        [_firstInputFramebuffer unlock];
        return;
    }
    [self __encodeVideoBufferAtTime:frameTime];
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    [newInputFramebuffer lock];
    _firstInputFramebuffer = newInputFramebuffer;
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex {
    _inputRotation = newInputRotation;
}

- (CGSize)maximumOutputSize {
    return _videoSize;
}

- (void)endProcessing {}

- (BOOL)shouldIgnoreUpdatesToThisTarget {
    return NO;
}

- (BOOL)enabled {
    return YES;
}

- (BOOL)wantsMonochromeInput {
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {}

#pragma mark - 帧渲染

- (void)renderAtInternalSizeUsingFramebuffer:(GPUImageFramebuffer *)inputFramebufferToUse {
    [_movieWriterContext useAsCurrentContext];
    [self setFilterFBO];
    
    [_movieWriterContext setContextShaderProgram:_colorSwizzlingProgram];
    
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // This needs to be flipped to write out to video correctly
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    const GLfloat *textureCoordinates = [GPUImageFilter textureCoordinatesForRotation:_inputRotation];
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [inputFramebufferToUse texture]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    glUniform1i(_colorSwizzlingInputTextureUniform, 4);
    
    //    NSLog(@"Movie writer framebuffer: %@", inputFramebufferToUse);
    
    glVertexAttribPointer(_colorSwizzlingPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(_colorSwizzlingTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
#pragma clang diagnostic pop
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
}

- (void)setFilterFBO {
    if (!_movieFramebuffer) {
        [self createDataFBO];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    glBindFramebuffer(GL_FRAMEBUFFER, _movieFramebuffer);
#pragma clang diagnostic pop
    glViewport(0, 0, (int)_videoSize.width, (int)_videoSize.height);
}

- (void)createDataFBO {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &_movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _movieFramebuffer);
    
    if ([GPUImageContext supportsFastTextureUpload]) {
        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
        CVPixelBufferPoolCreatePixelBuffer(NULL,
                                           [_assetWriterPixelBufferInput pixelBufferPool],
                                           &_renderTarget);
        
        /* AVAssetWriter will use BT.601 conversion matrix for RGB to YCbCr conversion
         * regardless of the kCVImageBufferYCbCrMatrixKey value.
         * Tagging the resulting video file as BT.601, is the best option right now.
         * Creating a proper BT.709 video is not possible at the moment.
         */
        CVBufferSetAttachment(_renderTarget,
                              kCVImageBufferColorPrimariesKey,
                              kCVImageBufferColorPrimaries_ITU_R_709_2,
                              kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(_renderTarget,
                              kCVImageBufferYCbCrMatrixKey,
                              kCVImageBufferYCbCrMatrix_ITU_R_601_4,
                              kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(_renderTarget,
                              kCVImageBufferTransferFunctionKey,
                              kCVImageBufferTransferFunction_ITU_R_709_2,
                              kCVAttachmentMode_ShouldPropagate);
        
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                      [_movieWriterContext coreVideoTextureCache],
                                                      _renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      (int)_videoSize.width,
                                                      (int)_videoSize.height,
                                                      GL_BGRA, // native iOS format
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &_renderTexture);
        
        glBindTexture(CVOpenGLESTextureGetTarget(_renderTexture), CVOpenGLESTextureGetName(_renderTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_renderTexture), 0);
        
    } else {
        glGenRenderbuffers(1, &_movieRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _movieRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (int)_videoSize.width, (int)_videoSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _movieRenderbuffer);
    }
    
    __unused GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
#pragma clang diagnostic pop
}

- (void)destroyDataFBO {
    // 为了确保这里能够执行完这个销毁过程，这里就不“__weak/strong self”了
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->_movieWriterContext useAsCurrentContext];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (self->_movieFramebuffer) {
            glDeleteFramebuffers(1, &self->_movieFramebuffer);
            self->_movieFramebuffer = 0;
        }
        
        if (self->_movieRenderbuffer) {
            glDeleteRenderbuffers(1, &self->_movieRenderbuffer);
            self->_movieRenderbuffer = 0;
        }
#pragma clang diagnostic pop
        
        if ([GPUImageContext supportsFastTextureUpload]) {
            if (self->_renderTexture) {
                CFRelease(self->_renderTexture);
                self->_renderTexture = 0;
            }
            if (self->_renderTarget) {
                CVPixelBufferRelease(self->_renderTarget);
                self->_renderTarget = 0;
            }
        }
        
        NSLog(@"JPMovieWriter is destroyDataFBO.");
    });
}

#pragma mark - 帧处理

#pragma mark JP_视频帧处理
- (void)__encodeVideoBufferAtTime:(CMTime)frameTime {
    // Drop frames forced by images and other things with no time constants
    // Also, if two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
    if ((CMTIME_IS_INVALID(frameTime)) ||
        (CMTIME_COMPARE_INLINE(frameTime, ==, _previousFrameTime)) ||
        (CMTIME_IS_INDEFINITE(frameTime))) {
        [_firstInputFramebuffer unlock];
        return;
    }
    
    [self __alignmentStartTime:frameTime];
    
    GPUImageFramebuffer *inputFramebufferForBlock = _firstInputFramebuffer;
    glFinish();
    
    __weak typeof(self) wSelf = self;
    runAsynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        if (!sSelf->_assetWriterVideoInput.readyForMoreMediaData && sSelf->_encodingLiveVideo) {
            [inputFramebufferForBlock unlock];
            NSLog(@"1: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            return;
        }
        
        // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
        [sSelf->_movieWriterContext useAsCurrentContext];
        [sSelf renderAtInternalSizeUsingFramebuffer:inputFramebufferForBlock];
        
        CVPixelBufferRef pixel_buffer = NULL;
        
        BOOL isRenderTarget = NO;
        if ([GPUImageContext supportsFastTextureUpload]) {
            isRenderTarget = YES;
            pixel_buffer = sSelf->_renderTarget;
            CVPixelBufferLockBaseAddress(pixel_buffer, 0);
        } else {
            CVReturn status = CVPixelBufferPoolCreatePixelBuffer (NULL, [sSelf->_assetWriterPixelBufferInput pixelBufferPool], &pixel_buffer);
            if ((pixel_buffer == NULL) || (status != kCVReturnSuccess)) {
                CVPixelBufferRelease(pixel_buffer);
                return;
            } else {
                CVPixelBufferLockBaseAddress(pixel_buffer, 0);
                GLubyte *pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pixel_buffer);
                glReadPixels(0, 0, sSelf->_videoSize.width, sSelf->_videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
            }
        }
        
        while (!sSelf->_assetWriterVideoInput.readyForMoreMediaData &&
               !sSelf->_encodingLiveVideo &&
               !sSelf->_videoEncodingIsFinished) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
            // NSLog(@"video waiting...");
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        
//        NSLog(@"Seconds 111 %.2lf %@", sSelf.recordDuration, NSThread.currentThread);
        BOOL isFailed = NO;
        
        if (!sSelf->_assetWriterVideoInput.readyForMoreMediaData) {
            NSLog(@"2: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            
        } else if (sSelf->_assetWriter.status == AVAssetWriterStatusWriting) {
            if (![sSelf->_assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:frameTime]) {
                NSLog(@"Problem appending pixel buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            } else {
                // jp_修改GPUImage：解决<<视频第一帧会黑屏>>的问题
                sSelf->_allowWriteAudio = YES;
            }
        } else {
            NSLog(@"jpjpjp Encode VideoBuffer Error: Couldn't write a frame");
            //NSLog(@"Wrote a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            isFailed = YES;
        }
        
        if (isRenderTarget) {
            // 有可能已经被别处释放了
            if (sSelf->_renderTarget) {
                CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
            }
        } else {
            CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
        }
        
        sSelf->_previousFrameTime = frameTime;
        
        if (![GPUImageContext supportsFastTextureUpload]) {
            CVPixelBufferRelease(pixel_buffer);
        }
        
        [inputFramebufferForBlock unlock];
        
//        NSLog(@"Seconds 222 %.2lf %@", sSelf.recordDuration, NSThread.currentThread);
//        NSLog(@"==============================");
        
        NSTimeInterval recordDuration = sSelf.recordDuration;
        NSTimeInterval maxRecordDuration = sSelf.maxRecordDuration;
        if (sSelf.delegate && [sSelf.delegate respondsToSelector:@selector(movieWriter:recording:totalDuration:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sSelf.delegate movieWriter:sSelf recording:recordDuration totalDuration: maxRecordDuration];
            });
        }
        
        // test faild
//        if (recordDuration >= 7) {
//            isFailed = YES;
//        }
        
        if (isFailed) {
            NSError *error = [[NSError alloc] initWithDomain:@"JPMovieWriterError" code:-7777 userInfo:@{
                NSLocalizedDescriptionKey:@"Couldn't write a frame",
                NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"Reason for status: %zd", sSelf->_assetWriter.status],
            }];
            if (sSelf.delegate && [sSelf.delegate respondsToSelector:@selector(movieWriter:recordWillDone:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf.delegate movieWriter:sSelf recordWillDone:error];
                });
            }
            [sSelf __autoStopRecord:JPMovieWriterStopType_Cancel completionHandler:^(NSArray<NSURL *> *recordedURLs) {
                if (sSelf.delegate && [sSelf.delegate respondsToSelector:@selector(movieWriter:recordDone:error:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sSelf.delegate movieWriter:sSelf recordDone:recordedURLs error:error];
                    });
                }
            }];
            return;
        }
        
        if (maxRecordDuration > 0 && recordDuration >= maxRecordDuration) {
            if (sSelf.delegate && [sSelf.delegate respondsToSelector:@selector(movieWriter:recordWillDone:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf.delegate movieWriter:sSelf recordWillDone:nil];
                });
            }
            [sSelf __autoStopRecord:JPMovieWriterStopType_Finish completionHandler:^(NSArray<NSURL *> *recordedURLs) {
                if (sSelf.delegate && [sSelf.delegate respondsToSelector:@selector(movieWriter:recordDone:error:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [sSelf.delegate movieWriter:sSelf recordDone:recordedURLs error:nil];
                    });
                }
            }];
            return;
        }
    });
}

#pragma mark JP_音频帧处理
- (void)__encodeAudioBuffer:(CMSampleBufferRef)audioBuffer {
    CFRetain(audioBuffer);
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(audioBuffer);
    
    [self __alignmentStartTime:currentSampleTime];
    
    if (!_assetWriterAudioInput.readyForMoreMediaData && _encodingLiveVideo) {
        NSLog(@"1: Had to drop an audio frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
        if (_shouldInvalidateAudioSampleWhenDone) {
            CMSampleBufferInvalidate(audioBuffer);
        }
        CFRelease(audioBuffer);
        return;
    }
    
    // record most recent time so we know the length of the pause
    currentSampleTime = CMSampleBufferGetPresentationTimeStamp(audioBuffer);
    
    _previousAudioTime = currentSampleTime;
    
    //if the consumer wants to do something with the audio samples before writing, let him.
    if (self.audioProcessingCallback) {
        //need to introspect into the opaque CMBlockBuffer structure to find its raw sample buffers.
        CMBlockBufferRef buffer = CMSampleBufferGetDataBuffer(audioBuffer);
        CMItemCount numSamplesInBuffer = CMSampleBufferGetNumSamples(audioBuffer);
        AudioBufferList audioBufferList;
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioBuffer,
                                                                NULL,
                                                                &audioBufferList,
                                                                sizeof(audioBufferList),
                                                                NULL,
                                                                NULL,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                &buffer);
        
        //passing a live pointer to the audio buffers, try to process them in-place or we might have syncing issues.
        for (int bufferCount=0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++) {
            SInt16 *samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
            self.audioProcessingCallback(&samples, numSamplesInBuffer);
        }
    }
    
    __weak typeof(self) wSelf = self;
    void(^write)(void) = ^() {
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        while (!sSelf->_assetWriterAudioInput.readyForMoreMediaData &&
               !sSelf->_encodingLiveVideo &&
               !sSelf->_audioEncodingIsFinished) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        
        if (!sSelf->_assetWriterAudioInput.readyForMoreMediaData) {
            NSLog(@"2: Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            
        } else if (sSelf->_assetWriter.status == AVAssetWriterStatusWriting) {
            if (![sSelf->_assetWriterAudioInput appendSampleBuffer:audioBuffer]) {
                NSLog(@"Problem appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }
        } else {
            NSLog(@"jpjpjp Encode VideoBuffer Error: Couldn't write an audio");
            //NSLog(@"Wrote an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
        }
        
        if (sSelf->_shouldInvalidateAudioSampleWhenDone) {
            CMSampleBufferInvalidate(audioBuffer);
        }
        CFRelease(audioBuffer);
    };
    
    if (_encodingLiveVideo) {
        runAsynchronouslyOnContextQueue(_movieWriterContext, write);
    } else {
        write();
    }
}

#pragma mark - 私有API

#pragma mark JP_对齐开始时间
- (void)__alignmentStartTime:(CMTime)time {
    if (CMTIME_IS_INVALID(_startTime) == NO) return;
    __weak typeof(self) wSelf = self;
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        if (sSelf->_assetWriter.status != AVAssetWriterStatusWriting) {
            [sSelf->_assetWriter startWriting];
        }
        
        [sSelf->_assetWriter startSessionAtSourceTime:time];
        sSelf->_startTime = time;
    });
}

#pragma mark JP_停止录制
- (void)__autoStopRecord:(JPMovieWriterStopType)stopType completionHandler:(void (^)(NSArray<NSURL *> *recordedURLs))handler {
    if (_isStoping) {
        NSLog(@"jpjpjp 正在Stoping！请别操作！__autoStopRecord");
        return;
    }
    
    if (!_isRecording) {
        if (handler) handler(self.recordedURLs);
        return;
    }
    
    _isStoping = YES;
    _isRecording = NO;
    
    [self __stopRecord:stopType completionHandler:handler];
}

- (void)__stopRecord:(JPMovieWriterStopType)stopType completionHandler:(void (^)(NSArray<NSURL *> *recordedURLs))handler {
    NSLog(@"jpjpjp stopRecord 111 %@", NSThread.currentThread);
    
    __weak typeof(self) wSelf = self;
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        NSLog(@"jpjpjp stopRecord 222 %@", NSThread.currentThread);
        
        if (sSelf->_assetWriter == nil ||
            sSelf->_assetWriter.status == AVAssetWriterStatusCompleted ||
            sSelf->_assetWriter.status == AVAssetWriterStatusCancelled ||
            sSelf->_assetWriter.status == AVAssetWriterStatusUnknown) {
            // jp_移除assetWriter
            [sSelf jp_removeAssetWriter];
            
            [sSelf __stopRecordDone:stopType completionHandler:handler];
            NSLog(@"jpjpjp stopRecord 333 %@", NSThread.currentThread);
        } else {
            if (sSelf->_assetWriter.status == AVAssetWriterStatusWriting && !sSelf->_videoEncodingIsFinished) {
                sSelf->_videoEncodingIsFinished = YES;
                [sSelf->_assetWriterVideoInput markAsFinished];
            }

            if (sSelf->_assetWriter.status == AVAssetWriterStatusWriting && !sSelf->_audioEncodingIsFinished) {
                sSelf->_audioEncodingIsFinished = YES;
                [sSelf->_assetWriterAudioInput markAsFinished];
            }
            
            if (stopType == JPMovieWriterStopType_Finish) {
                [sSelf->_assetWriter finishWritingWithCompletionHandler:^{
                    [sSelf __stopRecordDone:stopType completionHandler:handler];
                    NSLog(@"jpjpjp stopRecord 333 %@", NSThread.currentThread);
                }];
            } else {
                [sSelf->_assetWriter cancelWriting];
            }
            
            // jp_移除assetWriter
            [sSelf jp_removeAssetWriter];
            
            if (stopType != JPMovieWriterStopType_Finish) {
                [sSelf __stopRecordDone:stopType completionHandler:handler];
                NSLog(@"jpjpjp stopRecord 333 %@", NSThread.currentThread);
            }
        }
    });
    
    [self destroyDataFBO];
}

- (void)__stopRecordDone:(JPMovieWriterStopType)stopType completionHandler:(void (^)(NSArray<NSURL *> *recordedURLs))handler {
    switch (stopType) {
        case JPMovieWriterStopType_Finish:
            break;
            
        case JPMovieWriterStopType_Cancel:
        {
            NSURL *lastURL = _recordedURLs.lastObject;
            if (![_originRecordedURLs containsObject:lastURL]) {
                [[NSFileManager defaultManager] removeItemAtURL:lastURL error:nil];
                [_recordedURLs removeLastObject];
            }
            break;
        }
            
        case JPMovieWriterStopType_Clean:
        {
            for (NSURL *url in _recordedURLs) {
                if ([_originRecordedURLs containsObject:url]) {
                    continue;
                }
                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            }
            _recordedURLs = _originRecordedURLs.mutableCopy;
            break;
        }
    }
    
    [self __updateCurrentDuration];
    
    _startTime = kCMTimeInvalid;
    _previousFrameTime = kCMTimeNegativeInfinity;
    _previousAudioTime = kCMTimeNegativeInfinity;
    
    _isStoping = NO;
    
    if (handler) {
        NSArray *recordedURLs = self.recordedURLs;
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(recordedURLs);
        });
    }
}

#pragma mark JP_刷新当前录制时长
- (void)__updateCurrentDuration {
    NSTimeInterval currentDuration = 0;
    for (NSURL *url in _recordedURLs) {
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        currentDuration += CMTimeGetSeconds(asset.duration);
    }
    _currentDuration = currentDuration;
}

#pragma mark - 公开API

#pragma mark JP_音频设置
- (void)setHasAudioTrack:(BOOL)hasAudioTrack audioSettings:(NSDictionary *)audioSettings {
    _hasAudioTrack = hasAudioTrack;
    
    if (!_hasAudioTrack) {
        audioSettings = nil;
    } else if (audioSettings == nil) {
        AVAudioSession *sharedAudioSession = [AVAudioSession sharedInstance];
        double preferredHardwareSampleRate;
        
        if ([sharedAudioSession respondsToSelector:@selector(sampleRate)]) {
            preferredHardwareSampleRate = [sharedAudioSession sampleRate];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            preferredHardwareSampleRate = [sharedAudioSession currentHardwareSampleRate];
#pragma clang diagnostic pop
        }
        
        AudioChannelLayout acl;
        bzero( &acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        
        audioSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: @(1),
            AVSampleRateKey: @(preferredHardwareSampleRate),
            AVChannelLayoutKey: [NSData dataWithBytes:&acl length:sizeof(acl)],
            AVEncoderBitRateKey: @(64000),
        };
    }
    
    _audioOutputSettings = audioSettings;
}

#pragma mark JP_音频采样
- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer {
    if (!_hasAudioTrack) return;
    if (!_isRecording) return;
    // jp_修改GPUImage：解决<<视频第一帧会黑屏>>的问题
    if (!_allowWriteAudio) return;
    [self __encodeAudioBuffer:audioBuffer];
}

#pragma mark JP_开始录制
- (BOOL)startRecord {
    if (_isStoping) {
        NSLog(@"jpjpjp 正在Stoping！请别操作！startRecord");
        return NO;
    }
    
    if (_isRecording) {
        return YES;
    }
    
    __weak typeof(self) wSelf = self;
    __block BOOL isRecording = NO;
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        // jp_重置assetWriter
        if (![sSelf jp_resetAssetWriter]) {
            return;
        }
        
        // 开始录制
        [sSelf->_assetWriter startWriting];
        isRecording = YES;
    });
    
    _isRecording = isRecording;
    return isRecording;
}

#pragma mark JP_完成录制
- (void)finishRecord {
    [self finishRecordWithCompletionHandler:nil];
}

- (void)finishRecordWithCompletionHandler:(void (^)(NSArray<NSURL *> *recordedURLs))handler {
    if (_isStoping) {
        NSLog(@"jpjpjp 正在Stoping！请别操作！finishRecord");
        return;
    }
    
    if (!_isRecording) {
        if (handler) handler(self.recordedURLs);
        return;
    }
    
    _isStoping = YES;
    _isRecording = NO;
    
    __weak typeof(self) wSelf = self;
    runAsynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        [sSelf __stopRecord:JPMovieWriterStopType_Finish completionHandler:handler];
    });
}

#pragma mark JP_取消录制
- (void)cancelRecord {
    [self cancelRecordWithCompletionHandler:nil];
}

- (void)cancelRecordWithCompletionHandler:(void (^)(NSArray<NSURL *> *recordedURLs))handler {
    if (_isStoping) {
        NSLog(@"jpjpjp 正在Stoping！请别操作！cancelRecord");
        return;
    }
    
    if (!_isRecording) {
        if (handler) handler(self.recordedURLs);
        return;
    }
    
    _isStoping = YES;
    _isRecording = NO;
    
    __weak typeof(self) wSelf = self;
    runAsynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        [sSelf __stopRecord:JPMovieWriterStopType_Cancel completionHandler:handler];
    });
}

#pragma mark JP_清空录制
- (void)cleanRecord {
    [self cleanRecordWithCompletionHandler:nil];
}

- (void)cleanRecordWithCompletionHandler:(void (^)(void))handler {
    if (_isStoping) {
        NSLog(@"jpjpjp 正在Stoping！请别操作！cleanRecord");
        return;
    }
    
    BOOL isRecording = _isRecording;
    
    _isStoping = YES;
    _isRecording = NO;
    
    __weak typeof(self) wSelf = self;
    runAsynchronouslyOnContextQueue(_movieWriterContext, ^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        if (isRecording) {
            [sSelf __stopRecord:JPMovieWriterStopType_Clean completionHandler:^(NSArray<NSURL *> *recordedURLs) {
                !handler ? : handler();
            }];
        } else {
            [sSelf __stopRecordDone:JPMovieWriterStopType_Clean completionHandler:^(NSArray<NSURL *> *recordedURLs) {
                !handler ? : handler();
            }];
        }
    });
}

@end

