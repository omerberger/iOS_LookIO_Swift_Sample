//
//  LIOBlurImageView.m
//  LookIO
//
//  Created by Yaron Karasik on 8/2/13.
//
//

#import "LIOBlurImageView.h"

// Core Libraries
#import <Accelerate/Accelerate.h>
#import <float.h>

// Managers
#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

@interface LIOBlurImageView ()

@property (nonatomic, retain) CALayer *tintLayer;

@end

@implementation LIOBlurImageView

@synthesize tintLayer;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.tintLayer = [[CALayer alloc] init];
        self.tintLayer.frame = self.bounds;
        self.tintLayer.opacity = 0.4;
        
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementChatBackground];
        CGFloat backgroundColorAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementChatBackground];
        
        self.tintLayer.backgroundColor = [[backgroundColor colorWithAlphaComponent:backgroundColorAlpha] CGColor];
        
        [self.layer addSublayer:self.tintLayer];
    }
    return self;
}

-(void)setImageAndBlur:(UIImage*)imageToBlur
{
    self.tintLayer.frame = self.bounds;
    
    CGFloat blurRadius = [[LIOBrandingManager brandingManager] floatValueForField:@"radius" forElement:LIOBrandingElementChatBackgroundBlur];
    NSInteger blurIterations = [[LIOBrandingManager brandingManager] integerValueForField:@"iterations" forElement:LIOBrandingElementChatBackgroundBlur];
    CGFloat saturationFactor = [[LIOBrandingManager brandingManager] floatValueForField:@"saturation_factor" forElement:LIOBrandingElementChatBackgroundBlur];
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
        UIColor *tintColor = [UIColor colorWithWhite:0.1 alpha:0.4];
        self.image = [self blurImage:imageToBlur withRadius:blurRadius iterations:blurIterations tintColor:tintColor saturationDeltaFactor:saturationFactor];
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
    }
}

- (void)layoutSubviews
{
    self.tintLayer.frame = self.bounds;
}

- (UIImage *)blurImage:(UIImage*)image withRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor
{
    //image must be nonzero size
    if (floorf(image.size.width) * floorf(image.size.height) <= 0.0f) return image;
    
    //boxsize must be an odd integer
    uint32_t boxSize = radius * image.scale;
    if (boxSize % 2 == 0) boxSize ++;
    
    //create image buffers
    CGImageRef imageRef = image.CGImage;
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    CFIndex bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);
    
    //create temp buffer
    void *tempBuffer = malloc(vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                         NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);
    
    for (NSUInteger i = 0; i < iterations; i++)
    {
        //perform blur
        vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
        
        //swap buffers
        void *temp = buffer1.data;
        buffer1.data = buffer2.data;
        buffer2.data = temp;
    }
    
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasSaturationChange) {
        CGFloat s = saturationDeltaFactor;
        CGFloat floatingPointSaturationMatrix[] = {
            0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
            0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
            0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
            0,                    0,                    0,  1,
        };
        const int32_t divisor = 256;
        NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
        int16_t saturationMatrix[matrixSize];
        for (NSUInteger i = 0; i < matrixSize; ++i) {
            saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
        }
        vImageMatrixMultiply_ARGB8888(&buffer1, &buffer2, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
    }
    
    void *temp = buffer1.data;
    buffer1.data = buffer2.data;
    buffer2.data = temp;
    
    //free buffers
    free(buffer2.data);
    free(tempBuffer);
    
    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    //apply tint
    if (tintColor && CGColorGetAlpha(tintColor.CGColor) > 0.0f)
    {
        CGContextSetFillColorWithColor(ctx, [tintColor colorWithAlphaComponent:0.25].CGColor);
        CGContextSetBlendMode(ctx, kCGBlendModePlusLighter);
        CGContextFillRect(ctx, CGRectMake(0, 0, buffer1.width, buffer1.height));
    }
    
    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return resultImage;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
