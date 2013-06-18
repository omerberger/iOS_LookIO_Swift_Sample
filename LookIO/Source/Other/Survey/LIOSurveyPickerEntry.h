//
//  LIOSurveyPickerEntry.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOSurveyPickerEntry : NSObject
{
    int order;
    BOOL initiallyChecked;
    NSString *label;
    NSArray *logicItems;
}

@property int order;
@property(nonatomic, assign) BOOL initiallyChecked;
@property(nonatomic, retain) NSString *label;
@property(nonatomic, retain) NSArray *logicItems;

@end