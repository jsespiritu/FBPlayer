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
	
	public class VideoAdV2 extends VideoAd {
		public function VideoAdV2() {
		}

		public override function triggerTrackingEvent(eventType:String, id:String=null):void {
			if(isLinear()) {
				_linearVideoAd.triggerTrackingEvent(eventType);
			}
			else if(isNonLinear()) {
				// the only events covered at present are fired in the nonLinearAd.start() method
			}
			else if(isCompanion()) {
				// no companion specific tracking events supported at this time apart from creativeView which is fired separately
			}
			else doLog("FATAL: Unable to fire tracking events for VideoAd (" + this.id + ", " + this.adId + ") - ad type unknown");
		}
	}
}