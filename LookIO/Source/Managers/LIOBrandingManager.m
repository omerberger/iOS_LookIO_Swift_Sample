//
//  LIOBrandingManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/17/13.
//
//

#import "LIOBrandingManager.h"

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                    green:((c>>8)&0xFF)/255.0 \
                                     blue:((c)&0xFF)/255.0 \
                                    alpha:1.0]

@interface LIOBrandingManager ()

@property (nonatomic, strong) NSMutableDictionary *brandingDictionary;

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
    self.brandingDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
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
    NSDictionary *visitDictionary = [self.brandingDictionary objectForKey:@"visit"];
    NSDictionary *engagementDictionary = [self.brandingDictionary objectForKey:@"engagement"];

    if (LIOBrandingElementControlButton == element)
    {
        if (visitDictionary)
            dictionary = [visitDictionary objectForKey:@"control_button"];
    }
    
    if (LIOBrandingElementFont == element)
    {
        return engagementDictionary;
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
    
    if (LIOBrandingElementVisitorChatBubble == element)
    {
        if (engagementDictionary)
        {
            NSDictionary *chatBubblesDictionary = [engagementDictionary objectForKey:@"chat_bubbles"];
            if (chatBubblesDictionary)
            {
                NSDictionary *agentDictionary = [chatBubblesDictionary objectForKey:@"visitor"];
                if (agentDictionary)
                    dictionary = agentDictionary;
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
    NSString *fontName = @"HelveticaNeue-Light";
    
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
        font = [UIFont fontWithName:[self fontNameForElement:LIOBrandingElementFont] size:size];
    else
        font = [UIFont systemFontOfSize:size];
    
    return font;
}






@end
