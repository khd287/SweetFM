//
//  Exporter.m
//  SweetFM
//
//  Created by Q on 05.06.09.
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

#import "Exporter.h"

#import "SynthesizeSingleton.h"
#import "iTunesBridge.h"
#import "Device.h"
#import "TagAPI.h"
#import "FMTrack.h"

#import "HSettings.h"
#import "HLyrics.h"

#import "NSString+FormatUtilities.h"
#import "NSString+Paths.h"



NSString * const TempExportPath = @"/tmp/sfm-dump";

@implementation Exporter

SYNTHESIZE_SINGLETON_FOR_CLASS(Exporter, instance);

- (id)init
{
	if(self = [super init])
	{
		tunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
		
		//
		// Register as an observer for the terminate notification
		//
		[[NSNotificationCenter defaultCenter] addObserver:self
																						 selector:@selector(applicationWillTerminate:)
																								 name:NSApplicationWillTerminateNotification
																							 object:nil];
	}

	return self;
}

- (void)dealloc
{
	[tunes release];
	[staticPlaylists release];
	
	[super dealloc];
}

+ (NSArray *)defaultPlaylistNames
{
	return [NSArray arrayWithObjects:@"Master", @"Music", @"Movies", @"TV Shows", @"Podcasts", @"Audiobooks", @"Purchased Music",	@"Party Shuffle", nil];
}

- (iTunesPlaylist *)libraryPlaylist
{
	for(iTunesSource *source in [tunes sources])
	{
		if([source kind] == iTunesESrcLibrary)
			return [[source libraryPlaylists] objectAtIndex:0];
	}
	
	return nil;
}

- (SBElementArray *)userPlaylists
{	
	for(iTunesSource *source in [tunes sources]) 
	{
		if([source kind] == iTunesESrcLibrary) 
			return [source userPlaylists];
	}
	
	return nil;
}

- (NSArray *)staticPlaylists
{
	if(staticPlaylists)
		return [[staticPlaylists copy] autorelease];
	
	return [self refreshStaticPlaylists];
}

- (NSArray *)refreshStaticPlaylists
{
	//
	// Get iTunes library
	//
	NSString *libPath = [NSHomeDirectory() stringByAppendingString:@"/Music/iTunes/iTunes Music Library.xml"];
	
	NSDictionary *plDict = [NSDictionary dictionaryWithContentsOfFile:libPath];
	
	if(!plDict)
		return nil;
	
	//
	// Extract static playlists
	//
	NSArray *exclude = [[Exporter defaultPlaylistNames] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:@"Genius Track ID", @"Folder", @"Parent Persistent ID",
																	   @"Smart Info", @"Smart Criteria", nil]];
	
	NSMutableArray *valid = [NSMutableArray array];
	
	for(NSDictionary *list in [plDict objectForKey:@"Playlists"]) 
	{
		BOOL skipPlaylist = NO;
		
		for(NSString *ex in exclude) 
			if([list objectForKey:ex])
				skipPlaylist = YES;
		
		if(!skipPlaylist)
			[valid addObject:[list objectForKey:@"Name"]];
	}
	
	//
	// Update static playlists
	//
	[staticPlaylists release];
	staticPlaylists = [[NSArray alloc] initWithArray:valid];
	
	return [[staticPlaylists copy] autorelease];
}

