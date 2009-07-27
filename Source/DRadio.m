//
//  DRadio.m
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

#import "DRadio.h"

#import "QHandler.h"
#import "ALStream.h"
#import "HSettings.h"
#import "HCover.h"
#import "Exporter.h"

#import "FMRadioSession.h"
#import "FMScrobbleSession.h"
#import "FMStation.h"
#import "FMPlaylist.h"
#import "FMTrack.h"

#import "XLog.h"


@interface DRadio (Private)

- (void)_renewSession;
- (void)_setAudioStream:(ALStream *)aStream;
- (void)_setPreviousStation:(NSString *)aStation;
- (void)_setTuneToStation:(NSString *)aStation;

@end

@implementation DRadio

@synthesize radioSession, station, playlist;

// 
// Helper
//
+ (NSString *)lastFmStationForType:(JSAppStationType)type name:(NSString *)name
{
	switch (type) {
		case NoStation: return nil; break;
		case ArtistStation: return [FMStation similarArtistsRadio:[name capitalizedString]]; break;
		case TagStation: return [FMStation globalTagsRadio:[name capitalizedString]]; break;
		case LibraryStation: return [FMStation userLibraryRadio:name]; break;
		case NeighbourStation: return [FMStation userNeighbourRadio:name]; break;
		case LovedStation: return [FMStation userLovedTracksRadio:[HSettings lastFmUserName]]; break;
		case RecommendedStation: return [FMStation userRecommendedRadio:name]; break;
		case FanStation: return [FMStation artistFanRadio:[name capitalizedString]]; break;
		case ShuffleStation: 
		{
			NSArray *tags = [HSettings shuffleNames];
			int rnd = random() % [tags count];
			
			if(![tags count])
				return nil;
			
			return [FMStation globalTagsRadio:[[tags objectAtIndex:rnd] capitalizedString]];
			break;
		}
		default: return [FMStation globalTagsRadio:name];
	}
}

//
// Device overrides
//
#pragma mark *** Device overrides
#pragma mark -

