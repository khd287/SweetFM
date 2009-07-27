//
//  FMStation.h
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


@class FMRadioSession;

@interface FMStation : FMBase <QueueProxyProtocol> {

	FMRadioSession *session;
	
	NSString *stationName;
	NSURL *stationURL;
}

@property (readonly, copy) NSString *stationName;
@property (readonly, copy) NSURL *stationURL;

+ (NSString *)globalTagsRadio:(NSString *)tags;
+ (NSString *)userLibraryRadio:(NSString *)user;
+ (NSString *)userNeighbourRadio:(NSString *)user;
+ (NSString *)userLovedTracksRadio:(NSString *)user;
+ (NSString *)userRecommendedRadio:(NSString *)user;
+ (NSString *)similarArtistsRadio:(NSString *)artist;
+ (NSString *)artistFanRadio:(NSString *)artist;

- (id)initWithRadioSession:(FMRadioSession *)aSession;

- (BOOL)tuneToStation:(NSString *)aStation;

@end
