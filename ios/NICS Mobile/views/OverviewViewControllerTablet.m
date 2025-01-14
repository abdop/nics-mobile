/*|~^~|Copyright (c) 2008-2016, Massachusetts Institute of Technology (MIT)
 |~^~|All rights reserved.
 |~^~|
 |~^~|Redistribution and use in source and binary forms, with or without
 |~^~|modification, are permitted provided that the following conditions are met:
 |~^~|
 |~^~|-1. Redistributions of source code must retain the above copyright notice, this
 |~^~|ist of conditions and the following disclaimer.
 |~^~|
 |~^~|-2. Redistributions in binary form must reproduce the above copyright notice,
 |~^~|this list of conditions and the following disclaimer in the documentation
 |~^~|and/or other materials provided with the distribution.
 |~^~|
 |~^~|-3. Neither the name of the copyright holder nor the names of its contributors
 |~^~|may be used to endorse or promote products derived from this software without
 |~^~|specific prior written permission.
 |~^~|
 |~^~|THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 |~^~|AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 |~^~|IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 |~^~|DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 |~^~|FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 |~^~|DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 |~^~|SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 |~^~|CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 |~^~|OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 |~^~|OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\*/
//
//  ViewController.m
//  SidebarDemo
//
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "OverviewViewControllerTablet.h"
#import "IncidentButtonBar.h"

@interface OverviewViewControllerTablet ()

@end

NSNotificationCenter *notificationCenter;

