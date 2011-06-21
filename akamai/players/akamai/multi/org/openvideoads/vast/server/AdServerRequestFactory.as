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
package org.openvideoads.vast.server {
	import org.openvideoads.vast.server.openx.OpenXVASTAdRequest;
	import org.openvideoads.vast.server.adtech.AdTechVASTAdRequest;
	import org.openvideoads.vast.server.direct.DirectVASTAdRequest;
	import org.openvideoads.vast.server.oas.OasVASTAdRequest;
	import org.openvideoads.vast.server.doubleclick.DARTVASTAdRequest;
	import org.openvideoads.vast.server.oasis.OasisVASTAdRequest;
	import org.openvideoads.vast.server.adify.AdifyVASTAdRequest;
	import org.openvideoads.vast.server.lightningcast.LightningcastVASTAdRequest;
	import org.openvideoads.vast.server.liverail.LiverailVASTAdRequest;
	import org.openvideoads.vast.server.microsoft.MicrosoftVASTAdRequest;
	import org.openvideoads.vast.server.scanscout.ScanscoutVASTAdRequest;
	
	/**
	 * @author Paul Schulz
	 */
	public class AdServerRequestFactory {
		public static const AD_SERVER_ADIFY:String = "ADIFY";
		public static const AD_SERVER_ADTECH:String = "ADTECH";
		public static const AD_SERVER_BRIDGE:String = "BRIDGE";
		public static const AD_SERVER_DART:String = "DART";
		public static const AD_SERVER_DIRECT:String = "DIRECT";
		public static const AD_SERVER_LIGHTNINGCAST:String = "LIGHTNINGCAST";
		public static const AD_SERVER_LIVERAIL:String = "LIVERAIL";
		public static const AD_SERVER_MICROSOFT:String = "MICROSOFT";
		public static const AD_SERVER_OAS:String = "OAS"; //247 Real Media
		public static const AD_SERVER_OASIS:String = "OASIS";
		public static const AD_SERVER_OPENX:String = "OPENX";
		public static const AD_SERVER_SCANSCOUT:String = "SCANSCOUT";
		public static const AD_SERVER_SMART:String = "SMART";
		
		public static function create(type:String):AdServerRequest {
			switch(type.toUpperCase()) {
				case AD_SERVER_ADTECH:
					return new AdTechVASTAdRequest();

				case AD_SERVER_ADIFY:
					return new AdifyVASTAdRequest();

				case AD_SERVER_DART:
					return new DARTVASTAdRequest();

				case AD_SERVER_DIRECT:
					return new DirectVASTAdRequest();

				case AD_SERVER_LIGHTNINGCAST:
					return new LightningcastVASTAdRequest();

				case AD_SERVER_LIVERAIL:
					return new LiverailVASTAdRequest();

				case AD_SERVER_MICROSOFT:
					return new MicrosoftVASTAdRequest();

				case AD_SERVER_OAS:
					return new OasVASTAdRequest();

				case AD_SERVER_OASIS:
					return new OasisVASTAdRequest();

				case AD_SERVER_OPENX:
					return new OpenXVASTAdRequest();

				case AD_SERVER_SCANSCOUT:
					return new ScanscoutVASTAdRequest();

//				case AD_SERVER_SMART:
//					return new SmartAdServerVASTAdRequest();
			}
			return null;
		}
	}
}