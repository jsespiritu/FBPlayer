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
	import org.openvideoads.base.Debuggable;
	import org.openvideoads.vast.server.adtech.AdTechServerConfig;
	import org.openvideoads.vast.server.bridge.BridgeServerConfig;
	import org.openvideoads.vast.server.openx.OpenXServerConfig;
	import org.openvideoads.vast.server.direct.DirectServerConfig;
	import org.openvideoads.vast.server.oas.OasServerConfig;
	import org.openvideoads.vast.server.doubleclick.DARTServerConfig;
	import org.openvideoads.vast.server.oasis.OasisServerConfig;
	import org.openvideoads.vast.server.adify.AdifyServerConfig;
	import org.openvideoads.vast.server.lightningcast.LightningcastServerConfig;
	import org.openvideoads.vast.server.liverail.LiverailServerConfig;
	import org.openvideoads.vast.server.microsoft.MicrosoftServerConfig;
	import org.openvideoads.vast.server.scanscout.ScanscoutServerConfig;
//	import org.openvideoads.vast.server.smart.SmartServerConfig;
	
	/**
	 * @author Paul Schulz
	 */
	public class AdServerConfigFactory {
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
		
		public static function getAdServerConfig(type:String):AdServerConfig {
			switch(type.toUpperCase()) {
				case AD_SERVER_ADIFY:
					return new AdifyServerConfig();
					
				case AD_SERVER_ADTECH:
					return new AdTechServerConfig();
					
				case AD_SERVER_BRIDGE:
					return new BridgeServerConfig();

				case AD_SERVER_DART:
					return new DARTServerConfig();

				case AD_SERVER_DIRECT:
					return new DirectServerConfig();

				case AD_SERVER_LIGHTNINGCAST:
					return new LightningcastServerConfig();

				case AD_SERVER_LIVERAIL:
					return new LiverailServerConfig();

				case AD_SERVER_MICROSOFT:
					return new MicrosoftServerConfig();

				case AD_SERVER_OAS:
					return new OasServerConfig();

				case AD_SERVER_OASIS:
					return new OasisServerConfig();

				case AD_SERVER_OPENX:
					return new OpenXServerConfig();

				case AD_SERVER_SCANSCOUT:
					return new ScanscoutServerConfig();

//				case AD_SERVER_SMART:
//					return new SmartServerConfig();

				default:
					Debuggable.getInstance().doLog("Cannot create AdServerConfig object for type " + type, Debuggable.DEBUG_CONFIG);
			}
			return null;
		}
	}
}