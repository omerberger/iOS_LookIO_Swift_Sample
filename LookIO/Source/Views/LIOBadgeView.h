//
//  LIOBadgeView.h
//  LookIO
//
//  Created by Yaron Karasik on 1/24/14.
//
//

#import <UIKit/UIKit.h>

// Managers
#import "LIOBrandingManager.h"

@interface LIOBadgeView : UIView

- (id)initWithFrame:(CGRect)frame forBrandingElement:(LIOBrandingElement)element;
- (void)setBadgeNumber:(NSInteger)number;

@end
