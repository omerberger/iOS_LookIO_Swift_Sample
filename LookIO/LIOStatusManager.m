//
//  LIOStatusManager.m
//  LookIO
//
//  Created by Yaron Karasik on 12/5/13.
//
//

#import "LIOStatusManager.h"

#import "LIOManager.h"

#import <AdSupport/AdSupport.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>

@interface LIOStatusManager ()

NSString *uniqueIdentifier()
{
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0)
    {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL)
    {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
    {
        printf("Error: sysctl, take 2");
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    const char *value = [outstring UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    
    return outputString;
}

@end

@implementation LIOStatusManager

static LIOStatusManager *statusManager = nil;

+ (LIOStatusManager *) statusManager
{
    if (nil == statusManager)
        statusManager = [[LIOStatusManager alloc] init];
    
    return statusManager;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
    }
    
    return self;
}

#pragma mark Device and App Data Methods

+ (NSString *)deviceType
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *deviceType = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    return deviceType;
}

+ (NSString *)bundleId
{
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    LIOManager *lioManager = [LIOManager sharedLookIOManager];
    
    if ([(NSObject *)lioManager.delegate respondsToSelector:@selector(lookIOManagerAppIdOverride:)])
    {
        NSString *overriddenBundleId = [(NSObject *)lioManager.delegate performSelector:@selector(lookIOManagerAppIdOverride:) withObject:lioManager];
        if ([overriddenBundleId length])
            bundleId = overriddenBundleId;
    }
    
    return bundleId;
}

+ (NSString *)systemVersion
{
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    return deviceVersion;
}

+ (NSString *)udid
{
    NSString *udid = nil;
    
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        udid = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    }
    else
    {
        udid = uniqueIdentifier();
        
    }
    
    return udid;
}

+ (NSNumber *)limitAdTracking
{
    NSNumber *limitAdTracking = nil;

    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        ASIdentifierManager *sharedIndentifierManager = [ASIdentifierManager sharedManager];
        BOOL limitAdTracking = !sharedIndentifierManager.advertisingTrackingEnabled;
        limitAdTracking = [NSNumber numberWithBool:limitAdTracking];
    }
    
    return limitAdTracking;
}

+ (NSString *)alternateUdid
{
    NSString *vendorDeviceId = nil;
    if (LIO_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        vendorDeviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return vendorDeviceId;
}

+ (NSString *)localeId
{
    NSString *localeId = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
    return localeId;
}

+ (NSString *)languageId
{
    NSString *languageId = [[NSLocale preferredLanguages] objectAtIndex:0];
    return languageId;
}

@end
