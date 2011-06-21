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
package org.openvideoads.vast.config.groupings {
	import org.openvideoads.base.Debuggable;
	
	public class ProvidersConfigGroup extends Debuggable{
		protected var _httpProvider:String = "http";
		protected var _httpStreamer:String = null;
		protected var _rtmpProvider:String = "rtmp";
		protected var _rtmpStreamer:String = null;
		
		public function ProvidersConfigGroup(providers:Object=null) {
			if(providers != null) {
				if(providers.http != undefined) {
					httpProvider = providers.http;
				}
				if(providers.rtmp != undefined) {
					rtmpProvider = providers.rtmp;
				}
			}
		}
		
		public function getProvider(providerType:String):String {
			switch(providerType.toUpperCase()) {
				case "RTMP":
					return rtmpProvider;
				case "HTTP":
					return httpProvider;
			}
			return null;
		}

		public function getStreamer(providerType:String):String {
			switch(providerType.toUpperCase()) {
				case "RTMP":
					return rtmpStreamer;
				case "HTTP":
					return httpStreamer;
			}
			return null;
		}
		
		public function set httpProvider(httpProvider:*):void {
			if(httpProvider is String) {
				_httpProvider = httpProvider;						
			}
			else {
				if(httpProvider.type != undefined) {
					_httpProvider = httpProvider.type;

					if(httpProvider.streamer != undefined) {
						httpStreamer = httpProvider.streamer;
					} 
				}
			}
			doLog("HTTP provider type set to " + _httpProvider, Debuggable.DEBUG_CONFIG);
		}
		
		public function get httpProvider():String {
			return _httpProvider;
		}

		public function set rtmpProvider(rtmpProvider:*):void {
			if(rtmpProvider is String) {
				_rtmpProvider = rtmpProvider;
			}
			else {
				if(rtmpProvider.type != undefined) {
					_rtmpProvider = rtmpProvider.type;

					if(rtmpProvider.streamer != undefined) {
						rtmpStreamer = rtmpProvider.streamer;
					}
				}						
			}
			doLog("RTMP provider type set to " + _rtmpProvider, Debuggable.DEBUG_CONFIG);
		}
		
		public function get rtmpProvider():String {
			return _rtmpProvider;
		}		

		public function set httpStreamer(httpStreamer:String):void {
			_httpStreamer = httpStreamer;
			doLog("HTTP provider streamer set to " + _httpStreamer, Debuggable.DEBUG_CONFIG);
		}
		
		public function get httpStreamer():String {
			return _httpStreamer;
		}

		public function set rtmpStreamer(rtmpStreamer:String):void {
			_rtmpStreamer = rtmpStreamer;
			doLog("RTMP provider streamer set to " + _rtmpStreamer, Debuggable.DEBUG_CONFIG);
		}
		
		public function get rtmpStreamer():String {
			return _rtmpStreamer;
		}		
	}
}