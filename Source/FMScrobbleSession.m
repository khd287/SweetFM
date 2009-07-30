//
//  FMScrobbleSession.m
//  SweetFM
//
//  Created by Q on 24.05.09.
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

#import "FMScrobbleSession.h"

#import "HSettings.h"
#import "Device.h"
#import "FMTrack.h"
#import "QOperation.h"
#import "QHandler.h"

#import "XLog.h"


// Player IDs and versions
NSString * const PlayerIDSweetFM = @"tst";	// this is changed back to the right ID in official releases
NSString * const PlayerIDiTunes = @"osx";
NSString * const PlayerIDTesting = @"tst";
NSString * const PlayerVersion = @"1.0";

// Scrobble ratings
NSString * const RatingFlagLove = @"L";
NSString * const RatingFlagBan = @"B";
NSString * const RatingFlagSkip = @"S";

// URLs
NSString * const ScrobbleHandshakePattern = @"http://post.audioscrobbler.com/?hs=true&p=1.2&c=%@&v=%@&u=%@&t=%@&a=%@";
NSString * const CommandURLString = @"http://ws.audioscrobbler.com/1.0/rw/xmlrpc.php";

// Keys
NSString * const FingerPrintUploadURLKey = @"fingerprint_upload_url";
NSString * const FrameHackKey = @"framehack";
NSString * const FreeTrialKey = @"freetrial";
NSString * const InfoMessageKey = @"info_message";
NSString * const PermitBootstrapKey = @"permit_bootstrap";
NSString * const StreamURLKey = @"stream_url";

// Track commands
NSString * const CommandLove = @"loveTrack";
NSString * const CommandBan = @"banTrack";
NSString * const CommandAddToUserPlaylist = @"addTrackToUserPlaylist";
NSString * const CommandArtistMetadata = @"artistMetadata";
NSString * const CommandTrackMetadata = @"trackMetadata";

//
// Proxy
//

@interface FMScrobbleSessionProxy : QProxy @end

@implementation FMScrobbleSessionProxy

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	SEL slc = [anInvocation selector];
	
	if(slc == @selector(authenticate) ||
		 slc == @selector(scrobble:withRatingFlag:) ||
		 slc == @selector(nowPlaying:) ||
		 slc == @selector(love:) ||
		 slc == @selector(ban:) ||
		 slc == @selector(addToPlaylist:) ||
		 slc == @selector(sendCommand:forTrack:))
	{
		[anInvocation setTarget:target];
		
		QOperation *op = [[QOperation alloc] initWithValidatedInvocation:anInvocation];
		[[QHandler messages] addOperation:op];
		[op release];
	}
}

@end


//
// FMScrobbleSession
//
@interface FMScrobbleSession (Private)

- (NSData *)commandDataForType:(NSString *)cmd track:(DeviceTrack *)track;

@end

@implementation FMScrobbleSession

@synthesize scrobbleKey, nowPlayingURL, submissionURL, authenticated;

- (id)initWithUser:(NSString *)aUser
					password:(NSString *)aPassword 
					playerID:(NSString *)pid;
{
	if(self = [super init])
	{
		user = [aUser copy];
		password = [aPassword copy];
		playerID = [pid copy];
	}
	
	return self;
}

- (void)dealloc
{
	[user release];
	[password release];
	[playerID release];
	[scrobbleKey release];
	[nowPlayingURL release];
	[submissionURL release];
	
	[super dealloc];
}

- (id)queue
{
	return [[[FMScrobbleSessionProxy alloc] initWithTarget:self] autorelease];
}

