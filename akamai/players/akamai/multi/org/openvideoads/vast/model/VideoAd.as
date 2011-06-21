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
package org.openvideoads.vast.model {
	import flash.external.ExternalInterface;
	import flash.utils.ByteArray;
	
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.util.NetworkResource;
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.util.Timestamp;
	import org.openvideoads.vast.events.VideoAdDisplayEvent;
	
	/**
	 * @author Paul Schulz
	 */
	public class VideoAd extends Debuggable {
		protected var _id:String;
		protected var _inlineAdId:String = null;
		protected var _adId:String = null;
		protected var _sequenceId:String;
		protected var _creativeId:String;
		protected var _adSystem:String;
		protected var _adTitle:String;
		protected var _description:String;
		protected var _survey:String;
		protected var _error:String;
		protected var _impressions:Array = new Array();			
		protected var _trackingEvents:Array = new Array();		
		protected var _linearVideoAd:LinearVideoAd = null;
		protected var _nonLinearVideoAds:Array  = new Array();
		protected var _companionAds:Array  = new Array();
		protected var _forceImpressionServing:Boolean = false;
		protected var _impressionsFired:Boolean = false;
		protected var _indexCounters:Array = new Array();
		protected var _canFireAPICalls:Boolean = true;

		public static const AD_TYPE_LINEAR:String = "linear";
		public static const AD_TYPE_NON_LINEAR:String = "non-linear";
		public static const AD_TYPE_COMPANION:String = "companion";
		public static const AD_TYPE_UNKNOWN:String = "unknown";

		public function VideoAd() {
		}
		
		public function setCanFireAPICalls(canFireAPICalls:Boolean):void {
			_canFireAPICalls = canFireAPICalls;
		}
		
		public function canFireAPICalls():Boolean {
			return _canFireAPICalls;
		}
		
		protected function clearIndexCounters():void {
			_indexCounters = new Array();
		}
		
		protected function createIndex(width:int, height:int):int {
			for(var i:int = 0; i < _indexCounters.length; i++) {
				if(_indexCounters[i].width == width && _indexCounters[i].height == height) {
					_indexCounters[i].index = _indexCounters[i].index + 1;
					return _indexCounters[i].index;
				}
			}
			_indexCounters.push({ width: width, height: height, index: 0});
			return 0;
		}

        /* V1.0 PARSING METHODS ******************************************************************************/
		
        public function parseImpressions(ad:XML):void {
			doLog("Parsing V1 impression tags...", Debuggable.DEBUG_VAST_TEMPLATE);
			if(ad.Impression != null && ad.Impression.children() != null) {
				var impressions:XMLList = ad.Impression.children();
				for(var i:int = 0; i < impressions.length(); i++) {
					this.addImpression(new Impression(impressions[i].id, impressions[i].text()));
				}
			}
			doLog(_impressions.length + " impressions recorded", Debuggable.DEBUG_VAST_TEMPLATE);        	
        }        
        	
        public function parseTrackingEvents(ad:XML):void {
			doLog("Parsing V1 TrackingEvent tags...", Debuggable.DEBUG_VAST_TEMPLATE);
			if(ad.TrackingEvents != null && ad.TrackingEvents.children() != null) {
				var trackingEvents:XMLList = ad.TrackingEvents.children();
				doLog(trackingEvents.length() + " tracking events specified", Debuggable.DEBUG_VAST_TEMPLATE);
				for(var i:int = 0; i < trackingEvents.length(); i++) {
					var trackingEventXML:XML = trackingEvents[i];
					var trackingEvent:TrackingEvent = new TrackingEvent(trackingEventXML.@event);
					var trackingEventURLs:XMLList = trackingEventXML.children();
					for(var j:int = 0; j < trackingEventURLs.length(); j++) {
						var trackingEventURL:XML = trackingEventURLs[j];
						trackingEvent.addURL(new NetworkResource(trackingEventURL.@id, trackingEventURL.text()));
					}
					this.addTrackingEvent(trackingEvent);				
				}
			} 
        }
        	
        public function parseLinears(ad:XML, index:int=-1):void {
			doLog("Parsing V1 Linear Ad tags...", Debuggable.DEBUG_VAST_TEMPLATE);
			var linearVideoAd:LinearVideoAd = new LinearVideoAd();
			linearVideoAd.adID = ad.Video.AdID;
			linearVideoAd.index = index;
			if(Timestamp.validate(ad.Video.Duration)) {
				linearVideoAd.duration = ad.Video.Duration;
			}
			else {
				linearVideoAd.duration = Timestamp.secondsStringToTimestamp(ad.Video.Duration);
				doLog("Duration has been specified in non-compliant manner (hh:mm:ss) - assuming seconds - converted to: " + linearVideoAd.duration, Debuggable.DEBUG_VAST_TEMPLATE);
			}
			if(ad.Video.VideoClicks != undefined) {
				var clickList:XMLList;
				var clickURL:XML;
				var i:int=0;
				if(ad.Video.VideoClicks.ClickThrough.children().length() > 0) {
					doLog("Parsing V1 VideoClicks ClickThrough tags...", Debuggable.DEBUG_VAST_TEMPLATE);
					clickList = ad.Video.VideoClicks.ClickThrough.children();
					for(i = 0; i < clickList.length(); i++) {
						clickURL = clickList[i];
						if(!StringUtils.isEmpty(clickURL.text())) {
							linearVideoAd.addClickThrough(new NetworkResource(clickURL.@id, clickURL.text()));
						}
					}
				}
				if(ad.Video.VideoClicks.ClickTracking.children().length() > 0) {
					doLog("Parsing V1 VideoClicks ClickTracking tags...", Debuggable.DEBUG_VAST_TEMPLATE);
					clickList = ad.Video.VideoClicks.ClickTracking.children();
					for(i = 0; i < clickList.length(); i++) {
						clickURL = clickList[i];
						if(!StringUtils.isEmpty(clickURL.text())) {
							linearVideoAd.addClickTrack(new NetworkResource(clickURL.@id, clickURL.text()));
						}
					}
				}
				if(ad.Video.VideoClicks.CustomClick.children().length() > 0) {
					doLog("Parsing V1 VideoClicks CustomClick tags...", Debuggable.DEBUG_VAST_TEMPLATE);
					clickList = ad.Video.CustomClick.ClickTracking.children();
					for(i = 0; i < clickList.length(); i++) {
						clickURL = clickList[i];
						if(!StringUtils.isEmpty(clickURL.text())) {
							linearVideoAd.addCustomClick(new NetworkResource(clickURL.@id, clickURL.text()));
						}
					}
				}
			}
			if(ad.Video.MediaFiles != undefined) {
				doLog("Parsing V1 MediaFiles tags...", Debuggable.DEBUG_VAST_TEMPLATE);
				var mediaFiles:XMLList = ad.Video.MediaFiles.children();
				for(i = 0; i < mediaFiles.length(); i++) {
					var mediaFileXML:XML = mediaFiles[i];
					var mediaFile:MediaFile = new MediaFile();
					mediaFile.id = mediaFileXML.@id; 
					mediaFile.bandwidth = mediaFileXML.@bandwidth; 
					mediaFile.delivery = mediaFileXML.@delivery; 
					mediaFile.mimeType = mediaFileXML.@type; 
					mediaFile.bitRate = int(mediaFileXML.@bitrate); 
					mediaFile.width = mediaFileXML.@width; 
					mediaFile.height = mediaFileXML.@height; 
					mediaFile.scale = mediaFileXML.@scalable; 
					mediaFile.maintainAspectRatio = mediaFileXML.@maintainAspectRatio; 
					if(mediaFileXML.children().length() > 0) {
						var mediaFileURLXML:XML = mediaFileXML.children()[0];
						mediaFile.url = new NetworkResource(mediaFileURLXML.@id, mediaFileURLXML.text());
					}
					linearVideoAd.addMediaFile(mediaFile);
				}					
			}
			this.linearVideoAd = linearVideoAd;
        }	
        
        public function parseNonLinears(ad:XML, index:int=-1):void {
			doLog("Parsing V1 NonLinearAd tags...", Debuggable.DEBUG_VAST_TEMPLATE);
			var nonLinearAds:XMLList = ad.NonLinearAds.children();
			var i:int=0;
			doLog(nonLinearAds.length() + " non-linear ads specified", Debuggable.DEBUG_VAST_TEMPLATE);
			for(i = 0; i < nonLinearAds.length(); i++) {
				var nonLinearAdXML:XML = nonLinearAds[i];
				var nonLinearAd:NonLinearVideoAd = null;
				switch(nonLinearAdXML.@resourceType.toUpperCase()) {
					case "HTML":
						doLog("Creating NonLinearHtmlAd()", Debuggable.DEBUG_VAST_TEMPLATE);
						nonLinearAd = new NonLinearHtmlAd();
						break;
					case "TEXT":
						doLog("Creating NonLinearTextAd()", Debuggable.DEBUG_VAST_TEMPLATE);
						nonLinearAd = new NonLinearTextAd();
						break;
					case "STATIC":
						if(nonLinearAdXML.@creativeType != undefined && nonLinearAdXML.@creativeType != null) {
							switch(nonLinearAdXML.@creativeType.toUpperCase()) {
								case "IMAGE/JPEG":
								case "JPEG":
								case "IMAGE/GIF":
								case "GIF":
								case "IMAGE/PNG":
								case "PNG":
								    doLog("Creating NonLinearImageAd()", Debuggable.DEBUG_VAST_TEMPLATE);
									nonLinearAd = new NonLinearImageAd();
									break;
								case "APPLICATION/X-SHOCKWAVE-FLASH":
								case "SWF":
								    doLog("Creating NonLinearFlashAd()", Debuggable.DEBUG_VAST_TEMPLATE);
									nonLinearAd = new NonLinearFlashAd();
									break;
								default:
								    doLog("Creating NonLinearVideoAd()", Debuggable.DEBUG_VAST_TEMPLATE);
									nonLinearAd = new NonLinearVideoAd();
							}									
						}
						else nonLinearAd = new NonLinearVideoAd();
						break;
					default:
						nonLinearAd = new NonLinearVideoAd();
				}
				nonLinearAd.index = index;
				nonLinearAd.id = nonLinearAdXML.@id;
				nonLinearAd.width = nonLinearAdXML.@width;
				nonLinearAd.height = nonLinearAdXML.@height; 
				nonLinearAd.resourceType = nonLinearAdXML.@resourceType; 
				nonLinearAd.creativeType = nonLinearAdXML.@creativeType; 
				nonLinearAd.apiFramework = nonLinearAdXML.@apiFramework; 
				if(nonLinearAdXML.URL != undefined) nonLinearAd.url = new NetworkResource(null, nonLinearAdXML.URL.text());
				if(nonLinearAdXML.Code != undefined) {
					nonLinearAd.codeBlock = nonLinearAdXML.Code.text();
				}
				if(nonLinearAdXML.NonLinearClickThrough != undefined) {
					var nlClickList:XMLList = nonLinearAdXML.NonLinearClickThrough.children();
					var nlClickURL:XML;
					for(i = 0; i < nlClickList.length(); i++) {
						nlClickURL = nlClickList[i];
						nonLinearAd.addClickThrough(new NetworkResource(nlClickURL.@id, nlClickURL.text()));
					}							
				}
				this.addNonLinearVideoAd(nonLinearAd);
			}
        }
        
        public function parseCompanions(ad:XML):void {
			doLog("Parsing V1 CompanionAd tags...", Debuggable.DEBUG_VAST_TEMPLATE);
			var companionAds:XMLList = ad.CompanionAds.children();
			var i:int=0;
			doLog(companionAds.length() + " companions specified", Debuggable.DEBUG_VAST_TEMPLATE);
			clearIndexCounters();
			for(i = 0; i < companionAds.length(); i++) {
				var companionAdXML:XML = companionAds[i];
				var companionAd:CompanionAd = new CompanionAd(this);
				companionAd.id = companionAdXML.@id;
				companionAd.width = companionAdXML.@width;
				companionAd.height = companionAdXML.@height; 
				companionAd.index = createIndex(companionAd.width, companionAd.height);
				if(companionAdXML.@resourceType != undefined) {
					companionAd.resourceType = companionAdXML.@resourceType; 
				}
				else companionAd.resourceType = "static";
				if(companionAdXML.@creativeType != undefined) companionAd.creativeType = companionAdXML.@creativeType;
				if(companionAdXML.URL != undefined) companionAd.url = new NetworkResource(null, companionAdXML.URL.text());
				if(companionAdXML.Code != undefined) {
					companionAd.codeBlock = companionAdXML.Code.text();							
				}
				if(companionAdXML.CompanionClickThrough != undefined) {
					var caClickList:XMLList = companionAdXML.CompanionClickThrough.children();
					var caClickURL:XML;
					for(var j:int = 0; j < caClickList.length(); j++) {
						caClickURL = caClickList[j];
						companionAd.addClickThrough(new NetworkResource(caClickURL.@id, caClickURL.text()));
					}							
				}
				this.addCompanionAd(companionAd);						 						
			}					
        }

        public function parseExtensions(ad:XML):void {
			doLog("Parsing V1.0 extension tags...", Debuggable.DEBUG_VAST_TEMPLATE);
        }

        /* HELPER METHODS ***********************************************************************************/
        
		protected function clone(source:Object):* {
		    var myBA:ByteArray = new ByteArray();
		    myBA.writeObject(source);
		    myBA.position = 0;
		    return(myBA.readObject());
		}        
		
		public function set id(id:String):void {
			_id = id;
		}
		
		public function get id():String {
			return _id;
		}

		public function set adId(adId:String):void {
			_adId = adId;
		}
		
		public function get adId():String {
			return _adId;
		}

		public function set inlineAdId(inlineAdId:String):void {
			_inlineAdId = inlineAdId;
		}
		
		public function get inlineAdId():String {
			return _inlineAdId;
		}
		
		public function belongsToInlineAd(idToMatch:String):Boolean {
			return (_inlineAdId == idToMatch);
		}

		public function set creativeId(creativeId:String):void {
			_creativeId = creativeId;
		}
		
		public function get creativeId():String {
			return _creativeId;
		}

		public function set sequenceId(sequenceId:String):void {
			_sequenceId = sequenceId;
		}
		
		public function get sequenceId():String {
			return _sequenceId;
		}
		
		public function set adSystem(adSystem:String):void {
			_adSystem = adSystem;
		}
		
		public function get adSystem():String {
			return _adSystem;
		}
		
		public function get duration():int {
			if(_linearVideoAd != null) {
				return Timestamp.timestampToSeconds(_linearVideoAd.duration);
			}
			else if(hasNonLinearAds()) {
				if(_nonLinearVideoAds[0].hasRecommendedMinDuration()) {
					return _nonLinearVideoAds[0].recommendedMinDuration;
				}
			}
			return 0;
		}
		
		public function getDurationGivenRecommendation(recommendedDuration:int):int {
			var recordedDuration:int = duration;
			if(recordedDuration == 0 && recommendedDuration > 0) {
				return recommendedDuration;
			}
			return recordedDuration;
		}
		
		public function set adTitle(adTitle:String):void {
			_adTitle = adTitle;
		}
		
		public function get adTitle():String {
			return _adTitle;
		}
		
		public function set description(description:String):void {
			_description = description;
		}
		
		public function get description():String {
			return _description;
		}
		
		public function set survey(survey:String):void {
			_survey = survey;
		}
		
		public function get survey():String {
			return _survey;
		}
		
		public function set error(error:String):void {
			_error = error;
		}
		
		public function get error():String {
			return _error;
		}
		
		public function set impressions(impressions:Array):void {
			_impressions = impressions;
		}
		
		public function get impressions():Array {
			return _impressions;
		}
		
		public function addImpression(impression:NetworkResource):void {
			_impressions.push(impression);
		}
		
		public function set forceImpressionServing(forceImpressionServing:Boolean):void {
			_forceImpressionServing = forceImpressionServing;
		}
		
		public function get forceImpressionServing():Boolean {
			return _forceImpressionServing;
		}
		
		public function setLinearAdDurationFromSeconds(durationAsSeconds:int):void {
			if((_linearVideoAd != null)) {
				_linearVideoAd.setDurationFromSeconds(durationAsSeconds);
			}
			else doLog("ERROR: Cannot change the duration for this linear ad - it does not have a linear ad attached", Debuggable.DEBUG_CONFIG);
		}		
		
		public function set trackingEvents(trackingEvents:Array):void {
			_trackingEvents = trackingEvents;
		}
		
		public function get trackingEvents():Array {
			return _trackingEvents;
		}
		
		public function addTrackingEvent(trackEvent:TrackingEvent):void {
			_trackingEvents.push(trackEvent);
		}
		
		public function set linearVideoAd(linearVideoAd:LinearVideoAd):void {
			linearVideoAd.parentAdContainer = this;
			_linearVideoAd = linearVideoAd;
		}
		
		public function get linearVideoAd():LinearVideoAd {
			return _linearVideoAd;
		}
		
		public function set nonLinearVideoAds(nonLinearVideoAds:Array):void {
			if(nonLinearVideoAds != null) {
				for each(var nonLinearVideoAd:NonLinearVideoAd in nonLinearVideoAds) {
					addNonLinearVideoAd(nonLinearVideoAd);
				}				
			}
			_nonLinearVideoAds = nonLinearVideoAds;
		}
		
		public function get nonLinearVideoAds():Array {
			return _nonLinearVideoAds;
		}
		
		public function get firstNonLinearVideoAd():NonLinearVideoAd {
			if(hasNonLinearAds()) {
				return _nonLinearVideoAds[0];
			}
			else return null;
		}
		
		public function addNonLinearVideoAd(nonLinearVideoAd:NonLinearVideoAd):void {
			nonLinearVideoAd.parentAdContainer = this;
			_nonLinearVideoAds.push(nonLinearVideoAd);
		}
		
		public function hasNonLinearAds():Boolean {
			if(_nonLinearVideoAds.length == 0) {
				return false;
			}
			else {
				for(var i:int=0; i < _nonLinearVideoAds.length; i++) {
					if(!_nonLinearVideoAds[i].isEmpty()) {
						return true;
					}
				}
			}
			return false;
		}

		public function hasLinearAd():Boolean {
			return (_linearVideoAd != null);
		}
		
		public function set companionAds(companionAds:Array):void {
			_companionAds = companionAds;
		}
		
		public function get companionAds():Array {
			return _companionAds;
		}
		
		public function addCompanionAd(companionAd:CompanionAd):void {
			_companionAds.push(companionAd);
		}
		
		public function hasCompanionAds():Boolean {
			return (_companionAds.length > 0);
		}

		public function isLinear():Boolean {
			return (_linearVideoAd != null);	
		}
		
		public function isNonLinear():Boolean {
			return (_linearVideoAd == null && (_nonLinearVideoAds.length > 0));	
		}
		
		public function isCompanion():Boolean {
			return (!isLinear() && !isNonLinear());
		}
		
		public function get adType():String {
			if(isLinear()) {
				return AD_TYPE_LINEAR;
			}
			else if(isNonLinear()) {
				return AD_TYPE_NON_LINEAR;
			}
			else if(isCompanion()) {
				return AD_TYPE_COMPANION;
			}
			else return AD_TYPE_UNKNOWN;			
		}
		
		public function getStreamToPlay(deliveryType:String, mimeType:String, bitrate:* = -1, width:int = -1, height:int = -1):NetworkResource {
			if(isLinear() || (isNonLinear() && hasLinearAd())) {
				return _linearVideoAd.getStreamToPlay(deliveryType, mimeType, bitrate, width, height);
			}
			return null;
		}
		
		public function canScale(deliveryType:String, mimeType:String, bitrate:* = -1, width:int = -1, height:int = -1):Boolean {
			if(hasLinearAd()) {
				return _linearVideoAd.canScale(deliveryType, mimeType, bitrate, width, height);
			}	
			return false;
		}
		
		public function shouldMaintainAspectRatio(deliveryType:String, mimeType:String, bitrate:* = -1, width:int = -1, height:int = -1):Boolean {
			if(hasLinearAd()) {
				return _linearVideoAd.shouldMaintainAspectRatio(deliveryType, mimeType, bitrate, width, height);				
			}	
			return false;			
		}
		
		public function isInteractive(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):Boolean {
			if(hasLinearAd() && _linearVideoAd != null) {
				return _linearVideoAd.isInteractive(deliveryType, mimeType, bitrate, width, height);								
			}
			return false;
		}
				
		public function triggerTrackingEvent(eventType:String, id:String=null):void {
			for(var i:int = 0; i < _trackingEvents.length; i++) {
				var trackingEvent:TrackingEvent = _trackingEvents[i];
				if(trackingEvent.eventType == eventType) {
					trackingEvent.execute();
				}				
			}
		}
		
		public function triggerCreativeViewEvents():void {
			triggerTrackingEvent(TrackingEvent.EVENT_CREATIVE_VIEW);	
		}
		
		public function triggerImpressionConfirmations(overrideIfAlreadyFired:Boolean=false):void {
			if(overrideIfAlreadyFired || !_impressionsFired) {
				for(var i:int = 0; i < _impressions.length; i++) {
					var impression:NetworkResource = _impressions[i];
					impression.call();
				}				
			}
			_impressionsFired = true;
		}

		public function triggerForcedImpressionConfirmations(overrideIfAlreadyFired:Boolean=false):void {
			if(overrideIfAlreadyFired || !_impressionsFired) {
				for(var i:int = 0; i < _impressions.length; i++) {
					var impression:NetworkResource = _impressions[i];
					impression.call();
				}	
				_impressionsFired = true;
			}
			else doLog("Not forcing impressions to fire - already fired once!", Debuggable.DEBUG_TRACKING_EVENTS);
		}
		
		/*
		protected function makeJavascriptAPICall(jsFunction:String):void {
			ExternalInterface.call(jsFunction);			
		}
		*/
		
		private function fireAPICall(... args):* {
			if (ExternalInterface.available && canFireAPICalls()) {
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
		
		public function processStartAdEvent():void {
			// call the impression tracking urls
			if(hasNonLinearAds() == false) { // this is here to stop impressions firing for overlays that have video ads attached
				triggerImpressionConfirmations();
			}
			
			// call the creativeView tracking urls
			triggerCreativeViewEvents();
			
			// now call the start click tracking urls
			triggerTrackingEvent(TrackingEvent.EVENT_START);
			fireAPICall("onLinearAdStart");
		}

		public function processStopAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_STOP);
			fireAPICall("onStopAd");
		}
		
		public function processPauseAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_PAUSE);
			fireAPICall("onPauseAd");
		}

		public function processResumeAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_RESUME);
			fireAPICall("onResumeAd");
		}

		public function processFullScreenAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_FULLSCREEN);
			fireAPICall("onFullscreenAd");
		}

		public function processFullScreenExitAdEvent():void {
//			triggerTrackingEvent(TrackingEvent.EVENT_FULLSCREEN);
			fireAPICall("onFullscreenExitAd");
		}

		public function processMuteAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_MUTE);
			fireAPICall("onMuteAd");
		}

		public function processUnmuteAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_UNMUTE);
			fireAPICall("onUnmuteAd");
		}

		public function processReplayAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_REPLAY);
			fireAPICall("onReplayAd");
		}

		public function processHitMidpointAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_MIDPOINT);
			fireAPICall("onLinearAdMidPointComplete");
		}

		public function processFirstQuartileCompleteAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_1STQUARTILE);
			fireAPICall("onLinearAdFirstQuartileComplete");
		}

		public function processThirdQuartileCompleteAdEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_3RDQUARTILE);
			fireAPICall("onLinearAdThirdQuartileComplete");
		}

		public function processAdCompleteEvent():void {
			triggerTrackingEvent(TrackingEvent.EVENT_COMPLETE);
			fireAPICall("onLinearAdFinish");
		}
		
		public function processStartNonLinearOverlayAdEvent(event:VideoAdDisplayEvent):void {
			var matched:Boolean = false;
			for(var i:int = 0; i < _nonLinearVideoAds.length && !matched; i++) {
				if(_nonLinearVideoAds[i].matchesSize(event.width, event.height)) {
					matched = true;
					_nonLinearVideoAds[i].start(event);
			        triggerImpressionConfirmations();
				}
			}
			if(!matched) doLog("No matching size found for Ad " + id + " - size required is (" + event.width + "," + event.height + ")", Debuggable.DEBUG_DATA_ERROR);
		}
		
		public function processStopNonLinearOverlayAdEvent(event:VideoAdDisplayEvent):void { 
			for(var i:int = 0; i < _nonLinearVideoAds.length; i++) {
				if(event.width > -1 && event.height > -1) {
					if(_nonLinearVideoAds[i].matchesSize(event.width, event.height)) {
						_nonLinearVideoAds[i].stop(event); 
					}					
				}
				else _nonLinearVideoAds[i].stop(event);
			}
		}
		
		public function processStartCompanionAdEvent(displayEvent:VideoAdDisplayEvent):void {
			if(displayEvent.controller.displayingCompanions()) {
				for(var i:int = 0; i < _companionAds.length; i++) {
					_companionAds[i].start(displayEvent); 
				}
			}
			else doLog("Ignoring request to start a companion - no companions are configured on this page", Debuggable.DEBUG_CUEPOINT_EVENTS);
		}
		
		public function processStopCompanionAdEvent(displayEvent:VideoAdDisplayEvent):void {
			if(displayEvent.controller.displayingCompanions()) {
				for(var i:int = 0; i < _companionAds.length; i++) {
					_companionAds[i].stop(displayEvent);
				}
			}
			else doLog("Ignoring request to stop a companion - no companions are configured on this page", Debuggable.DEBUG_CUEPOINT_EVENTS);
		}
	}
}