//
//  SKConnection.m
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

#import "SKConnection.h"


@implementation SKConnection

@synthesize delegate, buffer;

- (id)initWithURL:(NSURL *)aURL PCMSynthesizer:(id<SKSynth>)aSynth
{
	if(self = [super init])
	{
		mURL = [aURL copy];
		mSynth = [(NSObject *)aSynth retain];
		[mSynth setDelegate:self];
		
		// Install a 10kb buffer
		self.buffer = [SKBuffer bufferWithSize:1024*10];
	}
	
	return self;
}

- (void)dealloc 
{
	[mURL release];
	[(NSObject *)mSynth release];
	[mConnection release];
	self.buffer = nil;
	
	[super dealloc];
}

- (void)open
{
	NSURLRequest *request = [NSURLRequest requestWithURL:mURL];
	
	mConnection = [[NSURLConnection alloc] initWithRequest:request
																								delegate:self];
	
	if(!mConnection)
	{
		if([delegate respondsToSelector:@selector(streamConnection:didFailWithError:)])
			[delegate streamConnection:self didFailWithError:nil];
		
		[mConnection release];
	}
}

- (NSData *)data
{
	return [mSynth input];
}

- (NSData *)synthesizedData
{
	return [mSynth output];
}

- (id<SKSynth>)synthesizer 
{
	return mSynth;
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if([delegate respondsToSelector:
			@selector(streamConnectionOpened:)])
		[delegate streamConnectionOpened:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	// Feed the data to the pcm synthesizer
	[mSynth feed:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{	
	// No more data so we can drain the buffer
	[buffer drain];
	
	if([delegate respondsToSelector:
			@selector(streamConnectionDidFinishLoading:)])
		[delegate streamConnectionDidFinishLoading:self];
	
	[connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	if([delegate respondsToSelector:
			@selector(streamConnection:didFailWithError:)])
		[delegate streamConnection:self didFailWithError:error];
	
	[connection release];
}

#pragma mark SKSynth Delegate Methods

- (void)synthesizedDataAvailable:(NSData *)theData
{	
	[buffer push:theData];
	
	NSData *chunk = [buffer nextChunk];
		
	if(chunk)
	{
		if([delegate respondsToSelector:
				@selector(streamConnection:didSynthesizeAudioData:)])
			[delegate streamConnection:self didSynthesizeAudioData:chunk];
	}
}

- (void)synthesizeFailed:(id<SKSynth>)theSynth
{
	// Cancel connection
	[mConnection cancel];
	
	if([delegate respondsToSelector:@selector(streamConnection:didFailWithError:)])
		[delegate streamConnection:self 
							didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain
																									 code:1
																							 userInfo:nil]];
	
	[mConnection release];
}

@end
