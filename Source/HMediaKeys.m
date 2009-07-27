//
//  HMediaKeys.m
//  SweetFM
//
//  Created by Q on 31.05.09.
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

#import "HMediaKeys.h"

#import "SynthesizeSingleton.h"


//
// Notifications
//
NSString * const MediaKeyPlayPauseUpNotification = @"MediaKeyPlayPauseUpNotification";
NSString * const MediaKeyNextUpNotification = @"MediaKeyNextUpNotification";
NSString * const MediaKeyPreviousUpNotification = @"MediaKeyPreviousUpNotification";

@implementation HMediaKeys

SYNTHESIZE_SINGLETON_FOR_CLASS(HMediaKeys, install);

CGEventRef tapEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
		
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
	NSInteger eventData = 0;
	
	if([nsEvent type] == NSSystemDefined)
		eventData = [nsEvent data1];
	
	[pool release];
			
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	if(type==NX_SYSDEFINED && eventData==PlayPauseKeyUp)
	{
		[center postNotificationName:MediaKeyPlayPauseUpNotification object:(HMediaKeys *)refcon];
		return NULL;
	}
	else if(type==NX_SYSDEFINED && eventData==NextKeyUp)
	{
		[center postNotificationName:MediaKeyNextUpNotification object:(HMediaKeys *)refcon];
		return NULL;
	}
	else if(type==NX_SYSDEFINED && eventData==PreviousKeyUp)
	{
		[center postNotificationName:MediaKeyPreviousUpNotification object:(HMediaKeys *)refcon];
		return NULL;
	}
	
	if(type==NX_SYSDEFINED && (eventData==PlayPauseKeyDown || eventData==NextKeyDown || eventData==PreviousKeyDown))
		return NULL;
	
	return event;
}

- (id)init {
	
	if(self = [super init]) {
		
		[NSThread detachNewThreadSelector:@selector(initOnThread)
														 toTarget:self
													 withObject:nil];
	}
	
	return self;
}

- (void)initOnThread {
	
	CFMachPortRef eventPort;
	CFRunLoopSourceRef eventSrc;
	CFRunLoopRef runLoop;
	
	CGEventTapOptions opts = kCGEventTapOptionDefault;
	
#ifdef SWEETFM_DEBUG
	opts = kCGEventTapOptionListenOnly;
#endif
	
	eventPort = CGEventTapCreate (kCGSessionEventTap,
																kCGHeadInsertEventTap,
																opts,
																CGEventMaskBit(NX_SYSDEFINED) | CGEventMaskBit(NX_KEYUP),
																tapEventCallback,
																self);
	
	if (eventPort == NULL)
		NSLog(@"Event port is null");
	
	//
	// Get the event source from port
	//
	eventSrc = CFMachPortCreateRunLoopSource(kCFAllocatorSystemDefault, eventPort, 0);
	
	if (eventSrc == NULL)
		NSLog(@"No event run loop source found");
	
	//
	// Get the current threads run loop
	//
	runLoop = CFRunLoopGetCurrent();
	
	if (eventSrc == NULL)
		NSLog(@"No event run loop");
	
	//
	// Add the runloop source
	//
	CFRunLoopAddSource(runLoop, eventSrc, kCFRunLoopCommonModes);
	
	while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

@end
