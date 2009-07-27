//
//  FMTrack.m
//  SweetFM
//
//  Created by Q on 25.05.09.
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

#import "FMTrack.h"


// Track keys
NSString * const TrackLocationKey = @"location";
NSString * const TrackNameKey = @"title";
NSString * const TrackIDKey = @"id";
NSString * const TrackAlbumKey = @"album";
NSString * const TrackCreatorKey = @"creator";
NSString * const TrackDurationKey = @"duration";
NSString * const TrackImageURLKey = @"image";
NSString * const TrackAuthKey = @"lastfm:trackauth";
NSString * const TrackAlbumIDKey = @"lastfm:albumId";
NSString * const TrackArtistIDKey = @"lastfm:artistId";
NSString * const TrackLinkKey = @"link";

// TrackLinkKey attributes
NSString * const TrackLinkArtistPageAttribute = @"http://www.last.fm/artistpage";
NSString * const TrackLinkAlbumPageAttribute = @"http://www.last.fm/albumpage";
NSString * const TrackLinkTrackPageAttribute = @"http://www.last.fm/trackpage";
NSString * const TrackLinkBuyTrackURLAttribute = @"http://www.last.fm/buyTrackURL";
NSString * const TrackLinkBuyAlbumURLAttribute = @"http://www.last.fm/buyAlbumURL";
NSString * const TrackLinkFreeTrackURLAttribute = @"http://www.last.fm/freeTrackURL";

@implementation FMTrack

- (id)initWithXMLElement:(NSXMLElement *)xml
{
	xmlRepresentation = [xml retain];
	
	NSString *aName = [self valueForKey:TrackNameKey];
	NSString *aArtist = [self valueForKey:TrackCreatorKey];
	NSString *aAlbum = [self valueForKey:TrackAlbumKey];
	double aLength = (double)([[self valueForKey:TrackDurationKey] integerValue]/1000);
	
	self = [super initWithName:aName artist:aArtist album:aAlbum length:aLength];
	
	return self;
}

- (void)dealloc
{
	[xmlRepresentation release];
	[super dealloc];
}

- (NSURL *)location {
	return [NSURL URLWithString:[self valueForKey:TrackLocationKey]];
}

- (NSString *)trackID {
	return [self valueForKey:TrackIDKey];
}

- (NSURL *)imageLocation 
{	
	NSString *imgLoc = [self valueForKey:TrackImageURLKey];
	if([imgLoc length] < 10)
		return nil;
	else
		return [NSURL URLWithString:imgLoc];
}

- (NSURL *)imageLocationLarge
{	
	NSString *url = [self valueForKey:TrackImageURLKey];
	url = [url stringByReplacingOccurrencesOfString:@"174s" withString:@"300x300"];
	url = [url stringByReplacingOccurrencesOfString:@"130x130" withString:@"300x300"];
	
	return [NSURL URLWithString:url];
}

- (NSString *)auth {
	return [self valueForKey:TrackAuthKey];
}

- (NSString *)albumID {
	return [self valueForKey:TrackAlbumIDKey];
}

- (NSString *)artistID {
	return [self valueForKey:TrackArtistIDKey];
}

- (NSURL *)trackPage {
	return [NSURL URLWithString:[self valueForKey:TrackLinkKey attribute:TrackLinkTrackPageAttribute]];
}

- (NSURL *)albumPage {
	return [NSURL URLWithString:[self valueForKey:TrackLinkKey attribute:TrackLinkAlbumPageAttribute]];
}

- (NSURL *)artistPage {
	return [NSURL URLWithString:[self valueForKey:TrackLinkKey attribute:TrackLinkArtistPageAttribute]];
}

- (NSURL *)buyTrackURL {
	return [NSURL URLWithString:[self valueForKey:TrackLinkKey attribute:TrackLinkBuyTrackURLAttribute]];
}

- (NSURL *)buyAlbumURL {
	return [NSURL URLWithString:[self valueForKey:TrackLinkKey attribute:TrackLinkBuyAlbumURLAttribute]];
}

- (NSURL *)freeTrackURL {
	return [NSURL URLWithString:[self valueForKey:TrackLinkKey attribute:TrackLinkFreeTrackURLAttribute]];
}

//
// XML reader methods
//
- (NSString *)valueForKey:(NSString *)key
{
	return [self valueForKey:key attribute:nil];
}

- (NSString *)valueForKey:(NSString *)key attribute:(NSString *)attr {
	
	if(attr==nil) {
		
		for(NSXMLElement *e in [xmlRepresentation children]) {
			if([[e name] isEqualToString:key])
				return [e stringValue];
		}
		
		return nil;
	}
	else {
		NSError *err=noErr;
		NSString *xPath = [NSString stringWithFormat:@"%@[@rel=\"%@\"]", key, attr];
		NSArray *elm = [xmlRepresentation nodesForXPath:xPath error:&err];
		
		if(err || elm==nil || [elm count]==0)
			return nil;
		
		return [[elm objectAtIndex:0] stringValue];
	}
}

@end
