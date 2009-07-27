//
//  SKPlayer.m
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

#import "SKPlayer.h"


@implementation SKPlayer

@synthesize delegate;

- (id)initWithURL:(NSURL *)theURL synthesizer:(id<SKSynth>)theSynth
{
	return [self initWithURL:theURL synthesizer:theSynth buffer:nil];
}

- (id)initWithURL:(NSURL *)theURL synthesizer:(id<SKSynth>)theSynth 
					 buffer:(SKBuffer *)buf
{
	if(self = [super init])
	{
		connection = [[SKConnection alloc] initWithURL:theURL
																		PCMSynthesizer:theSynth];
		
		if(buf)
			connection.buffer = buf;
		
		connection.delegate = self;
		state = SKPlayerNotInitialized;
		pcmBuffer = [[NSMutableData alloc] init];
		bufferLock = [NSLock new];
		audioBufSize = 1024*200;
	}
	
	return self;
}

- (void)dealloc
{
	[bufferLock release];
	[pcmBuffer release];
	[connection release];	
	[super dealloc];
}

- (void)playPause
{
}

- (void)play
{
	if(state == SKPlayerNotInitialized)
	{
		state = SKPlayerWaitingForData;
		[connection open];
	}	
}

- (void)pause
{
}

- (void)stop
{
	run = NO;
}

- (void)setVolume:(double)vol
{
	volume = vol<0 ? 0 : (vol > 1 ? 1: vol);
}

- (double)volume
{
	return volume;
}

- (double)position
{	
	return playerPos;
}

- (SKPlayerState)state
{
	return state;
}

#pragma mark SKConnection delegate methods

- (void)streamConnectionOpened:(SKConnection *)theConnection
{
	[NSThread detachNewThreadSelector:@selector(audioLoop)
													 toTarget:self
												 withObject:nil];
}

- (void)streamConnection:(SKConnection *)theConnection 
	didSynthesizeAudioData:(NSData *)pcmData
{
	[bufferLock lock];
	[pcmBuffer appendData:pcmData]; 
	[bufferLock unlock];
	
	NSLog(@"synthesized %i bytes", [pcmData length]);
}

- (void)streamConnectionDidFinishLoading:(SKConnection *)theConnection
{
	downloadComplete = YES;
	
	// Inform delegate
	if([delegate respondsToSelector:@selector(streamFinishedDownload:)])
		[delegate performSelectorOnMainThread:@selector(streamFinishedDownload:)
															 withObject:self waitUntilDone:NO];
	
	NSLog(@"finished");
}

- (void)streamConnection:(SKConnection *)theConnection
				didFailWithError:(NSError *)theError
{
	state = SKPlayerConnectionFailed;
	if([delegate respondsToSelector:@selector(streamErrorOccurred:)])
		[delegate performSelectorOnMainThread:@selector(streamErrorOccurred:)
															 withObject:self waitUntilDone:NO];
	
	NSLog(@"failed");
}

#pragma mark Audio loop

