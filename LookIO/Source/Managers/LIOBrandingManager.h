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
    LIOBrandingElementControlButtonMessageLabel,
    LIOBrandingElementLoadingScreen,
    LIOBrandingElementLoadingScreenTitle,
    LIOBrandingElementLoadingScreenSubtitle,
    LIOBrandingElementChatBackground,
    LIOBrandingElementChatBackgroundBlur,
    LIOBrandingElementFont,
    LIOBrandingElementBoldFont,
    LIOBrandingElementKeyboardType,
    LIOBrandingElementLogo,
    LIOBrandingElementBrandingBar,
    LIOBrandingElementBrandingBarNotifications,
    LIOBrandingElementWebViewHeaderBar,
    LIOBrandingElementWebViewHeaderBarButtons,
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
    LIOBrandingElementSurveyStarsSelected,
    LIOBrandingElementSurveyStarsUnselected,
    LIOBrandingElementSurveyValidationAlert,
    LIOBrandingElementEmailChat,
    LIOBrandingElementEmailChatCard,
    LIOBrandingElementEmailChatTitle,
    LIOBrandingElementEmailChatSubtitle,
    LIOBrandingElementEmailChatTextField,
    LIOBrandingElementEmailChatSubmitButton,
    LIOBrandingElementEmailChatCancelButton,
    LIOBrandingElementApprovePhoto,
    LIOBrandingElementApprovePhotoCard,
    LIOBrandingElementApprovePhotoTitle,
    LIOBrandingElementApprovePhotoSubmitButton,
    LIOBrandingElementApprovePhotoCancelButton,
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

// Defaults keys
#define LIOBrandingManagerBrandingDictKey      @"LIOBrandingManagerBrandingDictKey"
#define LIOBrandingManagerBrandingDictHashKey  @"LIOBrandingManagerBrandingDictHashKey"

@interface LIOBrandingManager : NSObject

@property (nonatomic, strong) NSDictionary *lastKnownBrandingDictionary;

+ (LIOBrandingManager *)brandingManager;
- (UIColor *)colorForHexString:(NSString *)string;
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
- (BOOL)attachedToRightForElement:(LIOBrandingElement)element;
- (CGFloat)verticalPositionForElement:(LIOBrandingElement)element;
- (CGFloat)floatValueForField:(NSString *)field forElement:(LIOBrandingElement)element;
- (NSInteger)integerValueForField:(NSString *)field forElement:(LIOBrandingElement)element;
- (UIKeyboardAppearance)keyboardTypeForElement:(LIOBrandingElement)element;

@end

