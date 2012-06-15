//
//  LIOSurveyLogicProp.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    LIOSurveyLogicPropTypeShow
} LIOSurveyLogicPropType;

@interface LIOSurveyLogicProp : NSObject
{
    int targetLogicId;
    LIOSurveyLogicPropType propType;
}

@property(nonatomic, assign) int targetLogicId;
@property(nonatomic, assign) LIOSurveyLogicPropType propType;

@end