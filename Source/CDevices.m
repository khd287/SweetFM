//
//  CDevices.m
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

#import "CDevices.h"

#import "CApp.h"
#import "JSApp.h"
#import "Device.h"
#import "DTunes.h"
#import "DRadio.h"

#import "FMTrack.h"
#import "FMPlaylist.h"
#import "FMScrobbleSession.h"

#import "HRemote.h"
#import "HGrowl.h"
#import "HSettings.h"
#import "HMediaKeys.h"
#import "HSkype.h"

#import "QHandler.h"
#import "iTunesLinkBuilder.h"

#import "XLog.h"
#import "SysAudio.h"


@implementation CDevices

- (id)initWithAppProxy:(JSApp *)aProxy
{
	if(self = [super init])
	{
		proxy = [aProxy retain];
		
		tunesDevice = [[DTunes alloc] initWithDelegate:self appProxy:proxy];
		radioDevice = [[DRadio alloc] initWithDelegate:self appProxy:proxy];
		
		[self changeActiveDeviceTo:tunesDevice];
		
		NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
		
		//
		// Register for CApp notifications
		//
		[notify addObserver:self selector:@selector(stopAndSuspendAll)
									 name:AppDemoWillQuitNotification object:nil];
		
		//
		// Register for JSApp notifications
		//
		[notify addObserver:self selector:@selector(scrobbleSettingChanged:) 
									 name:JSAppScrobbleToggleNotification object:nil];
		[notify addObserver:self selector:@selector(playPauseTrack:)
									 name:JSAppPlayPauseNotification object:nil];
		[notify addObserver:self selector:@selector(stopTrack:)
									 name:JSAppStopNotification object:nil];
		[notify addObserver:self selector:@selector(nextTrack:) 
									 name:JSAppNextNotification object:nil];
		[notify addObserver:self selector:@selector(loveTrack:)
									 name:JSAppLoveNotification object:nil];
		[notify addObserver:self selector:@selector(banTrack:) 
									 name:JSAppBanNotification object:nil];
		[notify addObserver:self selector:@selector(addTrackToPlaylist:) 
									 name:JSAppAddToPlaylistNotification object:nil];
		[notify addObserver:self selector:@selector(tuneToStation:)
									 name:JSAppTuneToStationNotification object:nil];
		[notify addObserver:self selector:@selector(volumeChanged:) 
									 name:JSAppSetVolumeNotification object:nil];
		[notify addObserver:self selector:@selector(positionChanged:)
									 name:JSAppSetPositionNotification object:nil];
		
		[notify addObserver:self selector:@selector(openBuyPage:) 
									 name:JSAppOpenBuyPageNotification object:nil];
		[notify addObserver:self selector:@selector(openTrackPage:) 
									 name:JSAppOpenTrackPageNotification object:nil];
		[notify addObserver:self selector:@selector(openArtistPage:) 
									 name:JSAppOpenArtistPageNotification object:nil];
		[notify addObserver:self selector:@selector(openAlbumPage:) 
									 name:JSAppOpenAlbumPageNotification object:nil];
		
		//
		// Register for remote control notifications
		//
		[notify addObserver:self selector:@selector(playPauseTrack:) 
									 name:HRemotePlayPausePressedNotification object:nil];
		[notify addObserver:self selector:@selector(nextTrack:)
									 name:HRemoteNextPressedNotification object:nil];
		[notify addObserver:activeDevice selector:@selector(previousTrack)
									 name:HRemotePreviousPressedNotification object:nil];
		[notify addObserver:self selector:@selector(increaseCurrentDeviceVolume)
									 name:HRemoteVolumeUpPressedNotification object:nil];
		[notify addObserver:self selector:@selector(decreaseCurrentDeviceVolume)
									 name:HRemoteVolumeDownPressedNotification object:nil];
		
		//
		// Register for media key notifications
		//
		[HMediaKeys install];
		
		[notify addObserver:self selector:@selector(playPauseTrack:) 
									 name:MediaKeyPlayPauseUpNotification object:nil];
		[notify addObserver:self selector:@selector(nextTrack:) 
									 name:MediaKeyNextUpNotification object:nil];
		[notify addObserver:activeDevice selector:@selector(previousTrack)
									 name:MediaKeyPreviousUpNotification object:nil];
		
		//
		// Status update timer
		//
		statusTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
																									 target:self 
																								 selector:@selector(updateDeviceStatus:)
																									userInfo:nil repeats:YES] retain];
		
		//
		// Register for HSettings notifications
		//
		[notify addObserver:self selector:@selector(tuneToLastStation:) 
									 name:TuneToLastStationNotification object:nil];

		//
		// Register for protocol notifications
		//
		[notify addObserver:self selector:@selector(criticalError:) 
									 name:QHandlerProtocolErrorNotification object:nil];
		[notify addObserver:self selector:@selector(minorError:) 
									 name:QHandlerMinorProtocolErrorNotification object:nil];
		//
		// Refresh scrobble sessions every 15 minutes
		//
		[[NSTimer scheduledTimerWithTimeInterval:15*60 
																			target:self 
																		selector:@selector(refreshScrobbleSessions)
																		userInfo:nil repeats:YES] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[statusTimer invalidate];
	[statusTimer release];
	[proxy release];
	[super dealloc];
}

