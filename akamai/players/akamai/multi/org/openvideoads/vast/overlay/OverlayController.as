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
 package org.openvideoads.vast.overlay {
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.regions.RegionController;
	import org.openvideoads.regions.config.CloseButtonConfig;
	import org.openvideoads.regions.config.RegionViewConfig;
	import org.openvideoads.regions.view.RegionView;
	import org.openvideoads.util.DisplayProperties;
	import org.openvideoads.vast.VASTController;
	import org.openvideoads.vast.config.groupings.OverlaysConfigGroup;
	import org.openvideoads.vast.events.AdNoticeDisplayEvent;
	import org.openvideoads.vast.events.OverlayAdDisplayEvent;
	import org.openvideoads.vast.model.NonLinearFlashAd;
	import org.openvideoads.vast.model.NonLinearVideoAd;
	import org.openvideoads.vast.schedule.ads.AdSlot;
	
	/**
	 * @author Paul Schulz
	 */
	public class OverlayController extends RegionController {				
		protected var _vastController:VASTController;
		protected var _mouseTrackerRegion:ClickThroughCallToActionView = null;
		protected var _pausingClickForMoreInfoRegion:Boolean = false;
		protected var _activeAdNotice:AdNotice = null;
		
		public function OverlayController(vastController:VASTController, displayProperties:DisplayProperties, config:OverlaysConfigGroup) {
			_vastController = vastController;
			super(displayProperties, config);
		}

		protected override function newRegion(controller:RegionController, regionConfig:RegionViewConfig, displayProperties:DisplayProperties):RegionView {
			return new OverlayView(controller, regionConfig, displayProperties);
		}
		
		protected override function createPredefinedRegion(regionID:String):RegionView {
			var newRegionConfig:RegionViewConfig = null;
			switch(regionID) {
				case 'reserved-system-message':
					return createRegionView(new RegionViewConfig(
					         { 
					            id: 'reserved-system-message', 
					            verticalAlign: 'bottom', 
					            backgroundColor: 'transparent',
					            height: 20,
					            width: '100pct', 
								style: '.normaltext { font-family: "sans-serif"; font-size: 12pt; font-style: normal; color:#CCCCCC } ' +
								       '.smalltext { font-family: "sans-serif"; font-size: 10pt; color:#CCCCCC }',
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick				             
					         }
					));

				case 'reserved-top':
					return createRegionView(new RegionViewConfig(
						{ 
							id: 'reserved-top', 
							verticalAlign: 'top', 
							width: '100pct', 
							height: '50', 
			            	closeButton: this.closeButtonConfig,
							keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick 
						}
					));

				case 'reserved-fullscreen':
					return createRegionView(new RegionViewConfig(
						{ 
							id: 'reserved-fullscreen', 
							verticalAlign: 0, 
							horizontalAlign: 0, 
							width: '100pct', 
							height: '100pct', 
			            	closeButton: this.closeButtonConfig,
							keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick 
						}
					));

				case 'reserved-bottom-w100pct-h78px-000000-o50':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-w100pct-h78px-000000-o50', 
								verticalAlign: 'bottom', 
								backgroundColor: '#000000',
								opacity: 0.5, 
								width: '100pct', 
								height: 78, 
								padding: '5 5 5 5',
								style: '.title { font-family: "sans-serif"; font-size: 18pt; font-style: bold; color:#FAF8CC; leading:5px; } ' +
								       '.description { font-family: "sans-serif"; font-size: 15pt; leading:3px; } ' +
								       '.callToActionTitle { font-family: "sans-serif"; font-size: 15pt; font-style: bold; color:#FBB917; }',
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-w100pct-h50px-000000-o50':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-w100pct-h50px-000000-o50', 
								verticalAlign: 'bottom', 
								backgroundColor: '#000000',
								opacity: 0.5, 
								width: '100pct', 
								height: 50, 
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-w100pct-h50px-transparent-0m':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-w100pct-h50px-transparent-0m', 
								verticalAlign: 'bottom', 
								backgroundColor: 'transparent',
								width: '100pct', 
								height: 50,
								padding: '-10 -10 -10 -10',
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick								 
							}
						)
					);

				case 'reserved-bottom-w450px-h50px-000000-o50':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-w450px-h50px-000000-o50', 
								verticalAlign: 'bottom', 
								backgroundColor: '#000000',
								opacity: 0.5, 
								width: 450, 
								height: 50,
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);
					
				case 'reserved-bottom-w450px-h50px-transparent':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-w450px-h50px-transparent', 
								verticalAlign: 'bottom', 
								backgroundColor: 'transparent',
								width: 450, 
								height: 50,
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);
					
				case 'reserved-bottom-w450px-h50px-transparent-0m':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-w450px-h50px-transparent-0m', 
								verticalAlign: 'bottom', 
								backgroundColor: 'transparent',
								width: 450, 
								height: 50,
								padding: '-10 -10 -10 -10',
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-center-w450px-h50px-000000-o50':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-center-w450px-h50px-000000-o50', 
								verticalAlign: 'bottom', 
								backgroundColor: '#000000',
								horizontalAlign: 'center',
								opacity: 0.5, 
								width: 450, 
								height: 50,
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-center-w450px-h50px-transparent':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-center-w450px-h50px-transparent', 
								verticalAlign: 'bottom', 
								horizontalAlign: 'center',
								backgroundColor: 'transparent',
								width: 450, 
								height: 50,
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-center-w450px-h50px-transparent-0m':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-center-w450px-h50px-transparent-0m', 
								verticalAlign: 'bottom', 
								horizontalAlign: 'center',
								backgroundColor: 'transparent',
								width: 450, 
								height: 50,
								padding: '-10 -10 -10 -10',
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-center-w300px-h50px-000000-o50':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-center-w300px-h50px-000000-o50', 
								verticalAlign: 'bottom', 
								backgroundColor: '#000000',
								horizontalAlign: 'center',
								opacity: 0.5, 
								width: 300, 
								height: 50,
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-center-w300px-h50px-transparent':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-center-w300px-h50px-transparent', 
								verticalAlign: 'bottom', 
								horizontalAlign: 'center',
								backgroundColor: 'transparent',
								width: 300, 
								height: 50,
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);

				case 'reserved-bottom-center-w300px-h50px-transparent-0m':
					return createRegionView(
						new RegionViewConfig(
							{ 
								id: 'reserved-bottom-center-w300px-h50px-transparent-0m', 
								verticalAlign: 'bottom', 
								horizontalAlign: 'center',
								backgroundColor: 'transparent',
								width: 300, 
								height: 50,
								padding: '-10 -10 -10 -10',
				            	closeButton: this.closeButtonConfig,
								keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick
							}
						)
					);
			}
			return DEFAULT_REGION;			
		}
		
		protected override function createRegionViews():void {			
			if(_vastController.config.visuallyCueLinearAdClickThrough) {
				doLog("Have created a region to allow the mouse to be tracked over linear ads", Debuggable.DEBUG_REGION_FORMATION);
				_mouseTrackerRegion = 
						new ClickThroughCallToActionView(
								this,
							    new RegionViewConfig(
							         { 
							            id: 'reserved-clickable-click-through', 
						    	        verticalAlign: 0, 
						        	    horizontalAlign: 0, 
						        	    scaleRate: 0.75,
							            canScale: true,
									    width: '100pct',
						            	height: _displayProperties.displayHeight - _displayProperties.bottomMargin,
						            	clickable: true,
						            	closeButton: { enabled: false },
						            	backgroundColor: 'transparent',
						            	keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick 
						         	 }
						    	),
						    	_vastController.config.adsConfig.clickSignConfig,
								_displayProperties); 
				_regionViews.push(_mouseTrackerRegion);
				addChild(_mouseTrackerRegion);
				setChildIndex(_mouseTrackerRegion, 0);	
			}
			
			// always add the standard defaults

			DEFAULT_REGION = createRegionView(
				new RegionViewConfig(
					{ 
						id: 'reserved-bottom-w100pct-h50px-transparent', 
						verticalAlign: 'bottom', 
						backgroundColor: 'transparent',
						width: '100pct', 
						height: 50,
		            	closeButton: this.closeButtonConfig,
						keepAfterClick: _vastController.config.adsConfig.keepOverlayVisibleAfterClick								 
					}
				)
			);

			if(_config != null) {
				if(_config.hasRegionDefinitions()) {
					// setup the regions
					for(var i:int=0; i < _config.regions.length; i++) {
						doLogAndTrace("The following config has been used to create RegionView (" + i + ")", _config.regions[i], Debuggable.DEBUG_CONFIG);
						createRegionView(_config.regions[i]);
					}
				}
			}				

			doLogAndTrace("Regions created - " + _regionViews.length + " in total. Trace follows:", _config.regions, Debuggable.DEBUG_CONFIG);				
		}
		
		public function hideAllOverlays():void {
			hideAllRegions();
		}		
		
		public function enableLinearAdMouseOverRegion(adSlot:AdSlot):void {
			doLog("Enabling linear ad mouse over region", Debuggable.DEBUG_DISPLAY_EVENTS);
			_mouseTrackerRegion.activeAdSlotKey = adSlot.key;
			_mouseTrackerRegion.visible = true;
			_pausingClickForMoreInfoRegion = false;
		}

		public function disableLinearAdMouseOverRegion():void {
			doLog("Disabling linear ad mouse over region", Debuggable.DEBUG_DISPLAY_EVENTS);
			_mouseTrackerRegion.activeAdSlotKey = -1;
			_mouseTrackerRegion.visible = false;
			_pausingClickForMoreInfoRegion = false;
		}
		
		public function pauseLinearAdMouseOverRegion():void {
			if(_mouseTrackerRegion.visible) {
				doLog("Pausing linear ad mouse over region", Debuggable.DEBUG_DISPLAY_EVENTS);
				_mouseTrackerRegion.visible = false;
				_pausingClickForMoreInfoRegion = true;
			}
			else doLog("Ignoring request to pause linear ad mouse over region (was not visible)", Debuggable.DEBUG_DISPLAY_EVENTS);
		}

		public function resumeLinearAdMouseOverRegion():void {
			if(_pausingClickForMoreInfoRegion) {
				doLog("Resuming linear ad mouse over region", Debuggable.DEBUG_DISPLAY_EVENTS);
				_mouseTrackerRegion.visible = true;
				_pausingClickForMoreInfoRegion = false;		
			}
			else doLog("Ignoring request to resume linear ad mouse over region (was not paused)", Debuggable.DEBUG_DISPLAY_EVENTS);			
		}
		
		public function hasActiveLinearMouseOverRegion():Boolean {
			return _mouseTrackerRegion.visible;
		}
		
		public function displayNonLinearOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			doLog("Attempting to display overlay ad at index " + overlayAdDisplayEvent.adSlotKey, Debuggable.DEBUG_DISPLAY_EVENTS);
			var overlayAdSlot:AdSlot = _vastController.adSchedule.getSlot(overlayAdDisplayEvent.adSlotKey);

			if(overlayAdSlot != null) {
				var nonLinearVideoAd:NonLinearVideoAd = overlayAdDisplayEvent.ad as NonLinearVideoAd;
				var overlay:OverlayView = null;					
				if(overlayAdSlot.hasPositionDefined()) {
					if(overlayAdSlot.requiresAutoPosition()) {
						doLog("Overlay will be displayed using an AUTO region (" + nonLinearVideoAd.width + "x" + nonLinearVideoAd.height + " - " + overlayAdSlot.getAutoPositionAlignment() + ")");
						overlay = createAutoRegion("reserved-auto-region-" + overlayAdSlot.adSlotID,
						                           nonLinearVideoAd.width, 
						                           nonLinearVideoAd.height, 
						                           overlayAdSlot.getAutoPositionAlignment(), 
						                           _vastController.config.adsConfig.keepOverlayVisibleAfterClick) as OverlayView;
					}
					else {
						doLog("Attempting to display overlay in a region with ID " + overlayAdSlot.position, Debuggable.DEBUG_DISPLAY_EVENTS);
						overlay = getRegion(overlayAdSlot.position) as OverlayView;						
					}
				}
				else {
					// we can pull the region ID directly from the regions defined for the ad slot based on the overlay content type
					overlay = getRegion(overlayAdSlot.getRegionIDBasedOnResourceAndCreativeTypes(nonLinearVideoAd.resourceType, nonLinearVideoAd.creativeType)) as OverlayView;						
				}
				if(overlay != null) {
					overlay.activeAdSlotKey = overlayAdDisplayEvent.adSlotKey;
					overlay.visible = false;
					if(nonLinearVideoAd.isFlash()) {
						doLog("Displaying overlay as SWF...", Debuggable.DEBUG_CUEPOINT_EVENTS);
						overlay.loadDisplayContent((nonLinearVideoAd as NonLinearFlashAd).swfURL, 
						                           _vastController.config.adsConfig.allowDomains,
						                           (nonLinearVideoAd.hasClickThroughURL() ? true : nonLinearVideoAd.hasAccompanyingVideoAd()));
					}
					else {
						doLog("Displaying (" + nonLinearVideoAd.contentType() + ") overlay using HTML tag set... ", Debuggable.DEBUG_DISPLAY_EVENTS);
						var html:String = null;
						var content:String = overlayAdSlot.getTemplate(nonLinearVideoAd.contentType()).getContent(nonLinearVideoAd);
						if(nonLinearVideoAd.hasClickThroughURL()) {
							html = "<a href=\"" + nonLinearVideoAd.clickThroughs[0].url + "\" target=\"_blank\">";
							html += content;
							html += "</a>";						
						}
						else html = content;
						overlay.html = html;
					}
					overlay.visible = true;														
				}
				else doLog("Could not find an appropriate region to use given region ID " + overlayAdSlot.position, Debuggable.DEBUG_DISPLAY_EVENTS);	
			}
			else doLog("Cannot show the non linear ad - no adslot at " + overlayAdDisplayEvent.adSlotKey, Debuggable.DEBUG_DISPLAY_EVENTS);
		}
		
		public function hideNonLinearOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			var overlayAdSlot:AdSlot = _vastController.adSchedule.getSlot(overlayAdDisplayEvent.adSlotKey);			
			var oid:String = null;
			if(overlayAdSlot.hasPositionDefined()) {					
				if(overlayAdSlot.requiresAutoPosition()) {
					oid = "reserved-auto-region-" + overlayAdSlot.adSlotID;
				}		
				else oid = overlayAdSlot.position;
			}
			else {
				// we can pull the region ID directly from the regions defined for the ad slot based on the overlay content type
				var nonLinearVideoAd:NonLinearVideoAd = overlayAdDisplayEvent.ad as NonLinearVideoAd;
				oid = overlayAdSlot.getRegionIDBasedOnResourceAndCreativeTypes(nonLinearVideoAd.resourceType, nonLinearVideoAd.creativeType);
			}
			var overlay:OverlayView = getRegion(oid) as OverlayView;					
			if(overlay != null) {
				doLog("Hiding region with ID " + oid, Debuggable.DEBUG_DISPLAY_EVENTS);
				overlay.visible = false;
				overlay.clearDisplayContent();
				overlay.clearActiveAdSlotKey();
			}				
			else doLog("Could not find region with ID " + oid + " - hide request ignored", Debuggable.DEBUG_DISPLAY_EVENTS);
		}
				
		public function displayNonLinearNonOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {	
			doLog("displayNonLinearNonOverlayAd: NOT IMPLEMENTED");
		}
		
		public function hideNonLinearNonOverlayAd(overlayAdDisplayEvent:OverlayAdDisplayEvent):void {
			doLog("hideNonLinearNonOverlayAd: NOT IMPLEMENTED");
		}
 
		public function showAdNotice(adNoticeDisplayEvent:AdNoticeDisplayEvent):void {
			if(adNoticeDisplayEvent != null) {
				if(adNoticeDisplayEvent.notice.region != undefined) {
					var noticeRegion:RegionView = getRegion(adNoticeDisplayEvent.notice.region);
					if(noticeRegion != null) {
						_activeAdNotice = new AdNotice(adNoticeDisplayEvent.notice.message, adNoticeDisplayEvent.duration, noticeRegion);
						_activeAdNotice.show();			
					}
					else doLog("Cannot find the region '" + adNoticeDisplayEvent.notice.region + "'");
				}				
			}	
		}
		
		public function tickAdNotice(adNoticeDisplayEvent:AdNoticeDisplayEvent):void {
			if(_activeAdNotice == null) {
				showAdNotice(adNoticeDisplayEvent);
			}
			else _activeAdNotice.tickCountdownNotice(adNoticeDisplayEvent.duration);
		}
		
		public function hideAdNotice(adNoticeDisplayEvent:AdNoticeDisplayEvent=null):void {
			if(adNoticeDisplayEvent != null) {
				if(adNoticeDisplayEvent.notice.region != undefined) {
					if(_activeAdNotice != null) {
						_activeAdNotice.hide();
						_activeAdNotice = null;
					}
				}
			}	
			else {
				if(_activeAdNotice != null) {
					_activeAdNotice.hide();
					_activeAdNotice = null;				
				}
			}
		}
		
		// Mouse events
		
		public override function onRegionCloseClicked(regionView:RegionView):void {
			_vastController.onOverlayCloseClicked(regionView as OverlayView);
		}
		
		public override function onRegionClicked(regionView:RegionView):void {
			_vastController.onOverlayClicked(regionView as OverlayView);
		}	
		
		public function onLinearAdClickThroughCallToActionViewClicked(adSlotKey:int):void {
			_vastController.onLinearAdClickThroughCallToActionViewClicked(adSlotKey);
		}		
	}
}