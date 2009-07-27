//
//  FMRadioSession.m
//  SweetFM
//
//  Created by Q on 24.05.09.
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FMRadioSession.h"

#import "QOperation.h"
#import "QHandler.h"

#import "XLog.h"



// NSString * const HandshakePattern = @"http://ws.audioscrobbler.com/radio/handshake.php?version=1.3.1.1&platform=mac&username=%@&passwordmd5=%@";
NSString * const HandshakePattern = @"http://ws.audioscrobbler.com/radio/handshake.php?version=1.5.4.24670&platform=mac&username=%@&passwordmd5=%@";


NSString * const BasePathKey = @"base_path";
NSString * const BaseURLKey = @"base_url";
NSString * const MessageKey = @"msg";
NSString * const SessionKey = @"session";
NSString * const SubscriberKey = @"subscriber";


//
// Proxy
//
@interface FMRadioSessionProxy : QProxy @end

@implementation FMRadioSessionProxy

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if([anInvocation selector] == @selector(authenticate))
	{
		[anInvocation setTarget:target];
		
		QOperation *op = [[QOperation alloc] initWithCriticalValidatedInvocation:anInvocation];
		[[QHandler messages] addOperation:op];
		[op release];
	}
}

@end


//
// FMRadioSession
//
@implementation FMRadioSession

@synthesize user, password, message, sessionKey, domain, path;

- (id)initWithUser:(NSString *)aUser password:(NSString *)aPassword
{
	if(self = [super init])
	{
		user = [aUser copy];
		password = [aPassword copy];
	}
	
	return self;
}

- (void)dealloc
{
	[user release];
	[password release];
	
	[path release];
	[domain release];
	[message release];
	[sessionKey release];
	
	[super dealloc];
}

- (id)queue
{
	return [[[FMRadioSessionProxy alloc] initWithTarget:self] autorelease];
}

- (BOOL)authenticate
{
	NSString *req = [NSString stringWithFormat:HandshakePattern, [user escapeAllURLCharacters], [password md5]];
	XLog(req);
	
	NSData *data = [self HTTPGetString:req];
	
	if(!data)
	{
		self.lastError = [NSString stringWithString:@"Error contacting radio service"];
		return NO;
	}
	
	//
	// Write info
	//
	NSDictionary *sessionInfo = [self parseAssignedList:data];
	
	[path release];
	path = [[sessionInfo valueForKey:BasePathKey] retain];
	[domain release];
	domain = [[sessionInfo valueForKey:BaseURLKey] retain];
	[message release];
	message = [[sessionInfo valueForKey:MessageKey] retain];
	[sessionKey release];
	sessionKey = [[sessionInfo valueForKey:SessionKey] retain];
	subscriber = [[sessionInfo valueForKey:SubscriberKey] boolValue];
	
	//XLog(@"Session info: %@", [sessionInfo description]);
		
	//
	// Check session key
	//
	if([sessionKey containsString:@"failed"])
	{
		XLog([sessionInfo description]);
		
		self.lastError = [NSString stringWithString:@"Last.fm login not valid"];
		return NO;
	}
		
	return YES;
}

@end