- (BOOL)authenticate
{
	NSString *req = [NSString stringWithFormat:
									 ScrobbleHandshakePattern, 
									 playerID,
									 PlayerVersion, 
									 user,
									 [self timestamp],
									 [self sessionToken]];
	
	NSData *data = [self HTTPGetString:req];
	
	if(!data)
	{
		self.lastError = @"Error contacting scrobble service";
		return NO;
	}
	
	NSArray *scrobbleInfo = [self parseList:data];
	
	if([scrobbleInfo count] < 4)
	{
		self.lastError = @"Could not retrieve scrobble ID";
		return NO;
	}
	
	[scrobbleKey release];
	scrobbleKey = [[scrobbleInfo objectAtIndex:1] retain];
	[nowPlayingURL release];
	nowPlayingURL = [[NSURL URLWithString:[scrobbleInfo objectAtIndex:2]] retain];
	[submissionURL release];
	submissionURL = [[NSURL URLWithString:[scrobbleInfo objectAtIndex:3]] retain];
	
	authenticated = YES;
	
	return YES;
}

- (NSString *)sessionToken
{
	return [[[password md5] stringByAppendingString:[self timestamp]] md5];
}

- (BOOL)scrobble:(DeviceTrack *)track withRatingFlag:(NSString *)rate
{
	if(!scrobbleKey || !submissionURL) {
		self.lastError = @"Last.fm session invalid";
		return NO;
	}
	
	if(track.scrobbled)
		return YES;
	
	track.scrobbled = YES;
	
	//
	// Build scrobble request
	//
	int index = 0;
	NSMutableString* params = [NSMutableString string];
	
	BOOL sourceIsLastFM = [track isKindOfClass:[FMTrack class]];

	//
	// Build track-auth
	//
	NSString *trackAuth = nil;
	if(sourceIsLastFM)
		trackAuth = [@"L" stringByAppendingString:((FMTrack *)track).auth];
	else
		trackAuth = @"P";
	
	//
	// Scrobble rating
	//
	NSString *rating = rate ? rate : @"";
			
	// scrobble session id
	[params appendFormat:@"s=%@", scrobbleKey];					
	// artist
	[params appendFormat:@"&a[%i]=", index];															
	[params appendString:[track.artist escapeAllURLCharactersAndUseWhitespacePlus:YES]];
	// title
	[params appendFormat:@"&t[%i]=", index];
	[params appendString:[track.name escapeAllURLCharactersAndUseWhitespacePlus:YES]];
	// timestamp
	[params appendFormat:@"&i[%i]=%@", index, [self timestamp]];
	// track-auth
	[params appendFormat:@"&o[%i]=%@", index, trackAuth];
	// rating (L/B/S)
	[params appendFormat:@"&r[%i]=", index];
	[params appendString:rating];	
	// duration
	[params appendFormat:@"&l[%i]=%i", index, (NSInteger)track.length];
	// album
	[params appendFormat:@"&b[%i]=%@", index, [track.album escapeAllURLCharactersAndUseWhitespacePlus:YES]];
	// track no, music brainz id... don't need that
	[params appendFormat:@"&n[%i]=&m[%i]=\n", index, index];
	
	//
	// Encode and send scrobble data
	//
	NSData *reqData = [params dataUsingEncoding:NSUTF8StringEncoding];
	NSData *data = [self HTTPPost:submissionURL data:reqData];
	
	if(!data)
	{
		self.lastError = @"Error scrobbling track";
		return NO;
	}
	
	if(![[data UTF8String] containsString:@"ok"])
	{
		self.lastError = [NSString stringWithFormat:@"Error scrobbling track"];
		return NO;
	}
		
	XLog(@"Track scrobbled");
	return YES;
}

