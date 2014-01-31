//
//  LIOBrandingManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/17/13.
//
//

#import "LIOBrandingManager.h"

// Managers
#import "LIOLogManager.h"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

@interface LIOBrandingManager ()

@property (nonatomic, strong) NSDictionary *originalBrandingDictionary;

@end


@implementation LIOBrandingManager

static LIOBrandingManager *brandingManager = nil;

#pragma mark Initialization Methods

+ (LIOBrandingManager *)brandingManager
{
    if (nil == brandingManager)
        brandingManager = [[LIOBrandingManager alloc] init];
    
    return brandingManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        [self loadDefaults];
    }
    
    return self;
}

- (void)loadDefaults
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"branding" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    self.originalBrandingDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:LIOBrandingManagerBrandingDictKey])
    {
        self.lastKnownBrandingDictionary = [userDefaults objectForKey:LIOBrandingManagerBrandingDictKey];
    }
    else
    {
        self.lastKnownBrandingDictionary = nil;
    }
    
}

#pragma mark Helper Methods

- (UIColor *)colorForHexString:(NSString *)string
{
    unsigned int colorValue;
    [[NSScanner scannerWithString:[string stringByReplacingOccurrencesOfString:@"#" withString:@""]] scanHexInt:&colorValue];
    
    return HEXCOLOR(colorValue);
}

#pragma mark Branding Methods

