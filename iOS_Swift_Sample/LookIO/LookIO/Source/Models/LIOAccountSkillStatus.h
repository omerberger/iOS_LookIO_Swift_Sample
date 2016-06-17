//
//  LIOAccountSkillStatus.h
//  LookIO
//
//  Created by Yaron Karasik on 5/28/14.
//
//

#import <Foundation/Foundation.h>

@interface LIOAccountSkillStatus : NSObject

@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *skill;
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) BOOL isEnabledOnServer;
@property (nonatomic, assign) BOOL isEnabledLastReported;

@end
