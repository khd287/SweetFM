//
//  ALStream.h
//  SweetFM
//
//  Created by Q on 05.05.09.
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

#include <OpenAL/al.h>
#include <OpenAL/alc.h>

#include <stdio.h>
#include "mpg123.h"


//
// C-Helpers
//
BOOL alUnqueueAll(ALuint source);
BOOL alCheck(const char *errMsg);
BOOL alcCheck(ALCdevice *device, const char *errMsg);

const char * alError(ALuint err);
const char * alcError(ALuint err);

//
// Class
//
@interface ALStream : NSObject {

	NSURL							*streamURL;
	CFReadStreamRef		stream;
	
	mpg123_handle			*mh;
	long							rate;
	int								channels;
	int								encoding;
	
	ALfloat						volume;
	
	ALuint						alSource;
	ALCdevice					*alDevice;
	ALCcontext				*alContext;
	
	id								delegate;
	
	BOOL							storePCM;
	
	NSLock						*bufLock;
		
	CFMutableDataRef	mpgData;
	CFMutableDataRef	pcmData;
	
	BOOL							started;
	BOOL							alStarted;
	BOOL							downloadFinished;
	BOOL							playbackFinished;
	BOOL							deviceClosed;
	BOOL							halt;
	
	BOOL							playing;
	BOOL							paused;
	BOOL							buffering;
	
	BOOL							failed;
	
	double						playbackPos;
}

@property (assign) BOOL storePCM;

- (id)initWithDelegate:(id)dlg URL:(NSURL *)aUrl;

- (NSMutableData *)RIFFHeaderFor16BitPCMAudio;

- (void)updateEq;

- (void)play;
- (void)pause;
- (void)stop;

@property (assign) double volume;

@property (readonly) BOOL isPlaying;
@property (readonly) BOOL isPaused;
@property (readonly) BOOL isBuffering;
@property (readonly) NSData *mp3Data;
@property (readonly) NSData *pcmData;
@property (readonly) double playbackPosition;

@end

//
// Informal protocol
//
@interface NSObject (ALStreamInformalProtocol)

- (void)streamPlaybackStarted:(ALStream *)aStream;
- (void)streamPlaybackPaused:(ALStream *)aStream;
- (void)streamPlaybackResumed:(ALStream *)aStream;
- (void)streamPlaybackAborted:(ALStream *)aStream;
- (void)streamPlaybackFinished:(ALStream *)aStream;

- (void)streamFinishedDownload:(ALStream *)aStream;

- (void)streamIsBuffering:(ALStream *)aStream;
- (void)streamErrorOccurred:(ALStream *)stream;

@end
