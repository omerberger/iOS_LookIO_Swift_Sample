//
//  LIOKeyboardMenu.m
//  LookIO
//
//  Created by Yaron Karasik on 8/5/13.
//
//

#import "LIOKeyboardMenu.h"
#import "LIOBundleManager.h"
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
        self.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.55];
        
        self.items = [[NSMutableArray alloc] init];
        [self setDefaultButtonItems];
        
        for (int i=0; i<self.items.count; i++)
        {
            LIOKeyboardMenuItem *item = [self.items objectAtIndex:i];
            LIOKeyboardMenuButton *button = [[LIOKeyboardMenuButton alloc] init];
            button.tag = LIOKeyboardMenuButtonTagBase + i;
            [button setImage:[[LIOBundleManager sharedBundleManager] imageNamed:item.iconName] forState:UIControlStateNormal];
            [button setBottomLabelText:[item.title uppercaseString]];
            [button addTarget:self action:@selector(keyboardMenuButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
        }
        
        /*
        
        BOOL attachNeeded = [[LIOLookIOManager sharedLookIOManager] enabledCollaborationComponents];

        if (attachNeeded) {
            LIOKeyboardMenuButton* attachButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
            [attachButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOCameraIconLarge"] forState:UIControlStateNormal];
            [self addSubview:attachButton];
            [attachButton setBottomLabelText:[LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonSendPhoto") uppercaseString]];
            [attachButton addTarget:self action:@selector(attachButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
            [buttonsArray addObject:attachButton];
        }
        
        LIOKeyboardMenuButton* faqsButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [faqsButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIONewspaperIcon"] forState:UIControlStateNormal];
        [self addSubview:faqsButton];
        [faqsButton setBottomLabelText:[LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonFaqs") uppercaseString]];
        [faqsButton addTarget:self action:@selector(faqsButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:faqsButton];
        
        LIOKeyboardMenuButton* emailChatButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [emailChatButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOEnvelopeIconLarge"] forState:UIControlStateNormal];
        [self addSubview:emailChatButton];
        [emailChatButton setBottomLabelText:[LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonEmailChat") uppercaseString]];
        [emailChatButton addTarget:self action:@selector(emailChatButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:emailChatButton];
        
        LIOKeyboardMenuButton* hideChatButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [hideChatButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIORoadSignIcon"] forState:UIControlStateNormal];
        [self addSubview:hideChatButton];
        [hideChatButton setBottomLabelText:[LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonHideChat") uppercaseString]];
        [hideChatButton addTarget:self action:@selector(hideChatButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:hideChatButton];
        
        LIOKeyboardMenuButton* endSessionButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [endSessionButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSkullIcon"] forState:UIControlStateNormal];
        [self addSubview:endSessionButton];
        [endSessionButton setBottomLabelText:[LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonEndSession") uppercaseString]];
        [endSessionButton addTarget:self action:@selector(endSessionButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:endSessionButton];
        
        LIOKeyboardMenuButton* keyboardButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [keyboardButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOArrowUpIconLarge"] forState:UIControlStateNormal];
        [self addSubview:keyboardButton];
        [keyboardButton setBottomLabelText:[LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonKeyboard") uppercaseString]];
        [keyboardButton addTarget:self action:@selector(showKeyboardButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:keyboardButton];
         */
    }
    
    return self;
}

- (void)setDefaultButtonItems
{
    LIOKeyboardMenuItem *item = [[LIOKeyboardMenuItem alloc] init];
    item.type = LIOKeyboardMenuItemEndChat;
    item.title = LIOLocalizedString(@"LIOLookIOManager.KeyboardMenuButtonEndSession");
    item.iconName = @"LIOSkullIcon";
    
    [self.items addObject:item];
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

-(void)drawRect:(CGRect)rect {
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

- (void)keyboardMenuButtonWasTapped:(id)sender
{
    LIOKeyboardMenuButton *button = (LIOKeyboardMenuButton *)sender;
    LIOKeyboardMenuItem *item = [self.items objectAtIndex:(button.tag - LIOKeyboardMenuButtonTagBase)];
    
    [self.delegate keyboardMenu:self itemWasTapped:item];
}

@end
