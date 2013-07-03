//
//  LPSSEManager.m
//  Barracuda
//
//  Created by Joe Toscano on 1/7/13.
//  Copyright (c) 2013 LivePerson, Inc. All rights reserved.
//

#import "LPSSEManager.h"
#import "AsyncSocket.h"
#import <CommonCrypto/CommonCrypto.h>
#import "NSData+Base64.h"
#import "LPSSEvent.h"

@interface LPSSEManager () <AsyncSocketDelegate_LIO>
{
    dispatch_queue_t delegateQueue;
    NSMutableString *partialPacket;
    NSData *sepData;
    
    AsyncSocket_LIO *socket;

    NSMutableDictionary *events;
    NSString *lastEventId;
    
    int readyState;
}

@property (nonatomic, retain) AsyncSocket_LIO *socket;
@property (nonatomic, retain) NSMutableDictionary *events;
@property (nonatomic, retain) NSString *lastEventId;
@property (nonatomic, assign) int readyState;


@end

@implementation LPSSEManager

@synthesize host, port, urlEndpoint, delegate, socket, events, lastEventId, readyState;

- (id)initWithHost:(NSString *)aHost port:(int)aPort urlEndpoint:(NSString *)anEndpoint lastEventId:(NSString *)anEventId
{
    self = [super init];
    if (self)
    {
        sepData = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
        
        socket = [[AsyncSocket_LIO alloc] initWithDelegate:self];
        
        self.host = aHost;
        self.port = aPort;
        self.urlEndpoint = anEndpoint;
        lastEventId = @"";
        if (lastEventId)
            self.lastEventId = anEventId;
            
        events = [[NSMutableDictionary alloc] init];
        
        readyState = LPSSEManagerReadyStateConnecting;
    }
    
    return self;
}

-(void)dealloc {    
    [events removeAllObjects];
    [events release];
    events = nil;
    
    [super dealloc];
}

- (void)reset {
    self.host = nil;
    self.port = 0;
    self.urlEndpoint = nil;
    
    [events removeAllObjects];
    lastEventId = @"";
    
    self.socket.delegate = nil;
    
    NSLog(@"[LPSSEManager] Manager reset");
    readyState = LPSSEManagerReadyStateConnecting;
}

- (void)connect
{
    NSError *anError = nil;
    [socket connectToHost:self.host onPort:self.port error:&anError];
    if (anError)
    {
        NSLog(@"[LPSSEManager] Couldn't connect: %@", anError);
        [delegate sseManagerDidDisconnect:self withError:anError];
        return;
    }
}

- (void)onSocket:(AsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    [socket startTLS:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], (NSString *)kCFStreamSSLAllowsAnyRoot, nil]];

}

- (void)disconnect
{
    [socket disconnect];
}

#pragma mark - GCDAsyncSocketDelegate methods -

- (void)onSocketDidSecure:(AsyncSocket_LIO *)sock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[LPSSEManager] SSL/TLS established");
        
        NSString* httpRequest = [NSString stringWithFormat:@"POST %@ HTTP/1.1\nHost: %@\nAccept: text/event-stream\nCache-Control: no-cache\n",
                                   urlEndpoint,
                                   host];
        
        NSLog(@"Socket did secure, last-event-id is %@", self.lastEventId);
        
        if (lastEventId)
            if (![lastEventId isEqualToString:@""])
                httpRequest = [httpRequest stringByAppendingString:[NSString stringWithFormat:@"Last-Event-ID: %@\n", lastEventId]];
        
        httpRequest = [httpRequest stringByAppendingString:@"\n"];        
        
        [socket writeData:[httpRequest dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        
        NSLog(@"%@", httpRequest);
        
        [socket readDataWithTimeout:-1 tag:0];
        
        readyState = LPSSEManagerReadyStateOpen;
        [delegate sseManagerDidConnect:self];
    });
}

- (void)createEventFromStreamString:(NSString*)streamString {
    LPSSEvent* event = [[LPSSEvent alloc] init];
    event.eventId = @"";
    event.eventType = @"";
    event.data = @"";
        
    NSArray *lines = [streamString componentsSeparatedByString:@"\n"];
    for (NSString* line in lines) {
        NSLog(@"Parsing line with content: %@", line);
        
        // Check if the line contains a colon character
        NSRange colonRange = [line rangeOfString:@":"];
        if (colonRange.location != NSNotFound) {
            // If the colon is the first character, ignore this line
            if (colonRange.location == 0 && colonRange.length == 1) {
                // Do nothing
            }
            // If not, parse the data before the colon as field, and the data after the colon as value (removing the first white space)
            else {
                NSString* field = [line substringToIndex:colonRange.location];
                NSString* value = [line substringFromIndex:colonRange.location + colonRange.length];
                NSRange whiteSpaceRange = [value rangeOfString:@" "];
                if (whiteSpaceRange.location != NSNotFound)
                    if (whiteSpaceRange.location == 0)
                        value = [value stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                
                NSLog(@"Read field: %@ value: %@", field, value);
                
                if ([field isEqualToString:@"id"])
                    event.eventId = value;
                if ([field isEqualToString:@"event"])
                    event.eventType = value;
                if ([field isEqualToString:@"data"])
                    event.data = [event.data stringByAppendingString:value];
            }
        }
        // If not colon is found, the line serves as the field name with a value of ""
        else {
            NSString* field = line;
            if ([field isEqualToString:@"id"])
                event.eventId = @"";
            if ([field isEqualToString:@"event"])
                event.eventType = @"";
            if ([field isEqualToString:@"data"])
                event.data = [event.data stringByAppendingString:@""];
        }
    }
    
    NSLog(@"Received event with id %@", event.eventId);
    
    // Let's not pass on events without any data
    if ([event.data isEqualToString:@""])
        return;
    
    // Let's check if this event has already been dispatched
    if (![event.eventId isEqualToString:@""]) {
        if ([events objectForKey:event.eventId])
            return;
        else {
            [events setObject:event forKey:event.eventId];
            lastEventId = event.eventId;
            [delegate sseManager:self didDispatchEvent:event];            
        }
        
    }
    // If event doesn't have an id, dispatch it
    else
        [delegate sseManager:self didDispatchEvent:event];
}

- (void)onSocket:(AsyncSocket_LIO *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"<DID READ DATA>: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *readString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if ([partialPacket length])
        {
            readString = [NSString stringWithFormat:@"%@%@", partialPacket, readString];
            partialPacket = nil;
        }
        
        NSLog(@"\n----------<READ>----------\n%@\n----------</READ>----------\n\n", readString);
        
        NSRange sepRange = [readString rangeOfString:@"\n\n"];
        if (sepRange.location != NSNotFound)
        {
            NSArray *eventStreamStrings = [readString componentsSeparatedByString:@"\n\n"];
            NSLog(@"Received %d events", eventStreamStrings.count);

            for (NSString* eventStreamString in eventStreamStrings)
                [self createEventFromStreamString:eventStreamString];
        }
        else
        {
            partialPacket = [readString mutableCopy];
        }
        
        [socket readDataWithTimeout:-1 tag:0];
    });
}

- (void)onSocketDidDisconnect:(AsyncSocket_LIO *)sock {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[LPSSEManager] onSocketDidDisconnect");
        readyState = LPSSEManagerReadyStateClosed;
        [self reset];
        [delegate sseManagerDidDisconnect:self];
    });
}

-(void)onSocket:(AsyncSocket_LIO *)sock willDisconnectWithError:(NSError *)err {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[LPSSEManager] willDisconnectWithError: %@", err);
        [delegate sseManagerWillDisconnect:self withError:err];
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