- (NSDictionary *)brandingDictionaryForElement:(LIOBrandingElement)element
{
    NSDictionary *dictionary = nil;
    
    NSDictionary *brandingDictionary = nil;
    if (self.lastKnownBrandingDictionary)
    {
        brandingDictionary = self.lastKnownBrandingDictionary;
    }
    else
    {
        brandingDictionary = self.originalBrandingDictionary;
    }
    @try
    {
        NSDictionary *visitDictionary = [brandingDictionary objectForKey:@"visit"];
        NSDictionary *engagementDictionary = [brandingDictionary objectForKey:@"engagement"];
        NSDictionary *surveyDictionary = [brandingDictionary objectForKey:@"surveys"];
        
        if (LIOBrandingElementControlButton == element)
        {
            if (visitDictionary)
                dictionary = [visitDictionary objectForKey:@"control_button"];
        }
        
        if (LIOBrandingElementControlButtonBadge == element)
        {
            if (visitDictionary)
            {
                NSDictionary *buttonDictionary = [visitDictionary objectForKey:@"control_button"];
                if (buttonDictionary)
                {
                    NSDictionary *badgeDictionary = [buttonDictionary objectForKey:@"badge"];
                    if (badgeDictionary)
                        dictionary = badgeDictionary;
                }
            }
        }
        
        if (LIOBrandingElementFont == element)
        {
            return engagementDictionary;
        }
        
        if (LIOBrandingElementBoldFont == element)
        {
            return engagementDictionary;
        }
        
        if (LIOBrandingElementLoadingScreen == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *loadingDictionary = [engagementDictionary objectForKey:@"loading_screen"];
                if (loadingDictionary)
                    dictionary = loadingDictionary;
            }
        }
        
        if (LIOBrandingElementLoadingScreenSubtitle == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *loadingDictionary = [engagementDictionary objectForKey:@"loading_screen"];
                if (loadingDictionary)
                {
                    NSDictionary *subtitleDictionary = [loadingDictionary objectForKey:@"subtitle"];
                    if (subtitleDictionary)
                        dictionary = subtitleDictionary;
                }
            }
        }
        
        if (LIOBrandingElementLoadingScreenTitle == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *loadingDictionary = [engagementDictionary objectForKey:@"loading_screen"];
                if (loadingDictionary)
                {
                    NSDictionary *titleDictionary = [loadingDictionary objectForKey:@"title"];
                    if (titleDictionary)
                        dictionary = titleDictionary;
                }
            }
        }
        
        
        if (LIOBrandingElementAgentChatBubble == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *chatBubblesDictionary = [engagementDictionary objectForKey:@"chat_bubbles"];
                if (chatBubblesDictionary)
                {
                    NSDictionary *agentDictionary = [chatBubblesDictionary objectForKey:@"agent"];
                    if (agentDictionary)
                        dictionary = agentDictionary;
                }
            }
        }
        
        if (LIOBrandingElementAgentChatBubbleLink == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *chatBubblesDictionary = [engagementDictionary objectForKey:@"chat_bubbles"];
                if (chatBubblesDictionary)
                {
                    NSDictionary *agentDictionary = [chatBubblesDictionary objectForKey:@"agent"];
                    if (agentDictionary)
                    {
                        NSDictionary *linksDictionary = [agentDictionary objectForKey:@"links"];
                        if (linksDictionary)
                            dictionary = linksDictionary;
                    }
                }
            }
        }
        
        if (LIOBrandingElementVisitorChatBubble == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *chatBubblesDictionary = [engagementDictionary objectForKey:@"chat_bubbles"];
                if (chatBubblesDictionary)
                {
                    NSDictionary *visitorDictionary = [chatBubblesDictionary objectForKey:@"visitor"];
                    if (visitorDictionary)
                        dictionary = visitorDictionary;
                }
            }
        }
        
        if (LIOBrandingElementVisitorChatBubbleLink == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *chatBubblesDictionary = [engagementDictionary objectForKey:@"chat_bubbles"];
                if (chatBubblesDictionary)
                {
                    NSDictionary *visitorDictionary = [chatBubblesDictionary objectForKey:@"visitor"];
                    if (visitorDictionary)
                    {
                        NSDictionary *linksDictionary = [visitorDictionary objectForKey:@"links"];
                        if (linksDictionary)
                            dictionary = linksDictionary;
                    }
                }
            }
        }
        
        if (LIOBrandingElementSendBar == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *sendBarDictionary = [engagementDictionary objectForKey:@"send_bar"];
                if (sendBarDictionary)
                {
                    dictionary = sendBarDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSendBarTextField == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *sendBarDictionary = [engagementDictionary objectForKey:@"send_bar"];
                if (sendBarDictionary)
                {
                    NSDictionary *textFieldDictionary = [sendBarDictionary objectForKey:@"text_field"];
                    if (textFieldDictionary)
                        dictionary = textFieldDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSendBarSendButton == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *sendBarDictionary = [engagementDictionary objectForKey:@"send_bar"];
                if (sendBarDictionary)
                {
                    NSDictionary *sendButtonDictionary = [sendBarDictionary objectForKey:@"send_button"];
                    if (sendButtonDictionary)
                        dictionary = sendButtonDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSendBarPlusButton == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *sendBarDictionary = [engagementDictionary objectForKey:@"send_bar"];
                if (sendBarDictionary)
                {
                    NSDictionary *plusButtonDictionary = [sendBarDictionary objectForKey:@"plus_button"];
                    if (plusButtonDictionary)
                        dictionary = plusButtonDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSendBarCharacterCount == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *sendBarDictionary = [engagementDictionary objectForKey:@"send_bar"];
                if (sendBarDictionary)
                {
                    NSDictionary *characterCountDictionary = [sendBarDictionary objectForKey:@"character_count"];
                    if (characterCountDictionary)
                        dictionary = characterCountDictionary;
                }
            }
        }
        
        if (LIOBrandingElementKeyboardMenu == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *keyboardMenuDictionary = [engagementDictionary objectForKey:@"keyboard_menu"];
                if (keyboardMenuDictionary)
                    dictionary = keyboardMenuDictionary;
            }
        }
        
        if (LIOBrandingElementBrandingBar == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *brandingBarDictionary = [engagementDictionary objectForKey:@"branding_bar"];
                if (brandingBarDictionary)
                    dictionary = brandingBarDictionary;
            }
        }
        
        if (LIOBrandingElementBrandingBarNotifications == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *brandingBarDictionary = [engagementDictionary objectForKey:@"branding_bar"];
                if (brandingBarDictionary)
                {
                    NSDictionary *notificationsDictionary = [brandingBarDictionary objectForKey:@"notifications"];
                    if (notificationsDictionary)
                        dictionary = notificationsDictionary;
                }
            }
        }
        
        if (LIOBrandingElementBrandingBarWebviewButtons == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *brandingBarDictionary = [engagementDictionary objectForKey:@"branding_bar"];
                if (brandingBarDictionary)
                {
                    NSDictionary *webViewButtonsDictionary = [brandingBarDictionary objectForKey:@"webview_buttons"];
                    if (webViewButtonsDictionary)
                        dictionary = webViewButtonsDictionary;
                }
            }
        }
        
        if (LIOBrandingElementBrandingBarWebviewButtonsBadge == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *brandingBarDictionary = [engagementDictionary objectForKey:@"branding_bar"];
                if (brandingBarDictionary)
                {
                    NSDictionary *webViewButtonsDictionary = [brandingBarDictionary objectForKey:@"webview_buttons"];
                    if (webViewButtonsDictionary)
                    {
                        NSDictionary *badgeDictionary = [webViewButtonsDictionary objectForKey:@"badge"];
                        if (badgeDictionary)
                            dictionary = badgeDictionary;
                    }
                }
            }
        }
        
        if (LIOBrandingElementSurveyCard == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyCardDictionary = [surveyDictionary objectForKey:@"survey_card"];
                if (surveyCardDictionary)
                    dictionary = surveyCardDictionary;
            }
        }
        
        if (LIOBrandingElementSurveyCardTitle == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyPageDictionary = [surveyDictionary objectForKey:@"survey_card"];
                if (surveyPageDictionary)
                {
                    NSDictionary *titleDictionary = [surveyPageDictionary objectForKey:@"title"];
                    if (titleDictionary)
                        dictionary = titleDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSurveyCardSubtitle == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyPageDictionary = [surveyDictionary objectForKey:@"survey_card"];
                if (surveyPageDictionary)
                {
                    NSDictionary *subtitleDictionary = [surveyPageDictionary objectForKey:@"subtitle"];
                    if (subtitleDictionary)
                        dictionary = subtitleDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSurveyCardNextButton == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyPageDictionary = [surveyDictionary objectForKey:@"survey_card"];
                if (surveyPageDictionary)
                {
                    NSDictionary *nextButtonDictionary = [surveyPageDictionary objectForKey:@"next_button"];
                    if (nextButtonDictionary)
                        dictionary = nextButtonDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSurveyCardCancelButton == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyPageDictionary = [surveyDictionary objectForKey:@"survey_card"];
                if (surveyPageDictionary)
                {
                    NSDictionary *cancelButtonDictionary = [surveyPageDictionary objectForKey:@"cancel"];
                    if (cancelButtonDictionary)
                        dictionary = cancelButtonDictionary;
                }
            }
        }
        
        if (LIOBrandingElementSurveyPageControl == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyPageDictionary = [surveyDictionary objectForKey:@"page_control"];
                if (surveyPageDictionary)
                    dictionary = surveyPageDictionary;
            }
        }
        
        if (LIOBrandingElementSurveyTextField == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyTextFieldDictionary = [surveyDictionary objectForKey:@"text_field"];
                if (surveyTextFieldDictionary)
                    dictionary = surveyTextFieldDictionary;
            }
        }
        
        if (LIOBrandingElementSurveyList == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyListDictionary = [surveyDictionary objectForKey:@"list"];
                if (surveyListDictionary)
                    dictionary = surveyListDictionary;
            }
        }
        
        if (LIOBrandingElementSurveyStars == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyStarsDictionary = [surveyDictionary objectForKey:@"stars"];
                if (surveyStarsDictionary)
                    dictionary = surveyStarsDictionary;
            }
        }
        
        if (LIOBrandingElementSurveyValidationAlert == element)
        {
            if (surveyDictionary)
            {
                NSDictionary *surveyValidationAlertDictionary = [surveyDictionary objectForKey:@"validation_alert"];
                if (surveyValidationAlertDictionary)
                    dictionary = surveyValidationAlertDictionary;
            }
        }
        
        if (LIOBrandingElementEmailChat == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                    dictionary = emailChatDictionary;
            }
        }
        
        if (LIOBrandingElementEmailChatCard == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                {
                    NSDictionary *emailChatCardDictionary = [emailChatDictionary objectForKey:@"email_chat_card"];
                    if (emailChatCardDictionary)
                        dictionary = emailChatCardDictionary;
                }
            }
        }
        
        if (LIOBrandingElementEmailChatTextField == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                {
                    NSDictionary *textFieldDictionary = [emailChatDictionary objectForKey:@"text_field"];
                    if (textFieldDictionary)
                        dictionary = textFieldDictionary;
                }
            }
        }
        
        if (LIOBrandingElementEmailChatTitle == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                {
                    NSDictionary *titleDictionary = [emailChatDictionary objectForKey:@"title"];
                    if (titleDictionary)
                        dictionary = titleDictionary;
                }
            }
        }
        
        if (LIOBrandingElementEmailChatSubtitle == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                {
                    NSDictionary *subtitleDictionary = [emailChatDictionary objectForKey:@"subtitle"];
                    if (subtitleDictionary)
                        dictionary = subtitleDictionary;
                }
            }
        }
        
        if (LIOBrandingElementEmailChatSubmitButton == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                {
                    NSDictionary *submitButtonDictionary = [emailChatDictionary objectForKey:@"submit_button"];
                    if (submitButtonDictionary)
                        dictionary = submitButtonDictionary;
                }
            }
        }
        
        if (LIOBrandingElementEmailChatCancelButton == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *emailChatDictionary = [engagementDictionary objectForKey:@"email_chat"];
                if (emailChatDictionary)
                {
                    NSDictionary *cancelButtonDictionary = [emailChatDictionary objectForKey:@"cancel_button"];
                    if (cancelButtonDictionary)
                        dictionary = cancelButtonDictionary;
                }
            }
        }
        
        if (LIOBrandingElementToasterView == element)
        {
            if (engagementDictionary)
            {
                NSDictionary *toasterViewDictionary = [engagementDictionary objectForKey:@"toaster_view"];
                if (toasterViewDictionary)
                    dictionary = toasterViewDictionary;
            }
        }
        
        return dictionary;
        
    }
    @catch (NSException *exception)
    {
        // If the error was in the original branding dictionary, we have a problem
        if (brandingDictionary == self.originalBrandingDictionary)
        {
            [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid branding payload received from the server! Using default branding. Exception: %@", exception];
            
            return [NSDictionary dictionary];
        }
        else
        {
            // Otherwise, let's fall back onto the original branding dictionary
            [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Invalid branding payload received from the server! Using default branding. Exception: %@", exception];
            
            self.lastKnownBrandingDictionary = self.originalBrandingDictionary;
            return [self brandingDictionaryForElement:element];
        }
    }
    
    return dictionary;
}

- (UIColor *)colorType:(LIOBrandingColor)colorType forElement:(LIOBrandingElement)element
{
    UIColor *backgroundColor = nil;
    
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *parentDictionary = nil;
        
        if (LIOBrandingColorColor == colorType)
        {
            NSString *colorString = [elementDictionary objectForKey:@"color"];
            if (colorString)
                backgroundColor = [self colorForHexString:colorString];
        }
        else {
            if (LIOBrandingColorBackground == colorType)
                parentDictionary = [elementDictionary objectForKey:@"background"];
            if (LIOBrandingColorText == colorType)
                parentDictionary = [elementDictionary objectForKey:@"font"];
            if (LIOBrandingColorBorder == colorType)
                parentDictionary = [elementDictionary objectForKey:@"border"];
            if (LIOBrandingColorContent == colorType)
                parentDictionary = [elementDictionary objectForKey:@"content"];
            if (LIOBrandingColorIcon == colorType)
                parentDictionary = [elementDictionary objectForKey:@"icon"];
            
            if (parentDictionary)
            {
                NSString *colorString = [parentDictionary objectForKey:@"color"];
                if (colorString)
                {
                    backgroundColor = [self colorForHexString:colorString];
                }
            }
        }
    }
    
    return backgroundColor;
}

