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
package org.openvideoads.regions.config {
	import org.openvideoads.base.Debuggable;
	
	/**
	 * @author Paul Schulz
	 */
	public class RegionsConfig extends BaseRegionConfig {
		protected var _makeRegionsVisible:Boolean = false;
		protected var _regions:Array = new Array();
		protected var _originalRegionDefinitions:Array = new Array();
		protected var _stageDimensions:StageDimensions = null;
		protected var _skin:String = null;
		
		public function RegionsConfig(config:Object=null) {
			super(config);
			id = "master";
			if(config != null) {
				if(config.regions != undefined) {
					regions = config.regions;
				}
				if(config.stagePaddingBottomWithControls != undefined) {
					if(_stageDimensions == null) {
						_stageDimensions = new StageDimensions();
					}
					_stageDimensions.withControlsPaddingBottom = config.stagePaddingBottomWithControls;
				}
				if(config.stagePaddingBottomNoControls != undefined) {
					if(_stageDimensions == null) {
						_stageDimensions = new StageDimensions()
					}
					_stageDimensions.noControlsPaddingBottom = config.stagePaddingBottomNoControls;
				}
				if(config.closeButton != undefined) {
					closeButton = new CloseButtonConfig(config.closeButton);
				}
			}
		}

		public function hasStageDimensions():Boolean {
			return (_stageDimensions != null);	
		}
		
		public function get stageDimensions():StageDimensions {
			return _stageDimensions;
		}
		
		public function set stageDimensions(stageDimensions:StageDimensions):void {
			_stageDimensions = stageDimensions;
		}
		
		public function hasRegionDefinitions():Boolean {
			return _regions.length > 0;
		}

		public function set makeRegionsVisible(visible:Boolean):void {
			_makeRegionsVisible = visible;
		}
		
		public function get makeRegionsVisible():Boolean {
			return _makeRegionsVisible;
		}
		
		public function set regions(newRegions:Array):void {
			_originalRegionDefinitions = newRegions;
			buildRegionConfigs();
		}
	
		public function get regions():Array {
			return _regions;
		}		
		
		public function get defaultRegions():Array {
			return new Array();
		}
		
		public function buildRegionConfigs():void {
			doLogAndTrace("Parsing individual region configurations. Using the master config as follows:", this, Debuggable.DEBUG_CONFIG);
			_regions = new Array();
			for(var i:int=0; i < _originalRegionDefinitions.length; i++) {
				var regionViewConfig:RegionViewConfig = new RegionViewConfig(properties);
				regionViewConfig.setup(_originalRegionDefinitions[i]);
				_regions.push(regionViewConfig);
			}			
		}
	}
}