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
package org.openvideoads.regions.view.button {
    import org.openvideoads.regions.view.RegionView;

	import flash.display.Bitmap;

	/**
	 * @author Paul Schulz
	 */
	public class StandardImageCloseButton extends CloseButton {
		
		[Embed(source='/resources/overlay/standard/button-normal.png')]
		private var normalButtonClass:Class;
		private var normalButton:Bitmap = new normalButtonClass();

		[Embed(source='/resources/overlay/standard/button-highlight.png')]
		private var highlightButtonClass:Class;
		private var highlightButton:Bitmap = new highlightButtonClass();
		
		public function StandardImageCloseButton(id:String=null, parentView:RegionView=null) {
			super(id, parentView, 15, 15);
		}

        protected override function drawButton():void {
			this.addChild(normalButton);
        }

        public override function calculateLayoutPosition(width:int, borderRadius:int):void {
			x = width - buttonWidth - (borderRadius/5);
			y = ((borderRadius > 0) ? 0 + borderRadius/5 : 0);
        }
	}
}