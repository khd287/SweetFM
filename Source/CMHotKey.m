//
//  CMHotKey.m
//  SweetFM
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

#import "CMHotKey.h"

#import "CMHotKeyCenter.h"
#import "CMKeyCombo.h"

@implementation CMHotKey

@synthesize identifier, name, target, action, keyCombo;

- (id)init {
	return [self initWithIdentifier:nil keyCombo:nil];
}


- (id)initWithIdentifier:(NSString *)idf keyCombo:(CMKeyCombo *)combo {
	
	if(self = [super init]) {
		self.identifier = idf;
		self.keyCombo = combo;
	}
	
	return self;
}

- (void)dealloc {
	self.identifier = nil;
	self.name = nil;
	self.target = nil;
	self.action = nil;

	[keyCombo release];
	
	[super dealloc];
}

- (void)setKeyCombo:(CMKeyCombo *)combo {
	if(combo == nil)
		combo = [CMKeyCombo clearKeyCombo];	
	
	[keyCombo release];
	keyCombo = [combo retain];
}

- (void)invoke {
	[target performSelector:action withObject:self];
}

- (NSString*)description {
	return [NSString stringWithFormat: @"<%@: %@, %@>", NSStringFromClass([self class]), identifier, keyCombo];
}

@end
