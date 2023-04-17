//
//  JPMovieWriter.h
//  JPMovieWriter
//
//  Created by 周健平 on 2023/3/10.
//
//  原型是`GPUImageMovieWriter`，在该类的基础上添加了【重录】的功能，来代替原来的【暂停】功能。
//  PS：原本`GPUImageMovieWriter`的暂停是不可用的；另外只要停止了录制就不可以再录制了，要重新创建一个新的，现在可以复用了。

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@class JPMovieWriter;

@protocol JPMovieWriterDelegate <NSObject>
@optional
- (void)movieWriter:(JPMovieWriter *)writer resetFailed:(nonnull NSArray<NSURL *> *)recordedURLs error:(nonnull NSError *)error;
- (void)movieWriter:(JPMovieWriter *)writer recording:(NSTimeInterval)recordDuration totalDuration:(NSTimeInterval)totalDuration;
- (void)movieWriter:(JPMovieWriter *)writer recordWillDone:(nullable NSError *)error;
- (void)movieWriter:(JPMovieWriter *)writer recordDone:(nonnull NSArray<NSURL *> *)recordedURLs error:(nullable NSError *)error;
@end

@interface JPMovieWriter : NSObject <GPUImageInput>
@property (nonatomic, weak) id<JPMovieWriterDelegate> _Nullable delegate;

@property (nonatomic, assign, readonly) CGSize videoSize;
@property (nonatomic, copy, readonly) AVFileType fileType;

@property (nonatomic, copy) NSArray *metaData;
@property (nonatomic, assign) CGAffineTransform transform;

@property (nonatomic, assign, readonly) GPUImageRotationMode inputRotation;
@property (nonatomic, strong, readonly) GPUImageContext *movieWriterContext;
@property (nonatomic, assign, readonly) CVPixelBufferRef renderTarget;
@property (nonatomic, assign, readonly) CVOpenGLESTextureRef renderTexture;

@property (nonatomic, strong, readonly) AVAssetWriter *assetWriter;
@property (nonatomic, strong, readonly) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong, readonly) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong, readonly) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;

@property (nonatomic, assign) BOOL encodingLiveVideo;

@property (nonatomic, assign) BOOL hasAudioTrack;
@property (nonatomic, assign) BOOL shouldInvalidateAudioSampleWhenDone;
@property (nonatomic, copy) void (^_Nullable audioProcessingCallback)(SInt16 *_Nullable *_Nullable samplesRef, CMItemCount numSamplesInBuffer);

@property (nonatomic, assign, readonly) BOOL isRecording;
@property (nonatomic, assign, readonly) BOOL isStoping;

@property (readonly) NSArray<NSURL *> *originRecordedURLs;
@property (readonly) NSArray<NSURL *> *recordedURLs;
@property (readonly) NSTimeInterval recordDuration;
@property (nonatomic, assign) NSTimeInterval maxRecordDuration;

+ (BOOL)isAlive;

- (instancetype)initWithFileType:(AVFileType)fileType
                       videoSize:(CGSize)videoSize
                   videoSettings:(NSDictionary *)videoSettings
                    recordedURLs:(NSArray<NSURL *> *)recordedURLs;

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;

- (void)setHasAudioTrack:(BOOL)hasAudioTrack audioSettings:(NSDictionary *)audioSettings;

- (BOOL)startRecord;

- (void)finishRecord;
- (void)finishRecordWithCompletionHandler:(void (^_Nullable)(NSArray<NSURL *> *recordedURLs))handler;

- (void)cancelRecord;
- (void)cancelRecordWithCompletionHandler:(void (^_Nullable)(NSArray<NSURL *> *recordedURLs))handler;

- (void)cleanRecord;
- (void)cleanRecordWithCompletionHandler:(void (^_Nullable)(void))handler;
@end

NS_ASSUME_NONNULL_END
