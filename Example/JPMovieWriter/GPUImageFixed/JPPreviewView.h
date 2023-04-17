//
//  JPPreviewView.h
//  JPMovieWriter
//
//  Created by 周健平 on 2023/3/11.
//
//  原型是`GPUImageView`，修复了该类在子线程访问了`bounds`的问题（需在主线程访问）。

#import "GPUImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface JPPreviewView : UIView <GPUImageInput>
@property (nonatomic, assign) GPUImageRotationMode inputRotation;

/** The fill mode dictates how images are fit in the view, with the default being kGPUImageFillModePreserveAspectRatio */
@property (nonatomic, assign) GPUImageFillModeType fillMode;

/** This calculates the current display size, in pixels, taking into account Retina scaling factors */
@property (nonatomic, assign, readonly) CGSize sizeInPixels;

@property (nonatomic, assign) BOOL enabled;

/** Handling fill mode
 @param redComponent Red component for background color
 @param greenComponent Green component for background color
 @param blueComponent Blue component for background color
 @param alphaComponent Alpha component for background color
 */
- (void)setBackgroundColorRed:(GLfloat)redComponent
                        green:(GLfloat)greenComponent
                         blue:(GLfloat)blueComponent
                        alpha:(GLfloat)alphaComponent;

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;

@property (nonatomic, assign) BOOL isShowBlurView;
- (void)setIsShowBlurView:(BOOL)isShowBlurView duration:(NSTimeInterval)duration complete:(void(^_Nullable)(void))complete;
@end

NS_ASSUME_NONNULL_END
