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

@synthesize tintLayer;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.tintLayer = [[[CALayer alloc] init] autorelease];
        self.tintLayer.frame = self.bounds;
        self.tintLayer.opacity = 0.4;
        self.tintLayer.backgroundColor = [[UIColor colorWithWhite:0.85 alpha:1.0] CGColor];
        
        [self.layer addSublayer:self.tintLayer];
    }
    return self;
}

-(void)dealloc {
    [super dealloc];
}

-(void)setImageAndBlur:(UIImage*)imageToBlur {
    UIColor *tintColor = [UIColor colorWithWhite:0.8 alpha:0.4];
    
    self.image = [imageToBlur applyBlurWithRadius:12 tintColor:tintColor saturationDeltaFactor:3.0 maskImage:nil];
}


@end
