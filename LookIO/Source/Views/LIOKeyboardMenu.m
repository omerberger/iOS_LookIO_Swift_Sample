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

@property (nonatomic, assign) NSInteger numberOfPages;
@property (nonatomic, assign) NSInteger numberOfRows;
@property (nonatomic, assign) NSInteger numberOfColumns;
@property (nonatomic, assign) NSInteger numberOfItemsPerPage;

@end

@implementation LIOKeyboardMenu

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        
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
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemWebView;
    item.title = @"Sample";
    item.iconName = @"LIONewspaperIcon";
    
    [self.items addObject:item];
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemWebView;
    item.title = @"Sample";
    item.iconName = @"LIONewspaperIcon";
    
    [self.items addObject:item];
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemWebView;
    item.title = @"Sample";
    item.iconName = @"LIONewspaperIcon";
    
    [self.items addObject:item];
    
    item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemWebView;
    item.title = @"Sample";
    item.iconName = @"LIONewspaperIcon";
    
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
    BOOL padUI = UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom];

    NSInteger rowWidth = padUI ? 160 : 100;
    NSInteger rowHeight = padUI ? 120 : 80;
    
    if (self.bounds.size.width < rowWidth || self.bounds.size.height < rowHeight)
        return;
    
    self.numberOfColumns = self.bounds.size.width / rowWidth;
    self.numberOfRows = self.bounds.size.height / rowHeight;
    self.numberOfItemsPerPage = self.numberOfColumns * self.numberOfRows;
    self.numberOfPages = (self.items.count / self.numberOfItemsPerPage);
    if ((self.items.count % self.numberOfItemsPerPage) != 0)
        self.numberOfPages += 1;
    
    CGSize contentSize = self.contentSize;
    contentSize.width = self.numberOfPages*self.bounds.size.width;
    self.contentSize = contentSize;
    
    for (int i=0; i<self.items.count; i++) {
        LIOKeyboardMenuButton* button = (LIOKeyboardMenuButton*)[self viewWithTag:(i + LIOKeyboardMenuButtonTagBase)];

        NSInteger currentPage = i/self.numberOfItemsPerPage;
        NSInteger currentIndexInPage = i - currentPage*self.numberOfItemsPerPage;
        
        NSInteger buttonRow = currentIndexInPage/self.numberOfColumns;
        NSInteger buttonColumn = currentIndexInPage % self.numberOfColumns;
        
        CGRect aFrame = button.frame;
        aFrame.size.width = self.bounds.size.width/self.numberOfColumns;
        aFrame.size.height = self.bounds.size.height/self.numberOfRows;
        aFrame.origin.x = buttonColumn*aFrame.size.width + self.bounds.size.width*currentPage;
        aFrame.origin.y = buttonRow*aFrame.size.height;
        button.frame = aFrame;
    }
    
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *lineColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementKeyboardMenu];

    CGContextSaveGState(context);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    for (int i=1; i<self.numberOfRows; i++)
    {
        CGContextMoveToPoint(context, 0, (self.bounds.size.height/self.numberOfRows)*i);
        CGContextAddLineToPoint(context, self.bounds.size.width*self.numberOfPages, (self.bounds.size.height/self.numberOfRows)*i);
    }
    
    for (int i=0; i<self.numberOfPages; i++)
    {
        for (int j=0; j<self.numberOfColumns; j++)
        {
            // Don't draw first row
            if (!(i == 0 && j == 0))
            {
                CGContextMoveToPoint(context, (self.bounds.size.width/self.numberOfColumns)*j + i*self.bounds.size.width, 0);
                CGContextAddLineToPoint(context,(self.bounds.size.width/self.numberOfColumns)*j + i*self.bounds.size.width, self.bounds.size.height);
            }
        }
    }

    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);    
}

- (void)keyboardMenuButtonWasTapped:(id)sender
{
    LIOKeyboardMenuButton *button = (LIOKeyboardMenuButton *)sender;
    LIOKeyboardMenuItem *item = [self.items objectAtIndex:(button.tag - LIOKeyboardMenuButtonTagBase)];
    
    [self.delegate keyboardMenu:self itemWasTapped:item];
}

@end
