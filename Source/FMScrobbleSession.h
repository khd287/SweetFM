//
//  FMScrobbleSession.h
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

#import "FMBase.h"
#import "QProxy.h"


@class DeviceTrack;
@class FMTrack;

extern NSString * const PlayerIDSweetFM;
extern NSString * const PlayerIDiTunes;
extern NSString * const PlayerIDTesting;
extern NSString * const PlayerVersion;

// Track scrobble ratings
extern NSString * const RatingFlagLove;
extern NSString * const RatingFlagBan;
extern NSString * const RatingFlagSkip;

@interface FMScrobbleSession : FMBase <QueueProxyProtocol> {

	NSString *user;
	NSString *password;
	NSString *playerID;
	
	NSString *scrobbleKey;
	NSURL *nowPlayingURL;
	NSURL *submissionURL;
	
	BOOL authenticated;
}

@property (readonly, copy) NSString *scrobbleKey;
@property (readonly, copy) NSURL *nowPlayingURL;
@property (readonly, copy) NSURL *submissionURL;

@property (readonly) BOOL authenticated;

- (id)initWithUser:(NSString *)aUser
					password:(NSString *)aPassword 
					playerID:(NSString *)pid;

- (BOOL)authenticate;
- (NSString *)sessionToken;

- (BOOL)scrobble:(DeviceTrack *)track withRatingFlag:(NSString *)rate;
- (BOOL)nowPlaying:(DeviceTrack *)track;

- (BOOL)love:(DeviceTrack *)track;
- (BOOL)ban:(DeviceTrack *)track;
- (BOOL)addToPlaylist:(DeviceTrack *)track;

- (BOOL)sendCommand:(NSString *)cmd forTrack:(DeviceTrack *)track;

@end
