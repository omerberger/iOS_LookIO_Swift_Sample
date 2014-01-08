//
//  LIOKeyboardMenu.m
//  LookIO
//
//  Created by Yaron Karasik on 8/5/13.
//
//

#import "LIOKeyboardMenu.h"

#import "LIOBundleManager.h"
#import "LIOBrandingManager.h"

#import "LIOKeyboardMenuButton.h"
#import "LIOKeyboardMenuItem.h"

@interface LIOKeyboardMenu ()

#define LIOKeyboardMenuButtonTagBase 2000

@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation LIOKeyboardMenu

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIColor *backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementKeyboardMenu];
        CGFloat backgroundAlpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementKeyboardMenu];
        
        self.backgroundColor = [backgroundColor colorWithAlphaComponent:backgroundAlpha];
        
        self.items = [[NSMutableArray alloc] init];
        
    }
    
    return self;
}

- (void)setDefaultButtonItems
{
    LIOKeyboardMenuItem *item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemSendPhoto;
    item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonSendPhoto");
    item.iconName = @"LIOCameraIconLarge";
    
    [self.items addObject:item];
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemWebView;
    item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonFaqs");
    item.iconName = @"LIONewspaperIcon";
    
    [self.items addObject:item];

    if (![self.delegate keyboardMenuShouldShowHideEmailChatDefaultItem:self])
    {
        item = [[LIOKeyboardMenuItem alloc] init];
        item.type = LIOKeyboardMenuItemEmailChat;
        item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonEmailChat");
        item.iconName = @"LIOEnvelopeIconLarge";
    
        [self.items addObject:item];
    }
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemHideChat;
    item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonHideChat");
    item.iconName = @"LIORoadSignIcon";
    
    [self.items addObject:item];
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemEndChat;
    item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonEndSession");
    item.iconName = @"LIOSkullIcon";

    [self.items addObject:item];
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemShowKeyboard;
    item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonKeyboard");
    item.iconName = @"LIOArrowUpIconLarge";
    
    [self.items addObject:item];

    UIColor *iconColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorIcon forElement:LIOBrandingElementKeyboardMenu];

    for (int i=0; i<self.items.count; i++)
    {
        LIOKeyboardMenuItem *item = [self.items objectAtIndex:i];
        LIOKeyboardMenuButton *button = [[LIOKeyboardMenuButton alloc] init];
        button.tag = LIOKeyboardMenuButtonTagBase + i;
        [button setImage:[[LIOBundleManager sharedBundleManager] imageNamed:item.iconName withTint:iconColor] forState:UIControlStateNormal];
        [button setBottomLabelText:[item.title uppercaseString]];
        [button addTarget:self action:@selector(keyboardMenuButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
    
}

-(void)layoutSubviews {
    for (int i=0; i<self.items.count; i++) {
        LIOKeyboardMenuButton* button = (LIOKeyboardMenuButton*)[self viewWithTag:(i + LIOKeyboardMenuButtonTagBase)];

        int buttonRow = i/3;
        int buttonColumn = i % 3;
        
        CGRect aFrame = button.frame;
        aFrame.size.width = self.bounds.size.width/3;
        aFrame.size.height = self.bounds.size.height/2;
        aFrame.origin.x = buttonColumn*aFrame.size.width;
        aFrame.origin.y = buttonRow*aFrame.size.height;
        button.frame = aFrame;
    }    
}

/*
-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *lineColor = [UIColor colorWithRed:81.0/255.0 green:81.0/255 blue:81.0/255.0 alpha:1.0];
    UIColor *shadowColor = [UIColor colorWithRed:103.0/255.0 green:103.0/255 blue:103.0/255.0 alpha:1.0];

    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(1.0, 1.0), 0.0, shadowColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0, self.bounds.size.height/2);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height/2);
    
    CGContextMoveToPoint(context, self.bounds.size.width/3, 0);
    CGContextAddLineToPoint(context, self.bounds.size.width/3, self.bounds.size.height);
    CGContextMoveToPoint(context, self.bounds.size.width*2/3, 0);
    CGContextAddLineToPoint(context, self.bounds.size.width*2/3, self.bounds.size.height);
    CGContextStrokePath(context);
    
    
    CGContextRestoreGState(context);    
}
*/

- (void)keyboardMenuButtonWasTapped:(id)sender
{
    LIOKeyboardMenuButton *button = (LIOKeyboardMenuButton *)sender;
    LIOKeyboardMenuItem *item = [self.items objectAtIndex:(button.tag - LIOKeyboardMenuButtonTagBase)];
    
    [self.delegate keyboardMenu:self itemWasTapped:item];
}

@end
