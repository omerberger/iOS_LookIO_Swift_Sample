//
//  LPSSEManager.m
//  Barracuda
//
//  Created by Joe Toscano on 1/7/13.
//  Copyright (c) 2013 LivePerson, Inc. All rights reserved.
//

#import "LPSSEManager.h"
#import "GCDAsyncSocket.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+Base64.h"

@interface LPSSEManager () <GCDAsyncSocketDelegate_LIO>
{
    dispatch_queue_t delegateQueue;
    NSMutableString *partialPacket;
    NSData *sepData;
}

@property(nonatomic, retain) GCDAsyncSocket_LIO *socket;

@end

@implementation LPSSEManager

@synthesize host, port, urlEndpoint, delegate, socket;

- (id)initWithHost:(NSString *)aHost port:(int)aPort urlEndpoint:(NSString *)anEndpoint
{
    self = [super init];
    if (self)
    {
        sepData = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
        
        delegateQueue = dispatch_queue_create("com.liveperson.LPSSEManager", 0);
        socket = [[GCDAsyncSocket_LIO alloc] initWithDelegate:self delegateQueue:delegateQueue];
        
        self.host = aHost;
        self.port = aPort;
        self.urlEndpoint = anEndpoint;
    }
    
    return self;
}

- (void)connect
{
    NSError *anError = nil;
    [socket connectToHost:self.host onPort:self.port error:&anError];
    if (anError)
    {
        NSLog(@"[LPSSEManager] Couldn't connect: %@", anError);
        [delegate sseManagerDidDisconnect:self];
        return;
    }
    [socket startTLS:nil];
}

- (void)disconnect
{
    [socket disconnect];
}

#pragma mark - GCDAsyncSocketDelegate methods -

- (void)socket:(GCDAsyncSocket_LIO *)sock didConnectToHost:(NSString *)aHost port:(uint16_t)aPort
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[LPSSEManager] Connected to %@:%u", aHost, aPort);
    });
}

- (void)socketDidSecure:(GCDAsyncSocket_LIO *)sock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[LPSSEManager] SSL/TLS established");
        
        NSString *httpRequest = [NSString stringWithFormat:@"POST %@ HTTP/1.1\nHost: %@\nAccept: text/event-stream\n\n",
                                 urlEndpoint,
                                 host];
        [socket writeData:[httpRequest dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        
        NSLog(@"%@", httpRequest);
        
        [socket readDataWithTimeout:-1 tag:0];
        
        [delegate sseManagerDidConnect:self];
    });
}

- (void)socket:(GCDAsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if ([partialPacket length])
        {
            s = [NSString stringWithFormat:@"%@%@", partialPacket, s];
            partialPacket = nil;
        }
        
        NSLog(@"\n----------<READ>----------\n%@\n----------</READ>----------\n\n", s);
        
        NSRange sepRange = [s rangeOfString:@"\n\n"];
        if (sepRange.location != NSNotFound)
        {
            NSRange dataRange = [s rangeOfString:@"data: "];
            if (dataRange.location != NSNotFound) {
                dataRange.length -= 5;
                dataRange.location += 5;
                NSString *packet = [s substringWithRange:NSUnionRange(dataRange, sepRange)];
                [delegate sseManager:self didReceivePacket:packet];
                int afterSep = sepRange.location + sepRange.length;
                if (afterSep < [s length])
                    partialPacket = [[s substringFromIndex:afterSep] mutableCopy];
            }
        }
        else
        {
            partialPacket = [s mutableCopy];
        }
        
        [socket readDataWithTimeout:-1 tag:0];
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket_LIO *)sock withError:(NSError *)err
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[LPSSEManager] Connection closed. Error: %@", err);
        [delegate sseManagerDidDisconnect:self];
    });
}

- (NSString*) sha1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
    
}


@end