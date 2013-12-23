//
//  LIOKeyboardMenu.h
//  LookIO
//
//  Created by Yaron Karasik on 8/5/13.
//
//

#import <UIKit/UIKit.h>
#import "LIOKeyboardMenuButton.h"

@class LIOKeyboardMenu;

@protocol LIOKeyboardMenuDelegate <NSObject>

@optional

- (void)keyboardMenu:(LIOKeyboardMenu *)keyboardMenu buttonWasTapped:(LIOKeyboardMenuButton *)button;

@end

@interface LIOKeyboardMenu : UIView {
    NSMutableArray *buttonsArray;
    id <LIOKeyboardMenuDelegate> delegate;

}

@property (nonatomic, assign) id <LIOKeyboardMenuDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *buttonsArray;

@end
