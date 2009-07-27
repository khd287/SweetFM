//
//  DTunes.m
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

#import "DTunes.h"

#import "FMScrobbleSession.h"
#import "HSettings.h"
#import "iTunesBridge.h"
#import "XLog.h"


@interface DTunes (Private)

- (void)_setCurrentTrack:(DeviceTrack *)aTrack;
- (DeviceTrack *)_currentTrack;

- (void)_updateCurrentTrack;

@end

@implementation DTunes

- (id)initWithDelegate:(id)dlg appProxy:(JSApp *)app
{
	if(self = [super initWithDelegate:dlg appProxy:app])
	{
		tunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
		
		NSNotificationCenter *sharedNotify = [[NSWorkspace sharedWorkspace] notificationCenter];
		NSDistributedNotificationCenter *distribNotify = [NSDistributedNotificationCenter defaultCenter];
		
		//
		// Register for distributed iTunes notifications
		//
		[sharedNotify addObserver:self
										 selector:@selector(iTunesLaunched:)
												 name:NSWorkspaceDidLaunchApplicationNotification 
											 object:nil];
		
		[sharedNotify addObserver:self
										 selector:@selector(iTunesTerminated:)
												 name:NSWorkspaceDidTerminateApplicationNotification 
											 object:nil];
		
		[distribNotify addObserver:self 
											selector:@selector(iTunesChanged:) 
													name:@"com.apple.iTunes.playerInfo"
												object:nil];
		
		tunesState = DeviceStopped;
		tunesHash = 0;
		volume = 100.0f;
		
		[self refresh];
		
		//
		// Init scrobble session
		//
		self.scrobbleSession = [[[FMScrobbleSession alloc] initWithUser:[HSettings lastFmUserName] 
																													 password:[HSettings lastFmPassword] 
																													 playerID:PlayerIDiTunes] autorelease];
		
		//
		// Init position timer
		//
		[[NSTimer scheduledTimerWithTimeInterval:1
																			target:self 
																		selector:@selector(updatePosition) 
																		userInfo:nil 
																		 repeats:YES] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[tunes release];
	[currentTrack release];
	[super dealloc];
}

- (void)refresh
{
	if([self isRunning])
	{
		int state = [tunes playerState];
		
		/*
		 typedef enum {
		 iTunesEPlSStopped = 'kPSS',
		 iTunesEPlSPlaying = 'kPSP',
		 iTunesEPlSPaused = 'kPSp',
		 iTunesEPlSFastForwarding = 'kPSF',
		 iTunesEPlSRewinding = 'kPSR'
		 } iTunesEPlS;
		 */
		
		switch(state)
		{
			case iTunesEPlSStopped: tunesState = DeviceStopped; break;
			case iTunesEPlSPlaying: 
			{
				tunesState = DevicePlaying; 
				
				@try
				{
					tunesPosition = (double)tunes.playerPosition;
					volume = (double)tunes.soundVolume;
				}
				@catch (NSException *e) {}
				
				break;
			}
			case iTunesEPlSPaused: 
			{
				@try
				{
					tunesState = DevicePaused; 
					volume = (double)tunes.soundVolume;
				}
				@catch (NSException *e) {}
				
				break;
			}
		}
		
		[self scrobbleSession];
		[self _updateCurrentTrack];
	}
	
	
	//
	// Send initialized message
	//
	if([delegate respondsToSelector:@selector(deviceInitialized:)])
		[delegate deviceInitialized:self];
}

- (void)updatePosition
{
	if(tunesState == DevicePlaying)
		tunesPosition++;
}

- (void)iTunesLaunched:(NSNotification *)notify
{
	XLog(@"App launched: %@", [[notify userInfo] objectForKey:@"NSApplicationName"]);
	
	[self refresh];
}

- (void)iTunesTerminated:(NSNotification *)notify
{
	XLog(@"App terminated: %@", [[notify userInfo] objectForKey:@"NSApplicationName"]);
	
	if([[[notify userInfo] objectForKey:@"NSApplicationName"] isEqualToString:@"iTunes"])
		tunesState = DeviceStopped;
}

- (void)iTunesChanged:(NSNotification *)notify
{
	XMark();
	
	DeviceState newState = DeviceStopped;
	NSUInteger newHash = self.track.hash;
	
	NSString *state = [[notify userInfo] objectForKey:@"Player State"];
	
	XLog(state);
	
	if([state isEqualToString:@"Stopped"])
	{
		newState = DeviceStopped;
		tunesPosition = 0;
		[self _setCurrentTrack:nil];
	}
	else if([state isEqualToString:@"Paused"])
	{
		newState = DevicePaused;
		[self _updateCurrentTrack];
	}
	else if([state isEqualToString:@"Playing"])
	{
		newState = DevicePlaying;
		
		@try { tunesPosition = (double)tunes.playerPosition; }
		@catch (NSException *e) {}
		
		[self _updateCurrentTrack];
	}
		
	if(!suspended)
	{
		if(tunesHash != newHash || tunesState==DeviceStopped)
		{
			if(newState==DevicePlaying)
			{
				if([delegate respondsToSelector:@selector(devicePlaybackStarted:)])
					[delegate devicePlaybackStarted:self];
			}
		}
		else
		{
			if(newState==DevicePaused)
			{
				if([delegate respondsToSelector:@selector(devicePlaybackPaused:)])
					[delegate devicePlaybackPaused:self];
			}
			else if(newState==DevicePlaying)
			{
				if([delegate respondsToSelector:@selector(devicePlaybackResumed:)])
					[delegate devicePlaybackResumed:self];
			}
		}
		
		if(newState==DeviceStopped)
		{
			if([delegate respondsToSelector:@selector(devicePlaybackStopped:)])
				[delegate devicePlaybackStopped:self];
		}
	}
	
	tunesHash = newHash;
	tunesState = newState;
}

- (DeviceTrack *)track
{
	if([self isRunning])
		return currentTrack;
	
	return nil;
}

- (void)setVolume:(double)vol;
{
	if([self isRunning])
	{
		volume = vol*100.0f;;
		tunes.soundVolume = vol*100.0f;
	}
}

- (double)volume
{
	if([self isRunning])
		return tunes.soundVolume / 100.0f;
	
	return 0;
}

- (void)setPosition:(double)pos
{
	if([self isRunning]) 
	{
		tunes.playerPosition = pos; 
		
		//
		// We need to use this separate variable because otherwise
		// iTunes will hang our app when it quits
		//
		tunesPosition = pos;
	}
}
	
- (double)position
{	
	// TODO: Hangs on iTunes quit
	if([tunes isRunning])
		@try { return tunesPosition; } @catch (NSException *e) {}
	
	return 0;
}

- (DeviceState)deviceState
{
	XMark();
	
	if([self isRunning])
		return tunesState;
	
	return DeviceStopped;
}

- (FMScrobbleSession *)scrobbleSession
{
	//
	// Auth scrobble session if necessary
	//
	[[scrobbleSession queue] authenticate];
	return scrobbleSession;
}

- (BOOL)isRunning
{
	return [tunes isRunning];
}

- (void)playPause
{
	if([self isRunning])
		[tunes playpause];
}

- (void)stop
{
	if([self isRunning])
		[tunes stop];
}

- (void)nextTrack
{
	if([self isRunning])
	{
		tunesState = DeviceStopped;
		[tunes nextTrack];
	}
}

- (void)previousTrack
{
	if([self isRunning])
		[tunes previousTrack];
}

@end


@implementation DTunes (Private)

- (void)_setCurrentTrack:(DeviceTrack *)aTrack
{
	if(currentTrack!=aTrack)
	{
		[currentTrack release];
		currentTrack = [aTrack retain];
	}
}

- (DeviceTrack *)_currentTrack
{
	return currentTrack;
}

- (void)_updateCurrentTrack
{
	iTunesTrack *track = [tunes currentTrack];
	
	if(track)
	{
		//XMark();
		
		//
		// Create new DeviceTrack
		//
		
		DeviceTrack *devTrack = nil;
		
		@try
		{
			devTrack = [[DeviceTrack alloc] initWithName:track.name
																						artist:track.artist
																						 album:track.album
																						length:track.duration];
		}
		@catch (NSException *e) {
			return;
		}
		
		[self _setCurrentTrack:devTrack];
		[devTrack release];
		
		//
		// Check if cover is available
		//
		NSImage *trackCover = nil;
		@try 
		{
			XLog(@"Retrieving iTunes cover");
			trackCover = [(iTunesArtwork *)[[track artworks] objectAtIndex:0] data];
		}
		@catch (NSException *e) 
		{
			XLog(@"No Cover");
		}
		@finally 
		{
			currentTrack.cover = trackCover;
		}
		
		//
		// Set track rating
		//
		currentTrack.rating = [track rating];
	}
}

@end













