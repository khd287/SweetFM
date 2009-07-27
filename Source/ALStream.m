//
//  ALStream.m
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

#import "ALStream.h"

#import "XLog.h"
#import "HSettings.h"


// C-callbacks
void ReadStreamCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *dataIn);
void alBuffFill(CFMutableDataRef data, UInt8 *buf, uint reqSize, int *bufSize, int *offset, NSLock *bufLock);

void strAppend(NSMutableData *data, NSString *s)
{
	[data appendBytes:[s UTF8String] length:[s lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

void u32Append(NSMutableData *data, UInt32 n)
{
	[data appendBytes:&n length:sizeof(UInt32)];
}

void u16Append(NSMutableData *data, UInt16 n)
{
	[data appendBytes:&n length:sizeof(UInt16)];
}


@implementation ALStream

@synthesize storePCM;

- (id)initWithDelegate:(id)dlg URL:(NSURL *)aUrl
{
	if(self = [super init])
	{
		if(aUrl)
		{
			volume = [HSettings radioVolume];
			
			streamURL = [aUrl retain];
			delegate = dlg;
			
			mpgData = CFDataCreateMutable(NULL, 0);
			pcmData = CFDataCreateMutable(NULL, 0);
			
			bufLock = [NSLock new];
		}
		else
		{
			[self autorelease];
			return nil;
		}
	}
	
	return self;
}

- (void)dealloc
{
	[streamURL release];
	
	if(mpgData)
		CFRelease(mpgData);
	
	if(pcmData)
		CFRelease(pcmData);
	
	[bufLock release];
	[super dealloc];
}

- (NSMutableData *)RIFFHeaderFor16BitPCMAudio
{
	if(!storePCM)
		return nil;
	
	// Prepend the RIFF header (processing produces only raw audio).
	NSMutableData *riff = [NSMutableData data];
	
	// RIFF-WAVE tag
	strAppend(riff, @"RIFF");
	u32Append(riff, CFDataGetLength(pcmData)+44);
	strAppend(riff, @"WAVE");
	
	/*
	 uint32 rate = 44100;
	 uint16 channels = 2;
	 */
	uint16 bitdepth = 16;
	
	// fmt signature
	strAppend(riff, @"fmt ");
	u32Append(riff, 16);										// fmt header length
	u16Append(riff, 1);											// format tag: 0x0001 = PCM
	u16Append(riff, 2);											// channels
	u32Append(riff, rate);									// sample rate
	u32Append(riff, 4*rate);								// bytes/sec = rate * block align
	u16Append(riff, channels*bitdepth/8);		// block align = channels * bitdepth / 8
	u16Append(riff, bitdepth);							// bitdepth
	
	// data signature
	strAppend(riff, @"data");
	u32Append(riff, CFDataGetLength(pcmData));
	
	return riff;
}

//
// Stream control
//
#pragma mark *** Stream control
#pragma mark -

- (void)updateEq
{
	if(mh)
	{
		if([HSettings eqEnabled])
		{
			XLog(@"EQ updated...");
			
			double eqGain = [HSettings eqGain];
			NSArray *eqBands = [HSettings eqPreset];
			
			for(int i=0; i<[eqBands count]; i++)
			{
				double band = [(NSNumber *)[eqBands objectAtIndex:i] doubleValue];
				band = 2.0f*((band-50.0f)/50.0f)+0.05f;
				band = pow(M_E, band);
				
				
				double gain = 2.0f*eqGain/100.0f+0.05f;
				
				double set = band*gain;
				
				//fprintf(stdout, "%i gain: %f band: %f set: %f\n", i, gain, band, set);
				mpg123_eq(mh, MPG123_LEFT|MPG123_RIGHT, i, set);
			}
		}
		else
		{
			XLog(@"EQ disabled...");
			mpg123_reset_eq(mh);
		}
	}
}

- (void)play
{
	XMark();
	
	@synchronized(self)
	{
		if(alSource)
		{
			alSourcePlay(alSource);
			//playing = true;
			//paused = false;
		}
		else
		{
			started = true;
			[NSThread detachNewThreadSelector:@selector(kickStream) toTarget:self withObject:nil];
		}
	}
}

- (void)pause
{
	XMark();
	
	@synchronized(self)
	{
		if(alSource)
		{
			alSourcePause(alSource);
			//paused = true;
			//playing = false;
		}
	}
}

- (void)stop
{
	XMark();
	
	@synchronized(self)
	{
		if(alSource)
		{
			playbackFinished = true;
			//downloadFinished = true;
			halt = true;
			paused = false;
			playing = false;
			
			//
			// Set volume to 0 (avoids clicking noise)
			//
			alSourcef(alSource, AL_GAIN, 0.0f);		
			alSourceStop(alSource);
			
			//
			// Wait for the device to close
			//
			do
			{
				[NSThread sleepForTimeInterval:0.1];
			}
			while(!deviceClosed);
		}	
	}
}

- (void)setVolume:(double)inVol
{
	@synchronized(self)
	{
		volume = inVol;
		
		if(alSource)
		{
			alSourcef(alSource, AL_GAIN, volume);		
		}
	}
}

- (double)volume
{
	if(alSource)
	{
		ALfloat outVol;
		alGetSourcef(alSource, AL_GAIN, &outVol);
		return outVol;
	}
	else
		return 1.0f;
}

- (BOOL)isPlaying
{
	return playing;
}

- (BOOL)isPaused
{
	return paused;
}

- (BOOL)isBuffering
{
	return buffering;
}

- (NSData *)mp3Data
{
	return [[(NSMutableData *)mpgData copy] autorelease];
}

- (NSData *)pcmData
{
	return [[(NSMutableData *)pcmData copy] autorelease];
}

- (double)playbackPosition 
{
	if(playing || paused || buffering)
		return playbackPos;
	else
		return 0;
}
		 
//
// Network part
//
#pragma mark *** Network part
#pragma mark -

- (void)kickStream
{
	// Cannot be released while resources not reset
	[self retain];
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	//fprintf(stdout, "Started stream.\n");
	
	// Init mpg123 decoder
	// This function is not thread-safe. Call it exactly once per process,
	// before any other (possibly threaded) work with the library.
	{
		if(mpg123_init())
		{
			fprintf(stderr, "Error initializing mpeg decoder.\n");
			failed = true;
			goto bail;
		}
		
		// Create new decoder
		if((mh = mpg123_new(NULL, NULL)) == NULL)
		{
			fprintf(stderr, "Error creating new mpeg decoder.\n");
			failed = true;
			goto bail;
		}
		
		//mpg123_param(mh, MPG123_VERBOSE, 2, 0);
		
		// Setup data feed
		if(mpg123_open_feed(mh))
		{
			fprintf(stderr, "Error opening mpeg feed.\n");
			failed = true;
			goto bail;
		}
		
		[self updateEq];		
	}
		
	// Create the HTTP request
	CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, 
																												CFSTR("GET"),
																												(CFURLRef)streamURL,
																												kCFHTTPVersion1_1);
	
	XLog(@"Stream URL: %@", [streamURL absoluteString]);
	
	// Init network stream
	stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
	CFRelease(request);
	
	// Should redirect...
	if(!CFReadStreamSetProperty(stream, 
															kCFStreamPropertyHTTPShouldAutoredirect,
															kCFBooleanTrue))
	{		
		failed = true;
		goto bail;
	}
	
	if(!CFReadStreamOpen(stream))
	{		
		failed = true;
		goto bail;
	}	
	
	CFStreamClientContext context = {0, self, NULL, NULL, NULL};
	CFReadStreamSetClient(stream, 
												kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
												ReadStreamCallBack,
												&context);
	
	// Schedule with runloop
	CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		
#define PCM_KICKOFF 1024*6
#define PCM_MIN_CHUNK_SIZE PCM_KICKOFF
	
	size_t dataOffset = 0;
	size_t sizeDone = 0;
	int err;
	
	do
	{
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);		
				
		size_t readRange = CFDataGetLength(mpgData)-dataOffset;
		
		if(dataOffset+readRange > PCM_KICKOFF && readRange > PCM_MIN_CHUNK_SIZE)
		{
			// Read chunk from input data
			UInt8 inBuf[readRange];
			CFDataGetBytes(mpgData, CFRangeMake(dataOffset, readRange), inBuf);
			
			//NSLog(@"read %i bytes (offset %i)", readRange, dataOffset);
			dataOffset += readRange;
			
			// Feed it to the decoder
			if(mpg123_feed(mh, inBuf, readRange))
				fprintf(stderr, "Error feeding decoder.\n");
			
			// Get buffer size estimate
			size_t outBufSize = mpg123_outblock(mh);
			unsigned char outBuf[outBufSize];
			
			do
			{
				//NSLog(@"--- inner encoder loop");
				
				err = mpg123_read(mh, outBuf, outBufSize, &sizeDone);
				
				if(err == MPG123_NEW_FORMAT && rate==0)
				{
					mpg123_getformat(mh, &rate, &channels, &encoding);
					//fprintf(stdout, "new format: %li Hz, %i channels, encoding %i\n", rate, channels, encoding);
					
					// Set output format
					mpg123_format_none(mh);
					mpg123_format(mh, rate, channels, encoding);
				}
				
				//NSLog(@"processed %i bytes (%i)", sizeDone, err);
				
				if(err==MPG123_OK)
				{
					[bufLock lock];
					CFDataAppendBytes(pcmData, outBuf, outBufSize);
					[bufLock unlock];
				}
				
			} while(err==MPG123_OK);
						
			if(!alStarted && CFDataGetLength(pcmData) > 1024*4)
			{
				alStarted = YES;
				// Start OpenAL playback
				[NSThread detachNewThreadSelector:@selector(audioLoop) toTarget:self withObject:nil];	
				[NSThread detachNewThreadSelector:@selector(updateAudioPosition) toTarget:self withObject:nil];
			}
		}
		
	} while(!downloadFinished && !halt && !failed);
	
	if(downloadFinished && !halt && !failed)
	{
		if([delegate respondsToSelector:@selector(streamFinishedDownload:)])
			[delegate streamFinishedDownload:self];
	}
		
bail:
	
	XLog(@"stream end");
	
	// Close MPG decoder
	if(mpg123_close(mh))
	{
		fprintf(stderr, "Error closing mpeg decoder.\n"); return;
	}
	
	mpg123_delete(mh);
	mpg123_exit();
	mh = nil;
		
	[pool release];
	
	// Close network stream
	if(stream)
	{
		CFReadStreamClose(stream);
		CFRelease(stream);
		stream = NULL;
	}
			
	[self release];
	
	if(failed)
	{
		if([delegate respondsToSelector:@selector(streamErrorOccurred:)])
			[delegate performSelectorOnMainThread:@selector(streamErrorOccurred:)
																 withObject:self 
															waitUntilDone:NO];
	}
}

//
// Audio part
//
#pragma mark *** Audio part
#pragma mark -

- (void)updateAudioPosition
{
	do
	{
		[NSThread sleepForTimeInterval:1];
		
		if(alSource && playing)
			playbackPos += 1;
	}
	while(!playbackFinished && !failed);
}

- (void)audioLoop
{
	[self retain];
	
	// Required (at least for delegate callbacks)	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	//
	// Clear errors
	//
	alGetError();

	// Open AL device and create context
	alDevice = alcOpenDevice(NULL);
	if(!alDevice)
	{
		alcCheck(alDevice, "could not open device");
		failed = true;
		goto cleanup;
	}
	
	// Create AL context
	alContext = alcCreateContext(alDevice, NULL);
	if(!alContext)
	{
		alcCheck(alDevice, "could not create AL context");
		failed = true;
		goto cleanup;
	}
	
	if(!alcMakeContextCurrent(alContext))
	{
		alcCheck(alDevice, "could not set AL context");
		failed = true;
		goto cleanup;
	}
	
	// Generate AL buffers for streaming. Buffer size should be multiple of 4
	
#define NUM_BUFFERS 6
#define BUFFER_SIZE 1024*100
#define BUFFER_MIN BUFFER_SIZE
		
	ALuint alBuffers[NUM_BUFFERS];
	ALuint frequency = rate;
	ALenum format = AL_FORMAT_STEREO16;
	
	alGenBuffers(NUM_BUFFERS, alBuffers);
	if(!alCheck("could not generate AL buffers"))
	{
		failed = true;
		goto cleanup;
	}
	
	alGenSources(1, &alSource);
	if(!alCheck("could not create AL source"))
	{
		failed = true;
		goto cleanup;
	}
	
	//
	// Prime the buffers
	//
	int bufSize;
	int bufOffset = storePCM ? 0 : -1;
	UInt8 inBuf[BUFFER_SIZE];
	
	alBuffFill(pcmData, inBuf, BUFFER_SIZE, &bufSize, &bufOffset, bufLock);
	alBufferData(alBuffers[0], format, inBuf, bufSize, frequency);
	alBuffFill(pcmData, inBuf, BUFFER_SIZE, &bufSize, &bufOffset, bufLock);
	alBufferData(alBuffers[1], format, inBuf, bufSize, frequency);
	alBuffFill(pcmData, inBuf, BUFFER_SIZE, &bufSize, &bufOffset, bufLock);
	alBufferData(alBuffers[2], format, inBuf, bufSize, frequency);
	
	if(!alCheck("could not fill buffers"))
	{
		failed = true;
		goto cleanup;
	}
	
	//
	// Enqueue the buffers and start playback
	//
	alSourceQueueBuffers(alSource, NUM_BUFFERS, alBuffers);
	alSourcePlay(alSource);
	if(!alCheck("could not start playback"))
	{
		failed = true;
		goto cleanup;
	}
		
	if([delegate respondsToSelector:@selector(streamPlaybackStarted:)])
		[delegate performSelectorOnMainThread:@selector(streamPlaybackStarted:)
															 withObject:self 
														waitUntilDone:NO];
	
	//BOOL justStarted = YES;
	long bufferingOffset = 0;
	
	ALuint buffer;
	ALint val;
	ALint oldState = -1;
	
	//
	// Set volume
	//
	alSourcef(alSource, AL_GAIN, volume);	
	
	while(!playbackFinished && !halt)
	{
		[NSThread sleepForTimeInterval:0.25];
				
		alGetSourcei(alSource, AL_BUFFERS_PROCESSED, &val);
		
		/*
		if(val <= 0)
			continue;
		 */
		
		while(val--) {
		
			alBuffFill(pcmData, inBuf, BUFFER_SIZE, &bufSize, &bufOffset, bufLock);
			
			if(!bufSize && downloadFinished)
			{
				playbackFinished = true;
				alSourceStop(alSource);
			}
			else if(bufSize)
			{
				//
				// Un-queue the old buffer
				//
				alSourceUnqueueBuffers(alSource, 1, &buffer);
				
				//
				// Refresh buffer with new audio and clear PCM buffer
				//
				alBufferData(buffer, format, &inBuf, bufSize, frequency);				
				
				//
				// Enqueue again
				//
				alSourceQueueBuffers(alSource, 1, &buffer);
				alCheck("could not buffer data");
			}
		}

		//
		// Get source state
		//
		ALint state;
		alGetSourcei(alSource, AL_SOURCE_STATE, &state);
		
		//XLog(@"Source state %02X", state);
		
		if(state == AL_PLAYING) 
		{
			//
			// OpenAL is playing
			//
			
			if(!playing && oldState == AL_PAUSED)
			{
				buffering = false;
				playing = true;
				paused = false;
				
				if([delegate respondsToSelector:@selector(streamPlaybackResumed:)])
					[delegate performSelectorOnMainThread:@selector(streamPlaybackResumed:)
																		 withObject:self
																	waitUntilDone:YES];
			}
			
			buffering = false;
			playing = true;
			paused = false;
			//justStarted = NO;
			
			oldState = state;
		}
		else if(state == AL_PAUSED) 
		{
			//
			// OpenAL is paused
			//
			buffering = false;
			playing = false;
			paused = true;
			
			if([delegate respondsToSelector:@selector(streamPlaybackPaused:)] &&
				state != oldState)
			{
				[delegate performSelectorOnMainThread:@selector(streamPlaybackPaused:)
																	 withObject:self
																waitUntilDone:YES];
			}
			
			oldState = state;
		}
		else
		{
			//
			// OpenAL is stopped
			//
			if(!buffering && !halt && !playbackFinished)
			{
				alSourcePause(alSource);
				bufferingOffset = CFDataGetLength(mpgData);
				
				playing = false;
				paused = true;
				buffering = true;
				
				if([delegate respondsToSelector:@selector(streamIsBuffering:)] &&
					state != oldState)
				{
					[delegate performSelectorOnMainThread:@selector(streamIsBuffering:)
																		 withObject:self
																	waitUntilDone:YES];
				}
			}
			
			long bufLen = CFDataGetLength(mpgData)-bufferingOffset;
			if((buffering && bufLen > BUFFER_MIN) || downloadFinished)
			{
				paused = false;
				playing = true;
				buffering = false;
				
				alSourcePlay(alSource);
			}

			playing = false;
			paused = false;
			
			oldState = state;
		}
	}
	
cleanup:
	
	//
	// Clean up
	//
	alSourceStop(alSource);
	do 
	{
		alGetSourcei(alSource, AL_SOURCE_STATE, &val);
		usleep(10000);
	} 
	while (val != AL_STOPPED);
		
	//
	// Unqueue buffers
	//
	alUnqueueAll(alSource);
	
	//
	// Delete source
	//
	alDeleteSources(1, &alSource);
	alCheck("could not delete source");
	
	//
	// Delete buffers
	//
	alDeleteBuffers(NUM_BUFFERS, alBuffers);
	alCheck("could not delete buffers");
	
	//
	// Destroy context and close device
	//
	if(!alcMakeContextCurrent(NULL))
		alcCheck(alDevice, "could not reset context");
	
	alcDestroyContext(alContext);
	alcCheck(alDevice, "could not destroy context");
	
	if(!alcCloseDevice(alDevice))
		alcCheck(alDevice, "could not close device");
	
	deviceClosed = YES;
	
	XLog(@"Audio loop ended");
	
	if(!failed && !halt)
	{
		if([delegate respondsToSelector:@selector(streamPlaybackFinished:)])
			[delegate performSelectorOnMainThread:@selector(streamPlaybackFinished:) 
																 withObject:self 
															waitUntilDone:NO];
	}
	
	if(halt)
	{
		if([delegate respondsToSelector:@selector(streamPlaybackAborted:)])
			[delegate performSelectorOnMainThread:@selector(streamPlaybackAborted:)
																 withObject:self 
															waitUntilDone:NO];
	}
	
	[pool release];
	[self release];
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
		return NO;
	}
	
	return YES;
}

