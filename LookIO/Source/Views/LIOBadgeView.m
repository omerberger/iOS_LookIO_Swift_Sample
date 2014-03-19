//
//  LIOBadgeView.m
//  LookIO
//
//  Created by Yaron Karasik on 1/24/14.
//
//

#import "LIOBadgeView.h"

@interface LIOBadgeView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation LIOBadgeView

- (id)initWithFrame:(CGRect)frame forBrandingElement:(LIOBrandingElement)element
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.label.textColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:element];
        self.label.font = [[LIOBrandingManager brandingManager] fontForElement:element];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.backgroundColor = [UIColor clearColor];
        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementControlButtonBadge] CGColor]);
    CGContextFillEllipseInRect(ctx, rect);
}

- (void)setBadgeNumber:(NSInteger)number
{
    self.label.text = [NSString stringWithFormat:@"%ld", (long)number];
}

@end