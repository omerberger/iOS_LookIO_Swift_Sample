//
//  LIOBlurImageView.m
//  LookIO
//
//  Created by Yaron Karasik on 8/2/13.
//
//

#import "LIOBlurImageView.h"
#import "UIImage+ImageEffects.h"
#import <QuartzCore/QuartzCore.h>

@interface LIOBlurImageView ()

@property (nonatomic, retain) CALayer *tintLayer;

@end

@implementation LIOBlurImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.tintLayer = [[[CALayer alloc] init] autorelease];
        self.tintLayer.frame = self.bounds;
        self.tintLayer.opacity = 0.5;
        
        [self.layer addSublayer:self.tintLayer];
    }
    return self;
}

-(void)dealloc {
    [super dealloc];
}

-(void)setImageAndBlur:(UIImage*)imageToBlur {
    NSData *imageData = UIImageJPEGRepresentation(imageToBlur, 1.0);

    UIColor *tintColor = [UIColor colorWithWhite:0.6 alpha:0.2];
    self.image = [[UIImage imageWithData:imageData] applyBlurWithRadius:6 tintColor:tintColor saturationDeltaFactor:1.0 maskImage:nil];
}


@end
