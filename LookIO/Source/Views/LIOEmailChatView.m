//
//  LIOEmailChatView.m
//  LookIO
//
//  Created by Yaron Karasik on 1/8/14.
//
//

#import "LIOEmailChatView.h"

#import "LIOBrandingManager.h"
#import "LIOBundleManager.h"

@interface LIOEmailChatView ()

@property (nonatomic, strong) UITextField *emailTextField;

@end

@implementation LIOEmailChatView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBackground forElement:LIOBrandingElementEmailChat];
        self.alpha = [[LIOBrandingManager brandingManager] backgroundAlphaForElement:LIOBrandingElementEmailChat];
        self.layer.borderColor = [[[LIOBrandingManager brandingManager] colorType:LIOBrandingColorBorder forElement:LIOBrandingElementEmailChat] CGColor];
        self.layer.cornerRadius = 5.0;
        
        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 100, 20)];
        [cancelButton setTitle:LIOLocalizedString(@"LIOEmailHistoryViewController.NavLeftButton") forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancelButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        UIColor *cancelButtonColor = [[LIOBrandingManager brandingManager] colorType:LIOBrandingColorText forElement:LIOBrandingElementEmailChatCancelButton];
        [cancelButton setTitleColor:cancelButtonColor forState:UIControlStateNormal];
        [cancelButton setTitleColor:[cancelButtonColor colorWithAlphaComponent:0.3] forState:UIControlStateNormal | UIControlStateHighlighted];
        cancelButton.titleLabel.font = [[LIOBrandingManager brandingManager] fontForElement:LIOBrandingElementEmailChatCancelButton];
        [self addSubview:cancelButton];
    }
    
    return self;
}

- (void)cancelButtonWasTapped:(id)sender
{
    [self.delegate emailChatViewDidCancel:self];
}

- (void)submitButtonWasTapped:(id)sender
{

}


@end
