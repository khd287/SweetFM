//
//  FMBase.h
//  SweetFM
//
//  Created by Q on 28.04.09.
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

#import "NSString+FormatUtilities.h"


@interface FMBase : NSObject {
	
	NSString *lastError;
}

@property (copy) NSString *lastError;

- (NSString *)timestamp;

- (NSData *)HTTPPost:(NSURL *)url data:(NSData *)data;
- (NSData *)HTTPMimePost:(NSURL *)url data:(NSData *)data mimeType:(NSString *)mimeType;
- (NSData *)HTTPGetString:(NSString *)urlString;
- (NSData *)HTTPGet:(NSURL *)url;

- (NSURLRequest *)setUserAgent:(NSURLRequest *)request;		// Thanks to Eric Musgrove
- (NSDictionary *)parseAssignedList:(NSData *)data;
- (NSArray *)parseList:(NSData *)data;

@end


@interface NSData (LMBaseAdditions)

- (NSString *)hexString;
- (NSString *)UTF8String;

@end

@interface NSString (LMBaseAdditions)

- (NSString *)md5;
- (BOOL)containsString:(NSString *)str;

@end
