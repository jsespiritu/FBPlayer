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
	import org.openvideoads.util.StringUtils;
	import org.openvideoads.vast.events.CompanionAdDisplayEvent;
	import org.openvideoads.vast.events.VideoAdDisplayEvent;
	
	/**
	 * @author Paul Schulz
	 */
	public class CompanionAd extends NonLinearVideoAd {
		protected var _altText:String = null;
		protected var _activeDivID:String = null;
		protected var _previousDivContent:String = "";
		protected var _divIndex:int = -1;
		
		public function CompanionAd(parentAd:VideoAd=null) {
			_parentAdContainer = parentAd;
			super();
		}
		
		public function set altText(altText:String):void {
			_altText = altText;
		}
		
		public function get altText():String {
			return _altText;
		}
		
		public function set activeDivID(activeDivID:String):void {
			_activeDivID = activeDivID;
		}
		
		public function get activeDivID():String {
			return _activeDivID;
		}
		
		public function set divIndex(divIndex:int):void {
			_divIndex = divIndex;
		}
		
		public function get divIndex():int {
			return _divIndex;
		}
		
		public function set previousDivContent(previousDivContent:String):void {
			_previousDivContent = previousDivContent;
		}
		
		public function get previousDivContent():String {
			return _previousDivContent;
		}
		
		public function matches(companionAd:CompanionAd):Boolean {
			if(companionAd != null) {
				if(this == companionAd) {
					return true;
				}
				return (companionAd.isVAST2 && this.isVAST2 && this.id != null && !StringUtils.isEmpty(this.id) && (companionAd.id == this.id));
			}
			return false;			
		}
		
		public function getMarkup():String {
			var newHtml:String = "";
			var dimensionAttributes:String = "";
			if(isHtml()) {
				doLog("CompanionAd (" + this.guid + ") - Inserting a HTML codeblock into the DIV for a companion banner... " + clickThroughs.length + " click through URL described", Debuggable.DEBUG_DISPLAY_EVENTS);
				doTrace(codeBlock, Debuggable.DEBUG_CUEPOINT_EVENTS);
				if(hasClickThroughURL() && !StringUtils.beginsWith(codeBlock, "<A ")) { // can't have a double <a> tag - so use the one provided
					newHtml = "<a href=\"" + clickThroughs[0].qualifiedHTTPUrl + "\" target=\"_blank\">";
					newHtml += codeBlock;
					newHtml += "</a>";
				}
				else newHtml = codeBlock;
			}
			else {
				if(isImage()) {
					doLog("CompanionAd (" + this.guid + ") - Inserting an IMG (" + url.url + ") into the DIV for a companion banner..." + clickThroughs.length + " click through URL described", Debuggable.DEBUG_DISPLAY_EVENTS);
					if(hasClickThroughURL()) {
						newHtml = "<a href=\"" + clickThroughs[0].qualifiedHTTPUrl + "\" target=\"_blank\">";
						newHtml += "<img src=\"" + url.url + "\" border=\"0\"/>";
						newHtml += "</a>";
					}
					else {
						newHtml += "<img src=\"" + url.url + "\" border=\"0\"/>";								
					}
				}		
				else if(isScript()) {
					if(hasCode()) {
						doLog("CompanionAd (" + this.guid + ") - Inserting a <SCRIPT> codeblock into the DIV for a companion banner...", Debuggable.DEBUG_DISPLAY_EVENTS);
						newHtml = codeBlock;
					}
					else if(hasUrl()) {
						doLog("CompanionAd (" + this.guid + ") - Inserting a <SCRIPT> based url (" + url.url + ") into the DIV for a companion banner...", Debuggable.DEBUG_DISPLAY_EVENTS);
					    newHtml += '<script type="text/javascript" src="' + url.url + '"></script>';					
					}
					else doLog("CompanionAd (" + this.guid + ") - Ignoring script type for companion - no URL or codeblock provided", Debuggable.DEBUG_DISPLAY_EVENTS);
				}
				else if(isFlash()) {
					if(hasCode()) {
						doLog("CompanionAd (" + this.guid + ") - Inserting a flash codeblock into the DIV for a companion banner...", Debuggable.DEBUG_DISPLAY_EVENTS);
						newHtml = codeBlock;
					}
					else {
						doLog("CompanionAd (" + this.guid + ") - Inserting SWF url (" + url.url + ") based companion using Object tags...", Debuggable.DEBUG_DISPLAY_EVENTS);
						if(this.hasWidth()) dimensionAttributes += ' width="' + this.width + '"';
						if(this.hasHeight()) dimensionAttributes += ' height="' + this.height + '"';
						newHtml = '<object codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,40,0"' + dimensionAttributes + ' id="companion-' + this.index + '">';
						newHtml += '<param name="movie" value="' + url.url + '">';
						newHtml += '<embed name="companion-' + this.index + '" src="' + url.url + '"' + dimensionAttributes + ' allowScriptAccess="always" allowFullScreen="true" pluginspage="http://www.macromedia.com/go/getflashplayer"></embed>';
						newHtml += '</object>';
					}
				}
				else if(isIFrame()) {
					if(hasUrl()) {
						doLog("CompanionAd (" + this.guid + ") - Inserting an IFRAME (" + url.url + ") into the DIV for a companion banner...", Debuggable.DEBUG_DISPLAY_EVENTS);		
						if(this.hasWidth()) dimensionAttributes += ' width="' + this.width + '"';
						if(this.hasHeight()) dimensionAttributes += ' height="' + this.height + '"';
						newHtml =  '<iframe src="' + url.url + '" hspace=0 vspace=0 frameborder=0 marginheight=0 marginwidth=0 scrolling=no' + dimensionAttributes + '>';
  						newHtml += '   <p>Your browser does not support iframes.</p>';
						newHtml += '</iframe>';
					}
					else doLog("CompanionAd (" + this.guid + ") - Ignoring IFRAME type for companion - no URL provided", Debuggable.DEBUG_DISPLAY_EVENTS);
				}
				else doLog("CompanionAd (" + this.guid + ") - Unknown resource type " + resourceType + ", creativeType is " + creativeType, Debuggable.DEBUG_DISPLAY_EVENTS);
			}	
			return newHtml;		
		}

		override public function start(displayEvent:VideoAdDisplayEvent):void {
			triggerTrackingEvent(TrackingEvent.EVENT_CREATIVE_VIEW);	
			triggerTrackingEvent(TrackingEvent.EVENT_START);	
			displayEvent.controller.onDisplayCompanionAd(new CompanionAdDisplayEvent(CompanionAdDisplayEvent.DISPLAY, this));
		}
		
		override public function stop(displayEvent:VideoAdDisplayEvent):void {
			triggerTrackingEvent(TrackingEvent.EVENT_STOP);	
			displayEvent.controller.onHideCompanionAd(new CompanionAdDisplayEvent(CompanionAdDisplayEvent.HIDE, this));
		}
		
		public override function clone(subClone:*=null):* {
			var clone:CompanionAd = super.clone(new CompanionAd(parentAdContainer));
			clone.altText = _altText;
			clone.previousDivContent = _previousDivContent;
			clone.activeDivID = _activeDivID;
			clone.divIndex = _divIndex;
			return clone;
		}
	}
}