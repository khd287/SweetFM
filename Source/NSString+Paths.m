//
//  NSString+Paths.m
//  SweetFM
//
//  Created by Q on 05.06.09.
//
//
//  Found on http://www.cocoabuilder.com/archive/message/cocoa/2005/7/13/141777
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

#import "NSString+Paths.h"


@implementation NSString (Paths)

- (NSString *)HFSPath
{
	//
	// thanks to stone.com for the pointer to CFURLCreateWithFileSystemPath()
	//
	CFURLRef    url;
	CFStringRef hfsPath = NULL;
	
	BOOL isDirectoryPath = [self hasSuffix:@"/"];
	
	//
	// Note that for the usual case of absolute paths, isDirectoryPath is
	// completely ignored by CFURLCreateWithFileSystemPath.
	// isDirectoryPath is only considered for relative paths.
	// This code has not really been tested relative paths...
	//
	url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
																			(CFStringRef)self,
																			kCFURLPOSIXPathStyle,
																			isDirectoryPath);
	if (NULL != url) 
	{
		//
		// Convert URL to a colon-delimited HFS path
		// represented as Unicode characters in an NSString.
		//
		hfsPath = CFURLCopyFileSystemPath(url, kCFURLHFSPathStyle);
		
		if(hfsPath)
			[(NSString *)hfsPath autorelease];
		
		CFRelease(url);
	}
	
	return (NSString *)hfsPath;
}

@end
