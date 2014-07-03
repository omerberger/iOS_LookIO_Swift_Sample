//
//  LPSSEManager.m
//  Barracuda
//
//  Created by Joe Toscano on 1/7/13.
//  Copyright (c) 2013 LivePerson, Inc. All rights reserved.
//

#import "LPSSEManager.h"
#import "AsyncSocket.h"
#import "NSData+Base64.h"
#import "LPSSEvent.h"
#import "LIOLogManager.h"

@interface LPSSEManager () <AsyncSocketDelegate_LIO>
{
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

@synthesize host, port, urlEndpoint, delegate, socket, events, lastEventId, readyState, usesTLS, cookies;

- (id)initWithHost:(NSString *)aHost port:(NSNumber*)aPort urlEndpoint:(NSString *)anEndpoint usesTLS:(BOOL)aUsesTLS lastEventId:(NSString *)anEventId cookies:(NSArray*)aCookies
{
    self = [super init];
    if (self)
    {
        sepData = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
        
        socket = [[AsyncSocket_LIO alloc] initWithDelegate:self];
        
        self.host = aHost;
        self.port = [aPort integerValue];
        self.urlEndpoint = anEndpoint;
        self.usesTLS = aUsesTLS;
        if (aCookies)
            self.cookies = aCookies;
        
        if (anEventId)
            lastEventId = anEventId;
        else
            lastEventId = @"";
            
        events = [[NSMutableDictionary alloc] init];
        
        readyState = LPSSEManagerReadyStateConnecting;
    }
    
    return self;
}

-(void)dealloc {    
    [events removeAllObjects];
    [events release];
    events = nil;
    
    socket.delegate = nil;
    if (socket.isConnected)
        [socket disconnect];
    [socket release];
    socket = nil;
    
    [super dealloc];
}

- (void)reset {
    self.host = nil;
    self.port = 0;
    self.urlEndpoint = nil;
            
    [events removeAllObjects];
    lastEventId = @"";
    
    self.socket.delegate = nil;
    
    readyState = LPSSEManagerReadyStateConnecting;
}

- (void)connect
{
    NSError *anError = nil;
    
    BOOL exceptionNotRaised = NO;
    BOOL connectResult = NO;
    @try
    {
        connectResult = [socket connectToHost:self.host onPort:self.port error:&anError];
        exceptionNotRaised = YES;
        
        LIOLog(@"Trying \"%@:%u\"...", self.host, self.port);
    }
    @catch (NSException *anException)
    {
        [[LIOLogManager sharedLogManager] logWithSeverity:LIOLogManagerSeverityWarning format:@"Connection attempt failed. Exception: %@", anException];
    }
    
    if (anError)
    {
        LIOLog(@"<LPSSEManager> Couldn't connect to host %@ port %d: %@", self.host, self.port, anError);
        [delegate sseManagerWillDisconnect:self withError:anError];
        [delegate sseManagerDidDisconnect:self];
        return;
    }
}

- (void)onSocket:(AsyncSocket_LIO *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    if (self.usesTLS)
        [socket startTLS:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], (NSString *)kCFStreamSSLAllowsAnyRoot, nil]];
    else {
        LIOLog(@"<LPSSEManager> Socket connected");
        [self sendEventStreamRequest];
    }
}

- (void)disconnect
{
    [socket disconnect];
}

#pragma mark - GCDAsyncSocketDelegate methods -

- (void)onSocketDidSecure:(AsyncSocket_LIO *)sock
{
    LIOLog(@"<LPSSEManager> SSL/TLS established");
    
    [self sendEventStreamRequest];
}

- (void)sendEventStreamRequest {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* httpRequest = [NSString stringWithFormat:@"POST %@ HTTP/1.1\nHost: %@\nAccept: text/event-stream\nCache-Control: no-cache\n",
                                 urlEndpoint,
                                 host];
        
        if (lastEventId)
            if (![lastEventId isEqualToString:@""])
                httpRequest = [httpRequest stringByAppendingString:[NSString stringWithFormat:@"Last-Event-ID: %@\n", lastEventId]];
        
        if (cookies) {
            if (cookies.count > 0) {
                httpRequest = [httpRequest stringByAppendingString:@"Cookie: "];
                for (NSHTTPCookie *cookie in cookies) {
                    httpRequest = [httpRequest stringByAppendingString:[NSString stringWithFormat:@"%@=%@; ", cookie.name, cookie.value]];
                }
                httpRequest = [httpRequest stringByAppendingString:@"\n"];
            }
        }
                
        httpRequest = [httpRequest stringByAppendingString:@"\n"];
        
        LIOLog(@"SSE request is %@", httpRequest);
        
        [socket writeData:[httpRequest dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        
        [socket readDataWithTimeout:-1 tag:0];
        
        readyState = LPSSEManagerReadyStateOpen;
        [delegate sseManagerDidConnect:self];
    });
}

- (void)createEventFromStreamString:(NSString*)streamString
{
    LPSSEvent* event = [[[LPSSEvent alloc] init] autorelease];
    event.eventId = @"";
    event.eventType = @"";
    event.data = @"";
        
    NSArray *lines = [streamString componentsSeparatedByString:@"\n"];
    for (NSString* line in lines) {
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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *readString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        
        if ([partialPacket length])
        {
            readString = [NSString stringWithFormat:@"%@%@", partialPacket, readString];
            partialPacket = nil;
        }
        
        LIOLog(@"\n\n<LPSSEManager> Read Event Stream:\n%@\n<END>\n\n", readString);
        
        NSRange sepRange = [readString rangeOfString:@"\n\n"];
        if (sepRange.location != NSNotFound && [readString hasSuffix:@"\n\n"])
        {
            NSArray *eventStreamStrings = [readString componentsSeparatedByString:@"\n\n"];

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
        LIOLog(@"<LPSSEManager> onSocketDidDisconnect");
        readyState = LPSSEManagerReadyStateClosed;
        [self reset];
        [delegate sseManagerDidDisconnect:self];
    });
}

-(void)onSocket:(AsyncSocket_LIO *)sock willDisconnectWithError:(NSError *)err {
    dispatch_async(dispatch_get_main_queue(), ^{
        LIOLog(@"<LPSSEManager> onSocketWillDisconnectWithError: %@", err);
        [delegate sseManagerWillDisconnect:self withError:err];
    });
}

@end