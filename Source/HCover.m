//
//  HCover.m
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

#import "HCover.h"

#import "SynthesizeSingleton.h"
#import "FMBase.h"
#import "FMTrack.h"


NSString * const AWSKey = @"1JBSJH46VR5G4ZZCC302";
NSString * const AWSVersion = @"2006-00-00";
NSString * const AWSPattern = @"http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService&Version=%@&AWSAccessKeyId=%@&Operation=ItemSearch&SearchIndex=Music&ResponseGroup=Images&Title=%@&Artist=%@";

#define SizeIsLarger(oldsz, newsz) ((oldsz.width*oldsz.height)<(newsz.width*newsz.height))

//
// HCover private
//
@interface HCover (Private)

- (void)amazonRequestFinished:(NSArray *)coverURLs;
- (NSOperationQueue *)imageQueue;
- (void)addCover:(NSImage *)aCover;

@end

//
// Operations
//
@interface AmazonOperation : NSOperation {
	
	NSString *artist;
	NSString *album;
}

- (id)initWithArtist:(NSString *)aArtist album:(NSString *)aAlbum;

@end

@interface CoverLoadOperation : NSOperation {
	
	NSURL *url;
}

- (id)initWithCoverURL:(NSURL *)aURL;

@end

//
// HCover
//
@implementation HCover

@synthesize delegate, largestSize, largestIndex, selectedIndex, covers;

SYNTHESIZE_SINGLETON_FOR_CLASS(HCover, instance);

+ (HCover *)installWithDelegate:(id)dlg
{
	HCover *covers = [HCover instance];
	covers.delegate = dlg;
	return covers;
}

- (id)init
{
	if(self = [super init])
	{
		amazonQueue = [[NSOperationQueue alloc] init];
		[amazonQueue setMaxConcurrentOperationCount:1];
		
		imageQueue = [[NSOperationQueue alloc] init];
		[imageQueue setMaxConcurrentOperationCount:4];
		
		covers = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (NSArray *)covers
{
	return [NSArray arrayWithArray:covers];
}

- (void)findLargestCoverForTrack:(FMTrack *)aTrack
{
	[imageQueue setSuspended:YES];
	
	[self loadCoverFromURL:aTrack.imageLocation];
	[self loadCoverFromURL:aTrack.imageLocationLarge];
	[self findLargestCoverForArtist:aTrack.artist album:aTrack.album];
}

- (void)findLargestCoverForArtist:(NSString *)aArtist album:(NSString *)aAlbum
{
	[self loadCoversForArtist:aArtist album:aAlbum];
}

- (void)loadCoverFromURL:(NSURL *)aUrl
{
	[covers removeAllObjects];
	
	selectedIndex = 0;
	largestIndex = 0;
	largestSize = NSZeroSize;
	
	CoverLoadOperation *op = [[CoverLoadOperation alloc] initWithCoverURL:aUrl];
	[imageQueue addOperation:op];
	[op release];
}

- (void)loadCoversWithURLs:(NSArray *)theURLs
{
	[imageQueue setSuspended:YES];
	
	for(NSURL *url in theURLs)
		[self loadCoverFromURL:url];
	
	[imageQueue setSuspended:NO];
}

- (void)loadCoversForArtist:(NSString *)aArtist album:(NSString *)aAlbum
{
	selectedIndex = 0;
	largestIndex = 0;
	largestSize = NSZeroSize;
	
	AmazonOperation *op = [[AmazonOperation alloc] initWithArtist:aArtist album:aAlbum];
	[amazonQueue addOperation:op];
	[op release];
}

- (void)cancelDownloads
{
	largestSize = NSZeroSize;
	largestIndex = 0;
	selectedIndex = 0;
	[covers removeAllObjects];
	
	[amazonQueue cancelAllOperations];
	[imageQueue cancelAllOperations];
	[imageQueue setSuspended:NO];
}

- (NSImage *)nextCover
{
	if(![covers count])
		return nil;
	
	if(selectedIndex >= [covers count]-1)
	{
		selectedIndex = 0;
		return [covers objectAtIndex:selectedIndex];
	}
	else
	{
		selectedIndex++;
		return [covers objectAtIndex:selectedIndex];
	}
}

- (NSImage *)previousCover
{
	if(![covers count])
		return nil;
	
	if(selectedIndex <= 0)
	{
		selectedIndex = [covers count]-1;
		return [covers objectAtIndex:selectedIndex];
	}
	else
	{
		selectedIndex--;
		return [covers objectAtIndex:selectedIndex];
	}
}

@end

@implementation HCover (Private)

- (void)amazonRequestFinished:(NSArray *)coverURLs
{
	[covers removeAllObjects];
	
	for(NSURL *url in coverURLs)
	{
		CoverLoadOperation *op = [[CoverLoadOperation alloc] initWithCoverURL:url];
		[imageQueue addOperation:op];
		[op release];
	}
	
	//
	// Re-enable the queue and load all covers at once
	//
	[imageQueue setSuspended:NO];
}

- (NSOperationQueue *)imageQueue
{
	return imageQueue;
}

- (void)addCover:(NSImage *)aCover
{
	[covers addObject:aCover];
}

@end

//
// AmazonOperation
//
@implementation AmazonOperation

- (id)initWithArtist:(NSString *)aArtist album:(NSString *)aAlbum
{
	if(self = [super init])
	{
		artist = [aArtist copy];
		album = [aAlbum copy];
	}
	
	return self;
}

- (void)dealloc
{
	[artist release];
	[album release];
	[super dealloc];
}

- (void)main
{
	NSMutableArray *covers = [NSMutableArray array];
	
	NSString *req = [NSString stringWithFormat:
									 AWSPattern,
									 AWSVersion,
									 AWSKey,
									 [album escapeAllURLCharacters],
									 [artist escapeAllURLCharacters]];
	
	NSURLRequest *urlReq = [NSURLRequest requestWithURL:[NSURL URLWithString:req]];
	
	NSError *err = noErr;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlReq
																			 returningResponse:nil 
																									 error:&err];
	
	if(!data || err || [self isCancelled])
		return;
	
	NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:data
																									 options:NSXMLDocumentTidyXML
																										 error:&err];
	[xml autorelease];
	
	if(!xml || err || [self isCancelled])
		return;
	
	NSArray *urlElements = [[xml rootElement] nodesForXPath:@"//LargeImage/URL" 
																										error:&err];
	
	if(!urlElements || err || [self isCancelled])
		return;
	
	for(NSXMLElement *element in urlElements)
		[covers addObject:[NSURL URLWithString:[element stringValue]]];
	
	[[HCover instance] amazonRequestFinished:[NSArray arrayWithArray:covers]];	
}

