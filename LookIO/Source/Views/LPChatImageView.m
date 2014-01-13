//
//  LPChatImageView.m
//  LookIO
//
//  Created by Yaron Karasik on 1/13/14.
//
//

#import "LPChatImageView.h"

#import "LIOBundleManager.h"

@implementation LPChatImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 10.0;
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.layer.masksToBounds = YES;
        self.imageView.layer.cornerRadius = 10.0;
        
        [self addSubview:self.imageView];

        UIImage *stretchableShadow = stretchableShadow = [[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOStretchablePhotoShadow"] stretchableImageWithLeftCapWidth:42 topCapHeight:62];
        self.foregroundImageView = [[UIImageView alloc] initWithImage:stretchableShadow];
        self.foregroundImageView.frame = self.bounds;
        self.foregroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
//        [self addSubview:self.foregroundImageView];
    }
    
    return self;
}

@end