- (void)audioLoop
{
	NSAutoreleasePool *arp = [NSAutoreleasePool new];
	
	// Clear errors
	alGetError();
	BOOL err;
	
	// Open the device
	alcDevice = alcOpenDevice(NULL);
	if(!alcDevice)
		err = alcCheck(alcDevice, "could not open device");
		
	// Create context
	alcContext = alcCreateContext(alcDevice, NULL);
	if(!err && !alcContext)
		err = alcCheck(alcDevice, "could not create context");
			
	// Set current context
	if(!err && !alcMakeContextCurrent(alcContext))
		err = alcCheck(alcDevice, "could not set context");
		
	// Generate buffers. Buffer size should be multiple of 4.
	int alBufNum = 6;
	int alBufSize = 1024*100;
	
	ALuint alBuffers[alBufNum];
	ALuint alFrequency = [connection.synthesizer rate];
	ALenum alFormat = [connection.synthesizer format];
	
	alGenBuffers(alBufNum, alBuffers);
	if(!err)
		err = alCheck("could not generate buffers");
		
	alGenSources(1, &alSource);
	if(!err)
		err = alCheck("could not create source");
		
	// Init state vars
	run = YES;
	uint numPrimed = 0;
	
	// Init temporary buffer
	UInt8 inBuf[alBufSize];
	uint bytesFilled;
	
	while(run && !err)
	{
		[NSThread sleepForTimeInterval:0.25];
				
		// Check if buffers are filled
		if([pcmBuffer length] == 0)
			continue;
		
		// Prime buffers if necessary
		if(numPrimed < alBufNum)
		{
			alFillBuffer((CFMutableDataRef)pcmBuffer, inBuf, 
									 alBufSize, &bytesFilled, bufferLock);
			alBufferData(alBuffers[numPrimed], alFormat, inBuf, bytesFilled, alFrequency);
			
			if(!err)
				err = alCheck("could not prime buffers");
			
			numPrimed++;
			continue;
		}
		else if(numPrimed == alBufNum)
		{				
			alSourceQueueBuffers(alSource, alBufNum, alBuffers);
			alSourcePlay(alSource);
			state = SKPlayerPlaying;
			
			if(!err)
				err = alCheck("could not start playback");
			
			// Inform delegate
			if([delegate respondsToSelector:@selector(streamPlaybackStarted:)])
				[delegate performSelectorOnMainThread:@selector(streamPlaybackStarted:)
																	 withObject:self waitUntilDone:NO];
			
			numPrimed++;
			continue;
		}
		
		// Check source state
		alSourceCheckState(alSource, &playerPos);
				
		// Check for processed buffers
		ALint bufProcessed;
		alGetSourcei(alSource, AL_BUFFERS_PROCESSED, &bufProcessed);
		
		while(bufProcessed--)
		{
			alFillBuffer((CFMutableDataRef)pcmBuffer, inBuf, alBufSize, &bytesFilled, bufferLock);
						
			if(bytesFilled > 0)
			{
				// Unqueue old buffer
				ALuint reqBuffer;
				alSourceUnqueueBuffers(alSource, 1, &reqBuffer);
				
				// Fill with new pcm data and requeue
				alBufferData(reqBuffer, alFormat, &inBuf, bytesFilled, alFrequency);
				alSourceQueueBuffers(alSource, 1, &reqBuffer);
				
				if(!err)
					err = alCheck("could not requeue buffer");
			}
		}
		
		// Buffer or not?
		if(alSourceGetState(alSource) == AL_PLAYING &&
			 [pcmBuffer length] < alBufSize)
		{
			alSourcePause(alSource);
			state = SKPlayerWaitingForData;
			
			if([delegate respondsToSelector:@selector(streamIsBuffering:)])
				[delegate performSelectorOnMainThread:@selector(streamIsBuffering:)
																	 withObject:self waitUntilDone:NO];
		}
		else if(alSourceGetState(alSource) == AL_PAUSED &&
						[pcmBuffer length] >= alBufSize+audioBufSize)
		{
			alSourcePlay(alSource);
			state = SKPlayerPlaying;
			
			if([delegate respondsToSelector:@selector(streamPlaybackResumed:)])
				[delegate performSelectorOnMainThread:@selector(streamPlaybackResumed:)
																	 withObject:self waitUntilDone:NO];
		}
	}
	
	// Check for errors and notify delegate
	if(err)
	{
		state = SKPlayerPlaybackFailed;
		if([delegate respondsToSelector:@selector(streamErrorOccurred:)])
			[delegate performSelectorOnMainThread:@selector(streamErrorOccurred:)
																 withObject:self waitUntilDone:NO];
	}
	else if(!run)
	{
		state = SKPlayerStopped;
		if([delegate respondsToSelector:@selector(streamPlaybackAborted:)])
			[delegate performSelectorOnMainThread:@selector(streamPlaybackAborted:)
																 withObject:self waitUntilDone:NO];
	}
	else
	{
		state = SKPlayerPlaybackFinished;
		if([delegate respondsToSelector:@selector(streamPlaybackFinished:)])
			[delegate performSelectorOnMainThread:@selector(streamPlaybackFinished:)
																 withObject:self waitUntilDone:NO];
	}
	
	// Stop source
	ALint sourceState;
	alSourceStop(alSource);
	do {
		alGetSourcei(alSource, AL_SOURCE_STATE, &sourceState);
		usleep(10000);
	} while(sourceState != AL_STOPPED);
	
	// Unqueue remaining buffers
	alUnqueueAll(alSource);
	
	// Delete source
	alDeleteSources(1, &alSource);
	if(!err)
		err = alCheck("could not delete source");
	
	// Delete buffers
	alDeleteBuffers(alBufNum, alBuffers);
	if(!err)
		err = alCheck("could not delete buffers");
	
	// Destroy context and close device
	if(!alcMakeContextCurrent(NULL) && !err)
		err = alcCheck(alcDevice, "could not reset context");
	
	alcDestroyContext(alcContext);
	if(!err)
		err = alcCheck(alcDevice, "could not destroy context");
	
	if(!alcCloseDevice(alcDevice) && !err)
		err = alcCheck(alcDevice, "could not close device");
	
	[arp release];	
}