- (void)refreshScrobbleSessions
{
	[[[activeDevice scrobbleSession] queue] authenticate];
}

- (void)stopAndSuspendAll
{
	[activeDevice stop];
	activeDevice = nil;
	
	[tunesDevice setSuspended:YES];
	[radioDevice setSuspended:YES];
}

- (void)updateDeviceStatus:(NSTimer *)updater
{
	//XMark();
	
	if((NSUInteger)activeDevice.position)
		[proxy uiSetPosition:(NSUInteger)activeDevice.position];
	
	if(activeDevice == tunesDevice)
		[proxy uiSetVolume:activeDevice.volume];
	else
		[proxy uiSetVolume:[HSettings radioVolume]];
	
	if(activeDevice.track.length > 0)
	{
		double progress = 100.0f*((double)activeDevice.position/(double)activeDevice.track.length);
		//XLog(@"Progress %f", progress);
		
		if(NSLocationInRange(progress, NSMakeRange(5, 1)) && 
			 !activeDevice.track.nowPlayingSent &&
			 [HSettings scrobbleEnabled])
		{
			XLog(@"Sending now playing...");
			FMScrobbleSession *session = [activeDevice scrobbleSession];
			[[session queue] nowPlaying:activeDevice.track];
		}
		
		if(NSLocationInRange(progress, NSMakeRange([HSettings scrobblePercentage]-5, 1)) &&
			 !activeDevice.track.scrobbled &&
			 [HSettings scrobbleEnabled])
		{
			XLog(@"Srobbling...");
			FMScrobbleSession *session = [activeDevice scrobbleSession];
			[[session queue] scrobble:activeDevice.track 
								 withRatingFlag:(activeDevice.track.loved ? RatingFlagLove : nil)];
		}
	}
}

- (void)changeActiveDeviceTo:(Device *)aDevice
{
	XMark();
	if(activeDevice==aDevice)
		return;
	
	[activeDevice stop];
	[activeDevice setSuspended:YES];
	
	activeDevice = aDevice;
	[activeDevice setSuspended:NO];
		
	[activeDevice refresh];
}

- (void)refreshInterface
{
	[activeDevice refresh];
}

- (void)increaseCurrentDeviceVolume
{
	XMark();
	if(activeDevice.volume < 1.0f)
		activeDevice.volume += 0.1f;
	else
		SysAudioIncreaseVolume();		
}

- (void)decreaseCurrentDeviceVolume
{
	XMark();
	if(activeDevice.volume > 0.0f)
		activeDevice.volume -= 0.1f;
	else
		SysAudioDecreaseVolume();
}

//
// Protocol notifications
//
#pragma mark *** Protocol notifications
#pragma mark -

- (void)criticalError:(NSNotification *)notify
{
	activeDevice.lastErrorMessage = [QHandler instance].lastErrorMessage;
	
	NSLog(@"Critical protocol error: %@", activeDevice.lastErrorMessage);
	[self deviceError:activeDevice];
}

- (void)minorError:(NSNotification *)notify
{
	NSString *errMsg = [QHandler instance].lastErrorMessage;
	
	NSLog(@"Minor protocol error: %@", errMsg);
	[proxy uiSetErrorMessage:errMsg];
}

//
// Device informal protocol
//
#pragma mark *** Device informal protocol
#pragma mark -

- (void)deviceInitialized:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	DeviceTrack *track = dev.track;
	
	if(track)
		XLog([track description]);
	else
		XMark();
	
	[proxy uiSetCoverImage:track.cover];
	[proxy uiSetTrackName:track.name];
	[proxy uiSetTrackAlbum:track.album];
	[proxy uiSetTrackArtist:track.artist];
	[proxy uiSetDuration:track.length];
	[proxy uiSetPosition:0];
	[proxy uiSetCoverNumber:0];
	[proxy uiSetCoverCount:0];
}

