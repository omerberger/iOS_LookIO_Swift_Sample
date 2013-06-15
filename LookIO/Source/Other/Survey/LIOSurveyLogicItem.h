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
{
    int sourceLogicId;
    int targetLogicId;
    NSString* sourceAnswerLabel;
    BOOL enabled;
    LIOSurveyLogicPropType propType;
}

@property (nonatomic, assign) int sourceLogicId;
@property (nonatomic, assign) int targetLogicId;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) LIOSurveyLogicPropType propType;
@property (nonatomic, copy) NSString* sourceAnswerLabel;

@end