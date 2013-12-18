//
//  LIOBrandingManager.h
//  LookIO
//
//  Created by Yaron Karasik on 12/17/13.
//
//

#import <UIKit/UIKit.h>

@interface LIOBrandingManager : NSObject

// Control Button
@property (nonatomic, copy) NSString *controlButtonIconUrl;
@property (nonatomic, strong) UIColor *controlButtonBackgroundColor;
@property (nonatomic, strong) UIColor *controlButtonBorderColor;
@property (nonatomic, strong) UIColor *controlButtonContentColor;
@property (nonatomic, assign) BOOL controlButtonAttachedToRight;
@property (nonatomic, assign) CGFloat controlButtonVerticalPosition;

@property (nonatomic, strong) UIColor *loadingScreenBackgroundColor;
@property (nonatomic, assign) CGFloat loadingScreenBackgroundAlpha;
@property (nonatomic, strong) UIColor *loadingScreenTextColor;
@property (nonatomic, copy) NSString *loadingScreenImageUrl;
@property (nonatomic, assign) BOOL loadingScreenSpinImage;

@property (nonatomic, strong) UIColor *chatBackgroundColor;
@property (nonatomic, assign) CGFloat chatBackgroundAlpha;
@property (nonatomic, assign) CGFloat chatBackgroundBlurRadius;
@property (nonatomic, assign) NSInteger chatBackgroundBlurIterations;
@property (nonatomic, assign) CGFloat chatBackgroundSaturationFactor;

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, copy) NSString *logoUrl;

@property (nonatomic, strong) UIColor *brandingBarBackgroundColor;
@property (nonatomic, assign) CGFloat brandingBarBackgroundAlpha;
@property (nonatomic, strong) UIColor *brandingbarNotificationsTextColor;
@property (nonatomic, assign) NSInteger brandingBarNotificationsFontSize;

@property (nonatomic, strong) UIColor *agentBubbleBackgroundColor;
@property (nonatomic, strong) UIColor *agentBubbleTextColor;
@property (nonatomic, assign) CGFloat agentBubbleWidth;
@property (nonatomic, assign) CGFloat agentBubbleFontSize;
@property (nonatomic, assign) BOOL agentBubbleShowAvatar;
@property (nonatomic, copy) NSString *agentAvatarImageUrl;
@property (nonatomic, strong) UIColor *agentLinkBackgroundColor;
@property (nonatomic, strong) UIColor *agentLinkBorderColor;
@property (nonatomic, strong) UIColor *agentLinkTextColor;
@property (nonatomic, assign) CGFloat agentLinkFontSize;

@property (nonatomic, strong) UIColor *visitorBubbleBackgroundColor;
@property (nonatomic, strong) UIColor *visitorBubbleTextColor;
@property (nonatomic, assign) CGFloat visitorBubbleWidth;
@property (nonatomic, assign) CGFloat visitorBubbleFontSize;
@property (nonatomic, assign) BOOL visitorBubbleShowAvatar;
@property (nonatomic, copy) NSString *visitorAvatarImageUrl;
@property (nonatomic, strong) UIColor *visitorLinkBackgroundColor;
@property (nonatomic, strong) UIColor *visitorLinkBorderColor;
@property (nonatomic, strong) UIColor *visitorLinkTextColor;
@property (nonatomic, assign) CGFloat visitorLinkFontSize;

@property (nonatomic, strong) UIColor *systemMessageBackgroundColor;
@property (nonatomic, strong) UIColor *systemMessageTextColor;
@property (nonatomic, assign) CGFloat systemMessageBubbleWidth;
@property (nonatomic, assign) CGFloat systemMessageFontSize;
@property (nonatomic, assign) UITextAlignment systemMessageBubbleAlignment;

@property (nonatomic, strong) UIColor *sendBarBackgroundColor;
@property (nonatomic, assign) CGFloat sendBar


@end

/*

 }
 "send_bar" : {
 "background" : {
 "background_color" : "#666666",
 "background_gradient" : "",
 "background_alpha" : "0.5"
 },
 "plus_button" : {
 "button_color" : "#ffffff"
 },
 "text_field" : {
 "background_color" : "#ffffff",
 "background_gradient" : "",
 "text_color" : "#a9a9a9",
 "border_color" : "#5e5e5e",
 "font_size" : "14.0"
 },
 "send_button" : {
 "background_color" : "",
 "background_gradient" : "",
 "text_color" : "#ffffff",
 "border_color" : "#ffffff",
 "font_size" : "16.0"
 }
 },
 "hide_bar" : {
 "background" : {
 "background_color" : "#ffffff",
 "background_gradient" : "",
 "background_alpha" : "0.0"
 },
 "label" : {
 "text_color" : "#ffffff",
 "font_size"  : "14.0",
 "text_shadow_color" : ""
 }
 },
 "keyboard_menu" : {
 "background_color" : "#4c4c4c",
 "background_alpha" : "0.55",
 "text_color" : "#b6b2ae",
 "font_size" : "13.0",
 "icon_color"  : "#b6b2ae"
 },
 "surveys" : {
 "page_control" : {
 "color" : "#ffffff"
 },
 "survey_card" : {
 "background_color" : "#ffffff",
 "background_alpha" : "0.9",
 "title_color" : "#555555",
 "title_font_size" : "15.0",
 "next_button" : {
 "text_color" : "#007df5",
 "background_gradient" : "",
 "font_size": "15.0"
 },
 "cancel" : {
 "text_color" : "#007df5",
 "background_gradient" : "",
 "font_size": "15.0"
 }
 },
 "text_field" : {
 "background_color" : "#ffffff",
 "text_color" : "#555555",
 "border_color" : "#b7b7b7",
 "font_size" : "17.0"
 },
 "list" : {
 "background_color" : "#ffffff",
 "text_color" : "#555555",
 "border_color" : "#b7b7b7",
 "font_size" : "17.0"
 },
 "stars" : {
 "border_color" : "#fafafa",
 "unselected_fill_color" : "#9b9b9b",
 "selected_fill_color" : "#f7a300"
 },
 "validation_alert" : {
 "background_color" : "#ff3737",
 "text_color" : "#ffffff",
 "font_size" : "15.0"
 }
 }
 }

*/