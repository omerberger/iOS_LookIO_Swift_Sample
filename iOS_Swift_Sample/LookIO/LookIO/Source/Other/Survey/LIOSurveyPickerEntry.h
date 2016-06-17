//
//  LIOSurveyPickerEntry.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOSurveyPickerEntry : NSObject

@property (nonatomic, assign) NSInteger order;
@property (nonatomic, assign) BOOL initiallyChecked;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, strong) NSArray *logicItems;

@end