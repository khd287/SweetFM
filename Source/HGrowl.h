//
//  HGrowl.h
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

#import "Growl.h"

extern NSString * const GrowlTrackPlaying;
extern NSString * const GrowlTrackPaused;
extern NSString * const GrowlTrackResumed;
extern NSString * const GrowlTrackStopped;
extern NSString * const GrowlTrackExported;
extern NSString * const GrowlTrackLoved;
extern NSString * const GrowlTrackBanned;
extern NSString * const GrowlTrackAddToPlaylist;
extern NSString * const GrowlTrackBuffering;
extern NSString * const GrowlTunedToStation;
extern NSString * const GrowlError;

@interface HGrowl : NSObject <GrowlApplicationBridgeDelegate> {

}

+ (HGrowl *)install;
+ (HGrowl *)instance;

- (void)postNotificationWithName:(NSString *)notify
													 title:(NSString *)title
										 description:(NSString *)desc
													 image:(NSImage *)img;

@end
