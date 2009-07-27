//
//  FMStation.m
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

#import "FMStation.h"

#import "FMRadioSession.h"
#import "QOperation.h"
#import "QHandler.h"

#import "HGrowl.h"
#import "XLog.h"


// URL
NSString * const StationAdjustPattern = @"http://%@%@/adjust.php?url=%@&session=%@";

// Tag
NSString * const TagRadioGlobal = @"lastfm://globaltags/%@";

// User
NSString * const UserRadioLibrary = @"lastfm://user/%@/library";
NSString * const UserRadioNeighbours = @"lastfm://user/%@/neighbours";
NSString * const UserRadioLovedTracks = @"lastfm://user/%@/loved";
NSString * const UserRadioRecommendation = @"lastfm://user/%@/recommended";

// Artist
NSString * const ArtistRadioSimilar = @"lastfm://artist/%@/similarartists";
NSString * const ArtistRadioTopFans = @"lastfm://artist/%@/fans";

// Keys
NSString * const StationResponseKey = @"response";
NSString * const StationResponseErrorKey = @"error";
NSString * const StationNameKey = @"stationname";
NSString * const StationURLKey = @"url";

// 
// Proxy
//

@interface FMStationProxy : QProxy @end

@implementation FMStationProxy

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	if([anInvocation selector] == @selector(tuneToStation:))
	{
		[anInvocation setTarget:target];
		
		QOperation *op = [[QOperation alloc] initWithCriticalValidatedInvocation:anInvocation];
		[[QHandler messages] addOperation:op];
		[op release];
	}
}

@end


//
// FMStation
//
@implementation FMStation

@synthesize stationName, stationURL;

//
// Radio URLs
//
+ (NSString *)globalTagsRadio:(NSString *)tags {
	return [NSString stringWithFormat:TagRadioGlobal, [tags escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

+ (NSString *)userLibraryRadio:(NSString *)user {
	return [NSString stringWithFormat:UserRadioLibrary, [user escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

+ (NSString *)userNeighbourRadio:(NSString *)user {
	return [NSString stringWithFormat:UserRadioNeighbours, [user escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

+ (NSString *)userLovedTracksRadio:(NSString *)user {
	return [NSString stringWithFormat:UserRadioLovedTracks, [user escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

+ (NSString *)userRecommendedRadio:(NSString *)user {
	return [NSString stringWithFormat:UserRadioRecommendation, [user escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

+ (NSString *)similarArtistsRadio:(NSString *)artist {
	return [NSString stringWithFormat:ArtistRadioSimilar, [artist escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

+ (NSString *)artistFanRadio:(NSString *)artist {
	return [NSString stringWithFormat:ArtistRadioTopFans, [artist escapeAllURLCharactersAndUseWhitespacePlus:YES]];
}

//
// Class
//
- (id)initWithRadioSession:(FMRadioSession *)aSession
{
	if(self = [super init])
	{
		session = [aSession retain];
	}
	
	return self;
}

- (void)dealloc
{
	[stationName release];
	[session release];
	[super dealloc];
}

- (id)queue 
{
	return [[[FMStationProxy alloc] initWithTarget:self] autorelease];
}

- (BOOL)tuneToStation:(NSString *)aStation
{
	if(!aStation)
	{
		self.lastError = @"Station invalid";
		return NO;
	}
	
	NSString *req = [NSString stringWithFormat:
											 StationAdjustPattern,
											 session.domain,
											 session.path,
											 [aStation escapeAllURLCharacters],
											 session.sessionKey];
	
	//XLog(@"Tune request: %@", req);
	NSData *data = [self HTTPGetString:req];
	
	if(!data) {
		self.lastError = [NSString stringWithFormat:@"Could not tune to %@", aStation]; 
		return NO;
	}
	
	NSDictionary *stationInfo = [self parseAssignedList:data];
	//XLog(@"Tune response: %@", [stationInfo description]);
	
	NSString *response = [stationInfo valueForKey:StationResponseKey];
	
	if([response rangeOfString:@"failed" options:NSCaseInsensitiveSearch].location != NSNotFound) 
	{
		NSString *err = [stationInfo valueForKey:StationResponseErrorKey];
		NSLog(@"ERROR: %@ (%@)", err, [stationInfo description]);
		
		if([err isEqualToString:@"4"])
			self.lastError = @"This station is not available for streaming";
		else if([err isEqualToString:@"5"])
			self.lastError = @"This station is for subscribers only!";
		else if([err isEqualToString:@"9"])
			self.lastError = @"Last.fm trial period expired!";
		else
			self.lastError = [NSString stringWithFormat:@"Could not tune to %@", aStation]; 
		
		return NO;
	}
	
	[stationName release];
	stationName = [[stationInfo valueForKey:StationNameKey] retain];;
	[stationURL release];
	stationURL = [[NSURL alloc] initWithString:[stationInfo valueForKey:StationURLKey]];
	
	if(!stationName || !stationURL)
	{
		self.lastError = @"Invalid station returned";
		return NO;
	}
	
	[[HGrowl instance] postNotificationWithName:GrowlTunedToStation
																				title:@"Tuned to station..."
																	description:[stationName stringByReplacingOccurrencesOfString:@"%20" withString:@"+"]
																				image:nil];
	
	return YES;
}

@end
