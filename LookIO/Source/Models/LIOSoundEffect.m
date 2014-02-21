//
//  LIOSoundEffect.m
//  LookIO
//
//  Created by Yaron Karasik on 2/20/14.
//
//

#import "LIOSoundEffect.h"

@interface LIOSoundEffect ()

@property (nonatomic, assign) SystemSoundID soundID;

@end

@implementation LIOSoundEffect

static void completionCallback (SystemSoundID  mySSID, void *myself) {
    LIOSoundEffect *soundEffect = (__bridge LIOSoundEffect *)myself;
    
    if (soundEffect.shouldRepeat)
    {
        [soundEffect play];
    }
    else
    {        
        AudioServicesDisposeSystemSoundID(mySSID);
        CFRelease(myself);
        
        if (soundEffect.completionBlock)
        {
            soundEffect.completionBlock();
        }
    }
}

- (id)initWithSoundNamed:(NSString *)filename
{
    if ((self = [super init]))
    {
        
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
        if (fileURL != nil)
        {
            SystemSoundID theSoundID;
            OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &theSoundID);
            if (error == kAudioServicesNoError)
                self.soundID = theSoundID;
            
            AudioServicesAddSystemSoundCompletion(self.soundID, NULL, NULL, completionCallback, (__bridge_retained void *)self);
        }
    }
    return self;
}

- (void)play
{
    AudioServicesPlaySystemSound(self.soundID);
}

- (void)stop
{
    completionCallback(self.soundID, (__bridge_retained void *)self);
}

@end