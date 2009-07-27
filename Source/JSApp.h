//
//  JSApp.h
//  SweetFM
//
//  Created by Q on 23.05.09.
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
#import "JSProxy.h"


extern NSString * const JSDOMReadyNotification;

extern NSString * const JSAppCloseWindowNotification;
extern NSString * const JSAppPinToggleNotification;
extern NSString * const JSAppScrobbleToggleNotification;
extern NSString * const JSAppPlayPauseNotification;
extern NSString * const JSAppStopNotification;
extern NSString * const JSAppNextNotification;
extern NSString * const JSAppLoveNotification;
extern NSString * const JSAppBanNotification;
extern NSString * const JSAppAddToPlaylistNotification;
extern NSString * const JSAppOpenQuickMenuNotification;
extern NSString * const JSAppTuneToStationNotification;
extern NSString * const JSAppSetVolumeNotification;
extern NSString * const JSAppSetPositionNotification;
extern NSString * const JSAppNextCoverNotification;
extern NSString * const JSAppPreviousCoverNotification;

extern NSString * const JSAppOpenBuyPageNotification;
extern NSString * const JSAppOpenTrackPageNotification;
extern NSString * const JSAppOpenArtistPageNotification;
extern NSString * const JSAppOpenAlbumPageNotification;

typedef enum {
	NoStation = 0,
	ArtistStation,
	TagStation,
	LibraryStation,
	NeighbourStation,
	LovedStation,
	RecommendedStation,
	FanStation,
	ShuffleStation
} JSAppStationType;

@interface JSApp : JSProxy {

	BOOL pinned;
	BOOL scrobble;
	
	NSUInteger stationType;
	NSString *stationTitle;
	
	double volume;
	double position;
}

@property (readonly) BOOL pinned;
@property (readonly) BOOL scrobble;

@property (readonly) JSAppStationType stationType;
@property (readonly, copy) NSString *stationTitle;

@property (readonly) double volume;
@property (readonly) double position;

- (NSArray *)classesAllowingDrag;
- (NSSize)resizeCoversTo;

//
// From UI
//
- (void)DOMReady;

- (void)closeWindow;
- (void)togglePinned;
- (void)toggleScrobble;

- (void)playPause;
- (void)stop;
- (void)next;
- (void)love;
- (void)ban;
- (void)addToPlaylist;

- (void)openQuickMenu;

- (void)tuneToStation:(NSString *)stationString;

- (void)setVolume:(double)vol;
- (void)setPosition:(double)seconds;

- (void)nextCover;
- (void)previousCover;

- (void)setArtistStationType;
- (void)setTagsStationType;
- (void)setLibraryStationType;
- (void)setNeighbourStationType;
- (void)setLovedStationType;
- (void)setRecommendedStationType;
- (void)setFansStationType;
- (void)setShuffleStationType;
- (void)handleStationString:(NSString *)stationString withPrefix:(NSString *)prefix andSuffix:(NSString *)suffix selectFrom:(NSUInteger)from to:(NSUInteger)to;

- (void)openBuyPage;
- (void)openTrackPage;
- (void)openArtistPage;
- (void)openAlbumPage;

//
// To UI
//
- (void)uiSetQuickMenuOpen;

- (void)uiSetPinEnabled:(BOOL)pin;
- (void)uiSetScrobbleEnabled:(BOOL)scrob;

- (void)uiSetCoverImage:(NSImage *)image;

- (void)uiSetCoverNumber:(NSUInteger)num;
- (void)uiSetCoverCount:(NSUInteger)num;

- (void)uiSetTrackName:(NSString *)trackName;
- (void)uiSetTrackAlbum:(NSString *)trackAlbum;
- (void)uiSetTrackArtist:(NSString *)trackArtist;

- (void)uiSetDuration:(NSUInteger)seconds;
- (void)uiSetPosition:(NSUInteger)seconds;

- (void)uiSetVolume:(double)vol;

- (void)uiSetStationTitle:(NSString *)title selectFrom:(NSUInteger)from to:(NSUInteger)to;
- (NSString *)uiGetStationTitle;

- (void)uiSetErrorMessage:(NSString *)msg;
- (void)uiSetStatusMessage:(NSString *)msg;

@end
