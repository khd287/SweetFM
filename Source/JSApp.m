//
//  JSApp.m
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

#import "JSApp.h"

#import "XLog.h"
#import "HSettings.h"
#import "NSString+FormatUtilities.h"


NSString * const JSDOMReadyNotification = @"JSDOMReadyNotification";

NSString * const JSAppCloseWindowNotification = @"JSAppCloseWindowNotification";
NSString * const JSAppPinToggleNotification = @"JSAppPinToggleNotification";
NSString * const JSAppScrobbleToggleNotification = @"JSAppScrobbleToggleNotification";
NSString * const JSAppPlayPauseNotification = @"JSAppPlayPauseNotification";
NSString * const JSAppStopNotification = @"JSAppStopNotification";
NSString * const JSAppNextNotification = @"JSAppNextNotification";
NSString * const JSAppLoveNotification = @"JSAppLoveNotification";
NSString * const JSAppBanNotification = @"JSAppBanNotification";
NSString * const JSAppAddToPlaylistNotification = @"JSAppAddToPlaylistNotification";
NSString * const JSAppOpenQuickMenuNotification = @"JSAppOpenQuickMenuNotification";
NSString * const JSAppTuneToStationNotification = @"JSAppTuneToStationNotification";
NSString * const JSAppSetVolumeNotification = @"JSAppSetVolumeNotification";
NSString * const JSAppSetPositionNotification = @"JSAppSetPositionNotification";
NSString * const JSAppNextCoverNotification = @"JSAppNextCoverNotification";
NSString * const JSAppPreviousCoverNotification = @"JSAppPreviousCoverNotification";

NSString * const JSAppOpenBuyPageNotification = @"JSAppOpenBuyPageNotification";
NSString * const JSAppOpenTrackPageNotification = @"JSAppOpenTrackPageNotification";
NSString * const JSAppOpenArtistPageNotification = @"JSAppOpenArtistPageNotification";
NSString * const JSAppOpenAlbumPageNotification = @"JSAppOpenAlbumPageNotification";

NSString * const ArtistPrefix = @"/a";
NSString * const TagPrefix = @"/t";
NSString * const LibraryPrefix = @"/u";
NSString * const NeighbourPrefix = @"/n";
NSString * const LovedPrefix = @"/loved";
NSString * const RecommendedPrefix = @"/r";
NSString * const FanPrefix = @"/f";
NSString * const ShufflePrefix = @"/shuffle";


@interface JSApp (Private)

- (void)_setStationTitle:(NSString *)title;

@end

@implementation JSApp (Private)

- (void)_setStationTitle:(NSString *)title
{
	if(stationTitle != title)
	{
		[stationTitle release];
		stationTitle = [[title stringByTrimmingLeadSpaces] copy];
	}
}

@end


@implementation JSApp

@synthesize pinned, scrobble, stationType, stationTitle, volume, position;

- (void)dealloc
{
	[stationTitle release];
	[super dealloc];
}

- (NSString *)javascriptName
{
	return [NSString stringWithString:@"app"];
}

- (NSArray *)classesAllowingDrag
{
	return [self returnValuesForMethodCall:@"uiClassesAllowingDrag"];
}

- (NSSize)resizeCoversTo
{
	NSArray *values = [self returnValuesForMethodCall:@"uiResizeCoversTo"];
	
	if([values count] < 2)
		return NSZeroSize;
	
	NSSize size = NSMakeSize([(NSNumber *)[values objectAtIndex:0] floatValue], 
													 [(NSNumber *)[values objectAtIndex:1] floatValue]);
	
	return size;
}

+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	if(aSelector == @selector(setVolume:))
		return @"setVolume";
	
	if(aSelector == @selector(setPosition:))
		return @"setPosition";
	
	if(aSelector == @selector(tuneToStation:))
		return @"tuneToStation";
		
	return nil;
}

//
// From UI
//

- (void)DOMReady
{
	XMark();
	//[self setCoverImage:[NSImage imageNamed:@"sampleCover"]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSDOMReadyNotification
																											object:self];
}

- (void)closeWindow
{
	XLog(@"closecalled");
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppCloseWindowNotification
																											object:self];
}

- (void)playPause
{
	XLog(@"playPause");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppPlayPauseNotification
																											object:self];
}

- (void)stop
{
	XLog(@"stop");
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppStopNotification
																											object:self];
}

- (void)next
{
	XLog(@"next");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppNextNotification
																											object:self];
}

- (void)love
{
	XLog(@"love");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppLoveNotification
																											object:self];
}

- (void)ban
{
	XLog(@"ban");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppBanNotification
																											object:self];
}

- (void)addToPlaylist
{
	XLog(@"addToPlaylist");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppAddToPlaylistNotification
																											object:self];
}