- (CGFloat)alphaForElement:(LIOBrandingElement)element
{
    CGFloat alpha = 1.0;
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];

    if (elementDictionary) {
        NSNumber *alphaObject = [elementDictionary objectForKey:@"alpha"];
        if (alphaObject)
            alpha = [alphaObject floatValue];
    }
    
    return alpha;
}

- (CGFloat)backgroundAlphaForElement:(LIOBrandingElement)element
{
    CGFloat alpha = 1.0;
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    
    if (elementDictionary) {
        NSDictionary *backgroundDictionary = [elementDictionary objectForKey:@"background"];
        if (backgroundDictionary)
        {
            NSNumber *alphaObject = [backgroundDictionary objectForKey:@"alpha"];
            if (alphaObject)
                alpha = [alphaObject floatValue];
        }
    }
    
    return alpha;
}

- (CGFloat)widthForElement:(LIOBrandingElement)element {
    CGFloat width = 1.0;
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    
    if (elementDictionary) {
        NSDictionary *sizeDictionary = [elementDictionary objectForKey:@"size"];
        if (sizeDictionary)
        {
            NSNumber *widthObject = [sizeDictionary objectForKey:@"width"];
            if (widthObject)
                width = [widthObject floatValue];
        }
    }
    
    return width;
}


- (NSString *)fontNameForElement:(LIOBrandingElement)element
{
    NSString *fontName = @"HelveticaNeue";
    
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *fontDictionary = [elementDictionary objectForKey:@"font"];
        if (fontDictionary)
        {
            NSString *fontNameString = [fontDictionary objectForKey:@"family"];
            if (fontNameString)
                fontName = fontNameString;
        }
    }
    return fontName;
}

