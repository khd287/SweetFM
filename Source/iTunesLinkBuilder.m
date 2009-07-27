//
//  iTunesLinkBuilder.m
//  iTunesAffilateTest
//
//  Created by Q on 06.06.09.
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

#import "iTunesLinkBuilder.h"

#import "JSON.h"
#import "XLog.h"

#import "NSString+FormatUtilities.h"


NSString * const TunesHost = @"http://ax.phobos.apple.com.edgesuite.net";
NSString * const TunesPath = @"/WebObjects/MZStoreServices.woa/wa/itmsSearch";
NSString * const TradeDoublerPattern = @"http://clk.tradedoubler.com/click?p=24380&a=%@&url=%@";

NSString * const MediaTypeAll = @"all";
NSString * const MediaTypeMusic = @"music";
NSString * const MediaTypeMovies = @"movie";
NSString * const MediaTypeShortFilms = @"shortFilm";
NSString * const MediaTypeTVShows = @"tvShow";
NSString * const MediaTypeApplications = @"software";
NSString * const MediaTypeMusicVideos = @"musicVideo";
NSString * const MediaTypeAudiobooks = @"audiobook";
NSString * const MediaTypePodcasts = @"podcast";
NSString * const MediaTypeiTunesU = @"iTunesU";

@implementation iTunesLinkBuilder

- (id)initWithTDAffilateID:(NSString *)theAffId
{
	if(self = [super init])
	{
		affId = [theAffId copy];
		[self useLocale:[NSLocale currentLocale]];
	}
	
	return self;
}

- (void)dealloc
{
	[affId release];
	[locale release];
	[super dealloc];
}

- (void)useLocale:(NSLocale *)aLocale
{
	if(locale != aLocale)
	{
		[locale release];
		locale = [aLocale copy];
	}
}

- (NSURL *)linkForAlbum:(NSString *)theAlbum artist:(NSString *)theArtist;
{
	NSURL *url = [self resultsForTerm:[NSString stringWithFormat:@"%@, %@", 
																		 theArtist, 
																		 theAlbum]
													mediaType:MediaTypeMusic];	
	
	NSError *err;
	NSData *jsonData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
																					 returningResponse:nil 
																											 error:&err];
	//
	// Parse the JSON repsonse
	//
	SBJSON *parser = [[SBJSON alloc] init];
	
	NSString *json = [[[NSString alloc] initWithData:jsonData
																					encoding:NSUTF8StringEncoding] autorelease];
	NSDictionary *result = [parser objectWithString:json error:&err];
		
	if(err)
		return nil;
		
	//
	// We just take the first link and ...
	//
	NSArray *results = [result objectForKey:@"results"];
	
	if(![results count])
		return nil;
		
	NSDictionary *first = [results objectAtIndex:0];
	
	/*
	NSMutableString *link = [NSMutableString stringWithString:[first objectForKey:@"itemParentLinkUrl"]];
	[link appendString:@"&partnerId=2003"];
	*/
	
	NSMutableString *link = [first objectForKey:@"itemParentLinkUrl"];
	
	return [NSURL URLWithString:link];
}

- (NSURL *)resultsForTerm:(NSString *)aTerm mediaType:(NSString *)aType
{
	//
	// p: the tradedoubler programme code
	// a: the affilate id
	//
	NSString *tdLink = [NSString stringWithFormat:TradeDoublerPattern, affId, @""];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[dict setObject:@"ISO8859_1" forKey:@"WOURLEncoding"];
	[dict setObject:@"1" forKey:@"lang"];
	[dict setObject:@"json" forKey:@"output"];
	[dict setObject:@"2003" forKey:@"partnerId"];
	[dict setObject:[tdLink escapeAllURLCharacters] forKey:@"TD_PARAM"];
	[dict setObject:[locale objectForKey:NSLocaleCountryCode] forKey:@"country"];
	[dict setObject:[aTerm escapeAllURLCharacters] forKey:@"term"];
	[dict setObject:aType forKey:@"media"];
	
	NSMutableString *link = [NSMutableString string];
	
	[link appendString:TunesHost];
	[link appendString:TunesPath];
	
	int first = YES;
	
	for(NSString *key in dict)
	{
		if(first)
		{
			[link appendFormat:@"?%@=%@", key, [dict objectForKey:key]];
			first = NO;
		}
		else
			[link appendFormat:@"&%@=%@", key, [dict objectForKey:key]];
	}
	
	XLog(@"iTunes link %@", link);
	
	return [NSURL URLWithString:link];
}

@end
