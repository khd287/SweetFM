//
//  SkinView.m
//  SweetFM
//
//  Created by Q on 22.05.09.
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

#import "SkinView.h"
#import "JSProxy.h"

#import "XLog.h"

NSString * const SkinViewDidFinishLoadingNotification = @"SkinViewDidFinishLoadingNotification";

@implementation SkinView

@synthesize scriptProxies;

- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect frameName:nil groupName:nil])
	{
		[self awakeFromNib];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[self setDrawsBackground:NO];
	[self setFrameLoadDelegate:self];
	[self setEditingDelegate:self];
	[self setFrameLoadDelegate:self];
	[self setUIDelegate:self];
	[self setMaintainsBackForwardList:NO];
}

- (void)dealloc
{
	[scriptProxies release];
	[super dealloc];
}

- (NSString *)elementClassNameAtPoint:(NSPoint)aPoint
{
	NSDictionary *element = [self elementAtPoint:aPoint];
	DOMNode *node = [element objectForKey:@"WebElementDOMNode"];
	return [node.attributes getNamedItem:@"class"].nodeValue;
}

//
// UI delegate methods
//
- (NSUInteger)webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point
{
	return WebDragSourceActionNone;
}

//
// Frame load delegate methods
//
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	// Resize to fit contents
	NSView *documentView = [[frame frameView] documentView];
	
	NSRect newFrame = NSMakeRect([[self window] frame].origin.x,
															 [[self window] frame].origin.y,
															 [documentView frame].size.width,
															 [documentView frame].size.height);
	
	[self setFrame:[documentView frame]];
	[[self window] setFrame:newFrame display:YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:SkinViewDidFinishLoadingNotification 
																											object:self];
}

//
// Editing delegate methods
//
- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag
{
	return (proposedRange.startContainer == proposedRange.endContainer);
}

//
// Frame-load delegate methods
//
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
	for(JSProxy *proxy in scriptProxies)
	{
		if([proxy respondsToSelector:@selector(javascriptName)])
		{
			XLog(@"Script proxy %@ installed (as %@).", 
						[proxy description], [proxy javascriptName]);
			
			proxy.scriptObject = windowObject;
			[windowObject setValue:proxy forKey:[proxy javascriptName]];
		}
	}
	
}

@end