- (BOOL)export:(DeviceTrack *)aTrack toPlaylist:(NSString *)aPlaylist audioData:(NSData *)theData
{
	//
	// Check values
	//
	if(!aTrack || !aPlaylist || !theData)
		return NO;
	
	//
	// Check conditions
	//
	if(![HSettings exportTracks])
		return NO;
	
	ExportCondition cond = [HSettings exportOn];
	
	switch(cond)
	{
		case ExportOnLoved: if(!aTrack.loved) return NO; break;
		case ExportOnAddToPlaylist: if(!aTrack.addedToPlaylist) return NO; break;
		case ExportOnLoveAndAddToPlaylist: 
		{
			if(!(aTrack.addedToPlaylist || 
				 aTrack.loved))
				return NO; 
			break;
		}
		case ExportAllways: break;
		default: return NO;
	}
	
	
	[aTrack retain];
	[aPlaylist retain];
	[theData retain];
	
	//
	// Build the file path and create directory if it doesn't exist
	//
	NSString *path = [NSString stringWithFormat:@"%@/%i.mp3", TempExportPath, [aTrack hash]];
	
	[[NSFileManager defaultManager] createDirectoryAtPath:TempExportPath attributes:nil];
	[theData writeToFile:path atomically:YES];
	
	//
	// Tag it!
	//
	TagAPI *tagger = [[TagAPI alloc] initWithGenreList:nil];
	
	[tagger examineFile:path];
	[tagger setTitle:aTrack.name];
	[tagger setAlbum:aTrack.album];
	[tagger setArtist:aTrack.artist];
	[tagger setComments:@"Recorded with SweetFM"];
	
	// TODO: Include rating sometime...
	// [tagger setFrame:frame replace:YES]; 
	
	if(aTrack.cover)
	{		
		/*
		NSArray *reps = [aTrack.cover representations];
		NSData *bitmap = [NSBitmapImageRep representationOfImageRepsInArray:reps usingType:NSJPEGFileType properties:nil];
		
		NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:bitmap];
		*/
		
		NSData *imageData = [aTrack.cover  TIFFRepresentation];
		NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
		NSDictionary *imageProps = [NSDictionary dictionaryWithObject:
																[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
		
		imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:imageData];
		
		//
		// Write image info dict
		//
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:rep forKey:@"Image"];
		[dict setObject:@"Other" forKey:@"Picture Type"];
		[dict setObject:@"image/jpeg" forKey:@"Mime Type"];
		[dict setObject:@"" forKey:@"Description"];
		
		[tagger setImages:[NSArray arrayWithObject:dict]];
	}
	
	[tagger updateFile];
	
	@try 
	{
		//
		// Start iTunes
		//
		NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow:15];
		
		if(![tunes isRunning])
		{
			[tunes run];
			
			while(![tunes isRunning])
			{
				[NSThread sleepForTimeInterval:0.5];
				
				if([(NSDate *)[NSDate date] compare:runUntil] == NSOrderedDescending)
					goto bail;
			}
		}
		
		//
		// Select playlist...
		//
		iTunesPlaylist *playlist = nil;
		
		for(iTunesPlaylist *aList in [self userPlaylists])
		{
			if([aPlaylist isEqual:aList.name])
			{
				playlist = aList;
				break;
			}
		}
		
		//
		// ... or create a new one
		//
		if(!playlist)
		{
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
														aPlaylist, @"name", nil];
			playlist = [[[tunes classForScriptingClass:@"playlist"] alloc] initWithProperties:dict];
			[[self userPlaylists] insertObject:playlist atIndex:0];
		}
		
		//
		// Check for duplicates before we import the track
		//
		NSString *query = [NSString stringWithFormat:@"%@ %@ %@", [aTrack.name empty], [aTrack.artist empty], [aTrack.album empty]];
		
		SBElementArray *found = (SBElementArray *)[[self libraryPlaylist] searchFor:query only:iTunesESrAAll];
		
		if(playlist && ![found count])
		{
			iTunesTrack *newTrack = [tunes add:[NSArray arrayWithObject:[path HFSPath]] to:playlist];
			newTrack.rating = aTrack.rating;
			
			//
			// Adding Lyrics
			//
			if([HSettings lyricDownloadEnabled] == YES) {
				NSString *lyrics = [HLyrics lyricsForTrack:aTrack];
				if(lyrics) {
					[newTrack setLyrics:lyrics];
				}
			}
			
			//
			// Increment cashtistics
			//
			[HSettings incrementCashtistic];
		}
		
	}
	@catch (NSException *e)
	{
		NSLog(@"Error: %@", [e reason]);
		goto bail;
	}
	
	[aTrack release];
	[aPlaylist release];
	[theData release];
	
	return YES;
	
bail:
	
	[aTrack release];
	[aPlaylist release];
	[theData release];
	
	return NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification 
{
	//
	// Clean up temporary audio files
	//
	[[NSFileManager defaultManager] removeItemAtPath:TempExportPath error:nil];
}

@end
