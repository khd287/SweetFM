//
//  iTunesLinkBuilder.h
//  iTunesAffilateTest
//
//  Created by Q on 06.06.09.
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


extern NSString * const MediaTypeAll;
extern NSString * const MediaTypeMusic;
extern NSString * const MediaTypeMovies;
extern NSString * const MediaTypeShortFilms;
extern NSString * const MediaTypeTVShows;
extern NSString * const MediaTypeApplications;
extern NSString * const MediaTypeMusicVideos;
extern NSString * const MediaTypeAudiobooks;
extern NSString * const MediaTypePodcasts;
extern NSString * const MediaTypeiTunesU;


@interface iTunesLinkBuilder : NSObject {

	NSString *affId;
	NSLocale *locale;
}

- (id)initWithTDAffilateID:(NSString *)theAffId;

- (void)useLocale:(NSLocale *)aLocale;
- (NSURL *)linkForAlbum:(NSString *)theAlbum artist:(NSString *)theArtist;

- (NSURL *)resultsForTerm:(NSString *)aTerm mediaType:(NSString *)aType;

@end
