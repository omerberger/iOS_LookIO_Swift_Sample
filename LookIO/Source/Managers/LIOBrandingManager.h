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
    LIOBrandingElementControlButtonBadge,
    LIOBrandingElementLoadingScreen,
    LIOBrandingElementLoadingScreenTitle,
    LIOBrandingElementLoadingScreenSubtitle,
    LIOBrandingElementChatBackground,
    LIOBrandingElementFont,
    LIOBrandingElementBoldFont,
    LIOBrandingElementLogo,
    LIOBrandingElementBrandingBar,
    LIOBrandingElementBrandingBarNotifications,
    LIOBrandingElementAgentChatBubble,
    LIOBrandingElementAgentChatBubbleLink,
    LIOBrandingElementVisitorChatBubble,
    LIOBrandingElementVisitorChatBubbleLink,
    LIOBrandingElementSendBar,
    LIOBrandingElementSendBarTextField,
    LIOBrandingElementSendBarPlusButton,
    LIOBrandingElementSendBarSendButton,
    LIOBrandingElementSendBarCharacterCount,
    LIOBrandingElementKeyboardMenu,
    LIOBrandingElementSurveyPageControl,
    LIOBrandingElementSurveyCard,
    LIOBrandingElementSurveyCardTitle,
    LIOBrandingElementSurveyCardSubtitle,
    LIOBrandingElementSurveyCardNextButton,
    LIOBrandingElementSurveyCardCancelButton,
    LIOBrandingElementSurveyTextField,
    LIOBrandingElementSurveyList,
    LIOBrandingElementSurveyStars,
    LIOBrandingElementSurveyValidationAlert,
    LIOBrandingElementEmailChat,
    LIOBrandingElementEmailChatCard,
    LIOBrandingElementEmailChatTitle,
    LIOBrandingElementEmailChatSubtitle,
    LIOBrandingElementEmailChatTextField,
    LIOBrandingElementEmailChatSubmitButton,
    LIOBrandingElementEmailChatCancelButton,
    LIOBrandingElementToasterView
} LIOBrandingElement;

typedef enum
{
    LIOBrandingColorBackground = 0,
    LIOBrandingColorText,
    LIOBrandingColorBorder,
    LIOBrandingColorContent,
    LIOBrandingColorIcon,
    LIOBrandingColorColor
} LIOBrandingColor;

@interface LIOBrandingManager : NSObject

+ (LIOBrandingManager *)brandingManager;
- (UIColor *)colorType:(LIOBrandingColor)colorType forElement:(LIOBrandingElement)element;
- (CGFloat)alphaForElement:(LIOBrandingElement)element;
- (CGFloat)backgroundAlphaForElement:(LIOBrandingElement)element;
- (CGFloat)widthForElement:(LIOBrandingElement)element;
- (NSString *)fontNameForElement:(LIOBrandingElement)element;
- (NSString *)boldFontNameForElement:(LIOBrandingElement)element;
- (UIFont *)boldFontForElement:(LIOBrandingElement)element;
- (UIFont *)fontForElement:(LIOBrandingElement)element;
- (CGFloat)fontSizeForElement:(LIOBrandingElement)element;
- (BOOL)booleanValueForField:(NSString *)field element:(LIOBrandingElement)element;

@end

