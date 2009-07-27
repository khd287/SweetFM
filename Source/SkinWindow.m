//
//  SkinWindow.m
//  SweetFM
//
//  Created by Q on 23.05.09.
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

#import "SkinWindow.h"

#import "JSProxy.h"
#import "JSApp.h"
#import "XLog.h"
#import "NullCache.h"

@implementation SkinWindow

- (id)initWithContentRect:(NSRect)contentRect 
								styleMask:(unsigned int)styleMask
									backing:(NSBackingStoreType)backingType
										defer:(BOOL)flag
{
	return [super initWithContentRect:contentRect 
													styleMask:NSBorderlessWindowMask 
														backing:(NSBackingStoreType)backingType 
															defer:YES];
}

- (void)awakeFromNib
{
	XMark();
	//
	// Setup spaces behavior
	//
	[self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	// Setup transparency
	[self setBackgroundColor:[NSColor clearColor]];
	[self setAlphaValue:1.0];
	[self setOpaque:NO];
	
	// We do not cache anything!
	[NSURLCache setSharedURLCache:[[[NullCache alloc] init] autorelease]];
	[[NSURLCache sharedURLCache] setMemoryCapacity:1024*1000*100];
		
	// Set skin view as content view
	skinView = [[SkinView alloc] initWithFrame:[self frame]];
	[self setContentView:skinView];
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (void)loadSkinFromURL:(NSURL *)url installScriptProxy:(JSProxy *)scriptProxy
{
	if(skinURL != url)
	{
		[skinURL release];
		skinURL = [url retain];
		
		skinView.scriptProxies = [NSArray arrayWithObject:scriptProxy];
		[skinView takeStringURLFrom:self];
	}
}

- (NSString *)stringValue
{
	return [skinURL absoluteString];
}

- (void)sendEvent:(NSEvent *)event
{	
	if([event type] == NSLeftMouseDown)
	{
		[self mouseDown:event];
		
		//
		// WebView -acceptsFirstMouse hack:
		// We need to send the event twice because overriding the -acceptsFirstMouse 
		// method in a WebView subclass won't work.
		//
		if(![self isMainWindow])
			[super sendEvent:event];
	}
	else if([event type] == NSLeftMouseDragged)
		[self mouseDragged:event];
	
	[super sendEvent:event];
}

- (void)mouseDragged:(NSEvent*)theEvent 
{
	if(!dragAllowed)
		return;	
		
	NSPoint currentLocation, newOrigin;
	NSRect  screenFrame = [[NSScreen mainScreen] frame];
	NSRect  windowFrame = [self frame];
	
	// Grab the current global mouse position
	currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
	newOrigin.x = currentLocation.x - initialLocation.x;
	newOrigin.y = currentLocation.y - initialLocation.y;
	
	// Don't let window get dragged up under the menu bar
	if((newOrigin.y+windowFrame.size.height) > (screenFrame.origin.y+screenFrame.size.height))
		newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height);
	
	// Go ahead and move the window to the new location
	[self setFrameOrigin:newOrigin];
}

- (void)mouseDown:(NSEvent*)theEvent
{  	
	// Check if skin view approves the drag
	// (only allowed on window)
	NSPoint eventLocation = [theEvent locationInWindow];
	NSString *className = [skinView elementClassNameAtPoint:eventLocation];
	//XLog(@"clicked on class: %@", className);
	
	dragAllowed = NO;
	
	for(NSObject *proxy in skinView.scriptProxies)
	{
		if(![proxy isKindOfClass:[JSApp class]])
			continue;
		
		NSArray *draggableClasses = [(JSApp *)proxy classesAllowingDrag];
		
		for(NSString *class in draggableClasses)
		{
			//XLog(@"checking class: %@ vs %@", className, class);
			if([class isEqual:className])
				dragAllowed = YES;
		}
	}
	
	NSRect windowFrame = [self frame];
	
	// Grab the mouse location in global coordinates
	initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
	initialLocation.x -= windowFrame.origin.x;
	initialLocation.y -= windowFrame.origin.y;
}

@end
