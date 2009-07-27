//
//  SKMP3Synth.m
//  StreamKit
//
//  Created by Q on 29.06.09.
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

#import "SKMP3Synth.h"


@interface NSMutableData (SKMP3SynthHelper)

- (void)appendString:(NSString *)theString;
- (void)appendUInt32:(UInt32)theInt;
- (void)appendUInt16:(UInt16)theInt;

@end

@implementation NSMutableData (SKMP3SynthHelper)

- (void)appendString:(NSString *)theString
{
	[self appendBytes:[theString UTF8String]
						 length:[theString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendUInt32:(UInt32)theInt
{
	[self appendBytes:&theInt length:sizeof(UInt32)];
}

- (void)appendUInt16:(UInt16)theInt
{
	[self appendBytes:&theInt length:sizeof(UInt16)];
}

@end


@implementation SKMP3Synth

- (NSData *)addPCMHeaderToAudio:(NSData *)pcmData
{	
	UInt16 bitDepth = 16;
	
	// Generate the RIFF header
	NSMutableData *riff = [NSMutableData data];
	
	// RIFF-WAVE tag
	[riff appendString:@"RIFF"];			
	[riff appendUInt32:[pcmData length]+44];
	[riff appendString:@"WAVE"];
	
	// Format signature
	[riff appendString:@"fmt "];
	[riff appendUInt32:16];										// fmt header length
	[riff appendUInt16:1];										// format tag: 0x0001 = PCM
	[riff appendUInt16:channels];							// channels
	[riff appendUInt32:rate];									// sample rate
	[riff appendUInt32:4*rate];								// bytes/sec = rate*block
	[riff appendUInt16:channels*bitDepth/8];	// block align = channels*bitdepth/8
	[riff appendUInt16:bitDepth];
	
	// Data signature
	[riff appendString:@"data"];
	[riff appendUInt32:[pcmData length]];
	
	[riff appendData:pcmData];
	
	return [NSData dataWithData:riff];
}

- (id)init
{
	if(self = [super init])
	{
		// Init mpg123
		if(mpg123_init())
		{
			fprintf(stderr, "Error initializing mpeg decoder.\n");
			[self release];
			return nil;
		}
		
		// Create new decoder
		if((mh = mpg123_new(NULL, NULL)) == NULL)
		{
			fprintf(stderr, "Error creating new mpeg decoder.\n");
			[self release];
			return nil;
		}
			
		// Setup data feed
		if(mpg123_open_feed(mh))
		{
			fprintf(stderr, "Error opening mpeg feed.\n");
			[self release];
			return nil;
		}
		
		dataIn = CFDataCreateMutable(NULL, 0);
		dataOut = CFDataCreateMutable(NULL, 0);
		
		rate = 44100;
		
		procOffset = 0;
	}
	
	return self;
}

- (void)dealloc
{
	if(mh)
	{
		// Close MPG decoder
		if(mpg123_close(mh))
		{
			fprintf(stderr, "Error closing mpeg decoder.\n"); return;
		}
		
		mpg123_delete(mh);
		mpg123_exit();
		mh = nil;
	}
	
	CFRelease(dataIn);
	CFRelease(dataOut);
	
	[super dealloc];
}

- (void)setDelegate:(id)dlg
{
	delegate = dlg;
}

- (id)delegate
{
	return delegate;
}

- (void)setPersistent:(BOOL)pers;
{
	persistent = pers;
}

- (BOOL)persistent
{
	return persistent;
}

- (NSData *)input
{
	if(!persistent)
		return nil;
	
	return [NSData dataWithData:(NSMutableData *)dataIn];
}

- (NSData *)output
{
	if(!persistent)
		return nil;
	
	return [NSData dataWithData:(NSMutableData *)dataOut];
}

- (NSUInteger)rate
{
	return (NSUInteger)rate;
}

- (NSUInteger)bytesPerSecond
{
	return [self rate]*4;
}

- (ALenum)format
{
	// TODO: not acceptable for other purposes
	return AL_FORMAT_STEREO16;
}

- (void)feed:(NSData *)theData
{
	// Append input data
	if(persistent)
		CFDataAppendBytes(dataIn, [theData bytes], [theData length]);

	// Fill input buffer
	long inBufLen = [theData length];
	UInt8 inBuf[inBufLen];
	
	[theData getBytes:inBuf length:inBufLen];
			
	// Feed it to the stream
	if(mpg123_feed(mh, inBuf, inBufLen))
	{
		fprintf(stderr, "Error feeding decoder.\n");
		
		if([delegate respondsToSelector:@selector(synthesizeFailed:)])
			[delegate synthesizeFailed:self];
		
		return;
	}
	
	// Synthesize packets
	size_t bytesProcessed;
	int length = 0;
	int err = MPG123_OK;
	
	size_t outSize = mpg123_outblock(mh);
	unsigned char outBuf[outSize];
	
	do
	{
		err = mpg123_read(mh, outBuf, outSize, &bytesProcessed);
	
		CFDataAppendBytes(dataOut, outBuf, bytesProcessed);
		length += bytesProcessed;
	}
	while(err == MPG123_OK);
	
	// Watch for state flags
	if(err == MPG123_NEW_FORMAT)
	{
		// Get new format
		mpg123_getformat(mh, &rate, &channels, &encoding);
		
		// Set new format
		mpg123_format_none(mh);
		mpg123_format(mh, rate, channels, encoding);
	}
	else if(err == MPG123_NEED_MORE && 
		 [delegate respondsToSelector:@selector(synthesizedDataAvailable:)])
	{
		NSRange dataRange = NSMakeRange(procOffset, length);
		NSData *chunk = [(NSData *)dataOut subdataWithRange:dataRange];
		
		[delegate synthesizedDataAvailable:chunk];
	}
	else
		printf("error %i\n", err);
	
	if(persistent)
		procOffset += length;
	else
	{
		procOffset = 0;
		CFDataSetLength(dataOut, 0);
	}
}

@end
