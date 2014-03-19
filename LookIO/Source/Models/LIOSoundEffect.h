//
//  LIOSoundEffect.h
//  LookIO
//
//  Created by Yaron Karasik on 2/20/14.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef void (^LIOSoundEffectCompletionBlock)(void);

@interface LIOSoundEffect : NSObject

@property (nonatomic, copy) LIOSoundEffectCompletionBlock completionBlock;
@property (nonatomic, assign) BOOL shouldRepeat;

- (id)initWithSoundNamed:(NSString *)filename;
- (void)play;
- (void)stop;

@end