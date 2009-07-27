//
//  Device.m
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

#import "Device.h"
#import "FMScrobbleSession.h"


@implementation Device

@synthesize suspended, locked, volume, scrobbleSession, lastErrorMessage;

- (id)initWithDelegate:(id)theDelegate appProxy:(JSApp *)app
{
	if(self = [super init])
	{
		volume = 1.0f;
		delegate = theDelegate;
		appProxy = [app retain];
	}
	
	return self;
}

- (void)dealloc
{
	self.lastErrorMessage = nil;
	[appProxy release];
	[super dealloc];
}

- (DeviceTrack *)track
{
	return nil;
}

- (void)setTrack:(DeviceTrack *)aTrack
{
	return;
}

- (void)setPosition:(double)pos
{
	// stub
}

- (double)position
{
	return 0;
}

- (DeviceState)deviceState
{
	return DeviceStopped;
}

- (BOOL)isRunning
{
	return NO;
}

- (NSString *)lastErrorMessage
{
	return [[lastErrorMessage copy] autorelease];
}

- (void)reset
{
	self.lastErrorMessage = nil;
}

- (void)refresh
{
	// stub
}

- (void)playPause
{
	// stub
}

- (void)stop
{
	// stub
}

- (void)nextTrack
{
	// stub
}

- (void)previousTrack
{
	// stub
}

@end

@implementation DeviceTrack

@synthesize name, artist, album, length, hash, cover, rating;
@synthesize scrobbled, nowPlayingSent, loved, banned, addedToPlaylist;

- (id)initWithName:(NSString *)aName artist:(NSString *)aArtist album:(NSString *)aAlbum length:(double)aLength
{
	if(self = [super init])
	{
		name = [aName copy];
		artist = [aArtist copy];
		album = [aAlbum copy];
		length = aLength;
	}
	
	return self;
}

- (void)dealloc
{
	[name release];
	[artist release];
	[album release];
	self.cover = nil;
	
	[super dealloc];
}

- (NSUInteger)hash
{
	return [name hash]/3 + [artist hash]/3 + [album hash]/3;
}

- (NSString *)nameAndArtist
{
	if(name && artist)
		return [NSString stringWithFormat:@"%@ - %@", name, artist];
	else if(name)
		return [[name copy] autorelease];
	else
		return nil;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ - %@, %@>", name, artist, album];
}

@end