- (id)initWithDelegate:(id)theDelegate appProxy:(JSApp *)app
{
	if(self = [super initWithDelegate:theDelegate appProxy:app])
	{
		appProxy = [app retain];
		
		[HCover installWithDelegate:self];
		
		//
		// Setup the protocol queue
		//
		[QHandler instance].delegate = self;
		
		//
		// Listen for notifications
		//
		NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
		[notify addObserver:self selector:@selector(nextCover:) 
									 name:JSAppNextCoverNotification object:nil];
		[notify addObserver:self selector:@selector(previousCover:)
									 name:JSAppPreviousCoverNotification object:nil];
		
		//
		// Init scrobble session
		//
		self.scrobbleSession = [[[FMScrobbleSession alloc] initWithUser:[HSettings lastFmUserName] 
																													 password:[HSettings lastFmPassword] 
																													 playerID:PlayerIDSweetFM] autorelease];
		
		//
		// Register for EQ notifications
		//
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(equalizerChanged:)
																								 name:EQChangedNotification object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[self _setAudioStream:nil];
	[self reset];
	[self _setPreviousStation:nil];
	[self _setTuneToStation:nil];
	[super dealloc];
}

- (void)refresh
{	
	XMark();
	
	[self scrobbleSession];
	
	//
	// Send initialized message
	//
	if([delegate respondsToSelector:@selector(deviceInitialized:)])
		[delegate deviceInitialized:self];
}

- (void)reset
{
	XMark();
	[super reset];

	//
	// Cancel cover downloads
	//
	[[HCover instance] cancelDownloads];
	
	// 
	// Reset audio stream
	//
	[self _setAudioStream:nil];
	
	//
	// Reset scrobble session
	//
	self.radioSession = nil;
	self.scrobbleSession = nil;
	self.station = nil;
	self.playlist = nil;
	self.track = nil;
	
	self.locked = NO;
	
	[self _renewSession];
}

- (DeviceTrack *)track
{
	return track;
}

- (void)setTrack:(DeviceTrack *)aTrack
{
	XMark();
	
	if(track != aTrack)
	{
		[track release];
		track = [aTrack retain];
	}
}

- (void)setVolume:(double)vol;
{
	XMark();
	volume = vol;
	audioStream.volume = vol;
	[HSettings setRadioVolume:vol];
}

- (double)volume
{	
	return [HSettings radioVolume];
}

- (double)position
{
	return audioStream.playbackPosition;
}

- (DeviceState)deviceState
{
	XMark();
	
	if(audioStream.isPaused)
		return DevicePaused;
	else if(audioStream.isPlaying)
		return DevicePlaying;
	else
		return DeviceStopped;
}

- (FMScrobbleSession *)scrobbleSession
{
	XMark();
	/*
	if(!scrobbleSession.authenticated)
	*/
	[[scrobbleSession queue] authenticate];
	return scrobbleSession;
}

- (BOOL)isRunning
{
	XMark();
	return audioStream.isPlaying || audioStream.isPaused;
}

- (void)playPause
{
	XMark();
	
	if(suspended || locked)
		return;
		
	//
	// Check if session needs renewal
	//
	[self _renewSession];
	
	if(audioStream && audioStream.isPlaying)
	{
		timeoutStamp = [[NSDate date] timeIntervalSince1970];
		[audioStream pause];
	}
	else if(audioStream && audioStream.isPaused)
	{
		NSTimeInterval elapsed = [[NSDate date] timeIntervalSince1970];
		if((elapsed-timeoutStamp) > 60*5)
		{
			self.scrobbleSession = nil;
		}
		
		timeoutStamp = 0;
		[audioStream play];
	}
	else if(!playlist || (!audioStream.isPlaying && !audioStream.isPaused))
	{
		//
		// Fetch playlist
		//
		self.playlist = [[[FMPlaylist alloc] initWithRadioSession:radioSession] autorelease];
		[[playlist queue] fetchNew];
	}
}

- (void)stop
{
	if(suspended || locked)
		return;
	
	XMark();
	
	[audioStream stop];
}

- (void)nextTrack
{
	if(suspended || locked)
		return;
	
	XMark();
	
	if(audioStream.isPlaying || audioStream.isPaused || audioStream.isBuffering)
	{
		skipped = YES;
		[audioStream stop];
	}
}

- (void)previousTrack
{
	if(suspended || locked)
		return;
	
	XMark();
	
	[audioStream stop];
}

//
// JSApp notifications
//
#pragma mark *** JSApp notifications
#pragma mark -

- (void)nextCover:(NSNotification *)notify
{
	if(suspended || locked)
		return;
	
	XMark();
	if(track)
	{
		track.cover = [[HCover instance] nextCover];
		[appProxy uiSetCoverNumber:[HCover instance].selectedIndex+1];
		[appProxy uiSetCoverImage:track.cover];
	}
}

- (void)previousCover:(NSNotification *)notify
{
	if(suspended || locked)
		return;
	
	XMark();
	if(track)
	{
		track.cover = [[HCover instance] previousCover];
		[appProxy uiSetCoverNumber:[HCover instance].selectedIndex+1];
		[appProxy uiSetCoverImage:track.cover];
	}
}

//
// HSettings notifications
//
#pragma mark *** HSettings notifications
#pragma mark -

- (void)tuneToLastStation
{
	self.locked = YES;
	
	XMark();
	[self _setTuneToStation:[HSettings lastStation]];
	[self stop];
	[self _renewSession];
		
	//
	// Fetch new playlist
	//
	FMPlaylist *newPlaylist = [[FMPlaylist alloc] initWithRadioSession:radioSession];
	self.playlist = newPlaylist;
	[newPlaylist release];
	
	[[playlist queue] fetchNew];
}

- (void)equalizerChanged:(NSNotification *)notify
{
	if(audioStream)
		[audioStream updateEq];
}

//
// Stream delegate methods
//
#pragma mark *** Stream delegate methods
#pragma mark -

- (void)streamPlaybackStarted:(ALStream *)aStream
{
	XMark();
	
	self.locked = NO;
	
	//
	// Begin fetching covers (if enabled)
	//
	if([HSettings coverDownloadEnabled])
		[[HCover instance] findLargestCoverForTrack:track];
	else
	{
		NSArray *covers = [NSArray arrayWithObjects:track.imageLocation, track.imageLocationLarge, nil];
		[[HCover instance] loadCoversWithURLs:covers];
	}
	
	[appProxy uiSetStatusMessage:nil];
	[delegate devicePlaybackStarted:self];
}

- (void)streamPlaybackPaused:(ALStream *)aStream
{
	XMark();
	[delegate devicePlaybackPaused:self];
}

- (void)streamPlaybackResumed:(ALStream *)aStream
{
	XMark();
	[delegate devicePlaybackResumed:self];
}

- (void)streamPlaybackAborted:(ALStream *)aStream
{
	XMark();
	
	[[HCover instance] cancelDownloads];
	
	if(!skipped)
	{
		[self _setAudioStream:nil];
		[delegate devicePlaybackStopped:self];
	}
	else
	{
		if(self.track = [playlist popTrack])
		{
			//
			// Setup new stream
			//
			ALStream *newStream = [[ALStream alloc] initWithDelegate:self URL:track.location];
			[self _setAudioStream:newStream];
			[newStream release];
			
			[audioStream play];
			[appProxy uiSetStatusMessage:@"connecting"];
		}
		else
		{
			//
			// Check if session needs renewal
			//
			[self _renewSession];
			
			//
			// Fetch new playlist
			//
			self.playlist = [[[FMPlaylist alloc] initWithRadioSession:radioSession] autorelease];
			[[playlist queue] fetchNew];
		}
	}
	
	skipped = NO;
}

- (void)streamPlaybackFinished:(ALStream *)aStream
{
	XMark();
		
	if(appProxy.stationType == ShuffleStation)
	{
		//
		// Tune to station
		//
		NSString *stationName = nil;
		
		do
		{
			stationName = [DRadio lastFmStationForType:appProxy.stationType
																				name:appProxy.stationTitle];
		} 
		while([stationName isEqualToString:previousStation]);
		
		XLog(@"Radio station: %@", stationName);
		[self _setPreviousStation:stationName];
		[self _setTuneToStation:stationName];
		
		//
		// Tune to station
		//
		self.station = nil;
		[self _renewSession];
		
		//
		// Fetch new playlist
		//
		[[playlist queue] fetchNew];		
	}
	else if(self.track = [playlist popTrack])
	{
		//
		// Setup new stream
		//
		ALStream *newStream = [[ALStream alloc] initWithDelegate:self URL:track.location];
		[self _setAudioStream:newStream];
		[newStream release];
		
		[audioStream play];
		[appProxy uiSetStatusMessage:@"connecting"];
	}
	else
	{
		//
		// Check if session needs renewal
		//
		[self _renewSession];
		
		//
		// Fetch new playlist
		//
		self.playlist = [[[FMPlaylist alloc] initWithRadioSession:radioSession] autorelease];
		[[playlist queue] fetchNew];
	}
	
	skipped = NO;
	//[delegate devicePlaybackStopped:self];
}



- (void)streamFinishedDownload:(ALStream *)aStream
{
	XMark();
	//
	// Export
	//
	NSString *playlistName = [HSettings exportPlaylistName];
	
	if(!playlistName)
		playlistName = station.stationName;
		
	[[Exporter instance] export:track
									 toPlaylist:playlistName
										audioData:aStream.mp3Data];
}

- (void)streamIsBuffering:(ALStream *)aStream
{
	XMark();
	[delegate deviceIsBuffering:self];
}

- (void)streamErrorOccurred:(ALStream *)stream
{
	XMark();
	self.locked = NO;
	
	self.lastErrorMessage = @"Streaming error";

	//
	// Notify device manager
	//
	[delegate deviceError:self];
}

//
// Protocol delegate methods
//
#pragma mark *** Protocol delegate methods
#pragma mark -

- (void)queueHandlerPlaylistReceived:(QHandler *)aHandler
{
	XLog([playlist description]);
	
	self.track = [playlist popTrack];
	
	if(track)
	{		
		ALStream *newStream = [[ALStream alloc] initWithDelegate:self URL:track.location];
		[self _setAudioStream:newStream];
		[newStream release];
		
		[newStream play];
		
		[appProxy uiSetStatusMessage:@"connecting"];
	}	
}

//
// Cover handler delegate methods
//

- (void)coverDownloaded:(NSImage *)aCover
{
	XMark();
	[appProxy uiSetCoverCount:[[HCover instance].covers count]];
}

- (void)currentLargestCover:(NSImage *)aCover
{
	XMark();
	[appProxy uiSetCoverImage:aCover];
	[appProxy uiSetCoverNumber:[HCover instance].largestIndex];
	
	track.cover = aCover;
}

- (void)allCoversLoaded:(HCover *)coverHandler
{
	// stub
}

@end


//
// Private stuff
//
@implementation DRadio (Private)

- (void)_setAudioStream:(ALStream *)aStream
{
	if(aStream != audioStream)
	{
		[audioStream stop]; // TODO: uncommented. check if issues arise
		[audioStream release];
		audioStream = [aStream retain];
		[audioStream setVolume:volume];
	}
}

- (void)_renewSession
{	
	if(radioSession == nil)
	{
		XLog(@"Renewing radio session...");
		//
		// Create radio session
		//
		self.radioSession = [[[FMRadioSession alloc] initWithUser:[HSettings lastFmUserName]
																												password:[HSettings lastFmPassword]]
														autorelease];
		[[radioSession queue] authenticate];
	}
	
	if(scrobbleSession == nil)
	{
		XLog(@"Renewing scrobble session...");
		//
		// Create new scrobble session
		//
		FMScrobbleSession *newSession =  [[FMScrobbleSession alloc] initWithUser:[HSettings lastFmUserName] 
																																		password:[HSettings lastFmPassword] 
																																		playerID:PlayerIDSweetFM];
		self.scrobbleSession = newSession;
		[newSession release];
		
		if(!scrobbleSession.authenticated)
			[[scrobbleSession queue] authenticate];
	}
	
	if(station == nil)
	{
		XLog(@"Renewing radio station...");
		//
		// Tune to station
		//
		self.station = [[[FMStation alloc] initWithRadioSession:radioSession] autorelease];
		
		NSString *stationName = nil;
		
		if(tuneToStation) {
			XLog(@"Tuning to predefined station");
			stationName = tuneToStation;
			[self _setTuneToStation:nil];
		}
		else
		{
			XLog(@"Tuning to requested station");
			stationName = [DRadio lastFmStationForType:appProxy.stationType
																						name:appProxy.stationTitle];
		}
		
		//
		// Write current URL to defaults as last used URL
		//
		[HSettings setLastStation:stationName];
		
		XLog(@"Radio station: %@", stationName);
		[(FMStation *)[station queue] tuneToStation:stationName];
	}
}

- (void)_setPreviousStation:(NSString *)aStation
{
	XMark();
	
	if(previousStation != aStation)
	{
		[previousStation release];
		previousStation = [aStation copy];
	}
}

- (void)_setTuneToStation:(NSString *)aStation
{
	XMark();
	
	if(tuneToStation != aStation)
	{
		[tuneToStation release];
		tuneToStation = [aStation copy];
	}
}

@end
