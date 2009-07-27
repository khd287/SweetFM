//
//  SysAudio.m
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

#import "SysAudio.h"


float SysAudioGetVolume()
{
	float			b_vol;
	OSStatus		err;
	AudioDeviceID		device;
	UInt32			size;
	UInt32			channels[2];
	float			volume[2];
	
	// get device
	size = sizeof device;
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
	if(err!=noErr) {
		NSLog(@"audio-volume error get device");
		return 0.0;
	}
	
	// try set master volume (channel 0)
	size = sizeof b_vol;
	err = AudioDeviceGetProperty(device, 0, 0, kAudioDevicePropertyVolumeScalar, &size, &b_vol);	//kAudioDevicePropertyVolumeScalarToDecibels
	if(noErr==err) return b_vol;
	
	// otherwise, try seperate channels
	// get channel numbers
	size = sizeof(channels);
	err = AudioDeviceGetProperty(device, 0, 0,kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
	if(err!=noErr) NSLog(@"error getting channel-numbers");
	
	size = sizeof(float);
	err = AudioDeviceGetProperty(device, channels[0], 0, kAudioDevicePropertyVolumeScalar, &size, &volume[0]);
	if(noErr!=err) NSLog(@"error getting volume of channel %d",channels[0]);
	err = AudioDeviceGetProperty(device, channels[1], 0, kAudioDevicePropertyVolumeScalar, &size, &volume[1]);
	if(noErr!=err) NSLog(@"error getting volume of channel %d",channels[1]);
	
	b_vol = (volume[0]+volume[1])/2.00;
	
	return  b_vol;
}

void SysAudioSetVolume(float involume)
{
	OSStatus		err;
	AudioDeviceID		device;
	UInt32			size;
	Boolean			canset	= false;
	UInt32			channels[2];
	//float			volume[2];
	
	// get default device
	size = sizeof device;
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
	if(err!=noErr) {
		NSLog(@"audio-volume error get device");
		return;
	}
	
	
	// try set master-channel (0) volume
	size = sizeof canset;
	err = AudioDeviceGetPropertyInfo(device, 0, false, kAudioDevicePropertyVolumeScalar, &size, &canset);
	if(err==noErr && canset==true) {
		size = sizeof involume;
		err = AudioDeviceSetProperty(device, NULL, 0, false, kAudioDevicePropertyVolumeScalar, size, &involume);
		return;
	}
	
	// else, try seperate channes
	// get channels
	size = sizeof(channels);
	err = AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
	if(err!=noErr) {
		NSLog(@"error getting channel-numbers");
		return;
	}
	
	// set volume
	size = sizeof(float);
	err = AudioDeviceSetProperty(device, 0, channels[0], false, kAudioDevicePropertyVolumeScalar, size, &involume);
	if(noErr!=err) NSLog(@"error setting volume of channel %d",channels[0]);
	err = AudioDeviceSetProperty(device, 0, channels[1], false, kAudioDevicePropertyVolumeScalar, size, &involume);
	if(noErr!=err) NSLog(@"error setting volume of channel %d",channels[1]);
	
}

void SysAudioIncreaseVolume()
{
	float vol = SysAudioGetVolume();
	vol = (vol <= 0.95f) ? vol+0.05f : 1.0f;
	
	SysAudioSetVolume(vol);
}

void SysAudioDecreaseVolume()
{
	float vol = SysAudioGetVolume();
	vol = (vol >= 0.05f) ? vol-0.05f : 0;
	
	SysAudioSetVolume(vol);
}

