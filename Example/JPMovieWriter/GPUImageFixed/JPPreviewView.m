//
//  JPPreviewView.m
//  JPMovieWriter
//
//  Created by 周健平 on 2023/3/11.
//

#import "JPPreviewView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageContext.h"
#import "GPUImageFilter.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - Private methods and instance variables

@interface JPPreviewView ()
{
    GPUImageFramebuffer *_inputFramebufferForDisplay;
    GLuint _displayRenderbuffer, _displayFramebuffer;
    
    GLProgram *_displayProgram;
    GLint _displayPositionAttribute, _displayTextureCoordinateAttribute;
    GLint _displayInputTextureUniform;

    CGSize _inputImageSize;
    GLfloat _imageVertices[8];
    GLfloat _backgroundColorRed, _backgroundColorGreen, _backgroundColorBlue, _backgroundColorAlpha;

    CGSize _boundsSizeAtFrameBufferEpoch;
    CGSize _sizeInPixels;
}
@property (nonatomic, weak) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIBlurEffect *effect;
@end

@implementation JPPreviewView

#pragma mark - Initialization and teardown

+ (Class)layerClass {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [CAEAGLLayer class];
#pragma clang diagnostic pop
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // Set scaling to account for Retina display
    if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }

    _inputRotation = kGPUImageNoRotation;
    self.opaque = YES;
    self.hidden = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
