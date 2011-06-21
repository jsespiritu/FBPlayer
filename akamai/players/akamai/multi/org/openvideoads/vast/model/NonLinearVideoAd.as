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
	import org.openvideoads.util.NetworkResource;
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.vast.events.OverlayAdDisplayEvent;
	import org.openvideoads.vast.events.VideoAdDisplayEvent;

	/**
	 * @author Paul Schulz
	 */
	public class NonLinearVideoAd extends TrackedVideoAd {
		protected var _width:int=-1;
		protected var _height:int=-1;
		protected var _recommendedMinDuration:int=-1;
		protected var _resourceType:String;
		protected var _creativeType:String;
		protected var _apiFramework:String;
		protected var _url:NetworkResource;
		protected var _codeBlock:String;
		
		public function NonLinearVideoAd() {
			super();
		}
		
		public function set width(width:*):void {
			if(typeof width == 'string') {
				_width = parseInt(width);
			}
			else _width = width;
		}
		
		public function get width():int {
			return _width;
		}
		
		public function hasWidth():Boolean {
			return _width > -1;
		}
		
		public function set height(height:*):void {
			if(typeof height == 'string') {
				_height = parseInt(height);
			}
			else _height = height;
		}
		
		public function get height():int {
			return _height;
		}
		
		public function hasHeight():Boolean {
			return _height > -1;
		}
		
		public function get recommendedMinDuration():int {
			return _recommendedMinDuration;
		}
		
		public function set recommendedMinDuration(recommendedMinDuration:*):void {
			if(typeof recommendedMinDuration == 'string') {
				_recommendedMinDuration = parseInt(recommendedMinDuration);
			}
			else _recommendedMinDuration = recommendedMinDuration;
		}
		
		public function hasRecommendedMinDuration():Boolean {
			return _recommendedMinDuration > -1;
		}
		
		public function set resourceType(resourceType:String):void {
			_resourceType = resourceType.toUpperCase();
		}
		
		public function get resourceType():String {
			return _resourceType;
		}
		
		public function set creativeType(creativeType:String):void {
			_creativeType = creativeType.toUpperCase();
		}
		
		public function get creativeType():String {
			if(_creativeType != null) {
				var slashPos:int = _creativeType.indexOf("/");
				if(slashPos > -1 && (slashPos+1 < _creativeType.length)) {
					// change a mime based type like "image/jpg" or "application/x-shockwave-flash" 
					// to strip out the "initial" bit leaving just the basic type
					return _creativeType.substr(slashPos + 1);	
				}
			}
			return _creativeType;
		}
		
		public function set apiFramework(apiFramework:String):void {
			_apiFramework = apiFramework;
		}
		
		public function get apiFramework():String {
			return apiFramework;
		}
		
		public function set url(url:NetworkResource):void {
			_url = url;
		}
		
		public function get url():NetworkResource {
			return _url;
		}
		
		public function hasUrl():Boolean {
			if(_url != null) {
				return _url.hasUrl();	
			}
			return false;
		}
		
		public function set codeBlock(codeBlock:String):void {
			_codeBlock = codeBlock;
		}
		
		public function get codeBlock():String {
			return _codeBlock;
		}
		
		public function hasCode():Boolean {
			if(_codeBlock != null) {
				return (StringUtils.trim(_codeBlock).length > 0);
			}
			return false;
		}
		
		public function isEmpty():Boolean {
			return !hasUrl() && !hasCode();
		}
		
		public function contentType():String {
			if(isHtml()) return "HTML";
			if(isFlash()) return "SWF";
			if(isText()) return "TEXT";
			return "IMAGE";
		}
		
		public function isHtml():Boolean {
			return isHtmlResourceType();
		}
		
		public function isFlash():Boolean {
			return isStaticResourceType() && isSWFCreativeType();
		}
		
		public function isScript():Boolean {
			return isScriptResourceType() || (isStaticResourceType() && isScriptCreativeType());
		}
		
		public function isImage():Boolean {
			return isStaticResourceType() && isImageCreativeType();
		}
		
		public function isText():Boolean {
			return isTextResourceType(); // && isTextCreativeType();
		}
		
		public function isIFrame():Boolean {
			return isIFrameResourceType();
		}

		public function isTextResourceType():Boolean {
			if(_resourceType != null) {
				return (_resourceType.toUpperCase()	== "TEXT");		
			}
			return false;
		}
		
		public function isHtmlResourceType():Boolean {
			if(_resourceType != null) {
				return (_resourceType.toUpperCase()	== "HTML");		
			}
			return false;
		}

		public function isScriptResourceType():Boolean {
			if(_resourceType != null) {
				return (_resourceType.toUpperCase()	== "SCRIPT");
			}
			return false;
		}
		
		public function isIFrameResourceType():Boolean {
			if(_resourceType != null) {
				return (_resourceType.toUpperCase()	== "IFRAME");						
			}
			return false;
		}
		public function isStaticResourceType():Boolean {
			if(_resourceType != null) {
				return (_resourceType.toUpperCase()	== "STATIC");		
			}
			return false;			
		}

		public function isSWFCreativeType():Boolean {
			if(creativeType != null) {
				return (creativeType.toUpperCase() == "APPLICATION/SWF" ||
				        creativeType.toUpperCase() == "SWF" || 
				        creativeType.toUpperCase() == "APPLICATION/X-SHOCKWAVE-FLASH" ||
				        creativeType.toUpperCase() == "X-SHOCKWAVE-FLASH");
			}	
			return false;
		}

		public function isTextCreativeType():Boolean {
			if(creativeType != null) {
				return (creativeType.toUpperCase() == "TEXT");
			}	
			return false;
		}

		public function isScriptCreativeType():Boolean {
			if(creativeType != null) {
				return (creativeType.toUpperCase() == "TEXT/JAVASCRIPT") || 
				       (creativeType.toUpperCase() == "JAVASCRIPT");
			}	
			return false;
		}
		
		public function isImageCreativeType():Boolean {
			return (creativeType == "IMAGE/JPEG" ||
			        creativeType == "JPEG" || 
					creativeType == "IMAGE/JPG" ||
			        creativeType == "JPG" || 
			        creativeType == "IMAGE/GIF" ||
			        creativeType == "GIF" || 
                    creativeType == "IMAGE/PNG" ||
			        creativeType == "PNG");
		}
		
		public function hasAccompanyingVideoAd():Boolean {
			if(parentAdContainer != null) {
				return parentAdContainer.hasLinearAd();
			}
			return false;
		}

		public function matchesSizeAndIndex(width:int, height:int, index:int):Boolean {
			if(matchesSize(width, height)) {
				return index == _index;
			}
			return false;
		}
		
		public function matchesSizeAndResourceType(width:int, height:int, resourceType:String):Boolean {
			if(matchesSize(width, height)) {
				if(resourceType != null && _resourceType != null) {
					return (_resourceType.toUpperCase() == resourceType.toUpperCase());
				}
			}
			return false;
		}
		
		public function matchesSizeAndTypes(width:int, height:int, creativeType:String, resourceType:String=null):Boolean {
			if(matchesSize(width, height)) {
				if(creativeType != null && _creativeType != null) {
					return ((_creativeType.toUpperCase() == creativeType.toUpperCase()) &&
				            (_resourceType.toUpperCase() == resourceType.toUpperCase()));
				}
				return (_resourceType.toUpperCase() == resourceType.toUpperCase());
			}
			return false;
		}
		
		public function matchesSize(width:int, height:int):Boolean {
			if(width == -1 && height == -1) {
				return true;
			}
			else {
				if(width == -1) { // just check the height
					return (height == _height);
				}
				else {
					if(width == _width) {
						return (height == _height);						
					}
					else return false;
				}
			}
		}
		
		public function start(displayEvent:VideoAdDisplayEvent):void {
			triggerTrackingEvent(TrackingEvent.EVENT_CREATIVE_VIEW);
			triggerTrackingEvent(TrackingEvent.EVENT_START);
			if(displayEvent.controller != null) {
				displayEvent.controller.onDisplayNonLinearOverlayAd(
				           new OverlayAdDisplayEvent(
				                     OverlayAdDisplayEvent.DISPLAY, 
				                     this,
			 						 displayEvent.customData.adSlotPosition,
			 						 displayEvent.customData.adSlotKey,
			 					 	 displayEvent.customData.adSlotAssociatedStreamIndex
				           ));				
			}
		}
		
		public function stop(displayEvent:VideoAdDisplayEvent):void {
			triggerTrackingEvent(TrackingEvent.EVENT_COMPLETE);	
			if(displayEvent.controller != null) {
				displayEvent.controller.onHideNonLinearOverlayAd(
				           new OverlayAdDisplayEvent(
				                     OverlayAdDisplayEvent.HIDE, 
				                     this,
			 						 displayEvent.customData.adSlotPosition,
			 						 displayEvent.customData.adSlotKey,
			 					 	 displayEvent.customData.adSlotAssociatedStreamIndex
				           ));				
			}
		}
		
		public function clicked():void {
			triggerTrackingEvent(TrackingEvent.EVENT_ACCEPT);
		}

		public function close():void {
			triggerTrackingEvent(TrackingEvent.EVENT_CLOSE);			
		}
		
		public override function clone(subClone:*=null):* {
			var clone:NonLinearVideoAd;
			if(subClone == null) {
				clone = new NonLinearVideoAd();
			}
			else clone = subClone;

			clone.width = _width;
			clone.height = _height;
			clone.recommendedMinDuration = _recommendedMinDuration;
			clone.resourceType = _resourceType;
			clone.creativeType = _creativeType;
			clone.apiFramework = _apiFramework;
			clone.url = _url;
			clone.codeBlock = _codeBlock;

			return super.clone(clone);
		}
	}
}