- (void)deviceUpdated:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	XMark();
	DeviceTrack *track = dev.track;
	[proxy uiSetCoverImage:track.cover];
	[proxy uiSetTrackName:track.name];
	[proxy uiSetTrackAlbum:track.album];
	[proxy uiSetTrackArtist:track.artist];
}

- (void)devicePlaybackStarted:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	XMark();
	DeviceTrack *track = dev.track;
	[proxy uiSetCoverImage:track.cover];
	[proxy uiSetTrackName:track.name];
	[proxy uiSetTrackAlbum:track.album];
	[proxy uiSetTrackArtist:track.artist];
	[proxy uiSetDuration:track.length];
	[proxy uiSetPosition:0];
	
	if(track.name && track.artist)
	{
		NSString *msg = [NSString stringWithFormat:@"%@ - %@", track.name, track.artist];
		[[HSkype instance] setSkypeStatus:msg];
	}
	else if(track.name)
	{
		[[HSkype instance] setSkypeStatus:track.name];
	}
	
	[[HGrowl instance] postNotificationWithName:GrowlTrackPlaying
																				title:track.name 
																	description:track.artist
																				image:track.cover];
}

- (void)devicePlaybackStopped:(Device *)dev
{	
	XMark();
	[proxy uiSetCoverImage:nil];
	[proxy uiSetTrackName:nil];
	[proxy uiSetTrackAlbum:nil];
	[proxy uiSetTrackArtist:nil];
	[proxy uiSetPosition:0];
	[proxy uiSetDuration:0];
	[proxy uiSetStationTitle:nil selectFrom:0 to:0]; 
	[proxy uiSetStatusMessage:nil];
	
	
	[[HGrowl instance] postNotificationWithName:GrowlTrackStopped
																				title:@"Stopped"
																	description:nil
																				image:nil];
	if([dev isEqualTo:radioDevice])
	{
		if(tuneToOtherStation)
		{
			tuneToOtherStation = NO;
			[radioDevice playPause];
		}
		else
		{
			[self changeActiveDeviceTo:tunesDevice];
			[self deviceUpdated:tunesDevice];
		}
	}
}

- (void)devicePlaybackPaused:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	XMark();
	[[HGrowl instance] postNotificationWithName:GrowlTrackPaused
																				title:@"Paused" 
																	description:[NSString stringWithFormat:@"%@\n%@", dev.track.name, dev.track.artist]
																				image:dev.track.cover];
}

- (void)devicePlaybackResumed:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	XMark();
	[[HGrowl instance] postNotificationWithName:GrowlTrackResumed
																				title:@"Resumed" 
																	description:[NSString stringWithFormat:@"%@\n%@", dev.track.name, dev.track.artist]
																				image:dev.track.cover];
}

- (void)deviceIsBuffering:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	XMark();
	[[HGrowl instance] postNotificationWithName:GrowlTrackBuffering
																				title:@"Buffering" 
																	description:[NSString stringWithFormat:@"%@\n%@", dev.track.name, dev.track.artist]
																				image:dev.track.cover];
}

- (void)deviceResumedFromBuffering:(Device *)dev
{
	if(dev!=activeDevice)
		return;
	
	XMark();
	[[HGrowl instance] postNotificationWithName:GrowlTrackResumed
																				title:@"Resumed from buffering" 
																	description:[NSString stringWithFormat:@"%@\n%@", dev.track.name, dev.track.artist]
																				image:dev.track.cover];
}

- (void)deviceError:(Device *)theDevice
{
	if(theDevice != activeDevice)
		return;

	//[proxy uiSetDuration:0];
	//[proxy uiSetPosition:0];
	[proxy uiSetErrorMessage:theDevice.lastErrorMessage];
	[proxy uiSetStationTitle:nil selectFrom:0 to:0]; 
	[proxy uiSetStatusMessage:nil];
	[proxy uiSetTrackName:@"An error occurred"];
	[proxy uiSetTrackArtist:nil];
	[proxy uiSetTrackAlbum:nil];
	
	XMark();
	[[HGrowl instance] postNotificationWithName:GrowlError
																				title:@"Error occurred" 
																	description:theDevice.lastErrorMessage
																				image:nil];
	
	[theDevice reset];
}