BOOL alcCheck(ALCdevice *dev, const char *errMsg)
{
	ALenum err;
	
	if((err = alcGetError(dev)) != ALC_NO_ERROR)
	{
		fprintf(stdout, "*** ALC Error: %s (%s) ***\n", errMsg, alError(err));
		return NO;
	}
	
	return YES;
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

void alBuffFill(CFMutableDataRef data, UInt8 *buf, uint reqSize, int *bufSize, int *offset, NSLock *bufLock)
{
	int length = CFDataGetLength(data);

	//fprintf(stdout, "PCM data length %i\n (offset %i reqSize %i)", length, *offset, reqSize);
	
	if(!data || *offset > length-1 || (*offset+reqSize) > length-1 || reqSize<=0 || length==0)
	{
		//fprintf(stdout, "0 length %i offset %i req %i\n", length, *offset, reqSize);
		buf = NULL;
		*bufSize = 0;
		return;
	}
	else
	{
		if(*offset != -1)
		{
			//fprintf(stdout, "0\n");
			CFDataGetBytes(data, CFRangeMake(*offset, reqSize), buf);
			//fprintf(stdout, "%i bytes written to AL buf (req size: %i)\n", range.length, reqSize);
			// Write out values
			*bufSize = reqSize;
			*offset = *offset+reqSize;
		}
		else
		{
			[bufLock lock];
			
			//fprintf(stdout, "1- length %i\n", length);
			
			CFDataGetBytes(data, CFRangeMake(0, reqSize), buf);
			CFDataDeleteBytes(data, CFRangeMake(0, reqSize));
			*bufSize = reqSize;
			*offset = -1;
			
			[bufLock unlock];
		}
	}
}

#define CF_STREAM_CHUNK_SIZE 1024*128

void ReadStreamCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *dataIn)
{
	ALStream *myData = (ALStream *)dataIn;
	
	if (eventType == kCFStreamEventErrorOccurred)
	{
		myData->failed = true;
	}
	else if (eventType == kCFStreamEventEndEncountered) 
	{
		long dataLength = CFDataGetLength(myData->mpgData);
		if(dataLength < 1024*500)
			myData->failed = true;
		else
			myData->downloadFinished = true;
	}
	else if (eventType == kCFStreamEventHasBytesAvailable) 
	{
		UInt8 bytes[CF_STREAM_CHUNK_SIZE];
		CFIndex bytesRead = CFReadStreamRead(stream, bytes, CF_STREAM_CHUNK_SIZE);
		//NSLog(@"bytes read %i", bytesRead);
		
		// An error occurred
		if(bytesRead == -1)
		{
			myData->failed = true;
		}
		// End of stream reached
		else if(bytesRead == 0)
		{
			myData->downloadFinished = true;
		}
		else
		{
			CFDataAppendBytes(myData->mpgData, bytes, bytesRead);
			//NSLog(@"appended %i bytes of data", bytesRead);
		}
	}
}

@end






























