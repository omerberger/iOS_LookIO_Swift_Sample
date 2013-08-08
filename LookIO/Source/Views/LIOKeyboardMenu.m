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

@implementation LIOKeyboardMenu

@synthesize buttonsArray, delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
        
        buttonsArray = [[NSMutableArray alloc] init];
        
        UIImageView* backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        backgroundImageView.image = [[LIOBundleManager sharedBundleManager] imageNamed:@"LIOKeyboardMenuSeparators"];
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:backgroundImageView];
        [backgroundImageView release];
        
        LIOKeyboardMenuButton* attachButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [attachButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOCameraIconLarge"] forState:UIControlStateNormal];
        [self addSubview:attachButton];
        [attachButton setBottomLabelText:@"SEND PHOTO"];
        [attachButton addTarget:self action:@selector(attachButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:attachButton];
        [attachButton release];
        
        LIOKeyboardMenuButton* faqsButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [faqsButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIONewspaperIcon"] forState:UIControlStateNormal];
        [self addSubview:faqsButton];
        [faqsButton setBottomLabelText:@"FAQS"];
        [faqsButton addTarget:self action:@selector(faqsButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:faqsButton];
        [faqsButton release];
        
        LIOKeyboardMenuButton* emailChatButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [emailChatButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOEnvelopeIconLarge"] forState:UIControlStateNormal];
        [self addSubview:emailChatButton];
        [emailChatButton setBottomLabelText:@"EMAIL CHAT"];
        [emailChatButton addTarget:self action:@selector(emailChatButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:emailChatButton];
        [emailChatButton release];
        
        LIOKeyboardMenuButton* hideChatButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [hideChatButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIORoadSignIcon"] forState:UIControlStateNormal];
        [self addSubview:hideChatButton];
        [hideChatButton setBottomLabelText:@"HIDE CHAT"];
        [hideChatButton addTarget:self action:@selector(hideChatButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:hideChatButton];
        [hideChatButton release];
        
        LIOKeyboardMenuButton* endSessionButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [endSessionButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOSkullIcon"] forState:UIControlStateNormal];
        [self addSubview:endSessionButton];
        [endSessionButton setBottomLabelText:@"END SESSION"];
        [endSessionButton addTarget:self action:@selector(endSessionButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:endSessionButton];
        [endSessionButton release];
        
        LIOKeyboardMenuButton* keyboardButton = [[LIOKeyboardMenuButton alloc] initWithFrame:CGRectZero];
        [keyboardButton setImage:[[LIOBundleManager sharedBundleManager] imageNamed:@"LIOArrowUpIconLarge"] forState:UIControlStateNormal];
        [self addSubview:keyboardButton];
        [keyboardButton setBottomLabelText:@"KEYBOARD"];
        [keyboardButton addTarget:self action:@selector(showKeyboardButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsArray addObject:keyboardButton];
        [keyboardButton release];
        
    }
    return self;
}

-(void)layoutSubviews {
    for (int i=0; i<buttonsArray.count; i++) {
        LIOKeyboardMenuButton* button = (LIOKeyboardMenuButton*)[buttonsArray objectAtIndex:i];

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

-(void)hideChatButtonWasTapped:(id)sender {
    [self.delegate keyboardMenuHideChatButtonWasTapped:self];
}

-(void)emailChatButtonWasTapped:(id)sender {
    [self.delegate keyboardMenuEmailChatButtonWasTapped:self];
}

-(void)endSessionButtonWasTapped:(id)sender {
    [self.delegate keyboardMenuEndSessionButtonWasTapped:self];
}

-(void)showKeyboardButtonWasTapped:(id)sender {
    [self.delegate keyboardMenuShowKeyboardButtonWasTapped:self];
}

-(void)attachButtonWasTapped:(id)sender {
    [self.delegate keyboardMenuAttachButtonWasTapped:self];
}

-(void)faqsButtonWasTapped:(id)sender {
    //
}

@end
