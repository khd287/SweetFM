//
//  HGrowl.m
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

#import "HGrowl.h"

#import "SynthesizeSingleton.h"
#import "XLog.h"


NSString * const GrowlTrackPlaying = @"Track playing";
NSString * const GrowlTrackPaused = @"Track paused";
NSString * const GrowlTrackResumed = @"Track resumed";
NSString * const GrowlTrackStopped = @"Track stopped";
NSString * const GrowlTrackExported = @"Track exported";
NSString * const GrowlTrackLoved = @"Track loved";
NSString * const GrowlTrackBanned = @"Track banned";
NSString * const GrowlTrackAddToPlaylist = @"Track added to playlist";
NSString * const GrowlTrackBuffering = @"Track buffering";
NSString * const GrowlTunedToStation = @"Tuned to station";
NSString * const GrowlError = @"Error";

@implementation HGrowl

SYNTHESIZE_SINGLETON_FOR_CLASS(HGrowl, instance);

+ (HGrowl *)install
{
	return [HGrowl instance];
}

- (id)init
{
	if(self = [super init])
	{
		[GrowlApplicationBridge setGrowlDelegate:self];
		[GrowlApplicationBridge registerWithDictionary:[self registrationDictionaryForGrowl]];
	}
	
	return self;
}

- (NSDictionary *)registrationDictionaryForGrowl {
	
	NSArray *notify = [NSArray arrayWithObjects:
										 GrowlTrackPlaying, 
										 GrowlTrackPaused, 
										 GrowlTrackResumed,
										 GrowlTrackStopped, 
										 GrowlTrackExported,
										 GrowlTrackLoved,
										 GrowlTrackBanned, 
										 GrowlTrackAddToPlaylist,
										 GrowlTrackBuffering,
										 GrowlTunedToStation,
										 GrowlError, nil];
	
	NSDictionary *dict =  [NSDictionary dictionaryWithObjectsAndKeys:
												 [NSNumber numberWithInt:1], @"TicketVersion",
												 notify, @"AllNotifications",
												 notify, @"DefaultNotifications", nil];
	
	return dict;
}

- (void) growlNotificationWasClicked:(id)clickContext
{
	if(clickContext && [clickContext isEqualToString:@"defaultClickContext"])
	{
		XLog(@"Notification clicked");
	}
}

- (void)growlIsReady 
{	
	// Stub
}

- (void)postNotificationWithName:(NSString *)notify
													 title:(NSString *)title
										 description:(NSString *)desc
													 image:(NSImage *)img
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
												notify, @"name",
												title, @"title",
												desc, @"desc", 
												img, @"image", nil];
	
	[self performSelectorOnMainThread:@selector(postOnMainThread:)
												 withObject:dict
											waitUntilDone:NO];	
}

- (void)postOnMainThread:(NSDictionary *)dict 
{
	[GrowlApplicationBridge notifyWithTitle:[dict objectForKey:@"title"]
															description:[dict objectForKey:@"desc"]
												 notificationName:[dict objectForKey:@"name"]
																 iconData:[[dict objectForKey:@"image"] TIFFRepresentation]
																 priority:0
																 isSticky:NO
														 clickContext:@"defaultClickContext"];
}
	
@end
