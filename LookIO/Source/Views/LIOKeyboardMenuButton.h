//
//  LIOKeyboardMenuButton.h
//  LookIO
//
//  Created by Yaron Karasik on 8/7/13.
//
//

#import <UIKit/UIKit.h>

@interface LIOKeyboardMenuButton : UIButton {
    UILabel* bottomLabel;
}

-(void)setBottomLabelText:(NSString*)text;

@end
