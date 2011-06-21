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
	import flash.events.*;
	import flash.net.*;
	import flash.utils.ByteArray;
	import flash.xml.*;
	
	import mx.utils.UIDUtil;
	
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.util.NetworkResource;
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.util.Timestamp;
	import org.openvideoads.vast.server.AdServerRequest;
	
	/**
	 * @author Paul Schulz
	 */
	public class VideoAdServingTemplate extends Debuggable {
		protected var _xmlLoader:URLLoader = null;
		protected var _listener:TemplateLoadListener = null;
		protected var _registeredLoaders:Array = new Array();
		protected var _ads:Array = new Array();
		protected var _templateData:String = "";
		protected var _dataLoaded:Boolean = false;
		protected var _replaceAdIds:Boolean = false;
		protected var _replacementAdIds:Array = null;
		protected var _indexCounters:Array = new Array();
		protected var _uid:String = null;
		protected var _forceImpressionServing:Boolean = false;
		
		/**
		 * The constructor for a VideoAdServingTemplate
		 * 
		 * @param listener an optional VASTLoadListener that will receive a callback when 
		 * the template successfully loads or fails
		 * @param request an optional OpenXVASTAdRequest that is the request URL to call to 
		 * obtain the VAST template from an OpenX Ad Server
		 */		
		public function VideoAdServingTemplate(listener:TemplateLoadListener=null, request:AdServerRequest=null, replaceAdIds:Boolean=false, adIds:Array=null) {
			_uid = UIDUtil.getUID(this);
			if(listener != null) _listener = listener;
			if(request != null) load(request);
			_replaceAdIds = replaceAdIds; 
			_replacementAdIds = adIds;
		}
		
		/**
		 * Makes a request to the VAST Ad Server to retrieve a VAST dataset given the request
		 * parameters before loading up the returned data and making a callback to the VASTLoadListener
		 * registered on construction of the template.
		 * 
		 * @param request the OpenXVASTAdRequest object that specifies the parameters to be passed
		 * to the OpenX Ad Server, including the address of the server itself 
		 */
		public function load(request:AdServerRequest):void {
			var requestString:String = request.formRequest();
			doLog("Loading VAST data from " + request.serverType() + " - request is " + requestString, Debuggable.DEBUG_VAST_TEMPLATE);
			_forceImpressionServing = request.config.forceImpressionServing;
			registerLoader(_uid);
			_xmlLoader = new URLLoader();
			_xmlLoader.addEventListener(Event.COMPLETE, templateLoaded);
			_xmlLoader.addEventListener(ErrorEvent.ERROR, errorHandler);
			_xmlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			_xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_xmlLoader.load(new URLRequest(requestString));
		}
		
		public function canFireAPICalls():Boolean {
			if(_listener != null) {
				return _listener.canFireAPICalls();				
			}
			return false;
		}
		
		protected function replacingAdIds():Boolean {
			return _replaceAdIds;
		}

/* DEPRECIATED
		protected function getReplacementAdId(index:int):String {
			if(_replacementAdIds != null) {
				if(index < _replacementAdIds.length) {
					return _replacementAdIds[index].id;
				}
			}	
			return "no-replacement-id-found";
		}
*/
		
		protected function getReplacementAdId_V2(requiredType:String):String {
			if(_replacementAdIds != null) {
				for each(var adId:Object in _replacementAdIds) {
					if(adId.slotType == requiredType && adId.assigned == false) {
						adId.assigned = true;
						return adId.id;
					}
				}
			}	
			return requiredType + ":not-scheduled";
		}
		
		protected function getReplacementAdIdObjectAtPosition(position:int):Object {
			if(_replacementAdIds != null) {
				if(position < _replacementAdIds.length) {
					return _replacementAdIds[position];				
				}
			}
			return { id:"no-id-found", slotType:"unknown", assigned:false};
		}
		
		public function merge(template:VideoAdServingTemplate):void {
			if(template.hasAds()) {
				_ads = _ads.concat(template.ads);
			}
			_templateData += template.getRawTemplateData();
		}
		
		protected function templateLoaded(e:Event):void {
			doLog("Loaded " + _xmlLoader.bytesLoaded + " bytes for the VAST template", Debuggable.DEBUG_VAST_TEMPLATE);
			doTrace(_xmlLoader, Debuggable.DEBUG_VAST_TEMPLATE);
			_templateData = _xmlLoader.data;
			parseFromRawData(_templateData);
			doLogAndTrace("VAST Template parsed and ready to use", this, Debuggable.DEBUG_VAST_TEMPLATE);
			_dataLoaded = true;
			signalTemplateLoaded(_uid);
		}
		
		protected function errorHandler(e:Event):void {
			doLog("VideoAdServingTemplate: HTTP ERROR: " + e.toString(), Debuggable.DEBUG_FATAL);
			signalTemplateLoadError(_uid, e);
		}
		
		/**
		 * Returns the raw template data that was returned by the Open X VAST server
		 * 
		 * return string the raw data
		 */
		public function getRawTemplateData():String {
			return _templateData;
		}
		
		/**
		 * Returns a version of the raw template data without newlines etc. that break a html textarea
		 * 
		 * return string the raw data minus newlines
		 */
		public function getHtmlFriendlyTemplateData():String {
		    var xmlData:XML = new XML(getRawTemplateData());
			var thePattern:RegExp = /\n/g;
			var encodedString:String = xmlData.toXMLString().replace(thePattern, "\\n");			
			return encodedString;
		}
		
		/**
		 * Identifies whether or not the data has been successfully loaded into the template. Remains false
		 * until the data has been retrieved from the OpenX Ad Server.
		 * 
		 * @return <code>true</code> if the data has been successfully retrieved 
		 */
		public function get dataLoaded():Boolean {
			return _dataLoaded;
		}
	
		public function registerLoader(uid:String):void {
			_registeredLoaders.push(uid);
		}
		
		protected function registeredLoadersIsEmpty():Boolean {
			if(_registeredLoaders.length > 0) {
				for(var i:int=0; i < _registeredLoaders.length; i++) {
					if(_registeredLoaders[i] != null) return false;
				}
			}
			return true;
		}
		
		public function signalTemplateLoaded(uid:String):void {
			var locationIndex:int = _registeredLoaders.indexOf(uid);
			_registeredLoaders[locationIndex] = null;
			if(registeredLoadersIsEmpty()) {
				if(_listener != null) {
					_listener.onTemplateLoaded(this);
				}			
			}
		}

		public function signalTemplateLoadError(uid:String, e:Event):void {
			if(_listener != null) {
				_listener.onTemplateLoadError(e);
			}
		}
		
		/**
		 * Identifies whether or not the data has been successfully loaded into the template. Remains false
		 * until the data has been retrieved from the OpenX Ad Server. Can be forceably set if there
		 * aren't any ads to get data for - hence why there is this public interface
		 * 
		 * @param loadedStatus a boolean value that identifies whether or not the data has been loaded 
		 */
		public function set dataLoaded(loadedStatus:Boolean):void {
			_dataLoaded = loadedStatus;
		}
				
		public function parseFromRawData(rawData:*):void {
			if(rawData != null) {
		      	XML.ignoreWhitespace = true;
				try {
		      		var xmlData:XML = new XML(rawData);
		      		if(xmlData != null) {
			 			doLog("Number of video ad serving templates returned = " + xmlData.length(), Debuggable.DEBUG_VAST_TEMPLATE);
			 			if(xmlData.length() > 0) {
			 				var tagName:String = xmlData.name();
			 				if(tagName != null) {
				 				if(tagName.indexOf("VAST") > -1) {
				 					// It's at least a V2 spec since this tag was introduced in V2
				 					if(xmlData.attribute("version") == "2.0") {
				 						parseAdSpecs_V2(xmlData.children());
				 					}
				 					else doLog("Version " + xmlData.attribute("version") + " of VAST is not currently supported.");
				 				}
				 				else {
				 					parseAdSpecs_V1(xmlData.children());
				 				}	 					
			 				}
			 				else doLog("VAST response is not a valid XML response - ignoring response", Debuggable.DEBUG_FATAL);
			 			}
			 			else doLog("VAST response does not seem to have any tags - ignoring response", Debuggable.DEBUG_FATAL);		      			
		      		}
		      		else doLog("Cannot parse the XML Response - XML object is null - ignoring response", Debuggable.DEBUG_FATAL);
				}
				catch(errObject:Error) {
					doLog("XML Parsing exception ('" + errObject.toString() + "') - tag structure is non-compliant - ignoring response", Debuggable.DEBUG_FATAL);
				}		      	
			}
			else doLog("Null VAST response - ignoring response", Debuggable.DEBUG_FATAL);
		}
		
		/* VAST V1.0 PARSING *****************************************************************/
		
		private function parseAdSpecs_V1(ads:XMLList):void {
			doLog("Parsing a V1.0 VAST response - " + ads.length() + " ads in the template...", Debuggable.DEBUG_VAST_TEMPLATE);
			for(var i:int=0; i < ads.length(); i++) {
				var adIds:XMLList = ads[i].attribute("id");
				if(ads[i].children().length() == 1) {
					var vad:VideoAd = parseAdResponse_V1(i, adIds[0], ads[i]);
					vad.forceImpressionServing = _forceImpressionServing;
					if(vad != null) addVideoAd(vad);
				}
				else doLog("No InLine tag found for Ad - " + adIds[0] + " - ignoring this entry", Debuggable.DEBUG_VAST_TEMPLATE);	
			}
			doLog("Parsing DONE", Debuggable.DEBUG_VAST_TEMPLATE);
		}
		
		private function parseAdResponse_V1(adRecordPosition:int, adId:String, adResponse:XML):VideoAd {
			doLog("Parsing ad record at position " + adRecordPosition + " with ID " + adId, Debuggable.DEBUG_VAST_TEMPLATE);
			if(adResponse.InLine != undefined) {
				return parseInlineAd_V1(adRecordPosition, adId, adResponse.children()[0]);
			}
			else return parseWrappedAd_V1(adRecordPosition, adId, adResponse.children()[0]);
		}

        private function parseWrappedAd_V1(adRecordPosition:int, adId:String, wrapperXML:XML):WrappedVideoAd {
			doLog("Parsing 1.0 XML Wrapper Ad record at position " + adRecordPosition + " with ID " + adId, Debuggable.DEBUG_VAST_TEMPLATE);
			if(wrapperXML.children().length() > 0) {
				return new WrappedVideoAd(getReplacementAdIdObjectAtPosition(adRecordPosition), wrapperXML, this);	
			}
			else doLog("No tags found for Wrapper " + adId + " - ignoring this entry", Debuggable.DEBUG_VAST_TEMPLATE);
        	return null;
        }	

		private function parseInlineAd_V1(adRecordPosition:int, adId:String, ad:XML):VideoAd {
			doLog("Parsing 1.0 INLINE Ad record at position " + adRecordPosition + " with ID " + adId, Debuggable.DEBUG_VAST_TEMPLATE);
			doLog("Ad has " + ad.children().length() + " attributes defined - see trace", Debuggable.DEBUG_VAST_TEMPLATE);
			doTrace(ad, Debuggable.DEBUG_VAST_TEMPLATE);
			if(ad.children().length() > 0) {
				var vad:VideoAd = new VideoAd();
				vad.adSystem = ad.AdSystem;
				vad.adTitle = ad.AdTitle;
				vad.description = ad.Description;
				vad.survey = ad.Survey;
				vad.error = ad.Error;
				vad.parseImpressions(ad);
				vad.parseTrackingEvents(ad);
				if(ad.Video != undefined) vad.parseLinears(ad);
				if(ad.NonLinearAds != undefined) vad.parseNonLinears(ad);
				if(ad.CompanionAds != undefined) vad.parseCompanions(ad);
				if(replacingAdIds()) {
					vad.id = getReplacementAdId_V2(((vad.isNonLinear()) ? "non-linear" : "linear"));
					doLog("Have replaced the received Ad ID " + adId + " with " + vad.id + " (" + adRecordPosition + ")");
				}
				else vad.id = adId;
				if(_listener != null) vad.setCanFireAPICalls(_listener.canFireAPICalls());
				doLog("Parsing V1.0 ad record " + adId + " done", Debuggable.DEBUG_VAST_TEMPLATE);
				doTrace(vad, Debuggable.DEBUG_VAST_TEMPLATE);
				return vad;
			}
			else doLog("No tags found for Ad " + adId + " - ignoring this entry", Debuggable.DEBUG_VAST_TEMPLATE);
			return null;
		}

		/* VAST V2.0 PARSING *****************************************************************/

		private function parseAdSpecs_V2(ads:XMLList):void {
			doLog("Parsing a V2.0 VAST response - " + ads.length() + " ads in the template...", Debuggable.DEBUG_VAST_TEMPLATE);
			for(var i:int=0; i < ads.length(); i++) {
				var adIds:XMLList = ads[i].attribute("id");
				if(ads[i].children().length() == 1) {
					parseAdResponse_V2(i, adIds[0], ads[i]);
				}
				else doLog("No InLine tag found for Ad - " + adIds[0] + " - ignoring this entry", Debuggable.DEBUG_VAST_TEMPLATE);	
			}
			doLog("Parsing DONE", Debuggable.DEBUG_VAST_TEMPLATE);
		}
		
		private function parseAdResponse_V2(adRecordPosition:int, templateAdId:String, adResponse:XML):void {
			doLog("Parsing ad record at position " + adRecordPosition + " with ID " + templateAdId, Debuggable.DEBUG_VAST_TEMPLATE);
			if(adResponse.InLine != undefined) {
				parseInlineAd_V2(adRecordPosition, templateAdId, adResponse.children()[0]);
			}
			else doLog("FATAL: V2.0 XML WRAPPER NOT IMPLEMENTED!");
//			else return parseWrappedAd_V1(adRecordPosition, templateAdId, adResponse.children()[0]);
		}

        private function parseImpressions_V2(ad:XML):Array {
			var result:Array = new Array();
			if(ad.Impression != null) {
				var impressionList:XMLList = ad.Impression;
				doLog("Parsing V2.0 impression tags - " + impressionList.length() + " impressions specified...", Debuggable.DEBUG_VAST_TEMPLATE);
				for each (var impressionElement:XML in impressionList) {
					result.push(new Impression(impressionElement.@id, impressionElement.text()));
				}
			}
			return result;      	
        }

		private function createVideoAd_V2(defaultAdId:String, ad:XML, creativeId:String, sequenceId:String, type:String, inlineAdId:String):VideoAd {
			var vad:VideoAd = new VideoAdV2();
			if(replacingAdIds()) {
				vad.id = getReplacementAdId_V2(type);
			}
			else vad.id = defaultAdId;
			vad.inlineAdId = inlineAdId;
			vad.adId = defaultAdId;
			vad.creativeId = creativeId;
			vad.sequenceId = sequenceId;
			vad.adSystem = ad.AdSystem;
			vad.adTitle = ad.AdTitle;
			vad.description = ad.Description;
			vad.survey = ad.Survey;
			vad.error = ad.Error;
			vad.forceImpressionServing = _forceImpressionServing;
			doLog("Created new VideoAd(" + type + ") adId: '" + vad.adId + "', creativeID: '" + creativeId + "', sequenceID: '" + sequenceId + "' - internal ID set as '" + vad.id + "'", Debuggable.DEBUG_VAST_TEMPLATE);
			return vad;
		}
		
		private function cloneCompanions(companions:Array, videoAd:VideoAd):Array {
			var companionsCopy:Array = new Array();
			var companionCopy:CompanionAd;
			for each(var companion:CompanionAd in companions) {
				companionCopy = companion.clone();
				companionCopy.parentAdContainer = videoAd;
				companionsCopy.push(companionCopy);
			}
			return companionsCopy;			
		}
		
		private function parseInlineAd_V2(adRecordPosition:int, templateAdId:String, ad:XML):void {
			var internalInlineAdID:String = UIDUtil.createUID();
			doLog("Parsing V2.0 INLINE Ad record at position " + adRecordPosition + " with Template AdID '" + templateAdId + "' - assigned internal inline ad id '" + internalInlineAdID + "'", Debuggable.DEBUG_VAST_TEMPLATE);
			doTrace(ad, Debuggable.DEBUG_VAST_TEMPLATE);
			if(ad.children().length() > 0) {
				var impressions:Array = parseImpressions_V2(ad);
				var creativesList:XMLList = ad.Creatives;
				if(creativesList != null) {
					doLog("Parsing V2.0 creatives blocks - " + creativesList.length() + " block of creatives defined ...", Debuggable.DEBUG_VAST_TEMPLATE);
					var attachableCompanions:Array = new Array();
					for(var k:int=0; k < creativesList.length(); k++) {
						var creativeElements:XMLList = creativesList[k].Creative;	
						if(creativeElements != null) {
							doLog("Parsing V2.0 creative block (" + k + ") - this block has " + creativeElements.length() + " elements ...", Debuggable.DEBUG_VAST_TEMPLATE);
							var counter:int = 1;
							var linears:Array = new Array();
							var nonLinears:Array = new Array();
							var companions:Array = new Array();
							for each (var creative:XML in creativeElements) {
								var adId:String = creative.attribute("AdID");
								var creativeId:String = creative.attribute("id");
								var sequenceId:String = creative.attribute("sequence");
								doLog("Parsing V2.0 creative (" + counter + ") creativeID '" + creativeId + "' SequenceID '" + sequenceId + "' ...", Debuggable.DEBUG_VAST_TEMPLATE);
								resetCompanionIndexCounters();
								linears = parseLinearAds_V2(creative.Linear);
								nonLinears = parseNonLinearAds_V2(creative.NonLinearAds);
								companions = parseCompanionAds_V2(creative.CompanionAds);

								// Ok, now let's create the set of VideoAds that correlate to the linear, non-linear and companion creatives specified
								var vad:VideoAd = null;
								for each(var linear:LinearVideoAd in linears) {
									vad = createVideoAd_V2(adId, ad, creativeId, sequenceId, VideoAd.AD_TYPE_LINEAR, internalInlineAdID);
									if(impressions.length > 0) vad.impressions = impressions;
									vad.linearVideoAd = linear;
									if(companions.length > 0) {
										vad.companionAds = cloneCompanions(companions, vad);
										doLog("Have attached " + companions.length + " companions to linear ad '" + vad.id + "'", Debuggable.DEBUG_VAST_TEMPLATE);
									}
									addVideoAd(vad);
								}	

								if(nonLinears.length > 0) {
									vad = createVideoAd_V2(adId, ad, creativeId, sequenceId, VideoAd.AD_TYPE_NON_LINEAR, internalInlineAdID);
									if(impressions.length > 0) vad.impressions = impressions;
									vad.nonLinearVideoAds = nonLinears;
									if(companions.length > 0) {
										vad.companionAds = cloneCompanions(companions, vad);
										doLog("Have attached " + companions.length + " companions to non-linear ad '" + vad.id + "'", Debuggable.DEBUG_VAST_TEMPLATE);
									}
									addVideoAd(vad);
								}	
								
								if((linears.length == 0 && nonLinears.length == 0) || false) { // change false to config.scheduleCompanionsSeparately
									vad = createVideoAd_V2(adId, ad, creativeId, sequenceId, VideoAd.AD_TYPE_COMPANION, internalInlineAdID);
									if(impressions.length > 0) vad.impressions = impressions;
									addVideoAd(vad);
									attachableCompanions.push(
										{ 
											"adId": adId,
											"creativeId": creativeId,
											"sequenceId": sequenceId,
											"companions": companions
										} 
									);
								}
								
								++counter;
							}								
						}
					}					

					// COMPANION MATCHING: Ok, go back over the ad list and match up companions as needed - two pass process
					
					// PASS 1 - Match companions that don't have a sequence or creative ID specified - basically attach these ownerless 
					// companions to every video ad that doesn't already have companions attached.
					
					var attachableCompanion:Object;
					var videoAd:VideoAd;
					doLog("Companion matching PASS 1 - attach ownerless companions to creatives within video ad that don't already have companions", Debuggable.DEBUG_VAST_TEMPLATE);
					for each(attachableCompanion in attachableCompanions) {
						for each(videoAd in _ads) {
							if(videoAd.belongsToInlineAd(internalInlineAdID)) {
								if(videoAd.adType != VideoAd.AD_TYPE_COMPANION && !videoAd.hasCompanionAds()) {
									if(attachableCompanion.creativeId == null && attachableCompanion.sequenceId == null) {
	  									doLog("Attaching companions PASS 1 (sequence: '" + attachableCompanion.sequenceId + "', creativeID: '" + attachableCompanion.creativeId + "', AdID: '" + attachableCompanion.adId + "') to video ad '" + videoAd.adType + ": " + videoAd.id + "'", Debuggable.DEBUG_VAST_TEMPLATE);
										videoAd.companionAds = cloneCompanions(attachableCompanion.companions, videoAd); 
									}	 								
								}								
							}
						}
					}
					
					// PASS 2 - Now match up companions that do have a sequence or creative ID specified
					// overwriting the blanket coverage of PASS 1

					doLog("Companion matching PASS 2 - match up companions based on sequence or creative ID", Debuggable.DEBUG_VAST_TEMPLATE);
					for each(attachableCompanion in attachableCompanions) {
						for each(videoAd in _ads) {
							if(videoAd.belongsToInlineAd(internalInlineAdID)) {
								if(videoAd.adType != VideoAd.AD_TYPE_COMPANION) {
								if((videoAd.sequenceId != null && (videoAd.sequenceId == attachableCompanion.sequenceId)) ||
								   (videoAd.creativeId != null && (videoAd.creativeId == attachableCompanion.creativeId))) { 
//									if(StringUtils.matchesAndHasValue(videoAd.sequenceId, attachableCompanion.sequenceId) ||
//									   StringUtils.matchesAndHasValue(videoAd.creativeId, attachableCompanion.creativeId)) {
		  									doLog("Attaching companions PASS 2 (sequence: '" + attachableCompanion.sequenceId + "', creativeID: '" + attachableCompanion.creativeId + "', AdID: '" + attachableCompanion.adId + "') to video ad '" + videoAd.adType + ": " + videoAd.id + "'", Debuggable.DEBUG_VAST_TEMPLATE);
											videoAd.companionAds = cloneCompanions(attachableCompanion.companions, videoAd); 
									}	 								
								}
							}
						}
					}
				}
			}
			else doLog("No tags found for Ad " + adId + " - ignoring this entry", Debuggable.DEBUG_VAST_TEMPLATE);
		}

		protected function resetCompanionIndexCounters():void {
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
		
		protected function parseLinearAds_V2(linearAds:XMLList):Array {
			var result:Array = new Array();
			if(linearAds.length() > 0) {
				doLog("Parsing V2.0 Linear Ad tags - " + linearAds.length() + " ads specified...", Debuggable.DEBUG_VAST_TEMPLATE);
  				for each(var ad:XML in linearAds) {
					var linearVideoAd:LinearVideoAd = new LinearVideoAd();
					linearVideoAd.index = linearAds.length();
		//			linearVideoAd.adID = ad.Video.AdID;
					if(Timestamp.validate(ad.Duration)) {
						linearVideoAd.duration = ad.Duration;
					}
					else {
						linearVideoAd.duration = Timestamp.secondsStringToTimestamp(ad.Duration);
						doLog("Duration has been specified in non-compliant manner (hh:mm:ss) - assuming seconds - converted to: " + linearVideoAd.duration, Debuggable.DEBUG_VAST_TEMPLATE);
					}
					if(ad.VideoClicks != undefined) {
						var clickList:XMLList;
						if(ad.VideoClicks.ClickThrough != undefined) {
							doLog("Parsing V2.0 Linear VideoClicks.ClickThrough tags...", Debuggable.DEBUG_VAST_TEMPLATE);
							for each (var clickThroughElement:XML in ad.VideoClicks.ClickThrough) {
								if(!StringUtils.isEmpty(clickThroughElement.text())) {
									linearVideoAd.addClickThrough(new NetworkResource(clickThroughElement.@id, clickThroughElement.text()));
								}
							}
							doLog(linearVideoAd.clickThroughCount() + " Linear ClickThroughs recorded", Debuggable.DEBUG_VAST_TEMPLATE);        	
						}
						if(ad.VideoClicks.ClickTracking != undefined) {
							doLog("Parsing V2.0 Linear VideoClicks.ClickTracking tags...", Debuggable.DEBUG_VAST_TEMPLATE);
							for each (var clickTrackingElement:XML in ad.VideoClicks.ClickTracking) {
								if(!StringUtils.isEmpty(clickTrackingElement.text())) {
									linearVideoAd.addClickTrack(new NetworkResource(clickTrackingElement.@id, clickTrackingElement.text()));
								}
							}
							doLog(linearVideoAd.clickTrackingCount() + " Linear ClickTracking events recorded", Debuggable.DEBUG_VAST_TEMPLATE);        	
						}
						if(ad.VideoClicks.CustomClick != undefined) {
							doLog("Parsing V2.0 Linear VideoClicks.CustomClick tags...", Debuggable.DEBUG_VAST_TEMPLATE);
							for each (var customClickElement:XML in ad.VideoClicks.CustomClick) {
								if(!StringUtils.isEmpty(customClickElement.text())) {
									linearVideoAd.addCustomClick(new NetworkResource(customClickElement.@id, customClickElement.text()));
								}
							}
							doLog(linearVideoAd.customClickCount() + " Linear CustomClicks recorded", Debuggable.DEBUG_VAST_TEMPLATE);        	
						}				
					}
					if(ad.MediaFiles != undefined) {
						doLog("Parsing V2.0 Linear MediaFiles tags...", Debuggable.DEBUG_VAST_TEMPLATE);
						var mediaFiles:XMLList = ad.MediaFiles.children();
						doLog(mediaFiles.length() + " Linear media files detected", Debuggable.DEBUG_VAST_TEMPLATE);
						for(var i:int = 0; i < mediaFiles.length(); i++) {
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
							mediaFile.url = new NetworkResource(mediaFileXML.@id, mediaFileXML.text());
							linearVideoAd.addMediaFile(mediaFile);
						}
						doLog(mediaFiles.length() + " mediaFiles added");			
					}
					if(ad.TrackingEvents != undefined && ad.TrackingEvents.children() != null) {
						doLog("Parsing V2.0 Linear TrackingEvent tags...", Debuggable.DEBUG_VAST_TEMPLATE);
						var trackingEvents:XMLList = ad.TrackingEvents.children();
						for(var j:int = 0; j < trackingEvents.length(); j++) {
							var trackingEventXML:XML = trackingEvents[j];
							var trackingEvent:TrackingEvent = new TrackingEvent(trackingEventXML.@event);
							var trackingEventURLs:XMLList = trackingEventXML.children();
							trackingEvent.addURL(new NetworkResource(trackingEvents[j].@event, trackingEvents[j].text()));
							linearVideoAd.addTrackingEvent(trackingEvent);				
						}
						doLog(linearVideoAd.trackingEvents.length + " Linear tracking events recorded", Debuggable.DEBUG_VAST_TEMPLATE);
					} 
					result.push(linearVideoAd);
  				}
			}
			return result;	
		}
		
		protected function parseNonLinearAds_V2(nonLinearAds:XMLList):Array {
			var result:Array = new Array();
			if(nonLinearAds.length() > 0) {
				doLog("Parsing V2.0 NonLinearAd tags - " + nonLinearAds.length() + " ads specified...", Debuggable.DEBUG_VAST_TEMPLATE);
  				for each(var ad:XML in nonLinearAds) {
					var nonLinearAds:XMLList = ad.children();
					var i:int=0;
					var trackingEventsHolder:Array = null;
					for(i = 0; i < nonLinearAds.length(); i++) {
						if(nonLinearAds[i].name() == "NonLinear") {
							var nonLinearAdXML:XML = nonLinearAds[i];
							var nonLinearAd:NonLinearVideoAd = null;
							var nonLinearAdID:String = ((nonLinearAdXML.@id != undefined) ? nonLinearAdXML.@id : "" + i);
							
							if(nonLinearAdXML.StaticResource != undefined && nonLinearAdXML.StaticResource != null) {
								if(nonLinearAdXML.StaticResource.@creativeType != undefined && nonLinearAdXML.StaticResource.@creativeType != null) {
									switch(nonLinearAdXML.StaticResource.@creativeType.toUpperCase()) {
										case "IMAGE/JPEG":
										case "JPEG":
										case "IMAGE/GIF":
										case "GIF":
										case "IMAGE/PNG":
										case "PNG":
											nonLinearAd = new NonLinearImageAd();
											break;
										case "APPLICATION/X-SHOCKWAVE-FLASH":
										case "SWF":
											nonLinearAd = new NonLinearFlashAd();
											break;
										default:
											nonLinearAd = new NonLinearVideoAd();
									}
									
									nonLinearAd.resourceType = "static"; 
									nonLinearAd.creativeType = nonLinearAdXML.StaticResource.@creativeType; 
									doLog("Parsing static NonLinear Ad (" + nonLinearAdID + ") of creative type " + nonLinearAd.creativeType + " ...", Debuggable.DEBUG_VAST_TEMPLATE);
								}
								else nonLinearAd = new NonLinearVideoAd();					
							}
							else if(nonLinearAdXML.HTMLResource != undefined && nonLinearAdXML.HTMLResource != null) {
								nonLinearAd = new NonLinearHtmlAd();					
								nonLinearAd.resourceType = "static"; 
								nonLinearAd.creativeType = "html"; 
								doLog("Parsing static NonLinear Ad (" + nonLinearAdID + ") of creative type HTML ...", Debuggable.DEBUG_VAST_TEMPLATE);
							}
							else if(nonLinearAdXML.IFrameResource != undefined) {
								doLog("iFrame resource type not currently supported - ad " + nonLinearAdID, Debuggable.DEBUG_VAST_TEMPLATE);					
							}
							else {
								doLog("Unknown non-linear resource type for ad " + nonLinearAdID, Debuggable.DEBUG_VAST_TEMPLATE);
							}
							
							nonLinearAd.index = i;
							nonLinearAd.id = nonLinearAdID;
							nonLinearAd.width = nonLinearAdXML.@width;
							nonLinearAd.height = nonLinearAdXML.@height; 
							nonLinearAd.apiFramework = nonLinearAdXML.@apiFramework; 
							nonLinearAd.expandedWidth = nonLinearAdXML.@expandedWidth; 
							nonLinearAd.expandedHeight = nonLinearAdXML.@expandedHeight; 
							nonLinearAd.scalable = nonLinearAdXML.@scalable; 
							nonLinearAd.maintainAspectRatio = nonLinearAdXML.@maintainAspectRatio; 
							if(nonLinearAdXML.@minSuggestedDuration != undefined) {
								// check to see if this is a timestamp format, or just seconds
								if(Timestamp.validate(nonLinearAdXML.@minSuggestedDuration)) {
									nonLinearAd.recommendedMinDuration = Timestamp.timestampToSecondsString(nonLinearAdXML.@minSuggestedDuration);
									doLog("MinSuggestedDuration converted from '" + nonLinearAdXML.@minSuggestedDuration + "' to '" + nonLinearAd.recommendedMinDuration + "' seconds", Debuggable.DEBUG_VAST_TEMPLATE);
								}
								else nonLinearAd.recommendedMinDuration = nonLinearAdXML.@minSuggestedDuration;
							}
		
							if(nonLinearAd is NonLinearHtmlAd) {
								if(nonLinearAdXML.HTMLResource != undefined) {
									// It's a HTML codeblock
									nonLinearAd.codeBlock = nonLinearAdXML.HTMLResource.text();							
								}
							}
							else {
								if(nonLinearAdXML.StaticResource != undefined) {
									// It's a URI - we only support static resource types at the moment
									nonLinearAd.url = new NetworkResource(null, nonLinearAdXML.StaticResource.text());						
								}
							}
		
							if(nonLinearAdXML.NonLinearClickThrough != undefined) {
								for each (var nonLinearClickThroughElement:XML in nonLinearAdXML.NonLinearClickThrough) {
									if(!StringUtils.isEmpty(nonLinearClickThroughElement.text())) {
										nonLinearAd.addClickThrough(new NetworkResource(null, nonLinearClickThroughElement.text()));
									}
								}
								doLog(nonLinearAd.clickThroughCount() + " NonLinear ClickThroughs recorded", Debuggable.DEBUG_VAST_TEMPLATE);        	
							}
							result.push(nonLinearAd);
						}
						else if(nonLinearAds[i].name() == "TrackingEvents") {
							// put the tracking events into holding storage so they can be added to each non-linear ad 
							// after the full set has been parsed
							doLog("Parsing V2.0 Non-Linear TrackingEvent tags...", Debuggable.DEBUG_VAST_TEMPLATE);
							var trackingEvents:XMLList = nonLinearAds[i].children();
							doLog(trackingEvents.length() + " Non-Linear tracking events detected", Debuggable.DEBUG_VAST_TEMPLATE);
							trackingEventsHolder = new Array();
							for(var l:int = 0; l < trackingEvents.length(); l++) {
								var trackingEventXML:XML = trackingEvents[l];
								var trackingEvent:TrackingEvent = new TrackingEvent(trackingEventXML.@event);
								var trackingEventURLs:XMLList = trackingEventXML.children();
								trackingEvent.addURL(new NetworkResource(trackingEvents[l].@event, trackingEvents[l].text()));
								trackingEventsHolder.push(trackingEvent);				
							}					
						}
						else doLog(nonLinearAds[i].name() + " tags currently not supported for non-linear ads", Debuggable.DEBUG_VAST_TEMPLATE);
					}
					
					// now, set the tracking events on each recorded non-linear ad - if there have been any tracking events specified
					if(trackingEventsHolder != null) {
						doLog("Attaching " + trackingEventsHolder.length + " NonLinear tracking events to " + result.length + " non-linear ads...");
						for each(var nlAd:NonLinearVideoAd in result) {
							nlAd.trackingEvents = clone(trackingEventsHolder);
						}
					}					
  				}
  			}
			return result;
		}
		
        protected function parseCompanionAds_V2(companionAdsXML:XMLList):Array {
        	var result:Array = new Array();
        	if(companionAdsXML.length() > 0) {
				doLog("Parsing V2.0 CompanionAd tags - " + companionAdsXML.children().length() + " companions specified", Debuggable.DEBUG_VAST_TEMPLATE);
  				for each(var companionAdXML:XML in companionAdsXML.children()) {
					var companionAd:CompanionAd = new CompanionAd();
					companionAd.isVAST2 = true;
					companionAd.id = companionAdXML.@id;
					companionAd.width = companionAdXML.@width;
					companionAd.height = companionAdXML.@height; 
					companionAd.index = createIndex(companionAd.width, companionAd.height);
					if(companionAdXML.StaticResource != undefined) {
						companionAd.creativeType = companionAdXML.StaticResource.@creativeType;
						companionAd.resourceType = "STATIC";
						companionAd.url = new NetworkResource(null, companionAdXML.StaticResource.text());
						doLog("Static companion ad (" + companionAd.guid + ") [" + companionAd.width + "," + companionAd.height + "] - creativeType: " + companionAd.creativeType + " - " + companionAdXML.StaticResource.text(), Debuggable.DEBUG_VAST_TEMPLATE);
					}
					else if(companionAdXML.IFrameResource != undefined) {
						companionAd.creativeType = "STATIC";
						companionAd.resourceType = "IFRAME";
						companionAd.url = new NetworkResource(null, companionAdXML.IFrameResource.text());
						doLog("iFrame companion ad (" + companionAd.guid + ") [" + companionAd.width + "," + companionAd.height + "] - creativeType: " + companionAd.creativeType + " - " + companionAdXML.IFrameResource.text(), Debuggable.DEBUG_VAST_TEMPLATE);
					}
					else if(companionAdXML.HTMLResource != undefined) {
						companionAd.creativeType = "TEXT";
						companionAd.resourceType = "HTML";
						companionAd.codeBlock = companionAdXML.HTMLResource.text();
						doLog("HTML companion ad (" + companionAd.guid + ") [" + companionAd.width + "," + companionAd.height + "] - creativeType: " + companionAd.creativeType + " - " + companionAd.codeBlock, Debuggable.DEBUG_VAST_TEMPLATE);
					}
					if(companionAdXML.CompanionClickThrough != undefined) {
						doLog("Parsing V2.0 Companion ClickThrough tags...", Debuggable.DEBUG_VAST_TEMPLATE);
						var caClickList:XMLList = companionAdXML.CompanionClickThrough; //.children();
						doLog(caClickList.length() + " Companion ClickThroughs detected", Debuggable.DEBUG_VAST_TEMPLATE);
						var caClickURL:XML;
						for(var j:int = 0; j < caClickList.length(); j++) {
							caClickURL = caClickList[j];
							companionAd.addClickThrough(new NetworkResource(caClickURL.@id, caClickURL.text()));
						}							
					}
					if(companionAdXML.AltText != undefined) companionAd.altText = companionAdXML.AltText.text();
					if(companionAdXML.TrackingEvents != undefined) {
						doLog("Parsing V2.0 Companion TrackingEvent tags...", Debuggable.DEBUG_VAST_TEMPLATE);
						var trackingEvents:XMLList = companionAdXML.TrackingEvents.children();
						doLog(trackingEvents.length() + " Companion tracking events detected", Debuggable.DEBUG_VAST_TEMPLATE);
						for(var k:int = 0; k < trackingEvents.length(); k++) {
							var trackingEventXML:XML = trackingEvents[k];
							var trackingEvent:TrackingEvent = new TrackingEvent(trackingEventXML.@event);
							var trackingEventURLs:XMLList = trackingEventXML.children();
							trackingEvent.addURL(new NetworkResource(trackingEvents[k].@event, trackingEvents[k].text()));
							companionAd.addTrackingEvent(trackingEvent);				
						}					
					}
					result.push(companionAd);						
				}				
        	}
			return result;	
        }        
				
		/* HELPER METHODS ********************************************************************/

		protected function clone(source:Object):* {
			if(source != null) {
				if(source is Array) {
					var result:Array = new Array();
					for each(var item:* in source) {
						result.push(item.clone());
					}	
					return result;
				}
				else {
				    var myBA:ByteArray = new ByteArray();
				    myBA.writeObject(source);
				    myBA.position = 0;
				    return(myBA.readObject());				
				}
			}
			return null;
		}        

		public function getFirstAd():VideoAd {
			if(_ads != null) {
				if(_ads.length > 0) {
					return _ads[0];
				}
			}	
			return null;
		}
		
		public function hasAds():Boolean {
			if(_ads == null) {
				return false;
			}
			return (_ads.length > 0);
		}
		
		/**
		 * Allows the list of "ads" to be manually set.
		 * 
		 * @param ads an array of VideoAd(s)
		 */
		public function set ads(ads:Array):void {
			_ads = ads;
		}

		/**
		 * Returns the list of video ads that are currently held by the template. If there are no
		 * ads currently being held, a zero length array is returned.
		 * 
		 * @return array an array of VideoAd(s)
		 */
		public function get ads():Array {
			return _ads;
		}		

		/**
		 * Add a VideoAd to the end of the current list of video ads recorded for this template
		 * 
		 * @param ad a VideoAd
		 */
		public function addVideoAd(ad:VideoAd):void {
			_ads.push(ad);
		}
		
		public function getVideoAdWithID(id:String):VideoAd {
			doLog("Looking for a Video Ad " + id, Debuggable.DEBUG_VAST_TEMPLATE);
			if(_ads != null) {
				for(var i:int = 0; i < _ads.length; i++) {
					if(_ads[i].id == id) {
						doLog("Found Video Ad " + id + " - returning", Debuggable.DEBUG_VAST_TEMPLATE);
						return _ads[i];
					}
				}	
				doLogAndTrace("Could not find Video Ad " + id + " in the VAST template", this, Debuggable.DEBUG_VAST_TEMPLATE);
			}
			else doLog("No ads in the list!", Debuggable.DEBUG_VAST_TEMPLATE);
			return null;
		}		
	}
}