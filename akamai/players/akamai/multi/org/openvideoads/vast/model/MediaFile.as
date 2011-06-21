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
	
	/**
	 * @author Paul Schulz
	 */
	public class MediaFile extends Debuggable {
		private var _url:NetworkResource;
		private var _id:String;
		private var _bandwidth:String; // high, medium, low, custom
		private var _delivery:String;  // streaming, progressive
		private var _scale:String = "false";
		private var _maintainAspectRatio:String = "true";
		private var _mimeType:String;     
		private var _bitRate:int = -1;
		private var _width:String;
		private var _height:String;
		
		public function MediaFile() {
		}
		
		public function set id(id:String):void {
			_id = id;
		}
		
		public function get id():String {
			return _id;
		}
		
		public function set url(url:NetworkResource):void {
			_url = url;
		}
		
		public function get url():NetworkResource {
			return _url;
		}
		
		public function set bandwidth(bandwidth:String):void {
			_bandwidth = bandwidth;
		}
		
		public function get bandwidth():String {
			return _bandwidth;
		}
		
		public function set delivery(delivery:String):void {
			_delivery = delivery;
		}
		
		public function get delivery():String {
			return _delivery;
		}
		
		public function set scale(scale:String):void {
			if(scale != null) _scale = scale;
		}
		
		public function get scale():String {
			return _scale;
		}
		
		public function canScale():Boolean {
			return _scale.toUpperCase() == "TRUE";
		}

		public function set maintainAspectRatio(maintainAspectRatio:String):void {
			if(maintainAspectRatio != null) {
				_maintainAspectRatio = (maintainAspectRatio.toUpperCase() == "FALSE") ? "FALSE" : "TRUE";
			}
		}
		
		public function get maintainAspectRatio():String {
			return _maintainAspectRatio;
		}
		
		public function shouldMaintainAspectRatio():Boolean {
			return _maintainAspectRatio.toUpperCase() == "TRUE";	
		}	
			
		public function set mimeType(mimeType:String):void {
			_mimeType = mimeType;
		}
		
		public function get mimeType():String {
			return _mimeType;
		}
		
		public function isInteractive():Boolean {
			if(_mimeType != null) {
				return (_mimeType.toUpperCase() == "APPLICATION/X-SHOCKWAVE-FLASH");	
			}
			return false;
		}
		
		public function set bitRate(bitRate:int):void {
			_bitRate = bitRate;
		}
		
		public function get bitRate():int {
			return _bitRate;
		}

		public function hasBitRate():Boolean {
			return _bitRate > -1;
		}
		
		public function set width(width:String):void {
			_width = width;
		}
		
		public function get width():String {
			return _width;
		}
		
		public function set height(height:String):void {
			_height = height;
		}
		
		public function get height():String {
			return _height;
		}
		
		public function isMimeType(mimeType:String):Boolean {
			if(mimeType == null) {
				return true;
			}
			else return (mimeType.toUpperCase() == 'ANY' || _mimeType.toUpperCase() == mimeType.toUpperCase());
		}
		
		public function isDeliveryType(deliveryType:String):Boolean {
			return (deliveryType.toUpperCase() == 'ANY' 
			        || _delivery.toUpperCase() == deliveryType.toUpperCase());
		}
	}
}