#pragma clang diagnostic pop
    self.enabled = YES;
    
    __weak typeof(self) wSelf = self;
    runSynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        [GPUImageContext useImageProcessingContext];
        
        sSelf->_displayProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
        if (!sSelf->_displayProgram.initialized) {
            [sSelf->_displayProgram addAttribute:@"position"];
            [sSelf->_displayProgram addAttribute:@"inputTextureCoordinate"];
            
            if (![sSelf->_displayProgram link]) {
                NSString *progLog = [sSelf->_displayProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [sSelf->_displayProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [sSelf->_displayProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                sSelf->_displayProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        sSelf->_displayPositionAttribute = [sSelf->_displayProgram attributeIndex:@"position"];
        sSelf->_displayTextureCoordinateAttribute = [sSelf->_displayProgram attributeIndex:@"inputTextureCoordinate"];
        sSelf->_displayInputTextureUniform = [sSelf->_displayProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputTexture" for the fragment shader

        [GPUImageContext setActiveShaderProgram:sSelf->_displayProgram];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        glEnableVertexAttribArray(sSelf->_displayPositionAttribute);
        glEnableVertexAttribArray(sSelf->_displayTextureCoordinateAttribute);
#pragma clang diagnostic pop
        [sSelf setBackgroundColorRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        sSelf->_fillMode = kGPUImageFillModePreserveAspectRatio;
        [sSelf createDisplayFramebuffer];
    });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // The frame buffer needs to be trashed and re-created when the view size changes.
    if (!CGSizeEqualToSize(self.bounds.size, _boundsSizeAtFrameBufferEpoch) &&
        !CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        __weak typeof(self) wSelf = self;
        runSynchronouslyOnVideoProcessingQueue(^{
            __strong typeof(wSelf) sSelf = wSelf;
            if (!sSelf) return;
            [sSelf destroyDisplayFramebuffer];
            [sSelf createDisplayFramebuffer];
        });
    } else if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        [self recalculateViewGeometry];
    }
}

- (void)dealloc {
    // 为了确保这里能够执行完这个销毁过程，这里就不“__weak/strong self”了
    runSynchronouslyOnVideoProcessingQueue(^{
        [self destroyDisplayFramebuffer];
        NSLog(@"JPPreviewView is destroy.");
    });
}

#pragma mark - Managing the display FBOs

- (void)createDisplayFramebuffer {
    [GPUImageContext useImageProcessingContext];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    glGenFramebuffers(1, &_displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
    
    glGenRenderbuffers(1, &_displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _displayRenderbuffer);
    
    [[[GPUImageContext sharedImageProcessingContext] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    GLint backingWidth, backingHeight;

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if ((backingWidth == 0) || (backingHeight == 0)) {
        [self destroyDisplayFramebuffer];
        return;
    }
    
    _sizeInPixels.width = (CGFloat)backingWidth;
    _sizeInPixels.height = (CGFloat)backingHeight;

//    NSLog(@"Backing width: %d, height: %d", backingWidth, backingHeight);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _displayRenderbuffer);
    
    __unused GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
#pragma clang diagnostic pop
    
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %f, %f", self.bounds.size.width, self.bounds.size.height);
    _boundsSizeAtFrameBufferEpoch = self.bounds.size;
    
    [self recalculateViewGeometry];
}

- (void)destroyDisplayFramebuffer {
    [GPUImageContext useImageProcessingContext];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (_displayFramebuffer) {
        glDeleteFramebuffers(1, &_displayFramebuffer);
        _displayFramebuffer = 0;
    }
    
    if (_displayRenderbuffer) {
        glDeleteRenderbuffers(1, &_displayRenderbuffer);
        _displayRenderbuffer = 0;
    }
#pragma clang diagnostic pop
}

- (void)setDisplayFramebuffer {
    if (!_displayFramebuffer) {
        [self createDisplayFramebuffer];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    glBindFramebuffer(GL_FRAMEBUFFER, _displayFramebuffer);
#pragma clang diagnostic pop
    glViewport(0, 0, (GLint)_sizeInPixels.width, (GLint)_sizeInPixels.height);
}

- (void)presentFramebuffer {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    glBindRenderbuffer(GL_RENDERBUFFER, _displayRenderbuffer);
#pragma clang diagnostic pop
    [[GPUImageContext sharedImageProcessingContext] presentBufferForDisplay];
}

#pragma mark - Handling fill mode

- (void)recalculateViewGeometry {
    __weak typeof(self) wSelf = self;
    runSynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        CGSize inputImageSize = sSelf->_inputImageSize;
        if (inputImageSize.width <= 0 || inputImageSize.height <= 0) return;
        
        CGFloat heightScaling, widthScaling;
        
        // jp_修改GPUImage：确保访问bounds属性时是在主线程
        __block CGRect currentViewBounds;
        if (NSThread.isMainThread) {
            currentViewBounds = sSelf.bounds;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                currentViewBounds = sSelf.bounds;
            });
        }
        CGSize currentViewSize = currentViewBounds.size;
        
        //    CGFloat imageAspectRatio = inputImageSize.width / inputImageSize.height;
        //    CGFloat viewAspectRatio = currentViewSize.width / currentViewSize.height;
        
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(inputImageSize, currentViewBounds);
        
        switch(sSelf->_fillMode) {
            case kGPUImageFillModeStretch:
            {
                widthScaling = 1.0;
                heightScaling = 1.0;
                break;
            }
                
            case kGPUImageFillModePreserveAspectRatio:
            {
                widthScaling = insetRect.size.width / currentViewSize.width;
                heightScaling = insetRect.size.height / currentViewSize.height;
                break;
            }
                
            case kGPUImageFillModePreserveAspectRatioAndFill:
            {
//                CGFloat widthHolder = insetRect.size.width / currentViewSize.width;
                widthScaling = currentViewSize.height / insetRect.size.height;
                heightScaling = currentViewSize.width / insetRect.size.width;
                break;
            }
        }
        
        sSelf->_imageVertices[0] = -widthScaling;
        sSelf->_imageVertices[1] = -heightScaling;
        sSelf->_imageVertices[2] = widthScaling;
        sSelf->_imageVertices[3] = -heightScaling;
        sSelf->_imageVertices[4] = -widthScaling;
        sSelf->_imageVertices[5] = heightScaling;
        sSelf->_imageVertices[6] = widthScaling;
        sSelf->_imageVertices[7] = heightScaling;
    });
    
//    static const GLfloat imageVertices[] = {
//        -1.0f, -1.0f,
//        1.0f, -1.0f,
//        -1.0f,  1.0f,
//        1.0f,  1.0f,
//    };
}

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent {
    _backgroundColorRed = redComponent;
    _backgroundColorGreen = greenComponent;
    _backgroundColorBlue = blueComponent;
    _backgroundColorAlpha = alphaComponent;
}

+ (const GLfloat *)textureCoordinatesForRotation:(GPUImageRotationMode)rotationMode {
//    static const GLfloat noRotationTextureCoordinates[] = {
//        0.0f, 0.0f,
//        1.0f, 0.0f,
//        0.0f, 1.0f,
//        1.0f, 1.0f,
//    };
    
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    static const GLfloat rotateRightTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotateLeftTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
        
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
    };
    
    switch(rotationMode) {
        case kGPUImageNoRotation: return noRotationTextureCoordinates;
        case kGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

#pragma mark - GPUInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    __weak typeof(self) wSelf = self;
    runSynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        [GPUImageContext setActiveShaderProgram:sSelf->_displayProgram];
        [sSelf setDisplayFramebuffer];
        
        glClearColor(sSelf->_backgroundColorRed, sSelf->_backgroundColorGreen, sSelf->_backgroundColorBlue, sSelf->_backgroundColorAlpha);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, [sSelf->_inputFramebufferForDisplay texture]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        glUniform1i(sSelf->_displayInputTextureUniform, 4);
        
        glVertexAttribPointer(sSelf->_displayPositionAttribute, 2, GL_FLOAT, 0, 0, sSelf->_imageVertices);
        glVertexAttribPointer(sSelf->_displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [JPPreviewView textureCoordinatesForRotation:sSelf->_inputRotation]);
#pragma clang diagnostic pop
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        [sSelf presentFramebuffer];
        [sSelf->_inputFramebufferForDisplay unlock];
        sSelf->_inputFramebufferForDisplay = nil;
    });
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    _inputFramebufferForDisplay = newInputFramebuffer;
    [_inputFramebufferForDisplay lock];
}

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex {
    _inputRotation = newInputRotation;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    __weak typeof(self) wSelf = self;
    runSynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(wSelf) sSelf = wSelf;
        if (!sSelf) return;
        
        CGSize rotatedSize = newSize;
        
        if (GPUImageRotationSwapsWidthAndHeight(sSelf->_inputRotation)) {
            rotatedSize.width = newSize.height;
            rotatedSize.height = newSize.width;
        }
        
        if (!CGSizeEqualToSize(sSelf->_inputImageSize, rotatedSize)) {
            sSelf->_inputImageSize = rotatedSize;
            [sSelf recalculateViewGeometry];
        }
    });
}

