//
//  DAKeyboardControlTableView.h
//  DAKeyboardControl
//
//  Created by Daniel Amitay on 2/5/12.
//  Copyright (c) 2012 Daniel Amitay. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DAKeyboardControlDelegate_LIO

@optional

- (void)keyboardFrameWillChange:(CGRect)newFrame from:(CGRect)oldFrame over:(CGFloat)seconds;

@end

@interface DAKeyboardControlTableView_LIO : UITableView
{
    UIResponder *activeInput;
    UIView *activeKeyboard;
    CGRect originalKeyboardFrame;
}
@property (nonatomic) CGFloat keyboardTriggerOffset;
@property (nonatomic, assign) id<DAKeyboardControlDelegate_LIO, UITableViewDelegate> delegate;

@end