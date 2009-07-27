//
//  XLog.m
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

#import "XLog.h"

void _XMark(char *output, int lineNumber, SEL slc)
{
	_XLog(output, lineNumber, slc, @"***");
}

void _XLog(char *output, int lineNumber, SEL slc, NSString *format, ...) 
{		
	va_list argList;
	va_start(argList, format);
	
	NSString *formatted = [[NSString alloc] initWithFormat:format arguments:argList];
	
	// Build the path string
  NSString *filePath = [[NSString alloc] initWithBytes:output length:strlen(output)
																							encoding:NSUTF8StringEncoding];
	
	printf("[%s:%i %s] %s\n", [[filePath lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding],
				 lineNumber,
				 slc,
				 [formatted cStringUsingEncoding:NSUTF8StringEncoding]);
	
	
	[formatted release];
	[filePath release];
	
	va_end(argList);
}
