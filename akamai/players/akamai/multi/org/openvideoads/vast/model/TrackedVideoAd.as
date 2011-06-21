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

	import mx.utils.UIDUtil;

	/**
	 * @author Paul Schulz
	 */
	public class TrackedVideoAd extends Debuggable {
		protected var _id:String;
		protected var _adID:String;
		protected var _guid:String;
		protected var _trackingEvents:Array = new Array();				
		protected var _clickThroughs:Array = new Array();
		protected var _clickTracking:Array = new Array();
		protected var _customClicks:Array = new Array();
		protected var _parentAdContainer:VideoAd = null;
		protected var _scalable:Boolean = false;
		protected var _maintainAspectRatio:Boolean = false;
		protected var _minSuggestedDuration:int = -1;
		protected var _expandedWidth:int = -1;
		protected var _expandedHeight:int = -1;
		protected var _index:int = -1;
		protected var _isVAST2:Boolean = false;

		public function TrackedVideoAd() {
			super();
			_guid = UIDUtil.createUID();
		}
		
		public function set id(id:String):void {
			_id = id;
		}
		
		public function get id():String {
			return _id;
		}

		public function set guid(guid:String):void {
			_guid = guid;
		}
		
		public function get guid():String {
			return _guid;
		}
		
		public function set adID(adID:String):void {
			_adID = adID;
		}
		
		public function get adID():String {
			return _adID;
		}
		
		public function get index():int {
			return _index;
		}
		
		public function set index(index:int):void {
			_index = index;
		}

		public function set isVAST2(isVAST2:Boolean):void {
			_isVAST2 = isVAST2;
		}
		
		public function get isVAST2():Boolean {
			return _isVAST2;
		}		
		
		public function set scalable(scalable:Boolean):void {
			_scalable = scalable;
		}
		
		public function get scalable():Boolean {
			return _scalable;
		}
		
		public function set maintainAspectRatio(maintainAspectRatio:Boolean):void {
			_maintainAspectRatio = maintainAspectRatio;
		}
		
		public function get maintainAspectRatio():Boolean {
			return _maintainAspectRatio;
		}
		
		public function set minSuggestedDuration(minSuggestedDuration:int):void {
			_minSuggestedDuration = minSuggestedDuration;
		}
		
		public function get minSuggestedDuration():int {
			return _minSuggestedDuration;
		}
		
		public function set expandedWidth(expandedWidth:int):void {
			_expandedWidth = expandedWidth;
		}
		
		public function get expandedWidth():int {
			return _expandedWidth;
		}

		public function set expandedHeight(expandedHeight:int):void {
			_expandedHeight = expandedHeight;
		}
		
		public function get expandedHeight():int {
			return _expandedHeight;
		}
		
		public function set parentAdContainer(parentAdContainer:VideoAd):void {
			_parentAdContainer = parentAdContainer;
		}
		
		public function get parentAdContainer():VideoAd {
			return _parentAdContainer;
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

		public function triggerTrackingEvent(eventType:String):void {
			if(_trackingEvents != null && eventType != null) {
				for(var i:int = 0; i < _trackingEvents.length; i++) {
					var trackingEvent:TrackingEvent = _trackingEvents[i];
					if(trackingEvent.eventType != null) {
						if(trackingEvent.eventType.toUpperCase() == eventType.toUpperCase()) {
							trackingEvent.execute();
						}									
					}
				}				
			}
		}
				
		public function set clickThroughs(clickThroughs:Array):void {
			_clickThroughs = clickThroughs;
		}
		
		public function get clickThroughs():Array {
			return _clickThroughs;
		}
		
		public function clickThroughCount():int {
			return _clickThroughs.length;
		}
		
		public function addClickThrough(clickThrough:NetworkResource):void {
			_clickThroughs.push(clickThrough);
		}
		
		public function hasClickThroughs():Boolean {
			return (_clickThroughs.length > 0);
		}
		
		public function firstClickThrough():String {
			if(hasClickThroughs()) {
				return _clickThroughs[0].qualifiedHTTPUrl;
			}	
			else return null;
		}

		public function set clickTracking(clickTracking:Array):void {
			_clickTracking = clickTracking;
		}
		
		public function get clickTracking():Array {
			return _clickTracking;
		}

		public function clickTrackingCount():int {
			return _clickTracking.length;
		}
		
		public function addClickTrack(clickURL:NetworkResource):void {
			_clickTracking.push(clickURL);
		}
		
		public function set customClicks(customClicks:Array):void {
			_customClicks = customClicks;
		}
		
		public function get customClicks():Array {
			return _customClicks;
		}
		
		public function customClickCount():int {
			return _customClicks.length;
		}		
		
		public function addCustomClick(customClick:NetworkResource):void {
			_customClicks.push(customClick);
		}
		
		public function hasClickThroughURL():Boolean {
			return (_clickThroughs.length > 0);
		}
		
		public function clone(subClone:*=null):* {
			var clone:TrackedVideoAd;
			if(subClone == null) {
				clone = new TrackedVideoAd();
			}
			else clone = subClone;
			clone.id = _id;
			clone.guid = _guid;
			clone.adID = _adID;
			clone.parentAdContainer = _parentAdContainer;
			clone.scalable = _scalable;
			clone.maintainAspectRatio = _maintainAspectRatio;
			clone.minSuggestedDuration = _minSuggestedDuration;
			clone.expandedWidth = _expandedWidth;
			clone.expandedHeight = _expandedHeight;
			clone.index = _index;
			clone.isVAST2 = _isVAST2;
			for each(var trackingEvent:TrackingEvent in _trackingEvents) {
				clone.addTrackingEvent(trackingEvent.clone());
			}
			for each(var clickThrough:NetworkResource in _clickThroughs) {
				clone.addClickThrough(clickThrough.clone());
			}
			for each(var clickTracking:NetworkResource in _clickTracking) {
				clone.addClickTrack(clickTracking.clone());
			}
			for each(var customClick:NetworkResource in _customClicks) {
				clone.addCustomClick(customClick.clone());
			}
			return clone;
		}
	}
}