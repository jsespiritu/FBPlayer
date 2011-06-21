/*    
 *    Copyright (c) 2010 LongTail AdSolutions, Inc
 *
 *    This file is part of the Open Video Ads VAST framework.
 *
 *    The VAST framework is free software: you can redistribute it 
 *    and/or modify it under the terms of the GNU General Public License 
 *    as published by the Free Software Foundation, either version 3 of 
 *    the License, or (at your option) any later version.
 *
 *    The VAST framework is distributed in the hope that it will be 
 *    useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with the framework.  If not, see <http://www.gnu.org/licenses/>.
 */
package org.openvideoads.vast {
	import flash.display.DisplayObjectContainer;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.base.EventController;
	import org.openvideoads.regions.config.StageDimensions;
	import org.openvideoads.util.DisplayProperties;
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.vast.config.Config;
	import org.openvideoads.vast.config.ConfigLoadListener;
	import org.openvideoads.vast.config.groupings.ProvidersConfigGroup;
	import org.openvideoads.vast.events.AdNoticeDisplayEvent;
	import org.openvideoads.vast.events.CompanionAdDisplayEvent;
	import org.openvideoads.vast.events.LinearAdDisplayEvent;
	import org.openvideoads.vast.events.NonLinearAdDisplayEvent;
	import org.openvideoads.vast.events.NonLinearSchedulingEvent;
	import org.openvideoads.vast.events.OverlayAdDisplayEvent;
	import org.openvideoads.vast.events.SeekerBarEvent;
	import org.openvideoads.vast.events.StreamSchedulingEvent;
	import org.openvideoads.vast.events.TemplateEvent;
	import org.openvideoads.vast.events.TrackingPointEvent;
	import org.openvideoads.vast.model.CompanionAd;
	import org.openvideoads.vast.model.LinearVideoAd;
	import org.openvideoads.vast.model.NonLinearVideoAd;
	import org.openvideoads.vast.model.TemplateLoadListener;
	import org.openvideoads.vast.model.VideoAdServingTemplate;
	import org.openvideoads.vast.overlay.OverlayController;
	import org.openvideoads.vast.overlay.OverlayView;
	import org.openvideoads.vast.playlist.Playlist;
	import org.openvideoads.vast.playlist.PlaylistController;
	import org.openvideoads.vast.playlist.mrss.MediaRSSPlaylist;
	import org.openvideoads.vast.playlist.xspf.XSPFPlaylist;
	import org.openvideoads.vast.schedule.DurationlessStreamSequence;
	import org.openvideoads.vast.schedule.Stream;
	import org.openvideoads.vast.schedule.StreamSequence;
	import org.openvideoads.vast.schedule.ads.AdSchedule;
	import org.openvideoads.vast.schedule.ads.AdSlot;
	import org.openvideoads.vast.tracking.TimeEvent;
	import org.openvideoads.vast.tracking.TrackingPoint;
	import org.openvideoads.vast.tracking.TrackingTable;
	
	/**
	 * @author Paul Schulz
	 */
	public class VASTController extends EventController implements TemplateLoadListener, ConfigLoadListener {
		public static const RELATIVE_TO_CLIP:String = "relative-to-clip";
		public static const CONTINUOUS:String = "continuous";
		public static const VERSION:String = "v0.5.3 (build 75)";
		
		protected var _streamSequence:StreamSequence = null;
		protected var _adSchedule:AdSchedule = null;
		protected var _overlayLinearVideoAdSlot:AdSlot = null;
		protected var _template:VideoAdServingTemplate = null;
		protected var _overlayController:OverlayController = null;
		protected var _config:Config = new Config();
		protected var _timeBaseline:String = VASTController.RELATIVE_TO_CLIP;
		protected var _trackStreamSlices:Boolean = false; // changed from default of true as this "slicing" is being depreciated
		protected var _visuallyCueingLinearAdClickthroughs:Boolean = true;
		protected var _startStreamSafetyMargin:int = 0;
		protected var _endStreamSafetyMargin:int = 0;	
		protected var _configLoadListener:ConfigLoadListener = null;
		protected var _loadDataOnConfigLoaded:Boolean = false;
		protected var _isLoadingConfig:Boolean = false;		
		protected var _controllingDisplayOfCompanionContent:Boolean = true;
        protected var _previousDivContent:Array = new Array();
        protected var _companionDisplayRegister:Object = new Object();
		
		public function VASTController(config:Config=null, endStreamSafetyMargin:int=0) {
			super();
			if(config != null) initialise(config);
			_endStreamSafetyMargin = endStreamSafetyMargin;
		}
		
		public function initialise(config:Object, loadData:Boolean=false, configLoadListener:ConfigLoadListener=null):void {
			_configLoadListener = configLoadListener;
			_loadDataOnConfigLoaded = loadData;
			
			// Load up the config
			if(config is Config) {
				this.config = config as Config;
			}
            else this.config = new Config(config); 

			if(this.config.outputingDebug()) doLog("Using OVA for AS3 " + VERSION, Debuggable.DEBUG_ALWAYS);

			this.config.setLoadedListener(this);
		}
		
		public function isOVAConfigLoading():Boolean {
			return _isLoadingConfig;
		}
		
		public function onOVAConfigLoaded():void {
			if(this.config.operateWithoutStreamDuration()) {
				_streamSequence = new DurationlessStreamSequence();
				doLog("Scheduler is operating in duration-less mode for show streams", Debuggable.DEBUG_ALL);
			}
			else {
				_streamSequence = new StreamSequence();
				doLog("Scheduler is expecting durations to be specified with the show streams", Debuggable.DEBUG_ALL);
			}

            if(_loadDataOnConfigLoaded) load();
            if(_configLoadListener != null) _configLoadListener.onOVAConfigLoaded();
		}
		
		public function canFireAPICalls():Boolean {
			if(_config != null) {
				return _config.canFireAPICalls;				
			}
			return false;
		}
		
		public function setupFlashContextMenu(displayContainer:DisplayObjectContainer):void { 
			var ova_menu:ContextMenu = new ContextMenu();
			var aboutMenuItem:ContextMenuItem = new ContextMenuItem("About OpenVideoAds.org");
			var debugMenuItem:ContextMenuItem = new ContextMenuItem("Debug OVA Ad Streamer");
 
			aboutMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,  
					function visit_ova(e:Event):void {
						var ova_link:URLRequest = new URLRequest("http://www.openvideoads.org");
						navigateToURL(ova_link, "_parent");
					}
			);
			aboutMenuItem.separatorBefore = false;
 
			ova_menu.hideBuiltInItems();
			ova_menu.customItems.push(aboutMenuItem, debugMenuItem);
			displayContainer.contextMenu = ova_menu; 
		}
		
		public function get controllingDisplayOfCompanionContent():Boolean {
			return _controllingDisplayOfCompanionContent;
		}
		
		public function set controlligDisplayOfCompanionContent(controllingDisplayOfCompanionContent:Boolean):void {
			_controllingDisplayOfCompanionContent = controllingDisplayOfCompanionContent;
		}
		
		public function get stageDimensions():StageDimensions {
			if(_config != null) {
				return _config.stageDimensions;
			}
			else return new StageDimensions();
		}
		
		public function set stageDimensions(stageDimensions:StageDimensions):void {
			if(_config != null) {
				_config.stageDimensions = stageDimensions;
			}
		}
		
		public function hasStageDimensions():Boolean {
			if(_config == null) {
				return false;
			}
			return _config.hasStageDimensions();
		}
		
		public function set endStreamSafetyMargin(endStreamSafetyMargin:int):void {
			_endStreamSafetyMargin = endStreamSafetyMargin;
			doLog("Saftey margin for end of stream time tracking events set to " + _endStreamSafetyMargin + " milliseconds", Debuggable.DEBUG_CONFIG);
		}
		
		public function get endStreamSafetyMargin():int {
			return _endStreamSafetyMargin;
		}

		
		public function set startStreamSafetyMargin(startStreamSafetyMargin:int):void {
			_startStreamSafetyMargin = startStreamSafetyMargin;
			doLog("Saftey margin for start of stream time tracking events set to " + _startStreamSafetyMargin + " milliseconds", Debuggable.DEBUG_CONFIG);
		}
		
		public function get startStreamSafetyMargin():int {
			return _startStreamSafetyMargin;
		}
		
		public function get assessControlBarState():Boolean {
			return _config.assessControlBarState;
		}
		
		public function get playOnce():Boolean {
			return config.playOnce;
		}
		
		public function set trackStreamSlices(trackStreamSlices:Boolean):void {
			_trackStreamSlices = trackStreamSlices;
		}
		
		public function get trackStreamSlices():Boolean {
			return _trackStreamSlices;
		}

		public function autoPlay():Boolean {
			return _config.autoPlay;	
		}
		
        public function get disableControls():Boolean {
        	return _config.disableControls;	
        }
        
        public function get allowPlaylistControl():Boolean {
        	return _config.allowPlaylistControl;
        }
        
		public function setTimeBaseline(timeBaseline:String):void {
			_timeBaseline = timeBaseline;
		}
		
		protected function timeRelativeToClip():Boolean {
			return (_timeBaseline == VASTController.RELATIVE_TO_CLIP);
		}
		
		public function getStreamSequenceIndexGivenOriginatingIndex(originalIndex:int, excludeSlices:Boolean=false, excludeMidRolls:Boolean=false):int {
			if(_streamSequence != null) {
				return _streamSequence.getStreamSequenceIndexGivenOriginatingIndex(originalIndex, excludeSlices, excludeMidRolls);
			}
			return -1;
		}
		
		public function load():void {
			this.config.ensureProvidersAreSet();
			_adSchedule.loadAdsFromAdServers(this);
		}
		
		public function set config(config:Config):void {
			_config = config;

            // Configure the debug level
   			if(_config.debugLevelSpecified()) Debuggable.getInstance().setLevelFromString(_config.debugLevel);
   			if(_config.debuggersSpecified()) Debuggable.getInstance().activeDebuggers = _config.debugger;

            // Now formulate the ad schedule
			_adSchedule = new AdSchedule(this, _streamSequence, _config);
		}
		
		public function get config():Config {
			return _config;
		}

        public function get template():VideoAdServingTemplate {
        	return _template;
        }		
        
		public function get adSchedule():AdSchedule {
			return _adSchedule;
		}
		
		public function get streamSequence():StreamSequence {
			return _streamSequence;
		}
		
		public function get overlayController():OverlayController {
			return _overlayController;
		}
		
		public function resetAdDurationForAdStreamAtIndex(streamIndex:int, newDuration:int):void {
			doLog("Setting new duration and resetting tracking table for ad stream at index " + streamIndex + " - new duration is: " + newDuration, Debuggable.DEBUG_CONFIG);
			if(_streamSequence != null) {
				_streamSequence.resetAdDurationForAdStreamAtIndex(streamIndex, newDuration);
			}
			else doLog("ERROR: Cannot reset duration and tracking table for ad stream at index " + streamIndex + " as the stream sequence is null", Debuggable.DEBUG_CONFIG); 
		}
		
		public function get pauseOnClickThrough():Boolean {
			return _config.pauseOnClickThrough;	
		}

		public function enforceLinearInteractiveAdScaling():Boolean {
			return _config.adsConfig.enforceLinearInteractiveAdScaling;
		}
		
		public function enforceLinearVideoAdScaling():Boolean {
			return _config.adsConfig.enforceLinearVideoAdScaling;
		}
		
		public function deriveAdDurationFromMetaData():Boolean {
			return _config.deriveAdDurationFromMetaData();
		}

		public function deriveShowDurationFromMetaData():Boolean {
			return _config.deriveShowDurationFromMetaData();
		}
		
		public function enableNonLinearAdDisplay(displayProperties:DisplayProperties):void {
			// Load up the overlay controller and pass in the regions that have been defined
			_overlayController = new OverlayController(this, displayProperties, _config.overlaysConfig);
			if(displayProperties.displayObjectContainer != null) displayProperties.displayObjectContainer.addChild(_overlayController);			
//            setupFlashContextMenu(displayProperties.displayObjectContainer);
		}
		
		public function resizeOverlays(resizedProperties:DisplayProperties):void {
			if(_overlayController != null) {
				_overlayController.resize(resizedProperties);
			}
		}
		
		public function handlingNonLinearAdDisplay():Boolean {
			return (_overlayController != null);
		}
		
		public function getTrackingTableForStream(streamIndex:int):TrackingTable {
			if(streamIndex < _streamSequence.length) {
				return _streamSequence.streamAt(streamIndex).getTrackingTable();
			}
			return null;
		}

		public function hideAllOverlays():void {
			if(_overlayController != null) {
				_overlayController.hideAllOverlays();
			}
		}
		
		public function closeActiveAdNotice():void {
			if(_overlayController != null) {
				_overlayController.hideAdNotice();
			}				
		}	
			
		public function closeActiveOverlaysAndCompanions():void {
			// used to clear up any active overlays or companions if the current stream is skipped
			if(_adSchedule != null) _adSchedule.closeActiveOverlaysAndCompanions();
		}
		
		public function getProvider(providerType:String):String {
			return _config.getProvider(providerType);
		}
		
		public function getProviders():ProvidersConfigGroup {
			return _config.providersConfig;
		}

		// Overlay linear video ad playlist API
		
		public function getActiveOverlayXSPFPlaylist():XSPFPlaylist {
			if(!allowPlaylistControl) {
				if(_overlayLinearVideoAdSlot != null) {
					var adStreamSequence:StreamSequence = new StreamSequence(this);
					adStreamSequence.addStream(_overlayLinearVideoAdSlot, false);
					return PlaylistController.createPlaylist(adStreamSequence, PlaylistController.PLAYLIST_FORMAT_XSPF, _config.providersForShows(), _config.providersForAds()) as XSPFPlaylist;			
				}
				else doLog("Cannot play the linear ad for this overlay - no adslot attached to the event - ignoring click", Debuggable.DEBUG_PLAYLIST);
			}
			else doLog("NOTIFICATION: Overlay clicked event ignored as playlistControl is turned on - this feature is not possible", Debuggable.DEBUG_DISPLAY_EVENTS);

			return null;
		}
		
		public function getActiveOverlayStreamSequence():StreamSequence {
			if(!allowPlaylistControl) {
				if(_overlayLinearVideoAdSlot != null) {
					var adStreamSequence:StreamSequence = new StreamSequence(this);
					adStreamSequence.addStream(_overlayLinearVideoAdSlot, false);
					return adStreamSequence;
				}
				else doLog("Cannot play the linear ad for this overlay - no adslot attached to the event - ignoring click", Debuggable.DEBUG_PLAYLIST);
			}
			else doLog("NOTIFICATION: Overlay clicked event ignored as playlistControl is turned on - this feature is not possible", Debuggable.DEBUG_DISPLAY_EVENTS);

			return null;
		}
		
		public function set activeOverlayVideoPlaying(playState:Boolean):void {
			if(_overlayLinearVideoAdSlot != null) {
				_overlayLinearVideoAdSlot.overlayVideoPlaying = playState;
			}					
		}
		
		public function isActiveOverlayVideoPlaying():Boolean {
			if(_overlayLinearVideoAdSlot != null) {
				return _overlayLinearVideoAdSlot.isOverlayVideoPlaying();
			}
			return false;
		}

		public function getActiveOverlayMediaRSSPlaylist():MediaRSSPlaylist {
			return null; // TO BE IMPLEMENTED
		}
		
		// Playlist API
		
		public function createPlaylist(type:int):Playlist {
			return null; // TO BE IMPLEMENTED
		}
		
		public function createXSPFPlaylist():XSPFPlaylist {
			return PlaylistController.createPlaylist(_streamSequence, PlaylistController.PLAYLIST_FORMAT_XSPF, _config.providersForShows(), _config.providersForAds()) as XSPFPlaylist;
		}

		public function createMediaRSSPlaylist():MediaRSSPlaylist {
			return null; // TO BE IMPLEMENTED
		}
				
		// Time Event Handlers
		
		public function processTimeEvent(associatedStreamIndex:int, timeEvent:TimeEvent):void {	
			// we're dealing with an event on the mainline streams and ad slots
			if(_adSchedule != null) {
				_adSchedule.processTimeEvent(associatedStreamIndex, timeEvent, false);												
			}
			if(_streamSequence != null) { // && !timeEvent.isAdOnlyEvent()) {
				_streamSequence.processTimeEvent(associatedStreamIndex, timeEvent, false);
			}
		}

		public function processOverlayLinearVideoAdTimeEvent(overlayAdSlotKey:int, timeEvent:TimeEvent, playingOverlayVideo:Boolean=false):void {
			if(overlayAdSlotKey != -1) {
				if(overlayAdSlotKey < _adSchedule.length) {
					_adSchedule.getSlot(overlayAdSlotKey).processTimeEvent(timeEvent, true);
				}
			}
		}

		public function resetAllAdTrackingPointsAssociatedWithStream(associatedStreamIndex:int):void {
			if(_adSchedule != null && associatedStreamIndex > -1) {
				_adSchedule.resetAllAdTrackingPointsAssociatedWithStream(associatedStreamIndex);
			} 
		}
		
		public function resetAllTrackingPointsAssociatedWithStream(associatedStreamIndex:int):void {
			if(_streamSequence != null && associatedStreamIndex > -1) {
				_streamSequence.resetAllTrackingPointsAssociatedWithStream(associatedStreamIndex);
			}			
		}
		
		public function resetRepeatableStreamTrackingPoints(streamIndex:int):void {
			if(_streamSequence != null && streamIndex > -1) {
				_streamSequence.resetRepeatableTrackingPoints(streamIndex);
			}
		}	
		
		// Regions API support
		
		public function setRegionStyle(regionID:String, cssText:String):String {
			if(_overlayController != null) {
				return _overlayController.setRegionStyle(regionID, cssText);
			}
			else return "-1, Overlay Controller is not active";
		}	
		
		// Javascript API support
		
		public function fireAPICall(... args):* {
			if (ExternalInterface.available && _config.canFireAPICalls) {
				try {
					// there must be a better way to do this
					switch (args.length) {
						case 1: 
							return ExternalInterface.call(args[0]);
						case 2: 
							return ExternalInterface.call(args[0],args[1]);
						case 3: 
							return ExternalInterface.call(args[0],args[1],args[2]);
						case 4: 
							return ExternalInterface.call(args[0],args[1],args[2],args[3]);
						case 5: 
							return ExternalInterface.call(args[0],args[1],args[2],args[3],args[4]);
						case 6: 
							return ExternalInterface.call(args[0],args[1],args[2],args[3],args[4],args[5]);
						case 7: 
							return ExternalInterface.call(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
						case 8: 
							return ExternalInterface.call(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
						case 9: 
							return ExternalInterface.call(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8]);
					}					
				}
				catch(e:Error) {
					doLog("Exception making external call (" + args[0] + ") - " + e);
				}				
			}
		}		

		// Scheduling callback
		
		public function onScheduleStream(scheduleIndex:int, stream:Stream):void {
			if((trackStreamSlices == false) && (stream.isSlicedStream()) && (!stream.isFirstSlice())) {
				// don't notify that this stream slice is to be scheduled
				doLog("Ignoring 'onScheduleStream' request for stream " + stream.url, Debuggable.DEBUG_SEGMENT_FORMATION);
			}	
			else {
				dispatchEvent(new StreamSchedulingEvent(StreamSchedulingEvent.SCHEDULE, scheduleIndex, stream));
				if(stream is AdSlot) {
					fireAPICall("onLinearAdScheduled", scheduleIndex, stream.baseURL, stream.streamName, stream.startTime, stream.duration);
				}
				else fireAPICall("onShowStreamScheduled", scheduleIndex, stream.baseURL, stream.streamName, stream.startTime, stream.duration);
			}
		}

		public function onScheduleNonLinear(adSlot:AdSlot):void {			
			dispatchEvent(new NonLinearSchedulingEvent(NonLinearSchedulingEvent.SCHEDULE, adSlot));
			fireAPICall("onNonLinearAdScheduled", adSlot.associatedStreamIndex, adSlot.startTime, adSlot.duration);
		}
		
		// Tracking Point callbacks
		
		public function onSetTrackingPoint(trackingPoint:TrackingPoint):void {
			if(trackingPoint != null) {
				dispatchEvent(new TrackingPointEvent(TrackingPointEvent.SET, trackingPoint));			
			}
		}

		public function onProcessTrackingPoint(trackingPoint:TrackingPoint):void {
			if(trackingPoint != null) {
				dispatchEvent(new TrackingPointEvent(TrackingPointEvent.FIRED, trackingPoint));
			}
		}
		
		// Linear Ad events
		
		public function onLinearAdStart(adSlot:AdSlot):void {
			dispatchEvent(new LinearAdDisplayEvent(LinearAdDisplayEvent.STARTED, adSlot));	
		}

		public function onLinearAdComplete(adSlot:AdSlot):void {
			dispatchEvent(new LinearAdDisplayEvent(LinearAdDisplayEvent.COMPLETE, adSlot));
		}
		
		public function enableVisualLinearAdClickThroughCue(adSlot:AdSlot):void {
			if(_config.visuallyCueLinearAdClickThrough && adSlot.hasLinearClickThroughs()) {
				overlayController.enableLinearAdMouseOverRegion(adSlot);
			}			
		}
		
		public function disableVisualLinearAdClickThroughCue(adSlot:AdSlot=null):void {
			if(_config.visuallyCueLinearAdClickThrough) overlayController.disableLinearAdMouseOverRegion();			
		}
		
		// TemplateLoadListener callbacks
		
		public function onTemplateLoaded(template:VideoAdServingTemplate):void {
			doLog("VASTController: notified that template has been fully loaded", Debuggable.DEBUG_VAST_TEMPLATE)
			_template = template;
			_adSchedule.mapVASTDataToAdSlots(template);
			_streamSequence.initialise(this, _config.streams, _adSchedule, _config.bestBitrate, _config.baseURL, 100, _config.previewImage);
			_adSchedule.addNonLinearAdTrackingPoints(timeRelativeToClip(), true);
			_adSchedule.fireNonLinearSchedulingEvents();
			dispatchEvent(new TemplateEvent(TemplateEvent.LOADED, _template));
			fireAPICall("onVASTLoadSuccess", template.getRawTemplateData());
		}
		
		public function onTemplateLoadError(event:Event):void {
			doLog("VASTController: FAILURE loading VAST template - " + event.toString(), Debuggable.DEBUG_FATAL);
			dispatchEvent(new TemplateEvent(TemplateEvent.LOAD_FAILED, event));
			fireAPICall("onVASTLoadFailure", event.toString());
		}
		
		// Player tracking control API
		
		public function onPlayerSeek(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false, newTimePoint:Number=0):void {
			// step 1 - close down any active ad slots that are now out of date given the new time
			_adSchedule.closeOutdatedOverlaysAndCompanionsForThisStream(activeStreamIndex, newTimePoint);
			// step 2 - process the new time event
			processTimeEvent(activeStreamIndex, new TimeEvent(newTimePoint, 0));
		}

		public function onPlayerMute(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {
			if(isAdSlotKey) {
				if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
					_adSchedule.getSlot(activeStreamIndex).processMuteEvent();					
				}
			}
			else if(_streamSequence != null) _streamSequence.processMuteEventForStream(activeStreamIndex);
		}

		public function onPlayerUnmute(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {			
			if(isAdSlotKey) {
				if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
					_adSchedule.getSlot(activeStreamIndex).processUnmuteEvent();					
				}				
			}
			else if(_streamSequence != null) _streamSequence.processUnmuteEventForStream(activeStreamIndex);
		}

		public function onPlayerPlay(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {
			// TO IMPLEMENT
		}

		public function onPlayerStop(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {
			if(isAdSlotKey) {
				if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
					_adSchedule.getSlot(activeStreamIndex).processStopStream();					
				}																
			}
			else {
				if(_streamSequence != null) _streamSequence.processStopEventForStream(activeStreamIndex);
				if(handlingNonLinearAdDisplay()) _overlayController.hideAllOverlays();		
			}
		}

		public function onPlayerResize(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {
			if(isAdSlotKey) {
				if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
					_adSchedule.getSlot(activeStreamIndex).processFullScreenEvent();					
				}								
			}
			else if(_streamSequence != null) _streamSequence.processFullScreenEventForStream(activeStreamIndex);
		}

		public function onPlayerFullscreenEntry(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {
			if(isAdSlotKey) {
				if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
					_adSchedule.getSlot(activeStreamIndex).processFullScreenEvent();					
				}								
			}
			else if(_streamSequence != null) _streamSequence.processFullScreenEventForStream(activeStreamIndex);
		}

		public function onPlayerFullscreenExit(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {
			if(isAdSlotKey) {
				if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
					_adSchedule.getSlot(activeStreamIndex).processFullScreenExitEvent();					
				}								
			}
			else if(_streamSequence != null) _streamSequence.processFullScreenExitEventForStream(activeStreamIndex);
		}

		public function onPlayerPause(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {	
			if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
				var adSlot:AdSlot = _adSchedule.getSlot(activeStreamIndex);
				if(adSlot != null) {
					if(_overlayController != null && adSlot.hasLinearClickThroughs()) {
						_overlayController.pauseLinearAdMouseOverRegion();
					}					
				}
			}										
			if(isAdSlotKey && adSlot != null) {
				adSlot.processPauseStream();
			}
			else if(_streamSequence != null) {
				_streamSequence.processPauseEventForStream(activeStreamIndex);
			}
		}

		public function onPlayerResume(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {	
			if(activeStreamIndex > -1 && activeStreamIndex < _adSchedule.length) {
				var adSlot:AdSlot = _adSchedule.getSlot(activeStreamIndex);
				if(adSlot != null) {
					if(_overlayController != null && adSlot.hasLinearClickThroughs()) {
						_overlayController.resumeLinearAdMouseOverRegion();
					}										
				}
			}												
			if(isAdSlotKey && adSlot != null) {
				adSlot.processResumeStream();					
			}
			else if(_streamSequence != null) {
				_streamSequence.processResumeEventForStream(activeStreamIndex);
			}
		}

		public function onPlayerReplay(activeStreamIndex:int=-1, isAdSlotKey:Boolean = false):void {			
			// TO IMPLEMENT
		}

        // SeekerBarDisplayController callbacks
        
		public function onToggleSeekerBar(enable:Boolean):void {
			if(_config.disableControls) {
	 			doLog("Request received to change the control bar state to " + ((!enable) ? "BLOCKED" : "ON"), Debuggable.DEBUG_DISPLAY_EVENTS);
			    dispatchEvent(new SeekerBarEvent(SeekerBarEvent.TOGGLE, enable));			
			}
			else doLog("Ignoring request to change control bar state", Debuggable.DEBUG_DISPLAY_EVENTS);
		}        
        		
		// VideoAdDisplayController callbacks 

		public function onDisplayNonLinearOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			// if the overlay ad has a linear video ad stream attached, create it and have to ready to 
			// go if the overlay is clicked
			if(overlayAdDisplayEvent.ad.hasAccompanyingVideoAd()) {
				_overlayLinearVideoAdSlot = _adSchedule.getSlot(overlayAdDisplayEvent.adSlotKey);
			}
			
			// Now handle the display of the overlay
			if(handlingNonLinearAdDisplay()) _overlayController.displayNonLinearOverlayAd(overlayAdDisplayEvent);
			dispatchEvent(overlayAdDisplayEvent);
			fireAPICall("onNonLinearAdShow");
		}
		
		public function onHideNonLinearOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			if(handlingNonLinearAdDisplay()) _overlayController.hideNonLinearOverlayAd(overlayAdDisplayEvent);
			dispatchEvent(overlayAdDisplayEvent);			
			fireAPICall("onNonLinearAdHide");
		}
		
		public function onDisplayNonLinearNonOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			if(handlingNonLinearAdDisplay()) _overlayController.displayNonLinearNonOverlayAd(overlayAdDisplayEvent);
			dispatchEvent(overlayAdDisplayEvent);			
			fireAPICall("onNonLinearAdShow");
		}
		
		public function onHideNonLinearNonOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			if(handlingNonLinearAdDisplay()) _overlayController.hideNonLinearNonOverlayAd(overlayAdDisplayEvent);
			dispatchEvent(overlayAdDisplayEvent);			
			fireAPICall("onNonLinearAdHide");
		}
		
		public function onShowAdNotice(adNoticeDisplayEvent:AdNoticeDisplayEvent):void {
			if(handlingNonLinearAdDisplay()) _overlayController.showAdNotice(adNoticeDisplayEvent);
			dispatchEvent(adNoticeDisplayEvent);				
			fireAPICall("onAdNoticeShow");
		}
		
		public function onTickAdNotice(adNoticeDisplayEvent:AdNoticeDisplayEvent):void {
			if(handlingNonLinearAdDisplay()) _overlayController.showAdNotice(adNoticeDisplayEvent);
			dispatchEvent(adNoticeDisplayEvent);			
			fireAPICall("onAdNoticeTick");			
		}
		
		public function onHideAdNotice(adNoticeDisplayEvent:AdNoticeDisplayEvent):void {
			if(handlingNonLinearAdDisplay()) _overlayController.hideAdNotice(adNoticeDisplayEvent);
			dispatchEvent(adNoticeDisplayEvent);			
			fireAPICall("onAdNoticeHide");
		}

		public function onOverlayCloseClicked(overlayView:OverlayView):void {
			if(overlayView.activeAdSlotKey > -1) {
				var ad:AdSlot = _adSchedule.getSlot(overlayView.activeAdSlotKey);
				var nonLinearVideoAd:NonLinearVideoAd = _adSchedule.getSlot(overlayView.activeAdSlotKey).getNonLinearVideoAd();
				nonLinearVideoAd.close();
				var event:NonLinearAdDisplayEvent = new OverlayAdDisplayEvent(
									OverlayAdDisplayEvent.CLOSE_CLICKED, 
									nonLinearVideoAd, 
									null, 
									overlayView.activeAdSlotKey, 
									-1, 
									overlayView);									
				dispatchEvent(event);					
			}
			fireAPICall("onRegionCloseClicked");
		}
		
		public function onOverlayClicked(overlayView:OverlayView):void {
			if(overlayView.activeAdSlotKey > -1) {
				var ad:AdSlot = _adSchedule.getSlot(overlayView.activeAdSlotKey);
				var nonLinearVideoAd:NonLinearVideoAd = _adSchedule.getSlot(overlayView.activeAdSlotKey).getNonLinearVideoAd();
				nonLinearVideoAd.clicked();
				var event:NonLinearAdDisplayEvent = new OverlayAdDisplayEvent(
									OverlayAdDisplayEvent.CLICKED, 
									nonLinearVideoAd, 
									null, 
									overlayView.activeAdSlotKey, 
									-1, 
									overlayView);
									
				if(ad.hasLinearAd()) {
					doLog("Non-linear click is triggering the start of a 'click-to-play' linear ad attached to the overlay", Debuggable.DEBUG_CLICKTHROUGH_EVENTS);
					dispatchEvent(event);					
				}
				else {
					if(nonLinearVideoAd.hasClickThroughs()) {
						var clickThroughURL:String = nonLinearVideoAd.firstClickThrough();
						doLog("Non-linear click is triggering a click-through to " + clickThroughURL , Debuggable.DEBUG_CLICKTHROUGH_EVENTS);
						navigateToURL(new URLRequest(clickThroughURL), "_blank");
					}
					else doLog("No action taken on non-linear click - no click-through specified", Debuggable.DEBUG_CLICKTHROUGH_EVENTS);
					dispatchEvent(event);
				}			
			}
			fireAPICall("onRegionClicked");
		}
		
		public function onLinearAdClickThroughCallToActionViewClicked(adSlotKey:int):void {
			var ad:LinearVideoAd = _adSchedule.getSlot(adSlotKey).getLinearVideoAd();
			if(ad != null && ad.hasClickThroughs()) {
				ad.clicked();
				navigateToURL(new URLRequest(ad.firstClickThrough()), "_blank");
				dispatchEvent(new LinearAdDisplayEvent(
									LinearAdDisplayEvent.CLICK_THROUGH, 
									_adSchedule.getSlot(adSlotKey))
				);
			}			
			fireAPICall("onLinearAdClick");
		}
		
		// Forced Impression Firing for blank VAST Ad Responses
		public function processImpressionsToForceFire(overrideIfAlreadyFired:Boolean=false):void {
			if(_adSchedule != null) {
				_adSchedule.processImpressionsToForceFire(overrideIfAlreadyFired);
			}
		}	
			
		// CompanionDisplayController APIs

		protected function registerCompanionBeingDisplayed(companionAd:NonLinearVideoAd, divID:String):void {
			_companionDisplayRegister[divID] = companionAd;
		}

		protected function deregisterCompanionBeingDisplayed(divID:String):void {
			registerCompanionBeingDisplayed(null, divID);
		}
		
		protected function companionIsCurrentlyDisplayed(companionAd:NonLinearVideoAd, divID:String):Boolean {
			if(_companionDisplayRegister[divID] != undefined && _companionDisplayRegister[divID] != null) {
				return CompanionAd(companionAd).matches(_companionDisplayRegister[divID]);
			}
			return false;
		}
		
		public function displayCompanionAd(companionEvent:CompanionAdDisplayEvent):void {	
			if(_previousDivContent == null) _previousDivContent = new Array();
			var companionAd:CompanionAd = companionEvent.ad as CompanionAd;
			var previousContent:String;
        	if(processCompanionsExternally()) {
		     	if(companionEvent.contentIsHTML()) {
	     	   		if(companionEvent.content != null) {
	        			if(companionEvent.content.length > 0) {
							doLog("Calling external javascript to insert companion - " + companionAd.width + "x" + companionAd.height + " creativeType: " + companionAd.creativeType + " resourceType: " + companionAd.resourceType, Debuggable.DEBUG_DISPLAY_EVENTS);
							if(!companionIsCurrentlyDisplayed(companionEvent.ad, companionEvent.divID)) {
								try {
									previousContent = ExternalInterface.call("ova.readHTML", companionEvent.divID);
									_previousDivContent.push({ divId: companionEvent.divID, content: previousContent } );
									registerCompanionBeingDisplayed(companionEvent.ad, companionEvent.divID);
									ExternalInterface.call("ova.writeCompanion", 
								                           companionEvent.divID, 
								                           companionEvent.content);								
								}
								catch(e:Error) {
									doLog("Exception attempting to insert the companion code - " + e.message, Debuggable.DEBUG_FATAL);					
								}
							}
							else doLog("Not writing companion content - it's already active in the DIV", Debuggable.DEBUG_DISPLAY_EVENTS);
	       				}
	       				else doLog("No displaying companion - 0 length", Debuggable.DEBUG_DISPLAY_EVENTS);
	      			}
        			else doLog("No displaying companion - null length", Debuggable.DEBUG_DISPLAY_EVENTS);       				
      			}
       			else if(companionEvent.contentIsSWF()) {
       				doLog("SWF content type not supported - should always be output as HTML - if this error comes up, something serious is wrong", Debuggable.DEBUG_FATAL);
       			}
	        	else doLog("Companion content type not supported", Debuggable.DEBUG_FATAL); 
        	}
        	else {
	        	if(companionEvent.contentIsHTML()) {
	        		if(companionEvent.content != null) {
	        			if(companionEvent.content.length > 0) {
							if(!companionIsCurrentlyDisplayed(companionEvent.ad, companionEvent.divID)) {
								try {
									previousContent = ExternalInterface.call("function() { return document.getElementById('" + companionEvent.divID + "').innerHTML; }");
									_previousDivContent.push({ divId: companionEvent.divID, content: previousContent } );
									registerCompanionBeingDisplayed(companionEvent.ad, companionEvent.divID);
									ExternalInterface.call("function(){ document.getElementById('" + 
									                        companionEvent.divID + 
									                        "').innerHTML='" + 
									                        StringUtils.doubleEscapeSingleQuotes(StringUtils.removeNewlines(companionEvent.content)) + 
									                        "'; }");
								}
								catch(e:Error) {
									doLog("Exception attempting to insert the companion code - " + e.message, Debuggable.DEBUG_FATAL);					
								}
							}
							else doLog("Not writing companion content - it's already active in the DIV", Debuggable.DEBUG_DISPLAY_EVENTS);
	        			}
	        			else doLog("No displaying companion - 0 length", Debuggable.DEBUG_DISPLAY_EVENTS);
	        		}
        			else doLog("No displaying companion - null length", Debuggable.DEBUG_DISPLAY_EVENTS);
	        	}
	        	else doLog("Companion content type not supported", Debuggable.DEBUG_FATAL); 
        	}
		}

		public function restoreCompanionDivs(companionEvent:CompanionAdDisplayEvent):void {
			var companionAd:CompanionAd = companionEvent.ad as CompanionAd;
        	if(processCompanionsExternally()) {
				doLog("Calling external javascript to hide companion ad: " + companionAd.id, Debuggable.DEBUG_DISPLAY_EVENTS);        		
			    for(var i:int=_previousDivContent.length-1; i >= 0; i--) { 
			    	deregisterCompanionBeingDisplayed(_previousDivContent[i].divId);
			    	try {
					    ExternalInterface.call("ova.writeHTML", _previousDivContent[i].divId, _previousDivContent[i].content);
					}
					catch(e:Error) {
						doLog("Exception attempting to restore the companion code - " + e.message, Debuggable.DEBUG_FATAL);					
					}
				}
        	}
        	else {
				doLog("Event trigger received to hide the companion Ad with ID " + companionAd.id, Debuggable.DEBUG_DISPLAY_EVENTS);
			    for(var j:int=_previousDivContent.length-1; j >= 0; j--) { 
			    	deregisterCompanionBeingDisplayed(_previousDivContent[i].divId);
					try {
						ExternalInterface.call("function(){ document.getElementById('" + _previousDivContent[j].divId + "').innerHTML='" + StringUtils.removeControlChars(_previousDivContent[j].content) + "'; }");				
					}
					catch(e:Error) {
						doLog("Exception attempting to restore the companion code - " + e.message, Debuggable.DEBUG_FATAL);					
					}
				}
        	}
			_previousDivContent = new Array();            			
		}

		public function displayingCompanions():Boolean {
			return _config.displayCompanions;
		}
		
		public function processCompanionsExternally():Boolean {
			return _config.processCompanionsExternally;
		}

		protected function matchAndDisplayCompanion(companionAd:CompanionAd, companionDivID:Object):Boolean {
			var matchFound:Boolean = false;
			var matched:Boolean = false;
			if(companionDivID.resourceType != undefined && companionDivID.creativeType == undefined) {
				doLog("Refining companion matching to " + companionDivID.width + "x" + companionDivID.height + " and resourceType:" + companionDivID.resourceType, Debuggable.DEBUG_DISPLAY_EVENTS);
				matched = companionAd.matchesSizeAndResourceType(companionDivID.width, companionDivID.height, companionDivID.resourceType);							
			}
			else if(companionDivID.index != undefined) {
				doLog("Refining companion matching to " + companionDivID.width + "x" + companionDivID.height + " and index:" + companionDivID.index, Debuggable.DEBUG_DISPLAY_EVENTS);
				matched = companionAd.matchesSizeAndIndex(companionDivID.width, companionDivID.height, companionDivID.index);
			}
			else if(companionDivID.creativeType != undefined && companionDivID.resoruceType != undefined) {
				doLog("Refining companion matching to " + companionDivID.width + "x" + companionDivID.height + " and creativeType: " + companionDivID.creativeType + " resourceType:" + companionDivID.resourceType, Debuggable.DEBUG_DISPLAY_EVENTS);
				matched = companionAd.matchesSizeAndTypes(companionDivID.width, companionDivID.height, companionDivID.creativeType, companionDivID.resourceType);						
			}
			else {
				matched = companionAd.matchesSize(companionDivID.width, companionDivID.height);
			}

			if(matched) {
				matchFound = true;
				doLog("Found a match for " + companionDivID.width + "," + companionDivID.height + " - id of matching DIV is " + companionDivID.id, Debuggable.DEBUG_DISPLAY_EVENTS);
				var newHtml:String = companionAd.getMarkup();
				if(newHtml != null) {
					var cde:CompanionAdDisplayEvent = new CompanionAdDisplayEvent(CompanionAdDisplayEvent.DISPLAY, companionAd);
					cde.divID = companionDivID.id;
					cde.content = newHtml;
					companionDivID.activeAdID = companionAd.parentAdContainer.id;
					if(this.controllingDisplayOfCompanionContent) {
						displayCompanionAd(cde);
					}
					else dispatchEvent(cde);
					fireAPICall("onCompanionAdShow");
				}
			}			
			return matchFound;
		}
		
		protected function displayCompanionsWithDelay(companionAd:CompanionAd, companionDivIDs:Array, delay:int):void {
			doLog("Displaying companions with a " + delay + " millisecond delay", Debuggable.DEBUG_DISPLAY_EVENTS);			
			var matchFound:Boolean = false;
			var displayTimer:Timer = new Timer(delay, companionDivIDs.length);
			var tickCounter:int = 0;
		    displayTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
				if(matchAndDisplayCompanion(companionAd, companionDivIDs[tickCounter])) matchFound = true;
				++tickCounter;
		    });
		    displayTimer.start();			
			if(!matchFound) doLog("No DIV match found for sizing (" + companionAd.width + "," + companionAd.height + ")", Debuggable.DEBUG_DISPLAY_EVENTS);				
		}

		protected function displayCompanionsWithoutDelay(companionAd:CompanionAd, companionDivIDs:Array):void {
			doLog("Displaying companions without a delay", Debuggable.DEBUG_DISPLAY_EVENTS);
			var matchFound:Boolean = false;
			for(var i:int=0; i < companionDivIDs.length; i++) {
				if(matchAndDisplayCompanion(companionAd, companionDivIDs[i])) matchFound = true;
			}
			if(!matchFound) doLog("No DIV match found for sizing (" + companionAd.width + "," + companionAd.height + ")", Debuggable.DEBUG_DISPLAY_EVENTS);				
		}

		public function onDisplayCompanionAd(companionEvent:CompanionAdDisplayEvent):void {
            doLogAndTrace("Request received to display companion ad", companionEvent, Debuggable.DEBUG_DISPLAY_EVENTS);
			var companionAd:CompanionAd = companionEvent.ad as CompanionAd;
			if(_config.hasCompanionDivs()) {
				var companionDivIDs:Array = _config.companionDivIDs;
				doLog("Event trigger received by companion Ad with ID " + companionAd.id + " - looking for a div to match the sizing (" + companionAd.width + "," + companionAd.height + ")", Debuggable.DEBUG_DISPLAY_EVENTS);
				if(_config.delayingCompanionInjection()) {
					displayCompanionsWithDelay(companionAd, companionDivIDs, _config.millisecondDelayOnCompanionInjection);
				}
				else displayCompanionsWithoutDelay(companionAd, companionDivIDs);
			}
			else doLog("No DIVS specified for companion ads to be displayed", Debuggable.DEBUG_DISPLAY_EVENTS);           				
		}
				
		public function onHideCompanionAd(companionEvent:CompanionAdDisplayEvent):void {
			if(_config.restoreCompanions) {
				if(this.controllingDisplayOfCompanionContent) {
					restoreCompanionDivs(companionEvent);
				}
				else dispatchEvent(new CompanionAdDisplayEvent(CompanionAdDisplayEvent.HIDE, companionEvent.ad as CompanionAd));				
  				fireAPICall("onCompanionAdHide");
			}
		}
		
		// Ad Notice Countdown Timer processing
		
		public function onProcessAdNoticeCountdownTick():void {			
		}
		
		// Event registration - region based events must be registered with the overlay(region) controller
		
        public override function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
        	if(type.indexOf("region-") > -1) {
        		if(_overlayController != null) {
        			_overlayController.addEventListener(type, listener, useCapture, priority, useWeakReference);
        		}
        	}
        	else super.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }
        
        public override function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
        	if(type.indexOf("region-") > -1) {
        		if(_overlayController != null) {
        			_overlayController.addEventListener(type, listener, useCapture);
        		}
        	}
        	else super.removeEventListener(type, listener, useCapture);
        }		
        
        public function getVASTResponseAsString():String {
        	if(_template != null) {
        		return _template.getRawTemplateData();
        	}
        	else return "No VAST response available";
        }
	}
}