- (NSString *)boldFontNameForElement:(LIOBrandingElement)element
{
    NSString *fontName = @"HelveticaNeue-Medium";
    
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *fontDictionary = [elementDictionary objectForKey:@"bold_font"];
        if (fontDictionary)
        {
            NSString *fontNameString = [fontDictionary objectForKey:@"family"];
            if (fontNameString)
                fontName = fontNameString;
        }
    }
    return fontName;
}


- (CGFloat)fontSizeForElement:(LIOBrandingElement)element
{
    CGFloat fontSize = 15.0;
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *fontDictionary = [elementDictionary objectForKey:@"font"];
        if (fontDictionary)
        {
            NSString *fontSizeObject = [fontDictionary objectForKey:@"size"];
            if (fontSizeObject)
                fontSize = [fontSizeObject floatValue];
        }
    }
    return fontSize;
}

- (UIFont *)fontForElement:(LIOBrandingElement)element
{
    UIFont *font;
    CGFloat size = [self fontSizeForElement:element];
    
    if ([self fontNameForElement:LIOBrandingElementFont])
    {
        NSString *fontName = [self fontNameForElement:LIOBrandingElementFont];
        // Check if branding defined a System font instead of a specific one
        if ([fontName isEqualToString:@"System"])
        {
            font = [UIFont systemFontOfSize:size];
        }
        else
        {
            font = [UIFont fontWithName:[self fontNameForElement:LIOBrandingElementFont] size:size];
        }
        
        // If the specified font was not found, let's fall back to system font
        if (!font)
            font = [UIFont systemFontOfSize:size];

    }
    else
        font = [UIFont systemFontOfSize:size];
    
    return font;
}

