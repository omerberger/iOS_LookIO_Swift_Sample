//
//  LIOSurveyLogicItem.h
//  LookIO
//
//  Created by Yaron Karasik on 6/14/13.
//
//

#import <Foundation/Foundation.h>

typedef enum
{
    LIOSurveyLogicPropTypeShow
} LIOSurveyLogicPropType;

@interface LIOSurveyLogicItem : NSObject

@property (nonatomic, assign) NSInteger sourceLogicId;
@property (nonatomic, assign) NSInteger targetLogicId;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) LIOSurveyLogicPropType propType;
@property (nonatomic, copy) NSString* sourceAnswerLabel;

@end