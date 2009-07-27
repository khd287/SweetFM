//
//  CMKeyCombo.m
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
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

#import "CMKeyCombo.h"

@implementation CMKeyCombo

+ (id)clearKeyCombo {
	return [self keyComboWithKeyCode: -1 modifiers: 0];
}

+ (id)keyComboWithKeyCode: (int)keyCode modifiers: (unsigned int)modifiers {
	return [[[self alloc] initWithKeyCode: keyCode modifiers: modifiers] autorelease];
}

- (id)initWithKeyCode: (int)keyCode modifiers: (unsigned int)modifiers {
	
	if(self = [super init]) {
		mKeyCode = keyCode;
		mModifiers = modifiers;
	}
	
	return self;
}

- (id)initWithPlistRepresentation:(id)plist {
	
	int keyCode, modifiers;
	
	if( !plist || ![plist count] ) {
		keyCode = -1;
		modifiers = 0;
	}
	else {
		keyCode = [[plist objectForKey: @"keyCode"] intValue];
		if( keyCode < 0 ) keyCode = -1;
	
		modifiers = [[plist objectForKey: @"modifiers"] unsignedIntValue];
	}

	return [self initWithKeyCode: keyCode modifiers: modifiers];
}

- (id)plistRepresentation {
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt: [self keyCode]], @"keyCode",
				[NSNumber numberWithUnsignedInt: [self modifiers]], @"modifiers",
				nil];
}

- (id)copyWithZone:(NSZone*)zone; {
	return [self retain];
}

- (BOOL)isEqual: (CMKeyCombo*)combo {
	return	[self keyCode] == [combo keyCode] &&
			[self modifiers] == [combo modifiers];
}

#pragma mark -

- (int)keyCode {
	return mKeyCode;
}

- (unsigned int)modifiers {
	return mModifiers;
}

- (BOOL)isValidHotKeyCombo {
	return mKeyCode >= 0;
}

- (BOOL)isClearCombo {
	return mKeyCode == -1;
}

@end