- (void)openQuickMenu
{
	XLog(@"openQuickMenu");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppOpenQuickMenuNotification
														object:self];
}

- (void)tuneToStation:(NSString *)stationString
{
	XLog(@"tuneToStation %@", stationString);
	
	//
	// Set our boolean for if the user selection has a prefix to true, initially
	//
	BOOL trimmedHasPrefix = true;
	
	//
	// Interpret slash commands
	//
	
	NSString *trimmed = [stationString stringByTrimmingLeadSpaces];
	
	if([trimmed hasPrefix:TagPrefix])
	{
		stationType = TagStation;
		[self _setStationTitle:[trimmed substringFromIndex:[TagPrefix length]]];
	}
	else if([trimmed hasPrefix:ArtistPrefix])
	{
		stationType = ArtistStation;
		[self _setStationTitle:[trimmed substringFromIndex:[ArtistPrefix length]]];
	}
	else if([trimmed hasPrefix:LibraryPrefix])
	{
		stationType = LibraryStation;
		[self _setStationTitle:[trimmed substringFromIndex:[LibraryPrefix length]]];
	}
	else if([trimmed hasPrefix:NeighbourPrefix])
	{
		stationType = NeighbourStation;
		[self _setStationTitle:[trimmed substringFromIndex:[NeighbourPrefix length]]];
	}
	else if([trimmed hasPrefix:LovedPrefix])
	{
		stationType = LovedStation;
		[self _setStationTitle:LovedPrefix];
	}
	else if([trimmed hasPrefix:RecommendedPrefix])
	{
		stationType = RecommendedStation;
		[self _setStationTitle:[trimmed substringFromIndex:[RecommendedPrefix length]]];
	}
	else if([trimmed hasPrefix:FanPrefix])
	{
		stationType = FanStation;
		[self _setStationTitle:[trimmed substringFromIndex:[FanPrefix length]]];
	}
	else if([trimmed hasPrefix:ShufflePrefix])
	{
		stationType = ShuffleStation;
		[self _setStationTitle:ShufflePrefix];
	}
	else
	{
		//
		// Ask the user what they want to tune
		//
		trimmedHasPrefix = false;
		[self uiSetQuickMenuOpen];
	}
	
	if(trimmedHasPrefix)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JSAppTuneToStationNotification
															object:stationString];
	}
}

- (void)togglePinned
{
	XLog(@"togglePinned");
	pinned = !pinned;
	
	// Reflect state
	[self uiSetPinEnabled:pinned];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppPinToggleNotification
																											object:self];
}

- (void)toggleScrobble
{
	XLog(@"toggleScrobble");
	scrobble = !scrobble;
	
	// Reflect state
	[self uiSetScrobbleEnabled:scrobble];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppScrobbleToggleNotification
																											object:self];
}

- (void)setVolume:(double)vol
{
	XLog(@"setVolume %f", vol);
	
	volume = vol;
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppSetVolumeNotification
																											object:self];
}

- (void)setPosition:(double)seconds
{
	XLog(@"setPosition %f", seconds);
	
	position = seconds;
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppSetPositionNotification
																											object:self];
}

- (void)nextCover
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppNextCoverNotification
																											object:self];
}

- (void)previousCover
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppPreviousCoverNotification
														object:self];
}

- (void)setArtistStationType
{
	NSString *stationString = [self uiGetStationTitle];
	
	XLog(@"setArtistStationType");
	stationType = ArtistStation;
	
	[self handleStationString:stationString
				   withPrefix:ArtistPrefix
				   andSuffix:@"artist"
				   selectFrom:3
						   to:9];
}

- (void)setTagsStationType
{
	NSString *stationString = [self uiGetStationTitle];

	XLog(@"setTagsStationType");
	stationType = TagStation;
	
	[self handleStationString:stationString
				   withPrefix:TagPrefix
					andSuffix:@"tags"
				   selectFrom:3
						   to:7];
}

- (void)setLibraryStationType
{
	NSString *stationString = [self uiGetStationTitle];

	XLog(@"setLibraryStationType");
	stationType = LibraryStation;
	
	[self handleStationString:stationString
				   withPrefix:LibraryPrefix
					andSuffix:[HSettings lastFmUserName]
				   selectFrom:3
						   to:3+[[HSettings lastFmUserName] length]];
}

- (void)setNeighbourStationType
{
	NSString *stationString = [self uiGetStationTitle];

	XLog(@"setNeighbourStationType");
	stationType = NeighbourStation;
	
	[self handleStationString:stationString
				   withPrefix:NeighbourPrefix
					andSuffix:[HSettings lastFmUserName]
				   selectFrom:3
						   to:3+[[HSettings lastFmUserName] length]];
}

