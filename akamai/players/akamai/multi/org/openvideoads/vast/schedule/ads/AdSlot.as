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
package org.openvideoads.vast.schedule.ads {
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.util.NetworkResource;
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.vast.VASTController;
	import org.openvideoads.vast.events.AdNoticeDisplayEvent;
	import org.openvideoads.vast.events.VideoAdDisplayEvent;
	import org.openvideoads.vast.model.LinearVideoAd;
	import org.openvideoads.vast.model.NonLinearVideoAd;
	import org.openvideoads.vast.model.VideoAd;
	import org.openvideoads.vast.schedule.Stream;
	import org.openvideoads.vast.schedule.StreamSequence;
	import org.openvideoads.vast.schedule.ads.templates.*;
	import org.openvideoads.vast.server.AdServerConfig;
	import org.openvideoads.vast.tracking.TimeEvent;
	import org.openvideoads.vast.tracking.TrackingPoint;
	
	/**
	 * @author Paul Schulz
	 */
	public class AdSlot extends Stream {
		protected var _zone:String;
		protected var _position:String = null;
		protected var _videoAd:VideoAd = null;
		protected var _notice:Object = null;
		protected var _disableControls:Boolean = false;
		protected var _companionDivIDs:Array = new Array({ id:'companion', width:300, height:250 });
		protected var _applyToParts:Object = null;
		protected var _originatingAssociatedStreamIndex:int = 0;
		protected var _associatedStreamStartTime:int = 0;
		protected var _originalAdSlot:AdSlot = null;
		protected var _owner:AdSchedule = null;
		protected var _clickSignEnabled:Boolean = true;
		protected var _adServerConfig:AdServerConfig = null;
		protected var _isPlaying:Boolean = false;
		protected var _companionsShowing:Boolean = false;
		protected var _played:Boolean = false;
		protected var _overlayVideoPlaying:Boolean = false;

		public static const AD_TYPE_LINEAR:String = "linear";
		public static const AD_TYPE_NON_LINEAR:String = "non-linear";
		public static const AD_TYPE_COMPANION:String = "companion";
		public static const AD_TYPE_UNKNOWN:String = "unknown";
		
		protected var _regions:Object = { 
			text: "reserved-bottom-w450px-h78px-000000-o50",
			html: "reserved-bottom-w450px-h50px-000000-o50",
			image: "reserved-bottom-w450px-h50px-transparent-0m",
			swf: "reserved-bottom-w450px-h50px-transparent"
		};
		
		protected var _templates:Object = { 
			text: new TextAdTemplate(),
			html: new HtmlAdTemplate(),
			image: new ImageAdTemplate(),
			swf: new FlashAdTemplate()
		};
		
		public static const SLOT_POSITION_PRE_ROLL:String = "pre-roll";
		public static const SLOT_POSITION_MID_ROLL:String = "mid-roll";
		public static const SLOT_POSITION_POST_ROLL:String = "post-roll";
		public static const SLOT_POSITION_COMPANION:String = "companion";
		
		private const EVENT_DELAY:int = 500;
				
		public function AdSlot(parent:StreamSequence,
		                       owner:AdSchedule, 
		                       vastController:VASTController, 
		                       key:int=0, 
		                       associatedStreamIndex:int=0, 
		                       id:String=null, 
		                       zone:String=null, 
		                       position:String=null, 
		                       applyToParts:Object=null, 
		                       duration:String=null, 
		                       originalDuration:String=null,
		                       startTime:String="00:00:00", 
		                       notice:Object=null, 
		                       disableControls:Boolean=true, 
		                       width:int=-1, 
		                       height:int=-1, 
		                       defaultLinearRegions:Array=null, 
		                       companionDivIDs:Array=null, 
		                       streamType:String="any",
		                       deliveryType:String="streaming", 
		                       bitrate:*=-1, 
		                       playOnce:Boolean=false,
		                       metaData:Boolean=true,
		                       autoPlay:Boolean=true,
		                       regions:Object=null,
		                       templates:Object=null,
		                       playerConfig:Object=null,
		                       clickSignEnabled:Boolean=true,
		                       adServerConfig:AdServerConfig=null,
		                       previewImage:String = null) {
			super(parent, vastController, key, id, null, startTime, duration, originalDuration, false, null, streamType, deliveryType, bitrate, playOnce, metaData, autoPlay, null, playerConfig, previewImage, associatedStreamIndex);
            _owner = owner;
			_associatedStreamIndex = associatedStreamIndex;
			_originatingAssociatedStreamIndex = associatedStreamIndex;
			_zone = zone;
			_position = position;
			_applyToParts = applyToParts;
			if(notice != null) _notice = notice;
			_disableControls = disableControls;
			_width = width;
			_height = height;
			if(companionDivIDs != null) _companionDivIDs = companionDivIDs;
			configureDefaultRegions();
			if(regions != null) this.regions = regions;
			if(templates != null) this.templates = templates;
			_clickSignEnabled = clickSignEnabled;
			if(adServerConfig != null) _adServerConfig = adServerConfig;
		}
		
		protected function configureDefaultRegions():void {
			if(_width == 300) {
				_regions.text = "reserved-bottom-w300px-h50px-000000-o50";
				_regions.image = "reserved-bottom-w300px-h50px-transparent-0m";
				_regions.swf = "reserved-bottom-w300px-h50px-transparent";
				_regions.html = "reserved-bottom-w300px-h50px-000000-o50";								
			}
			else if(_width == 450) {
				_regions.text = "reserved-bottom-w450px-h50px-000000-o50";
				_regions.image = "reserved-bottom-w450px-h50px-transparent-0m";
				_regions.swf = "reserved-bottom-w450px-h50px-transparent";
				_regions.html = "reserved-bottom-w450px-h50px-000000-o50";				
			}
			else {
				_regions.text = "reserved-bottom-w100pct-h78px-000000-o50";
				_regions.image = "reserved-bottom-w100pct-h50px-transparent-0m";
				_regions.swf = "reserved-bottom-w100pct-h50px-transparent";
				_regions.html = "reserved-bottom-w100pct-h50px-000000-o50";
			}
		}
		
		public function getTemplate(contentType:String):AdTemplate {
			switch(contentType.toUpperCase()) {
				case "TEXT":
					return _templates.text;
				case "HTML":
					return _templates.html;
				case "IMAGE":
					return _templates.image;
				case "SWF":
					return _templates.swf;
			}
			return _templates.html;
		}
		
		public override function get streamID():String {
			return _id;
		}
		
		public function get adSlotID():String {
			return id + "-" + associatedStreamIndex;
		}

		public function hasPositionDefined():Boolean {
			return _position != null;
		}
		
		public function requiresAutoPosition():Boolean {
			if(hasPositionDefined()) {
				return (_position.toUpperCase().indexOf("AUTO") > -1);	
			}
			return false;
		}
		
		public function getAutoPositionAlignment():String {
			if(hasPositionDefined()) {
				if(_position.toUpperCase().indexOf("AUTO:") > -1 && _position.length > 5) {
					var alignment:String = _position.substr(_position.toUpperCase().indexOf("AUTO:") + 5);
					if(alignment != null) {
						alignment = StringUtils.trim(alignment).toUpperCase();
						if("BOTTOM CENTER TOP LEFT RIGHT".indexOf(alignment) > -1 ) {
							return alignment;
						}						
					}
				}
			}
			return "BOTTOM";
		}
		
		public override function get title():String {
			if(hasVideoAd()) {
				return _videoAd.adTitle;	
			}
			return _title;
		}		
		
		public function getRegionIDBasedOnResourceAndCreativeTypes(resourceType:String, creativeType:String):String {
			if(_regions != null) {
				switch(resourceType.toUpperCase()) {
					case "HTML":
						return _regions.html;
					case "TEXT":
						return _regions.text;
					case "STATIC":
						switch(creativeType.toUpperCase()) {
							case "JPEG":
							case "GIF":
							case "PNG":
								return _regions.image;
							case "SWF":
								return _regions.swf;
						}
						break;
				}
			}
			return _regions.image;
		}
		
		public override function getStreamToPlay():NetworkResource {
			if(hasLinearAd() && hasVideoAd()) {
				return _videoAd.getStreamToPlay(deliveryType, mimeType, bitrate, width, height);			
			}
			return null;
		}

        public override function get baseURL():String {
			var streamURL:NetworkResource = getStreamToPlay();
			if(streamURL != null) {
				return streamURL.netConnectionAddress;
			}        	
        	return super.baseURL;
        }
		
		public override function get streamName():String {
			var streamURL:NetworkResource = getStreamToPlay();
			if(streamURL != null) {
				return cleanseStreamName(streamURL.getFilename(streamType + ":"));				
			}
			return null;
		}
		
		public override function canScale():Boolean {
			if(hasVideoAd()) {
				return _videoAd.canScale(deliveryType, mimeType, bitrate, width, height);
			}	
			return false;
		}
		
		public function canReplay():Boolean {
			return _vastController.config.adsConfig.replayNonLinearAds;
		}
		
		public override function shouldMaintainAspectRatio():Boolean {
			if(hasVideoAd()) {
				return _videoAd.shouldMaintainAspectRatio(deliveryType, mimeType, bitrate, width, height);				
			}	
			return false;			
		}
		
		public override function isInteractive():Boolean {
			if(hasVideoAd()) {
				return _videoAd.isInteractive(deliveryType, mimeType, bitrate, width, height);				
			}	
			return false;			
		}

		public function set zone(zone:String):void {
			_zone = zone;
		}
		
		public function get zone():String {
			return _zone;
		}
		
		public function set adServerConfig(adServerConfig:AdServerConfig):void {
			_adServerConfig = adServerConfig;
		}
		
		public function get adServerConfig():AdServerConfig {
			return _adServerConfig;
		}
		
		public function hasAdServerConfigured():Boolean {
			if(_adServerConfig != null) {
				return (_adServerConfig.serverType != null);	
			}
			return false;
		}
		
		public function set position(position:String):void {
			_position = position;
		}
		
		public function get position():String {
			return _position;
		}
		
		public function set regions(regions:Object):void {
			if(regions != null) {
				if(regions.text != undefined) _regions.text = regions.text;
				if(regions.html != undefined) _regions.html = regions.html;
				if(regions.image != undefined) _regions.image = regions.image;
				if(regions.swf != undefined) _regions.swf = regions.swf;				
			}
		}
		
		public function get regions():Object {
			return _regions;
		}
		
		public function set templates(templates:Object):void {
			if(templates != null) {
				if(templates.text != undefined) _templates.text = new TextAdTemplate(templates.text);
				if(templates.html != undefined) _templates.html = new HtmlAdTemplate(templates.html);
				if(templates.image != undefined) _templates.image = new ImageAdTemplate(templates.image);
				if(templates.swf != undefined) _templates.swf = new FlashAdTemplate(templates.swf);
			}
		}
		
		public function get templates():Object {
			return _templates;
		}
		
		public function get textRegionID():String {
			if(_regions != null) {
				if(_regions.text != undefined) return _regions.text;	
			}
			return null;
		}

		public function get imageRegionID():String {
			if(_regions != null) {
				if(_regions.image != undefined) return _regions.image;	
			}
			return null;
		}

		public function get swfRegionID():String {
			if(_regions != null) {
				if(_regions.swf != undefined) return _regions.swf;	
			}
			return null;
		}
		
		public function get htmlRegionID():String {
			if(_regions != null) {
				if(_regions.html != undefined) return _regions.html;	
			}
			return null;
		}		
		
		public override function isSlicedStream():Boolean {
			return false; 
		}
		
		public override function set duration(durationAsSeconds:String):void {
			if(_videoAd != null) _videoAd.setLinearAdDurationFromSeconds(int(durationAsSeconds));
			super.duration = durationAsSeconds;
		}

		public override function get duration():String {
			if(_videoAd != null) {
				if(_duration == null) {
					return new String(_videoAd.duration);
				}
				else if(_duration.toUpperCase().indexOf("RECOMMENDED:") > -1 && _duration.length > 12) {
					// format is "recommended:XX" where XX is the time to use if recommended is not available
					return new String(_videoAd.getDurationGivenRecommendation(
					               parseInt(_duration.substr(_duration.toUpperCase().indexOf("RECOMMENDED:")+12))));
				}
			}
			return super.duration;
		}

		public function set originatingAssociatedStreamIndex(originatingAssociatedStreamIndex:int):void {
			_originatingAssociatedStreamIndex = originatingAssociatedStreamIndex;
		}
		
		public function get originatingAssociatedStreamIndex():int {
			return _originatingAssociatedStreamIndex;
		}
		
		public function set applyToParts(applyToParts:Object):void {
			_applyToParts = applyToParts;
		}
		
		public function get applyToParts():Object {
			return _applyToParts;
		}

		public function set associatedStreamStartTime(associatedStreamStartTime:int):void {
			_associatedStreamStartTime = associatedStreamStartTime;
		}
		
		public function get associatedStreamStartTime():int {
			return _associatedStreamStartTime;
		}
		
		public function get slotType():String {
			if(isPreRoll() || isMidRoll() || isPostRoll()) {
				return AD_TYPE_LINEAR;
			}
			else if(isCompanion()) {
				return AD_TYPE_COMPANION;
			}
			return AD_TYPE_NON_LINEAR;
		}
		
		public function isPreRoll():Boolean {
			if(_position == null) return false;
			return (_position.toLowerCase() == SLOT_POSITION_PRE_ROLL);
		}
		
		public function isMidRoll():Boolean {
			if(_position == null) return false;
			return (_position.toLowerCase() == SLOT_POSITION_MID_ROLL);
		}
		
		public function isPostRoll():Boolean {
			if(_position == null) return false;
			return (_position.toLowerCase() == SLOT_POSITION_POST_ROLL);
		}
		
		public function isCompanion():Boolean {
			if(_position == null) return false;
			return (_position.toLowerCase() == SLOT_POSITION_COMPANION);			
		}
		
		public function isActive():Boolean {
			return (_videoAd != null);
		}
		
		public function get played():Boolean {
			return _played;
		}
		
		public function isPlaying():Boolean {
			return _isPlaying;
		}
		
		public function shouldBePlaying(milliseconds:Number):Boolean {
			return (_trackingTable.timeBetweenTwoPoints(milliseconds, "NS", "NE") && (played == false || canReplay()));
		}
		
		public function toRunIndefinitely():Boolean {
			return (!hasDuration() || getDurationAsInt() == -1 || hasZeroDuration());
		}
		
		public function companionsShowing():Boolean {
			return _companionsShowing;
		}
		
		public function set overlayVideoPlaying(overlayVideoPlaying:Boolean):void {
			_overlayVideoPlaying = overlayVideoPlaying;
		}
		
		public function isOverlayVideoPlaying():Boolean {
			return _overlayVideoPlaying;
		}
		
		public function isEmpty():Boolean {
			return !hasNonLinearAds() && !hasLinearAd();	
		}
		
		public function hasNonLinearAds():Boolean {
			if(_videoAd != null) {
				return _videoAd.hasNonLinearAds();
			}
			else return false;			
		}
		
		public function hasLinearAd():Boolean {
			if(_videoAd != null) {
				return _videoAd.hasLinearAd();	
			}
			return false;
		}
		
		public function hasLinearClickThroughs():Boolean {
			if(hasLinearAd()) {
				return getLinearVideoAd().hasClickThroughURL();
			}
			return false;
		}
		
		public function getLinearVideoAd():LinearVideoAd {
			if(_videoAd != null) {
				return _videoAd.linearVideoAd;
			}
			return null;
		}
		
		public function getNonLinearVideoAd():NonLinearVideoAd {
			if(_videoAd != null) {
				if(_videoAd.nonLinearVideoAds != null) {
					return _videoAd.nonLinearVideoAds[0];				
				}
			}
			return null;
		}
		
		public function getAttachedLinearAdDurationAsInt():int {
			if(_videoAd != null) {
				return _videoAd.duration;			
			}
			return 0;
		}
		
		public function hasCompanionAds():Boolean {
			if(_videoAd != null) {
				return _videoAd.hasCompanionAds();
			}
			else return false;
		}
		
		public function set videoAd(videoAd:VideoAd):void {
			_videoAd = videoAd;
		}
		
		public function get videoAd():VideoAd {
			return _videoAd;
		}
		
		public function hasVideoAd():Boolean {
			return (_videoAd != null);
		}
		
		public override function isLinear():Boolean {
			if(_videoAd != null) {
				return (isPreRoll() || isPostRoll() || isMidRoll()) && _videoAd.isLinear();
			}
			else return false;
		}
		
		public function isNonLinear():Boolean {
			if(_videoAd != null) {
				return (!isPreRoll() && !isPostRoll() && !isMidRoll()) && _videoAd != null && _videoAd.hasNonLinearAds();
			}
			else return false;
		}
		
		public function set disableControl(disableControls:Boolean):void {
			_disableControls = disableControls;
		}
		
		public function get disableControls():Boolean {
			return _disableControls;
		}

		public override function declareTrackingPoints(currentTimeInSeconds:int=0):void {
			if(_trackingPointsSet == false) {
				if(getDurationAsInt() > 0) {
					clearTrackingTable();
					if(isLinear()) {
						var timeFactor:int = 1000;
						var streamDuration:int = getDurationAsInt();
						var startTime:int = currentTimeInSeconds + streamStartTime;
						var midpointMilliseconds:int = Math.round(((startTime * timeFactor) + ((streamDuration * timeFactor) / 2)) / 100) * 100;
						var endFirstQuartileMilliseconds:int = Math.round(((startTime * timeFactor) + ((streamDuration * timeFactor) / 4)) / 100) * 100; 
						var endThirdQuartileMilliseconds:int = Math.round(((startTime * timeFactor) + (((streamDuration * timeFactor) / 4) * 3)) / 100) * 100;
						
						setTrackingPoint(new TrackingPoint((startTime * timeFactor) + _vastController.startStreamSafetyMargin, "BA"));
						setTrackingPoint(new TrackingPoint(endFirstQuartileMilliseconds, "1Q"));
						setTrackingPoint(new TrackingPoint(midpointMilliseconds, "HW"));
						setTrackingPoint(new TrackingPoint(endThirdQuartileMilliseconds, "3Q"));
						setTrackingPoint(new TrackingPoint((startTime * timeFactor) + _vastController.startStreamSafetyMargin, "SN"));
						setTrackingPoint(new TrackingPoint((((startTime + streamDuration) * timeFactor) - _vastController.endStreamSafetyMargin), "HN"));
						setTrackingPoint(new TrackingPoint((((startTime + streamDuration) * timeFactor) - _vastController.endStreamSafetyMargin), "EA"));
	
						if(hasTimedNotice()) {
							declareNoticeTimerTrackingPoints(streamDuration, false);
						}						
					}
					if(hasNonLinearAds()) { 
						addNonLinearAdTrackingPoints(key, true, false); 
					}
					if(hasCompanionAds()) { 
						addCompanionAdTrackingPoints(key, currentTimeInSeconds, getDurationAsInt());
					}			
					markTrackingPointsAsSet();					
				}
				else doLog("Not setting Ad tracking points on " + key + " - 0 duration specified", Debuggable.DEBUG_CUEPOINT_FORMATION);
			}
			else doLog("Not setting Ad tracking points on " + key + " - already set once", Debuggable.DEBUG_CUEPOINT_FORMATION);
		}

		protected function addCompanionAdTrackingPoints(adSlotIndex:int, startPoint:int, duration:int, overrideSetFlag:Boolean=false, fireTrackingEvent:Boolean=true, isChildLinear:Boolean=false):void {
			doTrace(this, Debuggable.DEBUG_CUEPOINT_FORMATION);
			setTrackingPoint(new TrackingPoint((startPoint * 1000) + _vastController.startStreamSafetyMargin, "CS", new String(adSlotIndex)), overrideSetFlag, fireTrackingEvent, isChildLinear); 

			if(duration > 0) {
				setTrackingPoint(new TrackingPoint((((startPoint + duration) * 1000) - _vastController.endStreamSafetyMargin), "CE", new String(adSlotIndex)), overrideSetFlag, fireTrackingEvent, isChildLinear);
				doLog("Tracking point set on " + key + " at " + startPoint + " seconds and run for " + duration + " seconds for companion ad with Ad id " + id, Debuggable.DEBUG_CUEPOINT_FORMATION);				
			}
			else doLog("Tracking point set on " + key + " at " + startPoint + " seconds running indefinitely - Companion Ad id " + id, Debuggable.DEBUG_CUEPOINT_FORMATION);			
		}
		
		public function addNonLinearAdTrackingPoints(adSlotIndex:int, resetStartTimeToZeroEachStream:Boolean=false, checkCompanionAds:Boolean=false, overrideSetFlag:Boolean=false):void {
			doTrace(this, Debuggable.DEBUG_CUEPOINT_FORMATION);
			var startPoint:int = ((resetStartTimeToZeroEachStream) ? 0 : associatedStreamStartTime) + getStartTimeAsSeconds();
			var duration:int = getDurationAsInt();
			setTrackingPoint(new TrackingPoint(startPoint * 1000, "NS", new String(adSlotIndex)), overrideSetFlag);

			if(duration > 0) {
				setTrackingPoint(new TrackingPoint(((startPoint + duration) * 1000) - _vastController.endStreamSafetyMargin, "NE", new String(adSlotIndex)), overrideSetFlag);
				doLog("Tracking point set on " + key + " at " + startPoint + " seconds and run for " + duration + " seconds for non-linear ad with Ad id " + id, Debuggable.DEBUG_CUEPOINT_FORMATION);				
			}
			else doLog("Tracking point set on " + key + " at " + startPoint + " seconds running indefinitely - non-linear Ad id " + id, Debuggable.DEBUG_CUEPOINT_FORMATION);

			if(checkCompanionAds && hasCompanionAds()) {
				addCompanionAdTrackingPoints(adSlotIndex, startPoint, duration); 
			}
			
			if(hasLinearAd()) {
				// setup the tracking points for the attached linear ad, but don't fire off tracking events just yet
				var timeFactor:int = 1000;
				var streamDuration:int = getAttachedLinearAdDurationAsInt();
				var startTime:int = 0;
				var midpointMilliseconds:int = Math.round(((startTime * timeFactor) + ((streamDuration * timeFactor) / 2)) / 100) * 100;
				var endFirstQuartileMilliseconds:int = Math.round(((startTime * timeFactor) + ((streamDuration * timeFactor) / 4)) / 100) * 100; 
				var endThirdQuartileMilliseconds:int = Math.round(((startTime * timeFactor) + (((streamDuration * timeFactor) / 4) * 3)) / 100) * 100;

				setTrackingPoint(new TrackingPoint((startTime * timeFactor) + _vastController.startStreamSafetyMargin, "BA"), false, false, true);
				setTrackingPoint(new TrackingPoint(endFirstQuartileMilliseconds, "1Q"), false, false, true);
				setTrackingPoint(new TrackingPoint(midpointMilliseconds, "HW"), false, false, true);
				setTrackingPoint(new TrackingPoint(endThirdQuartileMilliseconds, "3Q"), false, false, true);
				setTrackingPoint(new TrackingPoint((startTime * timeFactor) + _vastController.startStreamSafetyMargin, "SN"), false, false, true);
				setTrackingPoint(new TrackingPoint((((startTime + streamDuration) * timeFactor) - _vastController.endStreamSafetyMargin), "HN"), false, false, true);
		 		setTrackingPoint(new TrackingPoint((((startTime + streamDuration) * timeFactor) - _vastController.endStreamSafetyMargin), "EA"), false, false, true);
					
				if(hasTimedNotice()) {
					declareNoticeTimerTrackingPoints(streamDuration, true);
				}					
				if(hasCompanionAds()) { 
					addCompanionAdTrackingPoints(key, 0, streamDuration, false, false, true);
				}							
			}
		}

		protected function declareNoticeTimerTrackingPoints(duration:int, isChildLinear:Boolean=false):void {
			doLog("Declaring ad notice tracking points...", Debuggable.DEBUG_CUEPOINT_FORMATION);
			var timeFactor:int = 1000;
			for(var i:int=1; i < duration; i++) {
				setTrackingPoint(new TrackingPoint((i * timeFactor), "TN"), false, false, isChildLinear);
			}
		}
		
        public function processForcedImpression(overrideIfAlreadyFired:Boolean=false):void {
			if(_videoAd != null) {
				_videoAd.triggerForcedImpressionConfirmations(overrideIfAlreadyFired);
			}        	
        }
        
		public override function processStartStream():void {
			_isPlaying = _played = true;
			if(_videoAd != null) {
				_videoAd.processStartAdEvent();
			}
			else doLog("tracking event at start of ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
		}

		public override function processStreamComplete():void {
			_isPlaying = false;
			if(_videoAd != null) {
				_videoAd.processAdCompleteEvent();
			}
			else doLog("tracking event at end of ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
		}
		
	 	public override function processStopStream():void {
			if(_videoAd != null) {
				_videoAd.processStopAdEvent();
			}
			else doLog("tracking event for stop ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}
	 	
	 	public override function processPauseStream():void {
			if(_videoAd != null) {
				_videoAd.processPauseAdEvent();				
			}
			else doLog("tracking event for pause ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}
	 	
	 	public override function processResumeStream():void {
			if(_videoAd != null) {
				_videoAd.processResumeAdEvent();
			}
			else doLog("tracking event for resume ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}
	 	
	 	protected function processAdMidpointComplete():void {
			if(_videoAd != null) {
				_videoAd.processHitMidpointAdEvent();
			}
			else doLog("tracking event for midpoint ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}
	 	
	 	protected function processAdFirstQuartileComplete():void {
			if(_videoAd != null) {
				_videoAd.processFirstQuartileCompleteAdEvent();
			}
			else doLog("tracking event for first quartile " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}
	 	
	 	protected function processAdThirdQuartileComplete():void {
			if(_videoAd != null) {
				_videoAd.processThirdQuartileCompleteAdEvent();
			}
			else doLog("tracking event for third quartile " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}

        override public function processFullScreenEvent():void {	
			doLog("AdSlot " + id + " full screen event", Debuggable.DEBUG_TRACKING_EVENTS);        
		 	if(_videoAd != null) {
		 		_videoAd.processFullScreenAdEvent();
		 	}
			else doLog("tracking event for fullscreen on ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
        }

        override public function processFullScreenExitEvent():void {	
			doLog("AdSlot " + id + " full screen exit event", Debuggable.DEBUG_TRACKING_EVENTS);        
		 	if(_videoAd != null) {
		 		_videoAd.processFullScreenExitAdEvent();
		 	}
			else doLog("tracking event for fullscreen exit on ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
        }

        override public function processMuteEvent():void {	
			doLog("AdSlot " + id + " mute event", Debuggable.DEBUG_TRACKING_EVENTS);        
		 	if(_videoAd != null) {
		 		_videoAd.processMuteAdEvent();
		 	}
			else doLog("tracking event for mute on ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
        }

        override public function processUnmuteEvent():void {	
			doLog("AdSlot " + id + " unmute event", Debuggable.DEBUG_TRACKING_EVENTS);        
		 	if(_videoAd != null) {
		 		_videoAd.processUnmuteAdEvent();
		 	}
			else doLog("tracking event for unmute on ad " + key + " ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
        }

		protected function createDisplayEvent(controller:VASTController):VideoAdDisplayEvent {
		 	var displayEvent:VideoAdDisplayEvent = new VideoAdDisplayEvent(controller, _width, _height);
		 	displayEvent.customData.adSlotPosition = _position;
		 	displayEvent.customData.adSlotRegions = _regions;
		 	displayEvent.customData.adSlotKey = _key;
		 	displayEvent.customData.adSlotAssociatedStreamIndex = associatedStreamIndex;
			return displayEvent;
		}
			 	
	 	protected function actionNonLinearAdOverlayStart(controller:VASTController):void {
	 		_isPlaying = true; 
	 		_played = true;
	 		if(this.isLinear()) {
	 			doLog("tracking event for non-linear overlay start ignored on Linear Ad - not implemented", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 		}
	 		else {
		 		if(_videoAd != null) {
		 			doLog("tracking event for non-linear overlay start being processed - this is for a stand alone ad slot", Debuggable.DEBUG_CUEPOINT_EVENTS);
		 			_videoAd.processStartNonLinearOverlayAdEvent(createDisplayEvent(controller));
	 			}
	 			else doLog("tracking event for non-linear overlay start ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 		}
	 	}

	 	protected function actionNonLinearAdOverlayEnd(controller:VASTController):void {
	 		_isPlaying = false;
	 		if(this.isLinear()) {
	 			doLog("tracking event for non-linear overlay stop on Linear Ad ignored - not implemented", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 		}
	 		else {
		 		if(_videoAd != null) {
		 			doLog("tracking event for non-linear overlay stop being processed - this is for a stand alone ad slot", Debuggable.DEBUG_CUEPOINT_EVENTS);
			 		_videoAd.processStopNonLinearOverlayAdEvent(createDisplayEvent(controller)); 
	 			}
	 			else doLog("tracking event for non-linear overlay end ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 		}
	 	}
	 	
 	 	protected function actionCompanionAdStart(controller:VASTController):void {
			_companionsShowing = true;
	 		if(_videoAd != null) {
		 		var displayEvent:VideoAdDisplayEvent = new VideoAdDisplayEvent(controller, _width, _height);
	 			_videoAd.processStartCompanionAdEvent(displayEvent);
	 		}
	 		else doLog("tracking event for companion ad end ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}

	 	protected function actionCompanionAdEnd(controller:VASTController):void { 
			_companionsShowing = false;
	 		if(_videoAd != null) {
		 		var displayEvent:VideoAdDisplayEvent = new VideoAdDisplayEvent(controller, _width, _height);
	 			_videoAd.processStopCompanionAdEvent(displayEvent);
	 		}
	 		else doLog("tracking event for companion ad end ignored", Debuggable.DEBUG_CUEPOINT_EVENTS);
	 	}
	 	
	 	protected function actionAdNoticeCountdownTick(controller:VASTController, millisecondsPlayed:int):void {
	 		if(_notice != null) {
	 			if(_notice.region != undefined) {
	 				if(_notice.region != null && _videoAd != null) {
						var remainingDurationInSeconds:int = Math.round(_videoAd.duration - (millisecondsPlayed / 1000));			
	 					_vastController.onTickAdNotice(new AdNoticeDisplayEvent(AdNoticeDisplayEvent.TICK, _notice, remainingDurationInSeconds));
	 				}
	 			}
	 		}
	 	}
	 	
	 	public function hasNotice():Boolean {
	 		return noticeToBeShown();	
	 	}
	 	
	 	public function hasTimedNotice():Boolean {
			if(_notice != null) {
				if(_notice.message != undefined) {
					return (_notice.message.indexOf("_countdown_") > -1)				
				}
			}	 
			return false;		
	 	}
	 	
		private function noticeToBeShown():Boolean {
			if(_notice != null) {
				if(_notice.show) {
					return _notice.show;
				}
			}
			return false;
		}
		
	 	protected function showAdNotice():void {
			if(disableControls) {
				turnOffSeekerBar();
			}
			if(_clickSignEnabled) {
				_vastController.enableVisualLinearAdClickThroughCue(this);			
			}
	 		if(noticeToBeShown()) {
	 			if(_notice.region != undefined && _notice.region != null) {
	 				if(_notice.message != undefined && _notice.region != null) {
						if(_vastController != null) _vastController.onShowAdNotice(new AdNoticeDisplayEvent(AdNoticeDisplayEvent.DISPLAY, _notice, ((_videoAd) ? _videoAd.duration : 0)));
	 				}
	 			}
	 		}
	 	}
	 	
	 	protected function hideAdNotice():void {
			if(disableControls) {
				turnOnSeekerBar();
			}
			if(_clickSignEnabled) {
				_vastController.disableVisualLinearAdClickThroughCue(this);				
			}			
	 		if(noticeToBeShown()) {
	 			if(_notice.region != undefined && _notice.region != null) {
		 		    if(_vastController != null) _vastController.onHideAdNotice(new AdNoticeDisplayEvent(AdNoticeDisplayEvent.HIDE, _notice));
	 			}
	 		}
	 	}
	 	
        public override function processTimeEvent(timeEvent:TimeEvent, includeChildLinear:Boolean=true):void {
        	if((isNonLinear() && !toRunIndefinitely()) && isPlaying() && !isOverlayVideoPlaying() && (!_trackingTable.isTimeInBaseRange(timeEvent.milliseconds) || timeEvent.label == "NE")) {
     			doLog("AdSlot: " + id + " forcibly closing down the non-linear showing - current time is out of range", Debuggable.DEBUG_CUEPOINT_EVENTS);
				actionNonLinearAdOverlayEnd(_vastController);
				actionCompanionAdEnd(_vastController);
				_vastController.onProcessTrackingPoint(_trackingTable.getTrackingPointOfType("NE"));	
				_vastController.onProcessTrackingPoint(_trackingTable.getTrackingPointOfType("CE"));
        	}
        	else {
	        	var trackingPoints:Array = _trackingTable.activeTrackingPoints(timeEvent, includeChildLinear);
	        	if(isNonLinear() && !isPlaying() && !isOverlayVideoPlaying() && trackingPoints.length == 0) {
	        		if(timeEvent.label != "CE" && _trackingTable.timeBetweenTwoPoints(timeEvent.milliseconds, "NS", "NE") && (played == false || canReplay())) {
	        			// ok, we are in the timing range for an overlay, but it's not showing so force it up
		     			doLog("AdSlot: " + id + " forcibly showing non-linear ad - current time is in range but ad currently not showing", Debuggable.DEBUG_CUEPOINT_EVENTS);
		 				actionNonLinearAdOverlayStart(_vastController);
	 					actionCompanionAdStart(_vastController);
				 		_vastController.onProcessTrackingPoint(_trackingTable.getTrackingPointOfType("NS"));	
				 		_vastController.onProcessTrackingPoint(_trackingTable.getTrackingPointOfType("CS"));				
	        		}        			
	        	}
	        	else {
		        	for(var i:int=0; i < trackingPoints.length; i++) {
		        		var trackingPoint:TrackingPoint = trackingPoints[i];			
			        	if(trackingPoint != null) {
				 			doLog("AdSlot: " + id + " matched request to process tracking event of type " + trackingPoint.label, Debuggable.DEBUG_CUEPOINT_EVENTS);
							var description:String;
														
			        		switch(trackingPoint.label) {
					 			case "BA": // start of the Ad stream
					 				description = "Begin linear video advertisement event";
					 				processStartStream();
							 		_vastController.onProcessTrackingPoint(trackingPoint);
							 		_vastController.onLinearAdStart(this);	
					 				break;
					 			case "EA": // end of the Ad stream
					 				description = "End linear video advertisement event";
					 				processStreamComplete();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
							 		_vastController.onLinearAdComplete(this);	
					 				break;
					 			case "SS": // stop stream
					 				description = "Stop stream event";
					 				processStopStream();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "PS": // pause stream
					 				description = "Pause stream event";
					 				processPauseStream();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "RS": // resume stream
					 				description = "Resume stream event";
					 				processResumeStream();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "HW": // halfway midpoint
					 				description = "Halfway point tracking event";
					 				processAdMidpointComplete();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "1Q": // end of first quartile
					 				description = "1st quartile tracking event";
					 				processAdFirstQuartileComplete();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "3Q": // end of third quartile
					 				description = "3rd quartile tracking event";
					 				processAdThirdQuartileComplete();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "SN": // show ad notice
					 				description = "Show ad notice event";
					 			    showAdNotice();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
							 		break;			 			    
					 			case "HN": // hide the ad notice
					 				description = "Hide ad notice event";
					 				hideAdNotice();
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "NS": // a trigger to start a non-linear overlay
					 				if(!isPlaying()) {
						 				description = "Start non-linear ad event";
						 				actionNonLinearAdOverlayStart(_vastController);
								 		_vastController.onProcessTrackingPoint(trackingPoint);	
								 	}
								 	else doLog("Ignoring request to start non-linear ad - already playing", Debuggable.DEBUG_CUEPOINT_EVENTS);
					 				break;
					 			case "NE": // a trigger to stop a non-linear overlay
					 				description = "End non-linear ad event";
					 				actionNonLinearAdOverlayEnd(_vastController);
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "CS": // start a companion ad
					 				if(!companionsShowing()) {
						 				description = "Companion start event";
			 		 					actionCompanionAdStart(_vastController);
								 		_vastController.onProcessTrackingPoint(trackingPoint);	
								 	}
								 	else doLog("Ignoring request to show companion ad(s) - already showing", Debuggable.DEBUG_CUEPOINT_EVENTS);
					 				break;
					 			case "CE": // stop a companion ad
					 				description = "Companion end event";
					 				actionCompanionAdEnd(_vastController);
							 		_vastController.onProcessTrackingPoint(trackingPoint);	
					 				break;
					 			case "TN": // timed ad notice - countdown value
					 			    description = "Timed ad notice";
					 			    actionAdNoticeCountdownTick(_vastController, trackingPoint.milliseconds);
					 			    _vastController.onProcessTrackingPoint(trackingPoint);
					 		}	        		
			        	}        			        		
		        	}
	        	}
        	}
	 	}
	 	
	 	public function closeActiveOverlaysAndCompanions():void {
	 		actionNonLinearAdOverlayEnd(_vastController);
	 		actionCompanionAdEnd(_vastController);
//	 		hideAdNotice();
	 	}

        public function get clonedAdServerConfig():AdServerConfig {
        	if(_adServerConfig != null) {
	        	return _adServerConfig; //.clone();    		
        	}
        	return null;
        }
        
		public function markAsCopy(originalAdSlot:AdSlot):void {
			_originalAdSlot = originalAdSlot;
		}
	
		public function isCopy():Boolean {
			return (_originalAdSlot != null);
		}
	
		public function clone(instanceNumber:int=0):AdSlot {
			var clonedAdSlot:AdSlot = new AdSlot(
			                                _parent,
			                                _owner,
		                         			_vastController, 
		                         			_key, 
		                         			_associatedStreamIndex, 
		                         			_id + '-c', 
		                         			_zone, 
		                         			_position, 
		                         			_applyToParts, 
		                         			_duration, 
		                         			_originalDuration,
		                         			_startTime, 
		                         			_notice, 
		                         			_disableControls, 
		                         			_width, 
		                         			_height, 
		                         			null, 
		                         			_companionDivIDs, 
		                         			_streamType,
		                         			_deliveryType,
		                         			_bitrate,
		                         			_playOnce,
		                         			_metaData,
		                         			_autoPlay,
		                         			_regions,
		                         			_templates,
		                         			_playerConfig,
		                         			_clickSignEnabled,
		                         			clonedAdServerConfig,
		                         			_previewImage
		                      		  );
		    clonedAdSlot.originatingAssociatedStreamIndex = _originatingAssociatedStreamIndex;
		    clonedAdSlot.markAsCopy(this);
		    return clonedAdSlot;
		}

		public override function toString():String {
			return super.toString() +
			   ", adSlotId: " + adSlotID +
			   ", width: " + _width +
			   ", height: " + _height + 
			   ", position: " + _position + 
			   ", originatingAssociatedStreamIndex: " + _originatingAssociatedStreamIndex +
			   ", associatedStreamIndex: " + _associatedStreamIndex +
			   ", associatedStreamStartTime: " + _associatedStreamStartTime +
			   ", showNotice: " + noticeToBeShown() +
			   ", metaData: " + _metaData + 
			   ", regions: " + _regions +
			   ", templates: " + _templates;
		}
	}	
}
