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
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.util.NetworkResource;
	import org.openvideoads.util.Timestamp;

	/**
	 * @author Paul Schulz
	 */
	public class LinearVideoAd extends TrackedVideoAd {
		private var _duration:String; // hh:mm:ss
		private var _mediaFiles:Array = new Array();

		public function LinearVideoAd() {
			super();
		}

		public function set duration(duration:String):void {
			_duration = duration;
		}
		
		public function get duration():String {
			return _duration;
		}
		
		public function setDurationFromSeconds(durationAsSeconds:int):void {
			_duration = Timestamp.secondsToTimestamp(durationAsSeconds);
			doLog("Linear video ad duration has been changed to " + _duration, Debuggable.DEBUG_CONFIG);
		}		
		
		public function set mediaFiles(mediaFiles:Array):void {
			_mediaFiles = mediaFiles;
		}
		
		public function get mediaFiles():Array {
			return _mediaFiles;
		}
		
		public function addMediaFile(mediaFile:MediaFile):void {
			_mediaFiles.push(mediaFile);
		}
		
		public function getSpecificallyRatedMediaFile(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):MediaFile {
			doLog("Searching for linear ad SPECIFICALLY matching type: " + mimeType + ", bitrate: " + bitrate + ", width: " + width + ", height: " + height, Debuggable.DEBUG_SEGMENT_FORMATION);
			var bestMatch:MediaFile = null;
			var bitrateVariation:int = -1;
			var widthVariation:int = -1;
			var heightVariation:int = -1;
			if(_mediaFiles != null && _mediaFiles.length > 0) {
				for(var i:int = 0; i < _mediaFiles.length; i++) {
					if(_mediaFiles[i].isDeliveryType(deliveryType) && _mediaFiles[i].isMimeType(mimeType)) {
						if(bitrate == -1) {
							if(width == -1 && height == -1) {
								bestMatch = _mediaFiles[i];
								i = _mediaFiles.length;
							}
							else if(width > -1) { // we have a width requirement but possibly no height requirement
								if(widthVariation == -1 || Math.abs(width - _mediaFiles[i].width) < widthVariation) {
									if(height > -1) {
										if(heightVariation == -1 || Math.abs(height - _mediaFiles[i].height) < heightVariation) {
											bestMatch = _mediaFiles[i];
											heightVariation = Math.abs(height - _mediaFiles[i].height);
											widthVariation = Math.abs(width - _mediaFiles[i].width);
										}
									}
									else {
										bestMatch = _mediaFiles[i];
										widthVariation = Math.abs(width - _mediaFiles[i].width);
									}
								}
							}
							else { // we have a height requirement but no width requirement
								if(heightVariation == -1 || Math.abs(height - _mediaFiles[i].height) < heightVariation) {
									bestMatch = _mediaFiles[i];
									heightVariation = Math.abs(height - _mediaFiles[i].height);
								}
							}
						}
						else {
							// we have a bit rate requirement and possibly a height and width requirement as well
							if(bitrateVariation == -1 || _mediaFiles[i].hasBitRate()) {
								if(bitrateVariation == -1 || Math.abs(_mediaFiles[i].bitRate - bitrate) < bitrateVariation) {
									if(_mediaFiles[i].hasBitRate()) {
										bitrateVariation = Math.abs(_mediaFiles[i].bitRate - bitrate);	
									}
									if(width == -1 && height == -1) {
										bestMatch = _mediaFiles[i];
									}
									else if(width > -1) { // we have a width requirement but possibly no height requirement
										if(widthVariation == -1 || Math.abs(width - _mediaFiles[i].width) < widthVariation) {
											if(height > -1) {
												if(heightVariation == -1 || Math.abs(height - _mediaFiles[i].height) < heightVariation) {
													bestMatch = _mediaFiles[i];
													heightVariation = Math.abs(height - _mediaFiles[i].height);
													widthVariation = Math.abs(width - _mediaFiles[i].width);
												}
											}
											else {
												bestMatch = _mediaFiles[i];
												widthVariation = Math.abs(width - _mediaFiles[i].width);
											}
										}
									}
									else { // we have a height requirement but no width requirement
										if(heightVariation == -1 || Math.abs(height - _mediaFiles[i].height) < heightVariation) {
											bestMatch = _mediaFiles[i];
											heightVariation = Math.abs(height - _mediaFiles[i].height);
										}
									}									
								}
							}
						}
					}
				}
			}
			
			if(bestMatch != null) {
				doLog("Matched a media file with the parameters - bitrate: " + bestMatch.bitRate + ", width: " + bestMatch.width + ", height: " + bestMatch.height, Debuggable.DEBUG_SEGMENT_FORMATION);	
			}
			else doLog("Could not match a media file for the given search parameters", Debuggable.DEBUG_SEGMENT_FORMATION);
			
			return bestMatch;
		}

		public function getMinimumRatedMediaFile(deliveryType:String, mimeType:String='any', width:int = -1, height:int = -1):MediaFile {
			doLog("Searching for linear ad with LOW bitrate matching type: " + mimeType + ", width: " + width + ", height: " + height, Debuggable.DEBUG_SEGMENT_FORMATION);
			var matchedMediaFile:MediaFile = null;
			if(_mediaFiles != null && _mediaFiles.length > 0) {
				var currentMinBitrate:int = 99999999;
				for(var i:int = 0; i < _mediaFiles.length; i++) {
					if(width == -1 && height == -1) {
						if(_mediaFiles[i].bitRate < currentMinBitrate) {
							matchedMediaFile = _mediaFiles[i];
							currentMinBitrate = _mediaFiles[i].bitRate;
						}
					}
					else if(width == -1 && height > -1) {
						if(height == _mediaFiles[i].height) {
							if(_mediaFiles[i].bitRate < currentMinBitrate) {
								matchedMediaFile = _mediaFiles[i];
								currentMinBitrate = _mediaFiles[i].bitRate;
							}							
						}
					}
					else if(width > -1 && _mediaFiles[i].width == width) {
						if(_mediaFiles[i].bitRate < currentMinBitrate) {
							matchedMediaFile = _mediaFiles[i];
							currentMinBitrate = _mediaFiles[i].bitRate;
						}						
					}
				}
			}

			if(matchedMediaFile != null) {
				doLog("Matched a minimum rate media file with the parameters - bitrate: " + matchedMediaFile.bitRate + ", width: " + matchedMediaFile.width + ", height: " + matchedMediaFile.height, Debuggable.DEBUG_SEGMENT_FORMATION);	
			}
			else doLog("Unable to match a minimum rate media file - null returned", Debuggable.DEBUG_SEGMENT_FORMATION);

			return matchedMediaFile;
		}

		public function getMaximumRatedMediaFile(deliveryType:String, mimeType:String='any', width:int = -1, height:int = -1):MediaFile {
			doLog("Searching for linear ad with HIGH bitrate matching type: " + mimeType + ", width: " + width + ", height: " + height, Debuggable.DEBUG_SEGMENT_FORMATION);
			var matchedMediaFile:MediaFile = null;
			if(_mediaFiles != null && _mediaFiles.length > 0) {
				var currentMaxBitrate:int = -1;
				for(var i:int = 0; i < _mediaFiles.length; i++) {
					if(width == -1 && height == -1) {
						if(_mediaFiles[i].bitRate > currentMaxBitrate) {
							matchedMediaFile = _mediaFiles[i];
							currentMaxBitrate = _mediaFiles[i].bitRate;
						}
					}
					else if(width == -1 && height > -1) {
						if(height == _mediaFiles[i].height) {
							if(_mediaFiles[i].bitRate > currentMaxBitrate) {
								matchedMediaFile = _mediaFiles[i];
								currentMaxBitrate = _mediaFiles[i].bitRate;
							}							
						}
					}
					else if(width > -1 && _mediaFiles[i].width == width) {
						if(_mediaFiles[i].bitRate > currentMaxBitrate) {
							matchedMediaFile = _mediaFiles[i];
							currentMaxBitrate = _mediaFiles[i].bitRate;
						}						
					}
				}
			}

			if(matchedMediaFile != null) {
				doLog("Matched a maximum rate media file with the parameters - bitrate: " + matchedMediaFile.bitRate + ", width: " + matchedMediaFile.width + ", height: " + matchedMediaFile.height, Debuggable.DEBUG_SEGMENT_FORMATION);	
			}
			else doLog("Unable to match a maximum rate media file - null returned", Debuggable.DEBUG_SEGMENT_FORMATION);

			return matchedMediaFile;
		}

		public function getMediumRatedMediaFile(deliveryType:String, mimeType:String='any', width:int = -1, height:int = -1):MediaFile {
			doLog("Searching for linear ad with MID rated bitrate matching type: " + mimeType + ", width: " + width + ", height: " + height, Debuggable.DEBUG_SEGMENT_FORMATION);
			var matchedMediaFile:MediaFile = null;
			if(_mediaFiles != null && _mediaFiles.length > 0) {
				var maxBitrate:int = -1;
				var minBitrate:int = 9999999;
				var matchedIndexes:Array = new Array();
				// first find the min and max bit rates for the matching criteria
				for(var i:int = 0; i < _mediaFiles.length; i++) {
					if(width == -1 && height == -1) {
						if(_mediaFiles[i].bitRate > maxBitrate) {
							maxBitrate = _mediaFiles[i].bitRate;
							matchedMediaFile = _mediaFiles[i];
						}
						if(_mediaFiles[i].bitRate < minBitrate) {
							minBitrate = _mediaFiles[i].bitRate;
						}
						matchedIndexes.push(i);
					}
					else if(width == -1 && height > -1) {
						if(height == _mediaFiles[i].height) {
							if(_mediaFiles[i].bitRate > maxBitrate) {
								maxBitrate = _mediaFiles[i].bitRate;
								matchedMediaFile = _mediaFiles[i];
							}							
							if(_mediaFiles[i].bitRate < minBitrate) {
								minBitrate = _mediaFiles[i].bitRate;
							}
							matchedIndexes.push(i);
						}
					}
					else if(width > -1 && _mediaFiles[i].width == width) {
						if(_mediaFiles[i].bitRate > maxBitrate) {
							maxBitrate = _mediaFiles[i].bitRate;
							matchedMediaFile = _mediaFiles[i];
						}						
						if(_mediaFiles[i].bitRate < minBitrate) {
							minBitrate = _mediaFiles[i].bitRate;
						}
						matchedIndexes.push(i);
					}					
				}
				if(maxBitrate > -1 && minBitrate < 9999999) {
					var estimatedMidpointBitrate:int = minBitrate + ((maxBitrate - minBitrate) / 2);
					for(var j:int=0; j < matchedIndexes.length; j++) {
						if(_mediaFiles[matchedIndexes[j]].bitRate > minBitrate && _mediaFiles[matchedIndexes[j]].bitRate <= estimatedMidpointBitrate) {
							if(estimatedMidpointBitrate - matchedMediaFile.bitRate < 0 ||
							   (estimatedMidpointBitrate - _mediaFiles[matchedIndexes[j]].bitRate < (estimatedMidpointBitrate - matchedMediaFile.bitRate))) {
								matchedMediaFile = _mediaFiles[matchedIndexes[j]];								
							}
							else {
								matchedMediaFile = _mediaFiles[matchedIndexes[j]];
							}
						}
					}
				}
			}

			if(matchedMediaFile != null) {
				doLog("Matched a medium rate media file with the parameters - bitrate: " + matchedMediaFile.bitRate + ", width: " + matchedMediaFile.width + ", height: " + matchedMediaFile.height, Debuggable.DEBUG_SEGMENT_FORMATION);	
			}
			else doLog("Unable to match a medium rate media file - null returned", Debuggable.DEBUG_SEGMENT_FORMATION);

			return matchedMediaFile;
		}
		
		public function getRatedMediaFile(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):MediaFile {
			return getSpecificallyRatedMediaFile(deliveryType, mimeType, bitrate, width, height);
		}

		public function getStreamToPlay(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):NetworkResource {
			var _selectedMedia:MediaFile = getMediaFileToPlay(deliveryType, mimeType, bitrate, width, height);
			if(_selectedMedia != null) {
				return _selectedMedia.url;
			}
			return null;				
		}

		public function getMediaFileToPlay(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):MediaFile {
			if(bitrate is String && bitrate != null) {
				var _selectedMedia:MediaFile = null;
				if(bitrate != null) {
					switch(bitrate.toUpperCase()) {
						case "HIGH":
							return getMaximumRatedMediaFile(deliveryType, mimeType, width, height);
						case "MEDIUM":
							return getMediumRatedMediaFile(deliveryType, mimeType, width, height);
						case "LOW":
							return getMinimumRatedMediaFile(deliveryType, mimeType, width, height);
					}
				}
				return getRatedMediaFile(deliveryType, mimeType, -1, width, height);
			}
			else return getRatedMediaFile(deliveryType, mimeType, bitrate, width, height);
			return null;				
		}
		
		public function canScale(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):Boolean {
			var _selectedMedia:MediaFile = getMediaFileToPlay(deliveryType, mimeType, bitrate, width, height);
			if(_selectedMedia != null) {
				return _selectedMedia.canScale();
			}
			return false;			
		}
		
		public function shouldMaintainAspectRatio(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):Boolean {
			var _selectedMedia:MediaFile = getMediaFileToPlay(deliveryType, mimeType, bitrate, width, height);
			if(_selectedMedia != null) {
				return _selectedMedia.shouldMaintainAspectRatio();
			}
			return true;			
		}	
		
		public function isInteractive(deliveryType:String, mimeType:String='any', bitrate:* = -1, width:int = -1, height:int = -1):Boolean {
			var _selectedMedia:MediaFile = getMediaFileToPlay(deliveryType, mimeType, bitrate, width, height);
			if(_selectedMedia != null) {
				return _selectedMedia.isInteractive();
			}
			return false;						
		}	

		public function clicked():void {
			triggerTrackingEvent(TrackingEvent.EVENT_ACCEPT);
		}
	}
}