//
// HSettings notifications
//
#pragma mark *** HSettings notifications
#pragma mark -

- (void)tuneToLastStation:(NSNotification *)notify
{
	XMark();
	//
	// Reset station and playlist
	//	
	tuneToOtherStation = YES;
	[self changeActiveDeviceTo:radioDevice];
	
	[radioDevice tuneToLastStation];
}

//
// JSApp proxy notifications
//
#pragma mark *** JSApp proxy notifications
#pragma mark -

- (void)scrobbleSettingChanged:(NSNotification *)notify
{
	XMark();
	[HSettings setScrobbleEnabled:[proxy scrobble]];
}

- (void)playPauseTrack:(NSNotification *)notify
{
	XMark();
	[activeDevice playPause];
}

- (void)stopTrack:(NSNotification *)notify
{
	XMark();
	
	tuneToOtherStation = NO;
	[activeDevice stop];
	
	/*
	if(activeDevice == radioDevice)
		[self changeActiveDeviceTo:tunesDevice];
	 */
}

- (void)nextTrack:(NSNotification *)notify
{
	XMark();
	
	if(activeDevice.isRunning && activeDevice.track)
	{
		// TODO: Throws an error with iTunes. check!
		FMScrobbleSession *session = [activeDevice scrobbleSession];
		[[session queue] scrobble:activeDevice.track withRatingFlag:RatingFlagSkip];
		
		[activeDevice nextTrack];
	}	
}

- (void)loveTrack:(NSNotification *)notify
{
	if(activeDevice.isRunning && !activeDevice.track.loved && !activeDevice.track.banned)
	{
		//
		// Set rating to 5 star
		//
		activeDevice.track.rating = 100;
		
		FMScrobbleSession *session = [activeDevice scrobbleSession];
		[[session queue] love:activeDevice.track];
		
		[[HGrowl instance] postNotificationWithName:GrowlTrackLoved
																					title:@"Track loved" 
																		description:[NSString stringWithFormat:@"%@\n%@", 
																								 activeDevice.track.name, 
																								 activeDevice.track.artist]
																					image:activeDevice.track.cover];
	}
}

- (void)banTrack:(NSNotification *)notify
{
	if(activeDevice.isRunning && !activeDevice.track.banned && !activeDevice.track.loved)
	{
		FMScrobbleSession *session = [activeDevice scrobbleSession];
				
		[[HGrowl instance] postNotificationWithName:GrowlTrackBanned
																					title:@"Track banned" 
																		description:[NSString stringWithFormat:@"%@\n%@", 
																								 activeDevice.track.name, 
																								 activeDevice.track.artist]
																					image:activeDevice.track.cover];
		
		[[session queue] ban:activeDevice.track];
		[[session queue] scrobble:activeDevice.track withRatingFlag:RatingFlagBan];
		
		[activeDevice nextTrack];
	}
}

- (void)addTrackToPlaylist:(NSNotification *)notify
{
	if(activeDevice.isRunning && !activeDevice.track.addedToPlaylist)
	{
		FMScrobbleSession *session = [activeDevice scrobbleSession];
		[[session queue] addToPlaylist:activeDevice.track];
		
		[[HGrowl instance] postNotificationWithName:GrowlTrackAddToPlaylist
																					title:@"Track added to playlist"
																		description:[NSString stringWithFormat:@"%@\n%@", 
																								 activeDevice.track.name, 
																								 activeDevice.track.artist]
																					image:activeDevice.track.cover];
	}
}

- (void)tuneToStation:(NSNotification *)notify
{
	XMark();
	
	//
	// Reset station and playlist
	//	
	[self changeActiveDeviceTo:radioDevice];
	
	if(activeDevice.isRunning)
	{
		tuneToOtherStation = YES;
		[activeDevice reset];
	}
	else
	{
		[activeDevice reset];
		[activeDevice playPause];
	}
}

- (void)volumeChanged:(NSNotification *)notify
{
	XMark();
	activeDevice.volume = proxy.volume;
}

- (void)positionChanged:(NSNotification *)notify
{
	XMark();
	activeDevice.position = proxy.position;
}

