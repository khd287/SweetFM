//
//  SKPlayer.h
//  StreamKit
//
//  Created by Q on 02.07.09.
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

#import <OpenAL/al.h>
#import <OpenAL/alc.h>

#import "SKConnection.h"
#import "SKBuffer.h"


typedef enum SKPlayerState {
	SKPlayerNotInitialized = 0,
	SKPlayerWaitingForData,
	SKPlayerConnectionFailed,
	SKPlayerPlaybackFailed,
	SKPlayerPlaybackFinished,
	SKPlayerStopped,
	SKPlayerPlaying,
	SKPlayerPaused
} SKPlayerState;

//
// C-Helpers
//
ALint alSourceGetState(ALuint alSource);
void alSourceCheckState(ALuint alSource, ALfloat *pos);
void alFillBuffer(CFMutableDataRef data, 
									UInt8 *buf, uint bufSize, uint *bytesFilled, NSLock *lock);
BOOL alUnqueueAll(ALuint source);
BOOL alCheck(const char *errMsg);
BOOL alcCheck(ALCdevice *device, const char *errMsg);

const char * alError(ALuint err);
const char * alcError(ALuint err);
const char * alPlayState(ALuint st);

//
// Class
//
@interface SKPlayer : NSObject {

	SKConnection		*connection;	
	SKPlayerState		state;
	double					volume;
	NSUInteger			audioBufSize;
	
	NSMutableData		*pcmBuffer;
	NSLock					*bufferLock;
	
	ALuint					alSource;
	ALCdevice				*alcDevice;
	ALCcontext			*alcContext;
	
	ALfloat					playerPos;
		
	BOOL						downloadComplete;
	BOOL						run;
	
	id							delegate;
}

@property (assign) id delegate;

- (id)initWithURL:(NSURL *)theURL synthesizer:(id<SKSynth>)theSynth;
- (id)initWithURL:(NSURL *)theURL synthesizer:(id<SKSynth>)theSynth 
					 buffer:(SKBuffer *)buf;

- (void)playPause;
- (void)play;
- (void)pause;
- (void)stop;
- (void)setVolume:(double)vol;
- (double)volume;
- (double)position;

- (SKPlayerState)state;

@end

//
// Informal protocol
//
@interface NSObject (SKPlayerInformalProtocol)

- (void)streamPlaybackStarted:(SKPlayer *)aPlayer;
- (void)streamPlaybackPaused:(SKPlayer *)aPlayer;
- (void)streamPlaybackResumed:(SKPlayer *)aPlayer;
- (void)streamPlaybackAborted:(SKPlayer *)aPlayer;
- (void)streamPlaybackFinished:(SKPlayer *)aPlayer;

- (void)streamFinishedDownload:(SKPlayer *)aPlayer;

- (void)streamIsBuffering:(SKPlayer *)aPlayer;
- (void)streamErrorOccurred:(SKPlayer *)aPlayer;

@end
