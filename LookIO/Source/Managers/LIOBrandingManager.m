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
    
    if (LIOBrandingElementControlButton == element)
    {
        NSDictionary *visitDictionary = [self.brandingDictionary objectForKey:@"visit"];
        if (visitDictionary)
            dictionary = [visitDictionary objectForKey:@"control_button"];

        return dictionary;
    }
}

- (UIColor *)colorType:(LIOBrandingColor)colorType forElement:(LIOBrandingElement)element
{
    UIColor *backgroundColor = nil;
    
    NSDictionary *elementDictionary = [self brandingDictionaryForElement:element];
    if (elementDictionary)
    {
        NSDictionary *parentDictionary = nil;
        
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


@end
