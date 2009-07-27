//
//  DRadio.h
//  SweetFM
//
//  Created by Q on 25.05.09.
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

#import "Device.h"
#import "JSApp.h"

@class ALStream;

@class FMRadioSession;
@class FMScrobbleSession;
@class FMStation;
@class FMPlaylist;
@class FMTrack;

@interface DRadio : Device {

	ALStream *audioStream;
	BOOL skipped;
	
	NSTimeInterval timeoutStamp;
	
	NSString *previousStation;
	NSString *tuneToStation;
	
	FMRadioSession *radioSession;
	FMStation *station;
	FMPlaylist *playlist;
	FMTrack *track;
}

@property (retain) FMRadioSession *radioSession;
@property (retain) FMStation *station;
@property (retain) FMPlaylist *playlist;

+ (NSString *)lastFmStationForType:(JSAppStationType)type name:(NSString *)name;

- (void)tuneToLastStation;

@end