@end

//
// CoverLoadOperation
//
@implementation CoverLoadOperation

- (id)initWithCoverURL:(NSURL *)aURL
{
	if(self = [super init])
	{
		url = [aURL copy];
	}
	
	return self;
}

- (void)dealloc
{
	[url release];
	[super dealloc];
}

- (void)main
{
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	NSError *err = noErr;
	NSData *data = [NSURLConnection sendSynchronousRequest:request
																			 returningResponse:nil
																									 error:&err];
	
	NSImage *image = [[NSImage alloc] initWithData:data];
	
	if([self isCancelled])
	{
		[image release];
		return;
	}
	
	HCover *c = [HCover instance];
	
	[c addCover:image];
	
	if(SizeIsLarger(c.largestSize, [image size]))
	{
		c.largestSize = [image size];
		c.largestIndex = [c.covers count];
		c.selectedIndex = [c.covers count];
		if([c.delegate respondsToSelector:@selector(currentLargestCover:)])
		{
			[c.delegate performSelectorOnMainThread:@selector(currentLargestCover:)
			 withObject:[[image retain] autorelease] 
			 waitUntilDone:YES];
		}
	}
	
	if([c.delegate respondsToSelector:@selector(coverDownloaded:)])
	{
		[c.delegate performSelectorOnMainThread:@selector(coverDownloaded:)
		 withObject:[[image retain] autorelease] 
		 waitUntilDone:YES];
	}
		
	[image release];
		
	if([[c.imageQueue operations] count] <= 1)
	{
		if([c.delegate respondsToSelector:@selector(allCoversLoaded:)])
		{
			[c.delegate performSelectorOnMainThread:@selector(allCoversLoaded:)
			 withObject:c
			 waitUntilDone:YES];
		}
	}
}

@end