@implementation OverviewViewControllerTablet
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dataManager = [DataManager getInstance];
    [IncidentButtonBar SetOverview:self];
    [_dataManager setOverviewController:self];
    notificationCenter = [NSNotificationCenter defaultCenter];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SetPullTimersFromOptions) name:@"DidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startCollabLoadingSpinner) name:@"collabroomStartedLoading" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopCollabLoadingSpinner) name:@"collabroomFinishedLoading" object:nil];
    
    [self SetPullTimersFromOptions];
    
    self.navigationItem.hidesBackButton = YES;
    
    [_dataManager.locationManager startUpdatingLocation];
    
    _incidentMenu = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Incident", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    _incidentMenu.tag = 50;
    
    NSArray *options = [[[_dataManager getIncidentsList] allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for( NSString *title in options)  {
        [_incidentMenu addButtonWithTitle:title];
    }
    
    [_incidentMenu addButtonWithTitle:@"Cancel"];
    _incidentMenu.cancelButtonIndex = [options count];
        
    NSString *currentIncidentName = [_dataManager getActiveIncidentName];
    if(currentIncidentName != nil){
        _selectedIncident = [[_dataManager getIncidentsList] objectForKey:currentIncidentName];
        if(_selectedIncident != nil){
            [_dataManager requestCollabroomsForIncident:_selectedIncident];
            _selectedIncident.collabrooms = [_dataManager getCollabroomPayloadArray];
//            _selectedCollabroomList = _selectedIncident.collabrooms;
        }
        
    }
    
    NSString *currentRoomName = [_dataManager getSelectedCollabroomName];
    if(currentRoomName != nil){
        for(CollabroomPayload *collabroomPayload in _selectedIncident.collabrooms) {
            if([collabroomPayload.name isEqualToString:currentRoomName]){
                _selectedCollabroom = collabroomPayload;
                [_dataManager setSelectedCollabRoomId:collabroomPayload.collabRoomId  collabRoomName:collabroomPayload.name];
            }
        }
    }
    
    if(_selectedIncident == nil) {
        [_IncidentCanvas setHidden:TRUE];
        [_selectIncidentButton setTitle:NSLocalizedString(@"Select Incident", nil) forState:UIControlStateNormal];
        [_selectRoomButton setHidden:TRUE];
        [_collabroomDownArrowImage setHidden:TRUE];
        [_selectIncidentHelperLabel setHidden:false];
    }else{
        [_IncidentCanvas setHidden:FALSE];
        [_selectRoomButton setHidden:FALSE];
        [_collabroomDownArrowImage setHidden:FALSE];
        [_selectIncidentHelperLabel setHidden:true];
        [_selectIncidentButton setTitle:_selectedIncident.incidentname forState:UIControlStateNormal];
        
        NSNotification *IncidentSwitchedNotification = [NSNotification notificationWithName:@"IncidentSwitched" object:_selectedIncident.incidentname];
        [notificationCenter postNotification:IncidentSwitchedNotification];
        
        [_dataManager requestSimpleReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestDamageReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestFieldReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestResourceRequestsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestMdtRepeatedEvery:[DataManager getMdtUpdateFrequencyFromSettings] immediate:YES];
        [_dataManager requestWfsUpdateRepeatedEvery:[[DataManager getWfsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestWeatherReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
    }
    
    if(_selectedCollabroom == nil){
//        [_RoomCanvas setHidden:TRUE];
        [_selectRoomButton setTitle:NSLocalizedString(@"Select Room", nil) forState:UIControlStateNormal];
    }else{

        [_dataManager setSelectedCollabRoomId:_selectedCollabroom.collabRoomId collabRoomName:_selectedCollabroom.name];
        
        NSString* incidentNameReplace = [_selectedIncident.incidentname stringByAppendingString:@"-"];
        [_selectRoomButton setTitle:[_selectedCollabroom.name stringByReplacingOccurrencesOfString:incidentNameReplace withString:@""] forState:UIControlStateNormal]; forState:UIControlStateNormal;
        
        NSNotification *IncidentSwitchedNotification = [NSNotification notificationWithName:@"CollabRoomSwitched" object:_selectedIncident.incidentname];
        [notificationCenter postNotification:IncidentSwitchedNotification];
        
        [_dataManager requestChatMessagesRepeatedEvery:[[DataManager getChatUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestMarkupFeaturesRepeatedEvery:[[DataManager getMapUpdateFrequencyFromSettings] intValue] immediate:YES];
    }
}

-(void)SetPullTimersFromOptions{
    [_dataManager requestChatMessagesRepeatedEvery:[[DataManager getChatUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestSimpleReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestDamageReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestFieldReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestResourceRequestsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestMarkupFeaturesRepeatedEvery:[[DataManager getMapUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestMdtRepeatedEvery:[DataManager getMdtUpdateFrequencyFromSettings] immediate:NO];
    [_dataManager requestWfsUpdateRepeatedEvery:[[DataManager getWfsUpdateFrequencyFromSettings] intValue] immediate:NO];
    [_dataManager requestWeatherReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:NO];
}

- (IBAction)selectIncidentButtonPressed:(UIButton *)button {
    [_incidentMenu showInView:self.parentViewController.view];
}

- (IBAction)selectRoomButtonPressed:(UIButton *)button {
    
     NSMutableDictionary *collabrooms = [NSMutableDictionary new];
    
    for(CollabroomPayload *collabroomPayload in _selectedIncident.collabrooms) {
        [collabrooms setObject:collabroomPayload.collabRoomId forKey:collabroomPayload.name];
    }
    
    if(_selectedIncident.collabrooms != nil) {
        [_dataManager clearCollabRoomList];
        
        for(CollabroomPayload *payload in _selectedIncident.collabrooms) {
            [_dataManager addCollabroom:payload];
        }
    }
    
    NSArray * sortedCollabrooms = [[collabrooms allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    _collabroomMenu = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Room", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    NSString *replaceString = @"";
    replaceString = [_selectedIncident.incidentname stringByAppendingString:@"-"];
    
    for( NSString *title in sortedCollabrooms)  {
        [_collabroomMenu addButtonWithTitle:[title stringByReplacingOccurrencesOfString:replaceString withString:@""]];
    }
    
    [_collabroomMenu addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    _collabroomMenu.cancelButtonIndex = [sortedCollabrooms count];

    
    [_collabroomMenu showInView:self.parentViewController.view];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_dataManager.locationManager stopUpdatingLocation];
}

//fix for ghosting effect on ios7
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    actionSheet.backgroundColor = [UIColor whiteColor];
    for (UIView *subview in actionSheet.subviews) {
        subview.backgroundColor = [UIColor whiteColor];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *replaceString = @"";
    
    if(actionSheet.tag == 50) {
        if(buttonIndex != _incidentMenu.cancelButtonIndex) {

            _selectedIncident = [[_dataManager getIncidentsList] objectForKey:[actionSheet buttonTitleAtIndex:buttonIndex]];

            [_dataManager requestCollabroomsForIncident:_selectedIncident];
             _selectedIncident.collabrooms = [_dataManager getCollabroomPayloadArray];
            
            [_dataManager setSelectedCollabRoomId:@-1 collabRoomName:@"N/A"];
            _selectedCollabroom = nil;
        }else{
            replaceString = [_selectedIncident.incidentname stringByAppendingString:@"-"];
        }
    } else {
        replaceString = [_selectedIncident.incidentname stringByAppendingString:@"-"];
        if(buttonIndex != _collabroomMenu.cancelButtonIndex) {
            
            
            NSString* selectedRoom = [actionSheet buttonTitleAtIndex:buttonIndex];
            
//            [replaceString stringByAppendingString:
            
            _selectedCollabroom = [[_dataManager getCollabroomList] objectForKey:[[_dataManager getCollabroomNamesList] objectForKey:selectedRoom]];
            
            [_selectRoomButton setHidden:false];
            [_collabroomDownArrowImage setHidden:FALSE];
        }
    }
    
    NSNotification *IncidentSwitchedNotification = nil;
    NSNotification *CollabRoomSwitchedNotification = nil;
    
    if(_selectedIncident != nil) {
        [_dataManager setActiveIncident:_selectedIncident];
        
        [_dataManager requestSimpleReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestDamageReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestFieldReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestResourceRequestsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestMdtRepeatedEvery:[DataManager getMdtUpdateFrequencyFromSettings] immediate:YES];
        [_dataManager requestWfsUpdateRepeatedEvery:[[DataManager getWfsUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestWeatherReportsRepeatedEvery:[[DataManager getReportsUpdateFrequencyFromSettings] intValue] immediate:YES];
        
        [_selectIncidentButton setTitle:_selectedIncident.incidentname forState:UIControlStateNormal];
        IncidentSwitchedNotification = [NSNotification notificationWithName:@"IncidentSwitched" object:_selectedIncident.incidentname];

    } else {
        [_selectIncidentButton setTitle:NSLocalizedString(@"Select Incident", nil) forState:UIControlStateNormal];
        
    }
    
    if(_selectedCollabroom != nil) {
        [_dataManager setSelectedCollabRoomId:_selectedCollabroom.collabRoomId collabRoomName:_selectedCollabroom.name];
        
        [_dataManager requestChatMessagesRepeatedEvery:[[DataManager getChatUpdateFrequencyFromSettings] intValue] immediate:YES];
        [_dataManager requestMarkupFeaturesRepeatedEvery:[[DataManager getMapUpdateFrequencyFromSettings] intValue] immediate:YES];
        
      //  [_selectRoomButton setTitle:_selectedCollabroom.name forState:UIControlStateNormal];
        [_selectRoomButton setTitle:[_selectedCollabroom.name stringByReplacingOccurrencesOfString:replaceString withString:@""] forState:UIControlStateNormal];
         CollabRoomSwitchedNotification = [NSNotification notificationWithName:@"CollabRoomSwitched" object:_selectedCollabroom.name ];
        
    } else {
         [_selectRoomButton setTitle:NSLocalizedString(@"Select Room", nil) forState:UIControlStateNormal];
    }
    if(!_selectedIncident){
        [_selectRoomButton setHidden:true];
        [_collabroomDownArrowImage setHidden:TRUE];
        [_selectIncidentHelperLabel setHidden:false];
    }else{
        [_selectRoomButton setHidden:false];
        [_collabroomDownArrowImage setHidden:false];
        [_IncidentCanvas setHidden:FALSE];
        [_selectIncidentHelperLabel setHidden:true];
    }
    
    if(IncidentSwitchedNotification!=nil){
        [notificationCenter postNotification:IncidentSwitchedNotification];
    }
    if(CollabRoomSwitchedNotification!=nil){
        [notificationCenter postNotification:CollabRoomSwitchedNotification];
    }
}

- (IBAction)nicsHelpButtonPressed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://public.nics.ll.mit.edu/nicshelp/"]];
}

-(void)startCollabLoadingSpinner{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [_collabroomsLoadingIndicator startAnimating];
    });
    
}

-(void)stopCollabLoadingSpinner{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [_collabroomsLoadingIndicator stopAnimating];
        _selectedIncident.collabrooms = [_dataManager getCollabroomPayloadArray];
    });
}

-(void)navigateBackToLoginScreen{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
