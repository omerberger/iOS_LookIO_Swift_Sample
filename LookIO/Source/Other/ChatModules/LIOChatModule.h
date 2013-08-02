//
//  LIOChatModule.h
//  LookIO
//
//  Created by Yaron Karasik on 8/2/13.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum
{
    LIOChatModuleTypeWebView = 0
} LIOChatModuleType;


@class LIOChatModule;

@protocol LIOChatModuleDelegate <NSObject>

@optional

-(void)chatModuleContentDidLoad:(LIOChatModule*)chatModule;
-(void)chatModuleContentDidFail:(LIOChatModule*)chatModule;

@end

@interface LIOChatModule : NSObject {
    id <LIOChatModuleDelegate> delegate;
    LIOChatModuleType chatModuleType;
}

@property (nonatomic, assign) LIOChatModuleType chatModuleType;
@property (nonatomic, retain) UIView* view;

@property (nonatomic, assign) id <LIOChatModuleDelegate> delegate;

@end
