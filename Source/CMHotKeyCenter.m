//
//  CMHotKeyCenter.m
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

#import "CMHotKeyCenter.h"
#import "CMHotKey.h"
#import "CMKeyCombo.h"
#import <Carbon/Carbon.h>

@interface CMHotKeyCenter (Private)

- (CMHotKey *)_hotKeyForCarbonHotKey:(EventHotKeyRef)carbonHotKey;
- (EventHotKeyRef)_carbonHotKeyForHotKey:(CMHotKey *)hotKey;

- (void)_updateEventHandler;
- (void)_hotKeyDown: (CMHotKey *)hotKey;
- (void)_hotKeyUp: (CMHotKey *)hotKey;

static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void* refCon);

@end

@implementation CMHotKeyCenter

SYNTHESIZE_SINGLETON_FOR_CLASS(CMHotKeyCenter, sharedCenter);

- (id)init {

	if(self = [super init])	{
		hotKeys = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[hotKeys release];
	[super dealloc];
}

#pragma mark -

- (BOOL)registerHotKeyForIdentifier:(NSString *)idf target:(id)trg action:(SEL)act keyCombo:(CMKeyCombo *)combo {
	
	// Unregister previous hotkeys if any
	[self unregisterHotKeyForIdentifier:idf];
	
	// Register new one...
	CMHotKey *newHotkey = [[CMHotKey alloc] initWithIdentifier:idf keyCombo:combo];
	[newHotkey setTarget:trg];
	[newHotkey setAction:act];
	
	return [self registerHotKey:newHotkey];
}

- (BOOL)registerHotKey:(CMHotKey *)hotKey {
	
	OSStatus err;
	EventHotKeyID hotKeyID;
	EventHotKeyRef carbonHotKey;
	NSValue* key;

	if([[self allHotKeys] containsObject:hotKey] == YES)
		[self unregisterHotKey:hotKey];
	
	if([[hotKey keyCombo] isValidHotKeyCombo] == NO)
		return YES;
	
	hotKeyID.signature = 'HCHk';
	hotKeyID.id = (long)hotKey;
	
	err = RegisterEventHotKey([[hotKey keyCombo] keyCode],
														[[hotKey keyCombo] modifiers],
														hotKeyID,
														GetEventDispatcherTarget(),
														0,
														&carbonHotKey );

	if(err)
		return NO;

	key = [NSValue valueWithPointer: carbonHotKey];
	if( hotKey && key )
		[hotKeys setObject: hotKey forKey: key];

	[self _updateEventHandler];
	
	return YES;
}

- (void)unregisterHotKey:(CMHotKey *)hotKey {
	
	OSStatus err;
	EventHotKeyRef carbonHotKey;
	NSValue* key;
	
	if([[self allHotKeys] containsObject:hotKey] == NO)
		return;
		
	carbonHotKey = [self _carbonHotKeyForHotKey:hotKey];	
	NSAssert(carbonHotKey != nil, @"");

	err = UnregisterEventHotKey(carbonHotKey);
	//Watch as we ignore 'err':

	key = [NSValue valueWithPointer:carbonHotKey];
	[hotKeys removeObjectForKey:key];
	
	[self _updateEventHandler];

	//See that? Completely ignored
}

- (void)unregisterHotKeyForIdentifier:(NSString *)idf {
	CMHotKey *key = [self hotKeyWithIdentifier:idf];
	[self unregisterHotKey:key];
}

- (NSArray *)allHotKeys {
	return [hotKeys allValues];
}

- (CMHotKey *)hotKeyWithIdentifier:(NSString *)ident {
	
	NSEnumerator* hotKeysEnum = [[self allHotKeys] objectEnumerator];
	CMHotKey* hotKey;
	
	if(!ident)
		return nil;
	
	while((hotKey = [hotKeysEnum nextObject]) != nil) {
		if([[hotKey identifier] isEqualToString:ident])
			return hotKey;
	}

	return nil;
}

#pragma mark -

- (CMHotKey *)_hotKeyForCarbonHotKey:(EventHotKeyRef)carbonHotKey {
	NSValue *key = [NSValue valueWithPointer:carbonHotKey];
	return [hotKeys objectForKey:key];
}

- (EventHotKeyRef)_carbonHotKeyForHotKey:(CMHotKey *)hotKey {
	
	NSArray* values;
	NSValue* value;
	
	values = [hotKeys allKeysForObject: hotKey];
	NSAssert( [values count] == 1, @"Failed to find Carbon Hotkey for HotKey" );
	
	value = [values lastObject];
	
	return (EventHotKeyRef)[value pointerValue];
}

- (void)_updateEventHandler {
	
	if([hotKeys count] && eventHandlerInstalled == NO ) {
		EventTypeSpec eventSpec[2] = {
			{ kEventClassKeyboard, kEventHotKeyPressed },
			{ kEventClassKeyboard, kEventHotKeyReleased }
		};    

		InstallEventHandler( GetEventDispatcherTarget(),
												(EventHandlerProcPtr)hotKeyEventHandler, 
												2, eventSpec, nil, nil);
		
		eventHandlerInstalled = YES;
	}
}

- (void)_hotKeyDown:(CMHotKey *)hotKey {
}

- (void)_hotKeyUp:(CMHotKey *)hotKey {
	[hotKey invoke];
}

- (void)sendEvent: (NSEvent*)event {
	
	long subType;
	EventHotKeyRef carbonHotKey;
	
	if([event type] == NSSystemDefined)
	{
		subType = [event subtype];
		
		if( subType == 6 ) //6 is hot key down
		{
			carbonHotKey= (EventHotKeyRef)[event data1]; //data1 is our hot key ref
			if( carbonHotKey != nil )
			{
				CMHotKey* hotKey = [self _hotKeyForCarbonHotKey: carbonHotKey];
				[self _hotKeyDown: hotKey];
			}
		}
		else if( subType == 9 ) //9 is hot key up
		{
			carbonHotKey= (EventHotKeyRef)[event data1];
			if( carbonHotKey != nil )
			{
				CMHotKey* hotKey = [self _hotKeyForCarbonHotKey: carbonHotKey];
				[self _hotKeyUp: hotKey];
			}
		}
	}
}

- (OSStatus)sendCarbonEvent: (EventRef)event {
	
	OSStatus err;
	EventHotKeyID hotKeyID;
	CMHotKey* hotKey;

	NSAssert( GetEventClass( event ) == kEventClassKeyboard, @"Unknown event class" );

	err = GetEventParameter(	event,
								kEventParamDirectObject, 
								typeEventHotKeyID,
								nil,
								sizeof(EventHotKeyID),
								nil,
								&hotKeyID );
	if( err )
		return err;
	

	NSAssert( hotKeyID.signature == 'HCHk', @"Invalid hot key id" );
	NSAssert( hotKeyID.id != 0, @"Invalid hot key id" );

	hotKey = (CMHotKey*)hotKeyID.id;

	switch( GetEventKind( event ) )
	{
		case kEventHotKeyPressed:
			[self _hotKeyDown: hotKey];
		break;

		case kEventHotKeyReleased:
			[self _hotKeyUp: hotKey];
		break;

		default:
			NSAssert( 0, @"Unknown event kind" );
		break;
	}
	
	return noErr;
}

static OSStatus hotKeyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon) {
	return [[CMHotKeyCenter sharedCenter] sendCarbonEvent: inEvent];
}

@end
