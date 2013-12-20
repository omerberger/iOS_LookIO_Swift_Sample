//
//  LIOBrandingManager.h
//  LookIO
//
//  Created by Yaron Karasik on 12/17/13.
//
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOBrandingElementControlButton = 0,
    LIOBrandingElementLoadingScreen,
    LIOBrandingElementChatBackground,
    LIOBrandingElementFont,
    LIOBrandingElementLogo,
    LIOBrandingElementBrandingBar,
    LIOBrandingElementBrandingBarNotifications,
    LIOBrandingElementAgentChatBubble,
    LIOBrandingElementAgentChatBubbleLink,
    LIOBrandingElementVisitorChatBubble,
    LIOBrandingElementVisitorChatBubbleLink
} LIOBrandingElement;

typedef enum
{
    LIOBrandingColorBackground = 0,
    LIOBrandingColorText,
    LIOBrandingColorBorder,
    LIOBrandingColorContent
} LIOBrandingColor;

@interface LIOBrandingManager : NSObject

+ (LIOBrandingManager *)brandingManager;
- (UIColor *)colorType:(LIOBrandingColor)colorType forElement:(LIOBrandingElement)element;
- (CGFloat)alphaForElement:(LIOBrandingElement)element;
- (CGFloat)widthForElement:(LIOBrandingElement)element;
- (NSString *)fontNameForElement:(LIOBrandingElement)element;
- (CGFloat)fontSizeForElement:(LIOBrandingElement)element;

@end

