//
//  HLyrics.h
//  SweetFM
//
//  Created by Piero Avola on 09.07.09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DeviceTrack;

@interface HLyrics : NSObject {

}

+(NSString *)lyricsForTrack:(DeviceTrack *)track;

@end

@interface NSString (LyricAdditions)

-(NSString *)stringByReplacingSpecialCharacters;

@end
