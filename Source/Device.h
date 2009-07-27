//
//  Device.h
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

#import <Cocoa/Cocoa.h>


@class DeviceTrack;
@class JSApp;
@class FMScrobbleSession;

typedef enum {
	DeviceStopped = 0,
	DevicePlaying,
	DevicePaused,
	DeviceBuffering,
	DeviceError
} DeviceState;

@interface Device : NSObject {

	id delegate;
	JSApp *appProxy;
	
	BOOL suspended;
	BOOL locked;
	
	FMScrobbleSession *scrobbleSession;
	double volume;
	
	NSString *lastErrorMessage;
}

- (id)initWithDelegate:(id)dlg appProxy:(JSApp *)app;

@property (retain) DeviceTrack *track;
@property (assign) double volume;
@property (assign) double position;
@property (assign) BOOL suspended;
@property (assign) BOOL locked;

@property (readonly) DeviceState deviceState;
@property (retain) FMScrobbleSession *scrobbleSession;

@property (readonly) BOOL isRunning;
@property (copy) NSString *lastErrorMessage;

- (void)refresh;
- (void)reset;

- (void)playPause;
- (void)stop;
- (void)nextTrack;
- (void)previousTrack;

@end

//
// Informal protocol
//
@interface NSObject (DeviceInformalProtocol)

- (void)deviceInitialized:(Device *)dev;
- (void)deviceUpdated:(Device *)dev;

- (void)devicePlaybackStarted:(Device *)dev;
- (void)devicePlaybackResumed:(Device *)dev;
- (void)devicePlaybackPaused:(Device *)dev;
- (void)devicePlaybackStopped:(Device *)dev;

- (void)deviceIsBuffering:(Device *)dev;
- (void)deviceResumedFromBuffering:(Device *)dev;

- (void)deviceError:(Device *)dev;

@end

@interface DeviceTrack : NSObject
{
	NSString *name;
	NSString *artist;
	NSString *album;
	NSImage *cover;
	double length;
	NSUInteger rating;
	
	BOOL scrobbled;
	BOOL nowPlayingSent;
	
	BOOL loved;
	BOOL banned;
	BOOL addedToPlaylist;
}

- (id)initWithName:(NSString *)aName artist:(NSString *)aArtist album:(NSString *)aAlbum length:(double)aLength;

@property (readonly, copy) NSString *name;
@property (readonly, copy) NSString *artist;
@property (readonly, copy) NSString *album;
@property (readonly) double length;
@property (readonly) NSUInteger hash;

@property (retain) NSImage *cover;
@property (assign) NSUInteger rating; /* 1-100 */

@property (assign) BOOL scrobbled;
@property (assign) BOOL nowPlayingSent;

@property (assign) BOOL loved;
@property (assign) BOOL banned;
@property (assign) BOOL addedToPlaylist;

- (NSString *)nameAndArtist;

@end
