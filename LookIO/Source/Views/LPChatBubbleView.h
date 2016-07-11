//
//  LPChatBubbleView.h
//  LookIO
//
//  Created by Yaron Karasik on 12/20/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOChatMessage.h"
#import "TTTAttributedLabel.h"

@class LPChatBubbleView;

@protocol LPChatBubbleViewDelegate <NSObject>

- (void)chatBubbleView:(LPChatBubbleView *)aView didTapIntraAppLinkWithURL:(NSURL *)aURL;
- (void)chatBubbleView:(LPChatBubbleView *)aView didTapPhoneURL:(NSURL *)aURL link:(NSString *)aLink;
- (void)chatBubbleView:(LPChatBubbleView *)aView didTapWebLinkWithURL:(NSURL *)aURL;

@end

@interface LPChatBubbleView : UIView

@property (nonatomic, assign) id<LPChatBubbleViewDelegate> delegate;
@property (nonatomic, strong) TTTAttributedLabel_LIO *messageLabel;
@property (nonatomic, strong) NSMutableArray *linkButtons;

- (CGFloat)populateLinksChatBubbleViewWithMessage:(LIOChatMessage *)chatMessage forWidth:(CGFloat)width;
- (void)prepareForReuse;

@end