- (BOOL)nowPlaying:(DeviceTrack *)track
{
	if(!scrobbleKey || !submissionURL) {
		self.lastError = @"Last.fm session invalid";
		return NO;
	}
	
	if(track.nowPlayingSent)
		return YES;
	
	track.nowPlayingSent = YES;
	
	//
	// Build now playing post 
	//
	NSMutableString* params = [NSMutableString string];
	
	[params appendFormat:@"s=%@", scrobbleKey];
	[params appendFormat:@"&a=%@", [track.artist escape]];
	[params appendFormat:@"&t=%@", [track.name escape]];
	[params appendFormat:@"&b=%@", [track.album escape]];
	[params appendFormat:@"&l=%i", (NSInteger)track.length];
	[params appendString:@"&n=&m=\n"];
	
	//
	// Encode and send now playing notification
	//
	NSData *reqData = [params dataUsingEncoding:NSUTF8StringEncoding];
	NSData *data = [self HTTPPost:nowPlayingURL data:reqData];
	
	if(!data || ![[data UTF8String] containsString:@"ok"])
	{
		self.lastError = @"Error sending now playing notification";
		return NO;
	}
		
	if([HSettings adiumStatusChangeEnabled] == YES) {
		[self changeAdiumStatusMessage:track];
	}

	XLog(@"Now playing notification sent.");
	return YES;	
}

- (BOOL)love:(DeviceTrack *)track
{
	if(!track.loved && !track.banned)
	{
		track.loved = YES;
		XLog(@"Track loved");
		return [self sendCommand:CommandLove forTrack:track];
	}
	else
	{
		self.lastError = @"Error loving track";
		return NO;
	}
}

- (BOOL)ban:(DeviceTrack *)track
{
	if(!track.banned && !track.loved)
	{
		track.banned = YES;
		XLog(@"Track banned");
		return [self sendCommand:CommandBan forTrack:track];
	}
	else
	{
		self.lastError = @"Error banning track";
		return NO;
	}
}

- (BOOL)addToPlaylist:(DeviceTrack *)track
{
	if(!track.addedToPlaylist && !track.banned)
	{
		track.addedToPlaylist = YES;
		XLog(@"Track added to playlist");
		return [self sendCommand:CommandAddToUserPlaylist forTrack:track];
	}
	else
	{
		self.lastError = @"Error adding track to playlist";
		return NO;
	}
}

- (BOOL)sendCommand:(NSString *)cmd forTrack:(DeviceTrack *)track
{
	NSData *reqData = [self commandDataForType:cmd track:track];
	
	if(!reqData)
	{
		self.lastError = @"Error sending command";
		return NO;
	}
	
	NSData *data = [self HTTPMimePost:[NSURL URLWithString:CommandURLString]
															 data:reqData 
													 mimeType:@"xml/text"];
	
	if(!data || ![[data UTF8String] containsString:@"ok"])
	{
		XLog([data UTF8String]);
		self.lastError = @"Error sending command";
		return NO;
	}
	
	return YES;
}

//
// Adium Support
//

#pragma mark *** Adium
#pragma mark -

- (void)changeAdiumStatusMessage:(DeviceTrack *)aTrack {
	XMark();
	NSAppleScript *adiumScript = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Adium\"\ngo online with message \"♫ %@ - %@\"\nend tell\n", aTrack.name, aTrack.artist]];
	[adiumScript executeAndReturnError:nil];
	[adiumScript release];
}

@end


@implementation FMScrobbleSession (Private)

- (NSData *)commandDataForType:(NSString *)cmd track:(DeviceTrack *)track
{
	if(!cmd || !track)
		return nil;
	
	NSMutableString* xml = [NSMutableString string];
	[xml appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><methodCall><methodName>"];
	[xml appendString:cmd];
	[xml appendString:@"</methodName><params><param><value><string>"];
	[xml appendString:user];
	[xml appendString:@"</string></value></param><param><value><string>"];
	[xml appendString:[self timestamp]];
	[xml appendString:@"</string></value></param><param><value><string>"];
	[xml appendString:[self sessionToken]];
	[xml appendString:@"</string></value></param><param><value><string>"];
	[xml appendString:track.artist];
	[xml appendString:@"</string></value></param><param><value><string>"];
	[xml appendString:track.name];
	[xml appendString:@"</string></value></param></params></methodCall>\n"];
	
	return [xml dataUsingEncoding:NSUTF8StringEncoding];
}

@end
