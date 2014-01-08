//
//  LIOKeyboardMenu.h
//  LookIO
//
//  Created by Yaron Karasik on 8/5/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOKeyboardMenuItem.h"

@class LIOKeyboardMenu;

@protocol LIOKeyboardMenuDelegate <NSObject>

@optional

- (void)keyboardMenu:(LIOKeyboardMenu *)keyboardMenu itemWasTapped:(LIOKeyboardMenuItem *)item;
- (BOOL)keyboardMenuShouldShowHideEmailChatDefaultItem:(LIOKeyboardMenu *)keyboardMenu;

@end

@interface LIOKeyboardMenu : UIView

@property (nonatomic, assign) id <LIOKeyboardMenuDelegate> delegate;

- (void)setDefaultButtonItems;

@end
