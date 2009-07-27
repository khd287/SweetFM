//
//  FMPlaylist.m
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

#import "FMPlaylist.h"

#import "FMTrack.h"
#import "FMRadioSession.h"
#import "QOperation.h"
#import "QHandler.h"


NSString * const PlaylistPattern = @"http://ws.audioscrobbler.com/radio/xspf.php?sk=%@&discovery=0&desktop=1.5.1";

//
// Proxy
//

@interface FMPlaylistProxy : QProxy @end

@implementation FMPlaylistProxy

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if([anInvocation selector] == @selector(fetchNew))
	{
		[anInvocation setTarget:target];
		
		QOperation *op = [[QOperation alloc] initWithInvocation:anInvocation
																									 critical:YES
																									 callback:@selector(queueHandlerPlaylistReceived:)];
		[[QHandler messages] addOperation:op];
		[op release];
	}
}

@end


//
// FMPlaylist
//
@implementation FMPlaylist

@synthesize session;

- (id)initWithRadioSession:(FMRadioSession *)aSession
{
	if(self = [super init])
	{
		session = [aSession retain];
		tracks = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[session release];
	[tracks release];
	
	[super dealloc];
}

- (id)queue
{
	return [[[FMPlaylistProxy alloc] initWithTarget:self] autorelease];
}

- (BOOL)fetchNew
{
	[tracks removeAllObjects];
	
	NSString *req = [NSString stringWithFormat:
									 PlaylistPattern,
									 session.sessionKey];
	
	NSData *data = [self HTTPGetString:req];
	
	NSError *err=noErr;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData:data
																										options:NSXMLDocumentTidyXML
																											error:&err] autorelease];
	
	if(err || !doc)
	{
		self.lastError = @"Error reading playlist";
		return NO;
	}
		
	// Get tracks with XPath
	NSArray *xmlTracks = [[doc rootElement] nodesForXPath:@"/playlist[1]/trackList[1]/track"
																									error:&err];
	
	for(NSXMLElement *e in xmlTracks)
	{
		FMTrack *track = [[FMTrack alloc] initWithXMLElement:e];
		[tracks addObject:track];
		[track release];
	}
	
	return YES;
}

- (NSArray *)tracks
{
	return [NSArray arrayWithArray:tracks];
}

- (FMTrack *)popTrack
{
	if([tracks count] > 0) 
	{
		FMTrack *track = [[tracks objectAtIndex:0] retain];
		[tracks removeObjectAtIndex:0];
		return [track autorelease];
	}
	
	return nil;
}

- (NSString *)description
{
	NSMutableString *desc = [NSMutableString string];
	
	[desc appendString:@"Playlist {\n"];
	
	for(FMTrack *track in tracks)
		[desc appendFormat:@"%@\n", [track description]];
	
	[desc appendString:@"}"];
	
	return [NSString stringWithString:desc];
}

@end
