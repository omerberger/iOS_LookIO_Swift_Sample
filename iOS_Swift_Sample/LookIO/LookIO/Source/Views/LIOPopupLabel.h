//
//  LIOPopupLabel.h
//  LookIO
//
//  Created by Yaron Karasik on 2/6/14.
//
//

#import <UIKit/UIKit.h>

@interface LIOPopupLabel : UILabel


@property (nonatomic, strong) CAShapeLayer *arrowLayer;
@property (nonatomic, strong) CAShapeLayer *borderLayer;

@property (nonatomic, assign) BOOL isPointingRight;

@end
