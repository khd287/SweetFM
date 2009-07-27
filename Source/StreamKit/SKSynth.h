//
//  SKSynth.h
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

#import <Cocoa/Cocoa.h>

#import <OpenAL/al.h>


@protocol SKSynth

- (void)setDelegate:(id)dlg;
- (id)delegate;

- (void)setPersistent:(BOOL)pers;
- (BOOL)persistent;

- (void)feed:(NSData *)theData;

- (NSData *)input;
- (NSData *)output;

- (NSData *)addPCMHeaderToAudio:(NSData *)pcmData;

- (NSUInteger)rate;
- (NSUInteger)bytesPerSecond;
- (ALenum)format;

@end

@interface NSObject (SKSynthInformalProtocol)

- (void)synthesizedDataAvailable:(NSData *)theData;
- (void)synthesizeFailed:(id<SKSynth>)theSynth;

@end