- (void)setLovedStationType
{
	//
	// Since this station does not take arguments, assume the string is nil
	//
	NSString *stationString = @"";

	XLog(@"setLovedStationType");
	stationType = LovedStation;
	[self handleStationString:stationString
				   withPrefix:LovedPrefix
					andSuffix:@""
				   selectFrom:6
						   to:6];
}

- (void)setRecommendedStationType
{
	NSString *stationString = [self uiGetStationTitle];

	XLog(@"setRecommendedStationType");
	stationType = RecommendedStation;
	
	[self handleStationString:stationString
				   withPrefix:RecommendedPrefix
					andSuffix:[HSettings lastFmUserName]
				   selectFrom:3
						   to:3+[[HSettings lastFmUserName] length]];
	
	NSUInteger selectLength = [[HSettings lastFmUserName] length];
	NSString *title = [NSString stringWithFormat:@"%@ %@", RecommendedPrefix, [HSettings lastFmUserName]];
	[self uiSetStationTitle:title selectFrom:3 to:3+selectLength];
}

- (void)setFansStationType
{
	NSString *stationString = [self uiGetStationTitle];

	XLog(@"setFansStationType");
	stationType = FanStation;
	
	[self handleStationString:stationString
				   withPrefix:FanPrefix
					andSuffix:@"artist"
				   selectFrom:3
						   to:9];
}

- (void)setShuffleStationType
{
	//
	// Since this station does not take arguments, assume the string is nil
	//
	NSString *stationString = @"";

	XLog(@"setShuffleStationType");
	stationType = ShuffleStation;
	
	[self handleStationString:stationString
				   withPrefix:ShufflePrefix
					andSuffix:@""
				   selectFrom:8
						   to:8];
}

- (void)handleStationString:(NSString *)stationString withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix selectFrom:(NSUInteger)from to:(NSUInteger)to
{
	stationString = [stationString stringByTrimmingLeadSpaces];
	NSUInteger selectLength = [stationString length];
	NSString *title = [NSString string];
	
	if([stationString hasPrefix:ArtistPrefix] || [stationString hasPrefix:TagPrefix] ||
	   [stationString hasPrefix:LibraryPrefix] || [stationString hasPrefix:NeighbourPrefix] ||
	   [stationString hasPrefix:LovedPrefix] || [stationString hasPrefix:RecommendedPrefix] ||
	   [stationString hasPrefix:FanPrefix] || [stationString hasPrefix:ShufflePrefix] || ([stationString length] == 0))
	{		
		//
		// It has a prefix, but is this something we entered, or user entered?
		// We need to see if the prefix is one of the full range prefixes, so we can ignore it
		//
		if(![stationString hasPrefix:ShufflePrefix] && ![stationString hasPrefix:LovedPrefix] && ([stationString length] != 0))
		{	
			NSRange range = NSMakeRange(0, from);
			NSMutableString *titleTruncation = [NSMutableString stringWithString:stationString];
			[titleTruncation deleteCharactersInRange:range];
			
			//
			// If the data is not one of our 3 default types, then set it as our suffix
			// otherwise, ensure we provide the correct prefix
			//
			if(titleTruncation != @"artist" && titleTruncation != @"tags" || titleTruncation != [HSettings lastFmUserName])
			{
				suffix = titleTruncation;
			}
			else if([stationString hasPrefix:ArtistPrefix] || [stationString hasPrefix:FanPrefix])
			{
				suffix = @"artist";
			}
			else if([stationString hasPrefix:TagPrefix])
			{
				suffix = @"tags";
			}
			else
			{
				suffix = [HSettings lastFmUserName];
			}
		}
		
		// It has a prefix, so we should clear it out and enter the default information
		title = [NSString stringWithFormat:@"%@ %@", prefix, suffix];
	}
	else
	{
		// It does not have a prefix, so take it's value and append the user entered data
		title = [NSString stringWithFormat:@"%@ %@", prefix, stationString];
	}
	[self uiSetStationTitle:title selectFrom:from to:to+selectLength];
}

- (void)openBuyPage
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppOpenBuyPageNotification
																											object:self];
}

- (void)openTrackPage
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppOpenTrackPageNotification
																											object:self];
}

- (void)openArtistPage
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppOpenArtistPageNotification
																											object:self];
}

- (void)openAlbumPage
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JSAppOpenAlbumPageNotification
																											object:self];
}

//
// To UI
//
- (void)uiSetQuickMenuOpen
{
	XLog(@"setQuickMenuOpen");
	[scriptObject callWebScriptMethod:@"uiSetQuickMenuOpen"
						withArguments:[NSArray array]];
}