- (void)openBuyPage:(NSNotification *)notify
{
	/*
	if([activeDevice.track isKindOfClass:[FMTrack class]])
	{
		NSURL *buyURL = [(FMTrack *)activeDevice.track buyTrackURL];
		XLog(@"Buy link: %@", [buyURL absoluteString]);
		[[NSWorkspace sharedWorkspace] openURL:buyURL];
	}
	*/
	
	if(activeDevice.track)
	{
		XMark();
		iTunesLinkBuilder *link = [[iTunesLinkBuilder alloc] initWithTDAffilateID:@"1657504"];
		NSString *theAlbum = activeDevice.track.album;
		NSString *theArtist = activeDevice.track.artist;
		
		NSURL *tunesLink = [link linkForAlbum:theAlbum artist:theArtist];
		[link release];
		
		if(tunesLink)
		{
			XLog(@"Tunes link: %@", [[tunesLink absoluteString] 
															 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);
			[[NSWorkspace sharedWorkspace] openURL:tunesLink];
		}
		else
		{
			[proxy uiSetErrorMessage:@"Album not found on iTunes"];
		}
	}
}

- (void)openTrackPage:(NSNotification *)notify
{
	XMark();
	if([activeDevice.track isKindOfClass:[FMTrack class]])
		[[NSWorkspace sharedWorkspace] openURL:[(FMTrack *)activeDevice.track trackPage]];
}

- (void)openArtistPage:(NSNotification *)notify
{
	XMark();
	if([activeDevice.track isKindOfClass:[FMTrack class]])
		[[NSWorkspace sharedWorkspace] openURL:[(FMTrack *)activeDevice.track artistPage]];
}

- (void)openAlbumPage:(NSNotification *)notify
{
	XMark();
	if([activeDevice.track isKindOfClass:[FMTrack class]])
		[[NSWorkspace sharedWorkspace] openURL:[(FMTrack *)activeDevice.track albumPage]];
}

//
// Device control menu
//
#pragma mark *** Device control menu
#pragma mark -

- (NSMenu *)deviceControlMenu
{
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *item = nil;
	
	NSString *indent = @"   ";
	
	//
	// Build now playing head
	//
	if(activeDevice.deviceState == DevicePlaying ||
		 activeDevice.deviceState == DevicePaused)
	{
		DeviceTrack *track = activeDevice.track;
		
		[menu addItemWithTitle:@"Now Playing" action:nil keyEquivalent:@""];
		
		//
		// Add track line (name + artist)
		//		
		item = [[NSMenuItem alloc] initWithTitle:[indent stringByAppendingString:[track nameAndArtist]]
																			action:nil
															 keyEquivalent:@""];
		[menu addItem:item];
		[item release];
		
		//
		// Add album line
		//
		if([track.album length] > 3)
		{
			item = [[NSMenuItem alloc] initWithTitle:[indent stringByAppendingString:track.album]
																				action:nil
																 keyEquivalent:@""];
			[menu addItem:item];
			[item release];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	if(activeDevice == radioDevice)
	{
		//
		// Build playlist part
		//
		NSArray *tracks = radioDevice.playlist.tracks;
		
		if(activeDevice == radioDevice && [tracks count])
		{
			[menu addItemWithTitle:@"Next Up" action:nil keyEquivalent:@""];
			
			for(DeviceTrack *track in tracks)
			{
				item = [[NSMenuItem alloc] initWithTitle:[indent stringByAppendingString:[track nameAndArtist]]
																					action:nil
																	 keyEquivalent:@""];
				[menu addItem:item];
				[item release];
			}
			
			[menu addItem:[NSMenuItem separatorItem]];
		}
	}
	
	//
	// Build control part
	//
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
												@"playPauseTrack:", @"Play/Pause",
												@"nextTrack:", @"Skip",
												@"stopTrack:", @"Stop",
												nil];
	
	for(NSString *title in dict)
	{
		item = [[NSMenuItem alloc] initWithTitle:title
																			action:NSSelectorFromString([dict objectForKey:title]) 
															 keyEquivalent:@""];
		[item setTarget:self];
		[menu addItem:item];
		[item release];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	//
	// Build scrobble commands part
	//
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
					@"loveTrack:", @"Love",
					@"addTrackToPlaylist:", @"Add to Playlist",
					@"banTrack:", @"Ban",
					nil];
	
	for(NSString *title in dict)
	{
		item = [[NSMenuItem alloc] initWithTitle:title
																			action:NSSelectorFromString([dict objectForKey:title]) 
															 keyEquivalent:@""];
		[item setTarget:self];
		[menu addItem:item];
		[item release];
	}	
	
	return menu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	XMark();
	return activeDevice.isRunning;
}

@end
