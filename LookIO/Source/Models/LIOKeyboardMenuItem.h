//
//  LIOKeyboardMenuItem.h
//  LookIO
//
//  Created by Yaron Karasik on 12/23/13.
//
//

#import <Foundation/Foundation.h>

typedef enum
{
    LIOKeyboardMenuItemCustom = 0,
    LIOKeyboardMenuItemEndChat,
    LIOKeyboardMenuItemHideChat,
    LIOKeyboardMenuItemShowKeyboard,
    LIOKeyboardMenuItemEmailChat,
    LIOKeyboardMenuItemSendPhoto,
    LIOKeyboardMenuItemWebView
} LIOKeyboardMenuItemType;

@interface LIOKeyboardMenuItem : NSObject

@property (nonatomic, assign) LIOKeyboardMenuItemType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *iconName;

@end