- (void)uiSetPinEnabled:(BOOL)pin
{
	XLog(@"setPinEnabled %i", pin);
	NSNumber *p = [NSNumber numberWithBool:pin];
	[scriptObject callWebScriptMethod:@"uiSetPinEnabled" 
											withArguments:[NSArray arrayWithObject:p]];
	
	pinned = pin;
}

- (void)uiSetScrobbleEnabled:(BOOL)scrob
{
	XLog(@"setScrobbleEnabled %i", scrob);
	NSNumber *s = [NSNumber numberWithBool:scrob];
	[scriptObject callWebScriptMethod:@"uiSetScrobbleEnabled" 
											withArguments:[NSArray arrayWithObject:s]];
	
	scrobble = scrob;
}

- (void)uiSetCoverImage:(NSImage *)image
{
	if(image)
	{
		//
		// Resize the image first
		//
		NSSize size = [self resizeCoversTo];
		NSRect rect = NSMakeRect(0, 0, size.width, size.height);
		
		NSImage *img = [[NSImage alloc] initWithSize:size];
		
		[img lockFocus];
		[image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
		[img unlockFocus];
		
		NSString *base64ImageSource = [JSApp imageSourceBase64PNG:img];
		[img release];
		
		[scriptObject callWebScriptMethod:@"uiSetCoverImage" 
												withArguments:[NSArray arrayWithObject:base64ImageSource]];
	}
	else
	{
		[scriptObject callWebScriptMethod:@"uiSetCoverImage" 
												withArguments:[NSArray arrayWithObject:@" "]];
	}
}

- (void)uiSetCoverNumber:(NSUInteger)num
{
	[scriptObject callWebScriptMethod:@"uiSetCoverNumber" 
											withArguments:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:num]]];
}

- (void)uiSetCoverCount:(NSUInteger)num
{
	[scriptObject callWebScriptMethod:@"uiSetCoverCount" 
											withArguments:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:num]]];
}

- (void)uiSetTrackName:(NSString *)trackName
{
	if(trackName==nil)
		trackName = @" ";
	
	[scriptObject callWebScriptMethod:@"uiSetTrackName" 
											withArguments:[NSArray arrayWithObject:trackName]];
}

- (void)uiSetTrackAlbum:(NSString *)trackAlbum
{
	if(trackAlbum==nil)
		trackAlbum = @" ";
	
	[scriptObject callWebScriptMethod:@"uiSetTrackAlbum" 
											withArguments:[NSArray arrayWithObject:trackAlbum]];
}

- (void)uiSetTrackArtist:(NSString *)trackArtist
{
	if(trackArtist==nil)
		trackArtist = @" ";
	
	[scriptObject callWebScriptMethod:@"uiSetTrackArtist" 
											withArguments:[NSArray arrayWithObject:trackArtist]];
}

- (void)uiSetDuration:(NSUInteger)seconds
{
	if(seconds < 1)
		seconds = 1;
	
	NSNumber *i = [NSNumber numberWithUnsignedInt:seconds];
	[scriptObject callWebScriptMethod:@"uiSetDuration" 
											withArguments:[NSArray arrayWithObject:i]];
}

- (void)uiSetPosition:(NSUInteger)seconds
{
	NSNumber *i = [NSNumber numberWithUnsignedInt:seconds];
	[scriptObject callWebScriptMethod:@"uiSetPosition" 
											withArguments:[NSArray arrayWithObject:i]];
}

- (void)uiSetVolume:(double)vol
{
	if(vol == volume)
		return;
	
	NSNumber *i = [NSNumber numberWithDouble:vol];
	[scriptObject callWebScriptMethod:@"uiSetVolume" 
											withArguments:[NSArray arrayWithObject:i]];
}

- (void)uiSetStationTitle:(NSString *)title selectFrom:(NSUInteger)from to:(NSUInteger)to
{
	if(!title)
		title = @" ";
	
	[scriptObject callWebScriptMethod:@"uiSetStationTitle" 
						withArguments:[NSArray arrayWithObjects:title, 
							    [NSNumber numberWithUnsignedInt:from], 
								[NSNumber numberWithUnsignedInt:to], nil]];
}

- (NSString *)uiGetStationTitle
{
	return [scriptObject callWebScriptMethod:@"uiGetStationTitle" 
							   withArguments:[NSArray array]];	
}

- (void)uiSetErrorMessage:(NSString *)msg
{
	if(!msg)
		msg = @" ";
	
	[scriptObject callWebScriptMethod:@"uiSetErrorMessage" 
											withArguments:[NSArray arrayWithObject:msg]];
}

- (void)uiSetStatusMessage:(NSString *)msg
{
	if(!msg)
		msg = @" ";
	
	[scriptObject callWebScriptMethod:@"uiSetStatusMessage" 
											withArguments:[NSArray arrayWithObject:msg]];
}

@end
