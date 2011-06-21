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
package org.openvideoads.vast.schedule {
	import flash.external.ExternalInterface;
	
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.base.EventController;
	import org.openvideoads.util.NetworkResource;
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.util.Timestamp;
	import org.openvideoads.vast.VASTController;
	import org.openvideoads.vast.tracking.TimeEvent;
	import org.openvideoads.vast.tracking.TrackingPoint;
	import org.openvideoads.vast.tracking.TrackingTable;
				
	/**
	 * @author Paul Schulz
	 */
	public class Stream extends EventController {
		public const VAST_MIME_TYPE_FLV:String = "video/x-flv";
		public const VAST_MIME_TYPE_MP4:String = "video/x-mp4";
		public const VAST_DELIVERY_TYPE_STREAMING:String = "streaming";
		public const VAST_DELIVERY_TYPE_PROGRESSIVE:String = "progressive";
		
		protected var _id:String=null;
		protected var _key:int;
		protected var _streamName:String;
		protected var _startTime:String = "00:00:00";
		protected var _streamStartTime:int = 0;
		protected var _originalDuration:String = null;
		protected var _duration:String = null;
		protected var _reduceLength:Boolean = false;
		protected var _streamType:String = "any"; 
		protected var _mimeType:String = null; 
		protected var _bitrate:* = -1;
		protected var _width:int = -1;
		protected var _height:int = -1;
		protected var _trackingPointsSet:Boolean = false;
		protected var _baseURL:String = null;
		protected var _trackingTable:TrackingTable = null; 
		protected var _parent:StreamSequence = null;
		protected var _vastController:VASTController = null;
		protected var _deliveryType:String = VAST_DELIVERY_TYPE_STREAMING;
		protected var _playOnce:Boolean = false;
		protected var _metaData:Boolean = true;
		protected var _autoPlay:Boolean = true;
		protected var _provider:String = null;
		protected var _playerConfig:Object = new Object();
		protected var _previewImage:String = null;
		protected var _associatedStreamIndex:int = 0;
		protected var _originatingStreamIndex:int = 0;
		protected var _isSlice:Boolean = false;
		protected var _title:String = null;
		protected var _customProperties:Object = null;
		protected var _fireTrackingEvents:Boolean = false;
		protected var _endBlockMarker:Boolean = false;
		protected var _hasOffsetStartTime:Boolean = false;

		public function Stream(parent:StreamSequence, 
		                       vastController:VASTController, 
		                       key:int=0, 
		                       id:String=null, 
		                       streamName:String=null, 
		                       startTimestamp:String="00:00:00", 
		                       duration:String=null, 
		                       originalDuration:String=null,
		                       reducedLength:Boolean=false, 
		                       baseURL:String=null, 
		                       streamType:String="any", 
		                       deliveryType:String="streaming", 
		                       bitrate:* = -1, 
		                       playOnce:Boolean=false,
		                       metaData:Boolean=true,
		                       autoPlay:Boolean=true,
		                       provider:String=null,
		                       playerConfig:Object=null,
		                       previewImage:String=null,
		                       originatingStreamIndex:int=0,
		                       isSlice:Boolean=false,
		                       customProperties:Object=null,
		                       fireTrackingEvents:Boolean=false,
		                       hasOffsetStartTime:Boolean=false) {
			_parent = parent;
			_vastController = vastController;
			_key = key;
			_trackingTable = new TrackingTable(id, key, originatingStreamIndex);
			_id = id;
			_streamName = streamName;
			startTime = startTimestamp;
			_duration = duration;
			_originalDuration = originalDuration;
			_reduceLength = reducedLength;
			_streamType = streamType;
			_bitrate = bitrate;
			setMimeType();
			_baseURL = baseURL;
			_deliveryType = deliveryType;
			_playOnce = playOnce;
			_metaData = metaData;
			_autoPlay = autoPlay;
			_provider = provider;
			if(playerConfig != null) _playerConfig = playerConfig;
			if(customProperties != null) {
				_customProperties = customProperties;
			}
			_previewImage = previewImage;
			_originatingStreamIndex = originatingStreamIndex;
			_isSlice = isSlice;
			_fireTrackingEvents = fireTrackingEvents;
			_hasOffsetStartTime = hasOffsetStartTime;
		}
		
		public function set key(key:int):void {
			_key = key;
		}
		
		public function get key():int {
			return _key;
		}

		public function set id(id:String):void {
			_id = id;
		}
		
		public function get id():String {
			return _id;
		}
		
		public function set title(title:String):void {
			_title = title;
		}
		
		public function get title():String {
			return _title;
		}
		
		public function set hasOffsetStartTime(hasOffsetStartTime:Boolean):void {
			_hasOffsetStartTime = hasOffsetStartTime;
		}
		
		public function get hasOffsetStartTime():Boolean {
			return _hasOffsetStartTime;
		}
		
		public function isSlice():Boolean {
			return _isSlice;
		}

        public function set originatingStreamIndex(originatingStreamIndex:int):void {
        	_originatingStreamIndex = originatingStreamIndex;
        }		
        
		public function get originatingStreamIndex():int {
			return _originatingStreamIndex;
		}

		public function set associatedStreamIndex(associatedStreamIndex:int):void {
			_associatedStreamIndex = associatedStreamIndex;
		}
		
		public function get associatedStreamIndex():int {
			return _associatedStreamIndex;
		}
		
		public function set endBlockMarker(endBlockMarker:Boolean):void {
			_endBlockMarker = endBlockMarker;
		}
		
		public function get endBlockMarker():Boolean {
			return _endBlockMarker;
		}
		
		public function isEndBlock():Boolean {
			return _endBlockMarker;
		}
		
		public function set provider(provider:String):void {
			_provider = provider;
		}
		
		public function get provider():String {
			return _provider;
		}
		
		public function get playerConfig():Object {
			return _playerConfig;
		}
		
		public function set previewImage(previewImage:String):void {
			_previewImage = previewImage;
		}
		
		public function get previewImage():String {
			return _previewImage;
		}
		
		public function set autoPlay(autoPlay:Boolean):void {
			_autoPlay = autoPlay;
		}
		
		public function get autoPlay():Boolean {
			return _autoPlay;
		}
		
		public function get timerID():String {
			return "";
		}
		
		public function isInteractive():Boolean {
			return false;
		}

        public function get playOnce():Boolean {
        	return _playOnce;
        }
        
		public function set deliveryType(deliveryType:String):void {
			_deliveryType = deliveryType;
		}
		
		public function get deliveryType():String {
			return _deliveryType;
		}
		
		public function get metaData():Boolean {
			return _metaData;
		}

		public function set bitrate(bitrate:*):void {
			_bitrate = bitrate;
		}
		
		public function get bitrate():* {
			return _bitrate;
		}

		public function set width(width:int):void {
			_width = width;
		}
		
		public function get width():int {
			return _width;
		}

		public function set height(height:int):void {
			_height = height;
		}
		
		public function get height():int {
			return _height;
		}
		
		public function get fireTrackingEvents():Boolean {
			return _fireTrackingEvents;
		}
				
		public function hasCustomProperties():Boolean {
			return _customProperties != null;
		}
		
		public function hasCustomProperty(propertyName:String):Boolean {
			if(hasCustomProperties()) {
				return _customProperties.hasOwnProperty(propertyName);
			}
			return false;
		}
		
		public function set customProperties(customProperties:Object):void {
			_customProperties = customProperties;
		}
		
		public function get customProperties():Object {
			return _customProperties;	
		}
				
		public function getQualifiedStreamAddress():String {
			var url:NetworkResource = getStreamToPlay();
			return url.getQualifiedStreamAddress(_baseURL);
		}
		
		public function set parent(parent:StreamSequence):void {
			_parent = parent;
		}
		
		public function get parent():StreamSequence {
			return _parent;
		}
		
		public function set streamID(streamID:String):void {
			_streamName = streamID;
		}
		
		public function get streamID():String {
			return _streamName;
		}

        public function set streamType(streamType:String):void {
        	_streamType = streamType;
        	setMimeType();
        }
        
        public function get streamType():String {
        	return _streamType;
        }
        
        public function isSplashImage():Boolean {
        	var sn:String = this.streamName;
        	if(sn != null) {
        		var pattern:RegExp = new RegExp('.jpg|.png|.gif|.JPG|.PNG|.GIF');
        		return (sn.match(pattern) != null);
        	}
        	return false;
        }
        
        public function isStream():Boolean {
        	var sn:String = this.streamName;
        	if(sn != null) {
        		var pattern:RegExp = new RegExp('.jpg|.png|.gif|.swf|.JPG|.PNG|.GIF|.SWF');
        		return (sn.match(pattern) == null);
        	}
        	return false;        	
        }

        public function streamIdStartsWith(pattern:String):Boolean {
        	if(_id != null) {
	        	return StringUtils.beginsWith(_id, pattern);    		
        	}
        	return false;
        }
        
        public function streamNameStartsWith(pattern:String):Boolean {
        	return StringUtils.beginsWith(streamName, pattern);
        }
        
        public function streamNameWithout(pattern:String):String {
        	if(streamName != null) {
        		if(streamName.length > pattern.length) {
	        		return streamName.substr(pattern.length);     			
        		}
        	}
        	return null;
        }
        
		private function setMimeType():void {
			if(_streamType.toUpperCase() == "MP4") {
				_mimeType = VAST_MIME_TYPE_MP4;
			}
			else if(_streamType.toUpperCase() == "FLV") {
				_mimeType = VAST_MIME_TYPE_FLV;
			}
			else _mimeType = null; // ANY
		}
		
		public function get mimeType():String {
			return _mimeType;
		}
				
		public function set startTime(startTime:String):void {
			_startTime = startTime;
			_streamStartTime = getStartTimeAsSeconds();
		}
		
		public function get startTime():String {
			return _startTime;
		}
		
		public function getStartTimeAsSeconds():int {
			if(_startTime != null) {
				if(Timestamp.validate(_startTime)) {
					return Timestamp.timestampToSeconds(_startTime);
				}
				return parseInt(_startTime);
			}
			return 0;
		}
		
		public function getStartTimeAsSecondsString():String {
			return new String(getStartTimeAsSeconds());
		}

		public function set streamStartTime(streamStartTime:int):void {
			_streamStartTime = streamStartTime;
		}
		
		public function get streamStartTime():int {
			return _streamStartTime;
		}
		
		public function hasDuration():Boolean {
			if(duration != null) {
				return (duration != "00:00:00");			
			}
			return false;
		}
		
		public function hasNonZeroDuration():Boolean {
			if(duration != null) {
				return (getDurationAsInt() > 0);
			}
			return false;
		}
		
		public function hasZeroDuration():Boolean {
			return !hasNonZeroDuration();
		}

		public function isSlicedStream():Boolean {
			return isSlice();
//			return ((getStartTimeAsSeconds() > 0) || (getOriginalDurationAsInt() > getDurationAsInt()));
		}
		
		public function isFirstSlice():Boolean {
			var startInSeconds:int = getStartTimeAsSeconds();
			return (startInSeconds == 0 || (startInSeconds > 0 && this.hasOffsetStartTime));
		}
				
		public function set originalDuration(duration:String):void {
			_originalDuration = duration;
		}
		
		public function get originalDuration():String {
			return _originalDuration;
		}
		
		public function getOriginalDurationAsInt():int {
			return parseInt(_originalDuration);
		}
		
		public function set duration(duration:String):void {
			doLog("Setting the duration for stream " + streamName + " to " + duration, Debuggable.DEBUG_CONFIG);
			_duration = duration;
			_trackingPointsSet = false;
			declareTrackingPoints(0);
		}
		
		public function get duration():String {
			return ((_duration == null) ? "0" : _duration);
		}
		
		public function getDurationAsInt():int {
			return parseInt(duration);		
		}
		
		public function durationToTimestamp():String {
			return Timestamp.secondsToTimestamp(parseInt(_duration));
		}
		
		public function set reduceLength(reduceLength:Boolean):void {
			_reduceLength = reduceLength;
		}
		
		public function get reduceLength():Boolean {
			return _reduceLength;
		}

		public function isRTMP():Boolean {
			var streamURL:NetworkResource = getStreamToPlay();
			if(streamURL != null) {
				if(streamURL.isQualified()) {
					return streamURL.isRTMP();
				}
				else {
					if(hasBaseURL()) {
						var defaultURL:NetworkResource = new NetworkResource(null, baseURL);
						return defaultURL.isRTMP();
					}
				}
			}	
			return false;
		}
			
		public function getStreamToPlay():NetworkResource {
			return new NetworkResource(null, _streamName);
		}
		
		protected function ensureEndSlash(url:String):String {
			var cleanURL:String = StringUtils.trim(url);
			if(cleanURL.lastIndexOf("/") == (cleanURL.length - 1)) {
				return cleanURL;
			}
			else return cleanURL + "/";
		}
		
		public function get url():String {
			var streamURL:NetworkResource = getStreamToPlay();
			if(streamURL != null) {
				if(streamURL.isQualified()) {
					return streamURL.url;											
				}
				else {
					if(hasBaseURL()) {
						return ensureEndSlash(_baseURL) + stripPrefix(streamURL.url);
					}
					else return streamURL.url;
				}
			}
			return null;
		}

        public function set baseURL(baseURL:String):void {
        	_baseURL = baseURL;
        }
        
        public function get baseURL():String {
			var streamURL:NetworkResource = getStreamToPlay();
			if(streamURL != null) {
				if(streamURL.isQualified()) {
					return streamURL.netConnectionAddress;					
				}
				else if(hasBaseURL()) {
					return _baseURL;
				}
			}	
			return null;
        }

		public function hasBaseURL():Boolean {		
			return (_baseURL != null);
		}
		
		public function isLinear():Boolean {
			return true;
		}

		public function canScale():Boolean {
			return false;
		}
		
		public function shouldMaintainAspectRatio():Boolean {
			return false;			
		}
				        
		protected function stripPrefix(rawName:String):String {
			if(rawName != null) {
				if(rawName.indexOf("mp4:") >= 0) {
					return rawName.substr(rawName.indexOf("mp4:")+4);
				}
				else if(rawName.indexOf("flv:") >= 0) {
					return rawName.substr(rawName.indexOf("flv:")+4);
				}
				return rawName;
			}
			return null;			
		}
		
		public function get streamName():String {
			var streamURL:NetworkResource = getStreamToPlay();
			return cleanseStreamName(streamURL.getFilename(streamType + ":"));	
		}
		
		public function get streamNameWithoutPrefix():String {
			return stripPrefix(streamName);
		}
		
		protected function cleanseStreamName(rawName:String):String {
            if(rawName != null) {
				// first check if there is a netConnectionURL in the rawname - if so, remove it (we use the config netConnection setting)
				if(rawName.indexOf("mp4:") != 0 || rawName.indexOf("flv:") != 0) {
					if(rawName.indexOf("mp4:") > 0) {
						rawName = rawName.substr(rawName.indexOf("mp4:"));
					}
					else if(rawName.indexOf("flv:") > 0) {
						rawName = rawName.substr(rawName.indexOf("flv:"));
					}
				}
				
				// Now check if it's an FLV file - if so, clean up the flv: tag
				if(rawName.indexOf("flv:") > -1) {
					// if it's an FLV file, remove the flv: and any .flv extension
	                var pattern:RegExp = /flv:/g;  
	                return rawName.replace(pattern, "");
/* REMOVED - NEEDS TO BE CONFIG DRIVEN	                
	                var cleanName:String = rawName.replace(pattern, "");
	                pattern = /.flv/g;
	                return cleanName.replace(pattern, "");
*/	                
				}
				return rawName;	            	
            }            
            return null;
		}

		protected function markTrackingPointsAsSet():void {
			_trackingPointsSet = true;
		}
		
		protected function clearTrackingTable():void {
			doLog("Clearing the old tracking table attached to stream " + _streamName, Debuggable.DEBUG_CONFIG);
			_trackingTable = new TrackingTable(id, key, originatingStreamIndex); 
		}
		
		public function setTrackingPoint(trackingPoint:TrackingPoint, overrideSetFlag:Boolean=false, fireTrackingEvent:Boolean=true, isChildLinear:Boolean=false):void {
			if(overrideSetFlag || _trackingPointsSet == false) {
				_trackingTable.setPoint(trackingPoint, isChildLinear);
				if(fireTrackingEvent) {
					if(_vastController != null) _vastController.onSetTrackingPoint(trackingPoint);
				}
			}
			else doLog("Not setting StreamSegment tracking point - already set once", Debuggable.DEBUG_CUEPOINT_FORMATION);				
		}
		
		public function declareTrackingPoints(currentTimeInSeconds:int=0):void {
			if(_trackingPointsSet == false) {
				clearTrackingTable();
				var timeFactor:int = 1000; 
				if(getDurationAsInt() > 0) {
					setTrackingPoint(new TrackingPoint((currentTimeInSeconds * timeFactor) + _vastController.startStreamSafetyMargin , "BS"));
					if(!_vastController.trackStreamSlices && isSlicedStream()) {
						setTrackingPoint(new TrackingPoint(((currentTimeInSeconds + getOriginalDurationAsInt()) * timeFactor) - _vastController.endStreamSafetyMargin, "ES"));						
					}
					else setTrackingPoint(new TrackingPoint(((currentTimeInSeconds + getDurationAsInt()) * timeFactor) - _vastController.endStreamSafetyMargin, "ES"));
				}
				else doLog("Not setting tracking points for stream with index _" + 0 + " because of 0 duration", Debuggable.DEBUG_CUEPOINT_FORMATION);				
				markTrackingPointsAsSet();
			}
			else doLog("No setting StreamSegment tracking points - already set once", Debuggable.DEBUG_CUEPOINT_FORMATION);
		}
		
		public function getTrackingTable():TrackingTable {
			return _trackingTable;
		}

		public function resetAllTrackingPoints():void {
			if(_trackingTable != null) _trackingTable.resetAllTrackingPoints();
		}
		
		public function resetRepeatableTrackingPoints():void {
			if(_trackingTable != null) _trackingTable.resetRepeatableTrackingPoints();
		}
		
        public function processTimeEvent(timeEvent:TimeEvent, includeChildLinear:Boolean=true):void {
        	var trackingPoints:Array = _trackingTable.activeTrackingPoints(timeEvent, includeChildLinear);
        	for(var i:int=0; i < trackingPoints.length; i++) {
        		var trackingPoint:TrackingPoint = trackingPoints[i];
	        	if(trackingPoint != null) {
			 		doLog("Stream: " + id + " matched request to process tracking event of type " + trackingPoint.label, Debuggable.DEBUG_CUEPOINT_EVENTS);
	        		switch(trackingPoint.label) {
	        			case "BS":
	        				processStartStream();
			        		_vastController.onProcessTrackingPoint(trackingPoint);
	        				break;
	        				
	        			case "ES":
	        				processStreamComplete();
			        		_vastController.onProcessTrackingPoint(trackingPoint);
	        				break;
	
	        			default:
	        				break;
	        		}
	        	}        		
        	}
        }		

		public function processStartStream():void {
			doLog("Stream " + streamName + " started", Debuggable.DEBUG_TRACKING_EVENTS);
			if(fireTrackingEvents) ExternalInterface.call("onShowStart", streamName, _key);
		}

	 	public function processStopStream():void {
			doLog("Stream " + streamName + " stopped", Debuggable.DEBUG_TRACKING_EVENTS);
			if(fireTrackingEvents) ExternalInterface.call("onShowStopped", streamName, _key);
	 	}

		public function processStreamComplete():void {
			doLog("Stream " + streamName + " complete", Debuggable.DEBUG_TRACKING_EVENTS);
			if(fireTrackingEvents) ExternalInterface.call("onShowComplete", streamName, _key);
		}
		
		public function processPauseStream():void {
			doLog("Stream " + streamName + " paused", Debuggable.DEBUG_TRACKING_EVENTS);
			if(fireTrackingEvents) ExternalInterface.call("onShowPaused", streamName, _key);
		}

		public function processResumeStream():void {
			doLog("Stream " + streamName + " resumed", Debuggable.DEBUG_TRACKING_EVENTS);
			if(fireTrackingEvents) ExternalInterface.call("onShowResumed", streamName, _key);
		}

        public function processFullScreenEvent():void {	
			doLog("Stream " + streamName + " full screen event", Debuggable.DEBUG_TRACKING_EVENTS);        
			if(fireTrackingEvents) ExternalInterface.call("onShowFullscreen", streamName, _key);
        }

        public function processFullScreenExitEvent():void {	
			doLog("Stream " + streamName + " full screen event", Debuggable.DEBUG_TRACKING_EVENTS);        
			if(fireTrackingEvents) ExternalInterface.call("onShowExitFullscreen", streamName, _key);
        }

        public function processMuteEvent():void {	
			doLog("Stream " + streamName + " mute event", Debuggable.DEBUG_TRACKING_EVENTS);        
			if(fireTrackingEvents) ExternalInterface.call("onShowMute", streamName, _key);
        }

        public function processUnmuteEvent():void {	
			doLog("Stream " + streamName + " unmute event", Debuggable.DEBUG_TRACKING_EVENTS);        
			if(fireTrackingEvents) ExternalInterface.call("onShowUnmute", streamName, _key);
        }
        
        protected function turnOnSeekerBar():void {	
        	if(_vastController != null) {
        		_vastController.onToggleSeekerBar(true);
        	}
        }
        
        protected function turnOffSeekerBar():void {
        	if(_vastController != null) {
        		_vastController.onToggleSeekerBar(false);
        	}
        }
        
        public function toString():String {
			return "key: " + key +
			       ", id: " + id + 
			       ", originatingStreamIndex: " + originatingStreamIndex + 
			       ", baseURL: " + baseURL +
			       ", streamName: " + streamName +
			       ", startTime: " + startTime + 
			       ", duration: " + duration + 
			       ", originalDuration: " + originalDuration + 
			       ", reduceLength: " + reduceLength +
			       ", hasOffsetStartTime: " + hasOffsetStartTime + 
			       ", isSlice: " + isSlice() +
			       ", streamType: " + streamType +
			       ", bitrate: " + bitrate +
			       ", mimeType: " + mimeType +
			       ", deliveryType: " + deliveryType +
			       ", playOnce: " + playOnce +
			       ", metaData: " + metaData +
			       ", previewImage: " + previewImage + 
			       ", fireTrackingEvents: " + fireTrackingEvents;
        }
	}
}