ALint alSourceGetState(ALuint alSource)
{
	ALint sourceState;
	alGetSourcei(alSource, AL_SOURCE_STATE, &sourceState);
	
	return sourceState;
}

void alSourceCheckState(ALuint alSource, ALfloat *pos)
{
	ALint sourceState = alSourceGetState(alSource);	
	//printf("source state: %s\r\n", alPlayState(sourceState));
	
	if(sourceState == AL_PLAYING)
		*pos += 0.25f;
}

void alFillBuffer(CFMutableDataRef data, UInt8 *buf, 
									uint bufSize, uint *bytesFilled, NSLock *lock)
{
	uint length = CFDataGetLength(data) < bufSize ? CFDataGetLength(data) : bufSize;
	CFRange range = CFRangeMake(0, length);
	
	if(range.length > 0)
	{
		[lock lock];
		CFDataGetBytes(data, range, buf);
		CFDataDeleteBytes(data, range);
		[lock unlock];
		
		*bytesFilled = range.length;
		return;
	}
	
	*bytesFilled = 0;
	buf = NULL;
}

BOOL alUnqueueAll(ALuint source)
{
	int queued;
	BOOL err = YES;
	
	alGetSourcei(source, AL_BUFFERS_QUEUED, &queued);
	
	while(queued--)
	{
		ALuint buffer;
    
		alSourceUnqueueBuffers(source, 1, &buffer);
		err = alCheck("could not unqueue buffer");
	}
	
	return err;
}

BOOL alCheck(const char *errMsg)
{
	ALenum err;
	
	if((err = alGetError()) != AL_NO_ERROR)
	{
		fprintf(stdout, "*** AL Error: %s (%s) ***\n", errMsg, alError(err));
		return YES;
	}
	
	return NO;
}

BOOL alcCheck(ALCdevice *dev, const char *errMsg)
{
	ALenum err;
	
	if((err = alcGetError(dev)) != ALC_NO_ERROR)
	{
		fprintf(stdout, "*** ALC Error: %s (%s) ***\n", errMsg, alError(err));
		return YES;
	}
	
	return NO;
}

const char * alError(ALuint err)
{
	switch(err)
	{
		case AL_INVALID_NAME: return "invalid name";
		case AL_INVALID_ENUM: return "illegal or invalid enum";
		case AL_INVALID_VALUE: return "invalid value";
		case AL_INVALID_OPERATION: return "illegal or invalid command/operation";
		case AL_OUT_OF_MEMORY: return "out of memory";
		default: return "no error";
	}
}

const char * alcError(ALuint err)
{
	switch(err)
	{
		case ALC_INVALID_DEVICE: return "invalid device";
		case ALC_INVALID_CONTEXT: return "invalid context";
		case ALC_INVALID_ENUM: return "invalid enum";
		case ALC_INVALID_VALUE: return "invalid value";
		case ALC_OUT_OF_MEMORY: return "out of memory";
		default: return "no error";
	}
}

const char * alPlayState(ALuint st)
{
	switch (st) {
		case AL_PLAYING: return "playing"; break;
		case AL_PAUSED: return "paused"; break;
		case AL_STOPPED: return "stopped"; break;
		case AL_INITIAL: return "initial"; break;
		default: return "invalid";
	}
}

@end