- (CGSize)maximumOutputSize {
    if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
        CGSize pointSize = self.bounds.size;
        return CGSizeMake(self.contentScaleFactor * pointSize.width, self.contentScaleFactor * pointSize.height);
    } else {
        return self.bounds.size;
    }
}

- (void)endProcessing {}

- (BOOL)shouldIgnoreUpdatesToThisTarget {
    return NO;
}

- (BOOL)wantsMonochromeInput {
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {}

#pragma mark - Accessors

- (CGSize)sizeInPixels {
    if (CGSizeEqualToSize(_sizeInPixels, CGSizeZero)) {
        return [self maximumOutputSize];
    } else {
        return _sizeInPixels;
    }
}

- (void)setFillMode:(GPUImageFillModeType)newValue {
    _fillMode = newValue;
    [self recalculateViewGeometry];
}

#pragma mark - 视频画面设置

- (void)setIsShowBlurView:(BOOL)isShowBlurView {
    [self setIsShowBlurView:isShowBlurView duration:0 complete:nil];
}

- (void)setIsShowBlurView:(BOOL)isShowBlurView duration:(NSTimeInterval)duration complete:(void(^)(void))complete {
    if (_isShowBlurView == isShowBlurView) return;
    _isShowBlurView = isShowBlurView;
    
    if (isShowBlurView && !self.blurView) {
        self.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:nil];
        blurView.userInteractionEnabled = NO;
        blurView.frame = self.bounds;
        [self addSubview:blurView];
        self.blurView = blurView;
    }
    
    UIBlurEffect *effect = isShowBlurView ? self.effect : nil;
    if (duration > 0) {
        [UIView animateWithDuration:duration animations:^{
            self.blurView.effect = effect;
        } completion:^(BOOL finished) {
            if (finished && complete) complete();
        }];
    } else {
        self.blurView.effect = effect;
        !complete ? : complete();
    }
}
@end