- (UIFont *)boldFontForElement:(LIOBrandingElement)element
{
    UIFont *font;
    CGFloat size = [self fontSizeForElement:element];
    
    if ([self boldFontNameForElement:LIOBrandingElementBoldFont])
    {
        // Check if branding defined a System font instead of a specific one
        NSString *boldFontName = [self boldFontNameForElement:LIOBrandingElementBoldFont];
        if ([boldFontName isEqualToString:@"System"])
        {
            font = [UIFont boldSystemFontOfSize:size];
        }
        else
        {
            font = [UIFont fontWithName:[self boldFontNameForElement:LIOBrandingElementBoldFont] size:size];
        }

        // If the specified font was not found, let's fall back to system font
        if (!font)
            font = [UIFont boldSystemFontOfSize:size];
    }
    else
        font = [UIFont boldSystemFontOfSize:size];
    
    
    return font;
}


- (BOOL)booleanValueForField:(NSString *)field element:(LIOBrandingElement)element
{
    BOOL value = NO;
    
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSNumber *boolValueNumber = [elementDictionary objectForKey:field];
        if (boolValueNumber)
        {
            value = [boolValueNumber boolValue];
        }
    }

    return value;    
}

- (BOOL)attachedToRightForElement:(LIOBrandingElement)element
{
    BOOL attachedToRight = YES;

    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *positionDictionary = [elementDictionary objectForKey:@"position"];
        if (positionDictionary)
        {
            NSString *attachedToRightString = [positionDictionary objectForKey:@"horizontal"];
            if (attachedToRightString)
            {
                if ([attachedToRightString isEqualToString:@"right"])
                    attachedToRight = YES;
                if ([attachedToRightString isEqualToString:@"left"])
                    attachedToRight = NO;
            }
        }
    }
    
    return attachedToRight;
}

- (CGFloat)verticalPositionForElement:(LIOBrandingElement)element
{
    CGFloat verticalPosition = 0.5;

    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *positionDictionary = [elementDictionary objectForKey:@"position"];
        if (positionDictionary)
        {
            NSNumber *verticalPositionNumber = [positionDictionary objectForKey:@"vertical"];
            if (verticalPositionNumber)
                verticalPosition = [verticalPositionNumber floatValue];
        }
    }

    return verticalPosition;
}




@end
