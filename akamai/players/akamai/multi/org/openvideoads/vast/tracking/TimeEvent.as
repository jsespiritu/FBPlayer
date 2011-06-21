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
package org.openvideoads.vast.tracking {
 	import org.openvideoads.base.Debuggable;
 	
	/**
	 * @author Paul Schulz
	 */
	public class TimeEvent extends Debuggable{
		protected var _milliseconds:Number;
		protected var _duration:Number;
		protected var _label:String;
		protected var _adEventLabelList:String = "TM BA EA 1Q HW 3Q SN HN NS NE TN";
		
		public function TimeEvent(milliseconds:Number, duration:Number=0, label:String=null) {
			_milliseconds = milliseconds;
			_duration = duration;
			_label = label;
		}

        public function isAdOnlyEvent():Boolean {
        	return (_adEventLabelList.indexOf(label) > -1);	
        }
        
		public function get milliseconds():Number {
			return _milliseconds;
		}
		
		public function get seconds():Number {
			return _milliseconds / 1000;
		}
		
		public function get duration():Number {
			return _duration;
		}
		
		public function get label():String {
			return _label;
		}
		
		public function toString():String {
			return "TimeEvent(time point: " + _milliseconds + ", label: " + _label + ", duration: " + _duration + ")";
		}
	}
}