//
//  LIOSurveyTemplate.h
//  LookIO
//
//  Created by Joseph Toscano on 6/14/12.
//  Copyright (c) 2012 LivePerson, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIOSurveyTemplate : NSObject
{
    NSNumber *surveyId;
    NSString *headerString;
    NSArray *questions;
    NSArray *logicItems;
}

@property(nonatomic, retain) NSNumber *surveyId;
@property(nonatomic, retain) NSString *headerString;
@property(nonatomic, retain) NSArray *questions;
@property(nonatomic, retain) NSArray *logicItems;

@end