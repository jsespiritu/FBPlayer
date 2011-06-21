//
// Copyright (c) 2009-2010, the Open Video Player authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without 
// modification, are permitted provided that the following conditions are 
// met:
//
//    * Redistributions of source code must retain the above copyright 
//notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above 
//copyright notice, this list of conditions and the following 
//disclaimer in the documentation and/or other materials provided 
//with the distribution.
//    * Neither the name of the openvideoplayer.org nor the names of its 
//contributors may be used to endorse or promote products derived 
//from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

package controller{

	import com.akamai.net.*;
	import com.akamai.rss.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	import model.Model;
	
	import org.openvideoplayer.events.*;
	import org.openvideoplayer.net.*;
	import org.openvideoplayer.net.dynamicstream.*;
	import org.openvideoplayer.parsers.*;
	import org.openvideoplayer.rss.*;
	
	import view.VideoView;

	// ------- HD Library
	import com.akamai.hd.HDNetStream;
	import com.akamai.hd.HDEvent;
	
	/**
	 * Akamai Multi Player - controller working in conjunction with the VideoView
	 */
	public class VideoController extends EventDispatcher {

		private var _model:Model;
		private var _view:VideoView;
		private var _rss:AkamaiMediaRSS;
		private var _boss:AkamaiBOSSParser;
		private var _SMILparser:DynamicSmilParser;
		private var _ak:AkamaiConnection;
		private var _streamName:String;
		private var _mustDetectBandwidth:Boolean;
		private var _successfulPort:String;
		private var _successfulProtocol:String;
		private var _connectionAuthParameters:String;
		private var _streamAuthParameters:String;
		private var _isLive:Boolean;
		private var _needsRestart:Boolean;
		private var _needsSeek:Boolean;
		private var _needsResume:Boolean;
		private var _lastConnectionKey:String;
		private var _isMultiBitrate:Boolean;
		private var _ns:AkamaiDynamicNetStream;
		private var _dsi:DynamicStreamItem;
		private var _progressTimer:Timer;
		private var _adPlaying:Boolean;
		private var _startPlayPending:Boolean;
		private var _needToSetCuePointMgr:Boolean;
		
		// ----- test ------
		private var _nshd:HDNetStream;
		private var netStream:NetStream;
		private var netConnection:NetConnection;
		private var isHD:Boolean = false;
		
		// -------------------

		public function VideoController(model:Model,view:VideoView):void {
			_model = model;
			_view = view;
			_adPlaying = false;
			_startPlayPending = false;
			_needToSetCuePointMgr = false;
			initializeChildren();
		}
		private function initializeChildren():void {
			_model.addEventListener(_model.EVENT_VOLUME_CHANGE, volumeChangeHandler);
			_model.addEventListener(_model.EVENT_PLAY, playHandler);
			_model.addEventListener(_model.EVENT_PAUSE, pauseHandler);
			_model.addEventListener(_model.EVENT_SEEK, seekHandler);
			_model.addEventListener(_model.EVENT_NEW_SOURCE, newSourceHandler);
			_model.addEventListener(_model.EVENT_SWITCH_UP, switchUpHandler);
			_model.addEventListener(_model.EVENT_SWITCH_DOWN, switchDownHandler);
			_model.addEventListener(_model.EVENT_TOGGLE_AUTO_SWITCH, toggleSwitchHandler);
			_model.addEventListener(_model.EVENT_AD_START, adStartHandler);
			_model.addEventListener(_model.EVENT_AD_END, adEndHandler);
			_model.addEventListener(_model.EVENT_SET_CUEPOINT_MGR, cuePointMgrSetHandler);

			_rss = new AkamaiMediaRSS();
			_rss.addEventListener(OvpEvent.PARSED, rssParsedHandler);
			_rss.addEventListener(OvpEvent.ERROR, parseErrorHandler);
			_boss = new AkamaiBOSSParser();
			_boss.addEventListener(OvpEvent.PARSED, bossParsedHandler);
			_boss.addEventListener(OvpEvent.ERROR, parseErrorHandler);
			_SMILparser = new DynamicSmilParser();
			_SMILparser.addEventListener(OvpEvent.PARSED, smilParsedHandler);
			_SMILparser.addEventListener(OvpEvent.ERROR, parseErrorHandler);
			_successfulPort = "any";
			_successfulProtocol = "any";
			_isLive = false;
			_lastConnectionKey = "";
			_progressTimer = new Timer(100);
			_progressTimer.addEventListener(TimerEvent.TIMER, progressHandler);

		}

		private function newSourceHandler(e:Event):void {
			var protocol:String;
			_view.video.clear();
			if (_ns is NetStream) {
				_ns.pause();
			}
			_connectionAuthParameters = "";
			_streamAuthParameters = "";
			_isLive = false;
			_isMultiBitrate = false;
			switch (_model.srcType) {	
				case _model.TYPE_AMD_ONDEMAND :
					trace("TYPE_AMD_ONDEMAND");
					this.isHD = false;
					var host:String = _model.src.split("/")[2] + "/" + _model.src.split("/")[3];
					_streamName = _model.src.slice(_model.src.indexOf(host) + host.length + 1);
					if (_model.src.indexOf("?") != -1) {
						_connectionAuthParameters = _model.src.slice(_model.src.indexOf("?") + 1);
						_streamAuthParameters = _model.src.slice(_model.src.indexOf("?") + 1);
						_streamName = _streamName.slice(0,_streamName.indexOf("?"));
					}
					if (_streamName.slice(-4) == ".flv" || _streamName.slice(-4) == ".mp3") {
						_streamName = _streamName.slice(0,-4);
					}

					_mustDetectBandwidth = false;
					protocol = _model.src.indexOf(":") != -1 ? _model.src.slice(0,_model.src.indexOf(":")).toLowerCase():"any";
					connect(host,protocol);
					break;
				case _model.TYPE_BOSS_STREAM :
					trace("TYPE_BOSS_STREAM");
					this.isHD = false;
					_mustDetectBandwidth = false;
					_boss.load(_model.src);

					break;
				case _model.TYPE_MEDIA_RSS :
					trace("TYPE_MEDIA_RSS");
					this.isHD = false;
					_mustDetectBandwidth = false;
					_rss.load(_model.src);
					break;
				case _model.TYPE_BOSS_PROGRESSIVE :
					trace("TYPE_BOSS_PROGRESSIVE");
					this.isHD = false;
					_streamName = _model.src;
					connect(null);
					break;
				case _model.TYPE_AMD_PROGRESSIVE :
					trace("TYPE_AMD_PROGRESSIVE");
					this.isHD = false;
					_streamName = _model.src;
					connect(null);
					break;
				case _model.TYPE_AMD_LIVE :
					trace("TYPE_AMD_LIVE");
					this.isHD = false;
					var liveHost:String = _model.src.split("/")[2] + "/" + _model.src.split("/")[3];
					_streamName = _model.src.slice(_model.src.indexOf(liveHost) + liveHost.length + 1);
					_isLive = true;
					_model.isLive = _isLive;
					protocol = _model.src.indexOf(":") != -1 ? _model.src.slice(0,_model.src.indexOf(":")).toLowerCase():"any";
					connect(liveHost,protocol);
					break;
				case _model.TYPE_MBR_SMIL :
					trace("TYPE_MBR_SMIL");
//					_mustDetectBandwidth = false;
//					_SMILparser.load(_model.src);
/*					netConnection = new NetConnection();
					netConnection.connect(null);
					
					_nshd = new HDNetStream(netConnection);
					_nshd.loop = false;
					var clipStartTime:Number=NaN;
					var clipEndTime:Number=NaN
*/
//					var host:String = _model.src.split("/")[2] + "/" + _model.src.split("/")[3];
//					var str:String = _model.src.slice(_model.src.indexOf(host) + host.length + 1);
//					var ext:String = str.slice(-4);
//					trace("HOST NAME === " + ext );			
					this.isHD = true;
					connect(host, protocol);
/*					var playArgs:Array = [_model.src, clipStartTime, clipEndTime];
					_nshd.addEventListener(NetStatusEvent.NET_STATUS, netStreamStatusHandler);
					_nshd.addEventListener(HDEvent.METADATA, onHDMetaData);
					_nshd.addEventListener(HDEvent.COMPLETE, onComplete);
					_nshd.play.apply(this, playArgs);
					_view.video.attachNetStream(_nshd);
*/					break;
			}

		}

		// Handles a successful connection
		private function connectedHandler():void {			
			if(this.isHD)
			{
				// if disconnected
				if(!netConnection.connected)
				{
					netConnection = new NetConnection();
					netConnection.connect(null);
				}
				_model.debug("Connected to " + netConnection.uri);
								
				// not connected to HDNetStream
				if(_nshd != null)
				{
					_nshd.close();
					_nshd = null;
				}							
				_nshd = new HDNetStream(netConnection);
				_nshd.loop = false;
				setupHDListeners(true);
				
				if (_needToSetCuePointMgr) {
					cuePointMgrSetHandler(null);
				}
				
				volumeChangeHandler(null);
				
				var clipStartTime:Number=NaN;
				var clipEndTime:Number=NaN
				
				var playArgs:Array = [_model.src, clipStartTime, clipEndTime];
				var name:String = _streamName + (_streamAuthParameters != "" ? "?" + _streamAuthParameters:"");
				
				if(!_model.playlistItems)
				{
					if(_model.directPlay)
					{
						trace("----------------------------- single item -------------------------------------" + _model.src);
						_nshd.play.apply(this, playArgs);
						_view.video.attachNetStream(_nshd);
					
						_nshd.maxBufferLength = 5;
						
						// Notifier function
						_model.netStreamCreated(_nshd, name);
						
						_nshd.volume = _model.autoStart ? _model.volume:50;
						_progressTimer.start();
									
						if (_model.autoStart) {
							_model.showPauseButton();
						}
					}					
					_model.directPlay = true;
				}
				else
				{
					_model.singleItemInXML = (_model.playlistItems.length<2)?true:false;
					trace("------------------------ whith playlist ------------------------------------------" + _model.src);
					_nshd.play.apply(this, playArgs);
					_view.video.attachNetStream(_nshd);
				
					_nshd.maxBufferLength = 5;
					
					// Notifier function
					_model.netStreamCreated(_nshd, name);
					
					_nshd.volume = _model.autoStart ? _model.volume:50;
					_progressTimer.start();
								
					if (_model.autoStart) {
						_model.showPauseButton();
					}					
				}
			}
			else
			{
				if (! _ak || ! _ak.netConnection) {
					return;
				}
				
				_successfulPort = _ak.actualPort;
				_successfulProtocol = _ak.actualProtocol;
				_model.debug("Connected to " + _ak.netConnection.uri);
				_model.isLive = _ak.isLive;
				
				if (_ns != null)
				{
					_ns.close();
					setupListeners(false);
					_ns = null;
				}
				_ns = new AkamaiDynamicNetStream(_ak);
				setupListeners();
				
				if (_needToSetCuePointMgr) {
					cuePointMgrSetHandler(null);
				}
				
				_ns.createProgressivePauseEvents = true;
				
				volumeChangeHandler(null);
				
				_view.video.attachNetStream(_ns);
				if (_mustDetectBandwidth) {
					_ak.detectBandwidth();
				} else {
					trace("------------------------------------------------------------------" + _model.src);
					playStream();
				}
				
			}			

			/* for hd listeners */
			function setupHDListeners(add:Boolean=false):void
			{
				if (add)
				{
					_nshd.addEventListener(HDEvent.IS_BUFFERING, onBuffer);
					//_nshd.addEventListener(NetStatusEvent.NET_STATUS, netStreamStatusHandler);
					_nshd.addEventListener(OvpEvent.DEBUG, debugHDHandler);
					_nshd.addEventListener(HDEvent.METADATA, onHDMetaData);
					_nshd.addEventListener(HDEvent.COMPLETE, onComplete);
					_nshd.addEventListener(HDEvent.COMPLETE, handleHDTransitionComplete);
					
				}
				else
				{
					_nshd.removeEventListener(HDEvent.IS_BUFFERING, onBuffer);
					//_nshd.removeEventListener(NetStatusEvent.NET_STATUS, netStreamStatusHandler);
					_nshd.removeEventListener(HDEvent.DEBUG, debugHDHandler);
					_nshd.removeEventListener(HDEvent.METADATA, onHDMetaData);
					_nshd.removeEventListener(HDEvent.COMPLETE, onComplete);
					_nshd.removeEventListener(HDEvent.COMPLETE, handleHDTransitionComplete);
				}
			}
			/* end of hd connection */

			function setupListeners(add:Boolean=true):void
			{
				if (add)
				{
					_ns.addEventListener(NetStatusEvent.NET_STATUS, netStreamStatusHandler);
					_ns.addEventListener(OvpEvent.DEBUG, debugHandler);
					_ns.addEventListener(OvpEvent.COMPLETE, handleComplete);
					_ns.addEventListener(OvpEvent.NETSTREAM_METADATA, handleMetaData);
					_ns.addEventListener(OvpEvent.NETSTREAM_PLAYSTATUS, handleTransitionComplete);
					_ns.addEventListener(OvpEvent.STREAM_LENGTH, handleStreamLength);
					_ns.addEventListener(OvpEvent.NETSTREAM_CUEPOINT, handleCuePoint);
					_ns.addEventListener(OvpEvent.SUBSCRIBE_ATTEMPT, handleSubscribeAttempt);
					_ns.addEventListener(OvpEvent.SWITCH_REQUESTED, switchRequestedHandler);
					_ns.addEventListener(OvpEvent.SWITCH_ACKNOWLEDGED, switchAcknowledgedHandler);
					_ns.addEventListener(OvpEvent.SWITCH_COMPLETE, switchCompleteHandler);
				}
				else
				{
					_ns.removeEventListener(NetStatusEvent.NET_STATUS, netStreamStatusHandler);
					_ns.removeEventListener(OvpEvent.DEBUG, debugHandler);
					_ns.removeEventListener(OvpEvent.COMPLETE, handleComplete);
					_ns.removeEventListener(OvpEvent.NETSTREAM_METADATA, handleMetaData);
					_ns.removeEventListener(OvpEvent.NETSTREAM_PLAYSTATUS, handleTransitionComplete);
					_ns.removeEventListener(OvpEvent.STREAM_LENGTH, handleStreamLength);
					_ns.removeEventListener(OvpEvent.NETSTREAM_CUEPOINT, handleCuePoint);
					_ns.removeEventListener(OvpEvent.SUBSCRIBE_ATTEMPT, handleSubscribeAttempt);
					_ns.removeEventListener(OvpEvent.SWITCH_REQUESTED, switchRequestedHandler);
					_ns.removeEventListener(OvpEvent.SWITCH_ACKNOWLEDGED, switchAcknowledgedHandler);
					_ns.removeEventListener(OvpEvent.SWITCH_COMPLETE, switchCompleteHandler);					
				}
			}
		}
		

		private function switchRequestedHandler(e:OvpEvent):void {
			_model.switchRequested(e.data);
		}
		
		private function switchAcknowledgedHandler(e:OvpEvent):void {
			_model.switchAcknowledged(e.data);
		}
		
		private function switchCompleteHandler(e:OvpEvent):void {
			_model.switchComplete(e.data);
		}

		private function handleCuePoint(e:OvpEvent):void {
			_model.cuePointReached(e.data);
		}

		private function handleComplete(e:OvpEvent):void {
			_ns.pause();
			_ns.seek(0);
			_model.endOfItem();
		}
		// HD -----  
		private function onComplete(event:HDEvent):void
		{
			//_nshd.seek(0);
			_model.endOfItem();
			_nshd.pause();
		}
		
		private function handleTransitionComplete(e:OvpEvent):void {
			if (e.data.code == "NetStream.Play.TransitionComplete") {
				_model.currentIndex = _ns.renderingIndex;
			}
		}
		
		private function handleHDTransitionComplete(e:HDEvent):void
		{
			//if(e.data.code == "NetStream.Play.TransitionComplete")
			   _model.currentIndex = _nshd.currentIndex;
		}

		private function adStartHandler(e:Event):void {
			_adPlaying = true;
		}

		private function adEndHandler(e:Event):void {
			_adPlaying = false;
			if (_startPlayPending) {
				playStream();
			}
		}

		private function playStream():void {
			if (_adPlaying) {
				_startPlayPending = true;
				return;
			}

			_startPlayPending = false;
			if (_isMultiBitrate) {
				_model.maxIndex = _dsi.streamCount - 1;
				_ns.useFastStartBuffer = false;
				
				// Notifier function
				_model.netStreamCreated(_ns, null/*name*/, null/*start*/, null/*len*/, null/*reset*/, _dsi); 

				_ns.play(_dsi);
				_progressTimer.start();
				
				if (_ak.isLive) {
					_ns.maxBufferLength = 10;
				} else {
					_ns.maxBufferLength = 8;
					_ak.requestStreamLength(_dsi.streams[0].name);
				}
			} else {
				var name:String = _streamName + (_streamAuthParameters != "" ? "?" + _streamAuthParameters:"");
				_ns.useFastStartBuffer = ! _ak.isLive;
				_ns.maxBufferLength = 5;
				
				// Notifier function
				_model.netStreamCreated(_ns, name);
				
				_ns.play(name);
				_ns.volume = _model.autoStart ? _model.volume:50;
				_progressTimer.start();
				
				if (_model.srcType == _model.TYPE_AMD_ONDEMAND || _model.srcType == _model.TYPE_BOSS_STREAM) {
					_ak.requestStreamLength(_streamName);
				}
			}
			
			if (_model.autoStart) {
				_model.showPauseButton();
			}
			
			if (_needsSeek) {
				_needsSeek = false;
				seekHandler(null);
			}
		}
		// Handles a successful stream length request

		private function handleStreamLength(e:OvpEvent):void {
			_model.streamLength = Number(e.data.streamLength);
		}

//		private function handleHDStreamLength(e:HDEvent):void {
//			_model.streamLength = Number(_nshd.duration);
//		}
		
		// Updates the UI elements as the  video plays
		private function progressHandler(e:TimerEvent):void {
			if(!this.isHD)
			{	
				if(_nshd is NetStream)
				{
					netConnection.close();
					_nshd.close();
				}
				if (_ns && (_ns is AkamaiDynamicNetStream) && _ns.netConnection && (_ns.netConnection.connected)) {
					_model.time = _ns.time;
					_model.bufferPercentage = _ns.bufferLength * 100 / _ns.bufferTime;
					_model.bytesLoaded = _ns.bytesLoaded;
					_model.bytesTotal = _ns.bytesTotal;
					_model.bufferLength = _ns.bufferLength;
					if (_isMultiBitrate) {
						_model.maxBandwidth = Math.round(_ns.maxBandwidth);
						_model.currentStreamBitrate = Math.round(_dsi.getRateAt(_model.currentIndex));
					} else if (_model.srcType == _model.TYPE_AMD_ONDEMAND || _model.srcType == _model.TYPE_AMD_LIVE || _model.srcType == _model.TYPE_BOSS_STREAM) {
						_model.maxBandwidth = Math.round(_ns.info.maxBytesPerSecond * 8 / 1024);
						_model.currentStreamBitrate = Math.round(_ns.info.playbackBytesPerSecond * 8 / 1024);
					}
					_view.invokeResize();
				}
			}
			else
			{	
				if(_ns is AkamaiDynamicNetStream)
				{
					_ns.close();
				}
				if(_nshd && (_nshd is HDNetStream))
				{
					if(_nshd.duration == 0)
					{
						_model.streamLength = 0; 
					}
					
					_model.streamLength = (_model.streamLength<1?_nshd.duration:_model.streamLength);
//					if(!_model.streamLength)
//					{
//						trace("TOTAL DURATION ===== " + _nshd.duration);
//						_model.streamLength = _nshd.duration;						
//					}
					
					_model.time = _nshd.time;
	//				_model.bufferPercentage = _nshd.bufferLength * 100 / _nshd.bufferTime;
	//				_model.bytesLoaded = _nshd.bytesLoaded;
	//				_model.bytesTotal = _nshd.bytesTotal;
	//				_model.bufferLength = _nshd.bufferLength;
	//				_model.maxBandwidth = Math.round(_nshd.estimatedMaxbandwidth * 8 / 1024);
	//				_model.currentStreamBitrate = Math.round(_nshd.info.playbackBytesPerSecond * 8 / 1024);
					_view.invokeResize();
					// pending ----------
				}
			}
		}
		
		private function onBuffer(event:HDEvent):void
		{
			//_nshd.bufferLength * 100 / _nshd.bufferTime;
			//trace(" EVENT DATA ================== " + event.data);
			//event.data ? trace("===== BUFFERING ====== ") : trace(" ============== hide buffering ================"); 
			if(event.data)
			{
				pauseHandler(null);
				trace("BUFFERING ========================================================================= >>>>>>>>> ");
				_model.isBuffering = true;
				_model.playStart();
			}
			else
			{
				//_needsRestart = true;
				_view.showVideo();
				_model.bufferFull();
				//_nshd.resume();	
			}
		}

		// Handles netstream status events. We trap the buffer full event
		// in order to start updating our slider again, to prevent the
		// slider bouncing after a drag.		
		private function netStreamStatusHandler(e:NetStatusEvent):void {
			//var streamtime:Number = (this.isHD)?_nshd.time:_ns.time;
			var streamtime:Number = _ns.time;
			_model.debug(e.info.code + " at stream time " + streamtime);

			switch (e.info.code) {
				case "NetStream.Play.StreamNotFound" :
					_model.streamNotFound();
					break;
				case "NetStream.Buffer.Full" :
					if (! _model.autoStart) {
						pauseHandler(null);
						_needsRestart = true;
						_ns.volume = _model.volume;
						_ns.close();
						_ak.close();							
						_model.closeAfterPreview();
					}
					_view.showVideo();
					_model.bufferFull();

					break;
				case "NetStream.Buffer.Flush" :
					_model.bufferFull();
					break;
				case "NetStream.Play.Start" :
					_model.isBuffering = true;
					if (_ns.isProgressive) {
						_model.playStart();
					}
					break;
				case "NetStream.Play.Reset" :
					if (! _ns.isProgressive) {
						_model.playStart();
					}
					break;
				case "NetStream.Play.Transition" :
					_model.debug("Transition to new stream starting ...");
					break;

			}
		}

		// Handles NetConnection status events. 
		private function netStatusHandler(e:NetStatusEvent):void {
			_model.debug(e.info.code);
			switch (e.info.code) {
				case "NetConnection.Connect.IdleTimeOut" :
					_needsRestart = true;
					pauseHandler(null);
					break;
				case "NetConnection.Connect.Closed" :
					_needsRestart = true;
					pauseHandler(null);
					break;
				case "NetConnection.Connect.Success" :
					connectedHandler();
					break;
			}
		}
		// Handles metadata that is released by the stream
		private function onHDMetaData(event:HDEvent):void
		{
			if (_view != null && _view.stage != null && _view.stage.displayState != StageDisplayState.FULL_SCREEN) {
				_view.scaleVideo(Number(event.data.width), Number(event.data.height));
			}
		}		
		private function handleMetaData(e:OvpEvent):void {
			if (_view != null && _view.stage != null && _view.stage.displayState != StageDisplayState.FULL_SCREEN) {
				_view.scaleVideo(Number(e.data["width"]), Number(e.data["height"]));
			}
		}

		private function volumeChangeHandler(e:Event):void {
			if(this.isHD)
			{
				_nshd.soundTransform = new SoundTransform(_model.volume);
			}
			else
			{
				_ns.soundTransform = new SoundTransform(_model.volume);
			}
		}
		private function switchUpHandler(e:Event):void {
			_ns.switchUp();
		}
		private function switchDownHandler(e:Event):void {
			_ns.switchDown();
		}
		private function toggleSwitchHandler(e:Event):void {
			_ns.useManualSwitchMode(!_model.useAutoDynamicSwitching);
		}


		// Handles any errors dispatched by the connection class.
		private function onError(e:OvpEvent):void {
			switch (e.data.errorNumber) {
				case 6 :
					_successfulPort = "any";
					_successfulProtocol = "any";
					_model.showError(_model.ERROR_TIME_OUT_CONNECTING);
					break;
				case 7 :
					_model.showError(_model.ERROR_FILE_NOT_FOUND);
					break;
				case 9 :
					_model.showError(_model.ERROR_LIVE_STREAM_TIMEOUT);
					break;
				case 13 :
					_model.showError(_model.ERROR_CONNECTION_REJECTED);
					break;
				case 22 :
					_model.showError(_model.ERROR_NETSTREAM_FAILED);
					break;
				case 23 :
					_needsRestart = true;
					_successfulPort = "any";
					_successfulProtocol = "any";
					_model.showError(_model.ERROR_CONNECTION_FAILED);
					break;

			}
		}
		// HD Error
		// Handles any errors dispatched by the connection class.
		private function onHDError(e:HDEvent):void {
			switch (e.data.errorNumber) {
				case 1 :
					_model.showError(_model.ERROR_STREAM_NOT_FOUND);
					break;
				case 2 :
					_model.showError(_model.ERROR_TRACK_NOT_FOUND);
					break;
				case 3 :
					_model.showError(_model.ERROR_SEEK_OUT_OF_BOUNDS);
					break;
				case 4 :
					_model.showError(_model.ERROR_AUTHENTICATION_FAILED);
					break;
				case 5 :
					_model.showError(_model.ERROR_DVR_DISABLED);
					break;
				case 6 :
					_model.showError(_model.ERROR_INVALID_BITRATE_TEST);
					break;
				case 7 :
					_model.showError(_model.ERROR_RTMP_FALLBACK);
					break;
			}
		}
		
		// Handle play events
		private function playHandler(e:Event):void {
			if (_needsRestart) {
				_needsRestart = false;
				newSourceHandler(null);
			} else {
				
				if(this.isHD) 
					_nshd.resume();
				else 
					_ns.resume();
			}
		}
		// Handle pause events
		private function pauseHandler(e:Event):void {
			if(this.isHD)
			{
				_nshd.pause();
			}
			else
			{
				_ns.pause();
			}
		}
		// Handle seek events
		private function seekHandler(e:Event):void {
			if (_needsRestart) {
				_needsRestart = false;
				_needsSeek = true;
				newSourceHandler(null);
			} else {
				
				if(this.isHD)
				{
					_nshd.seek(_model.seekTarget);
				}
				else
				{
					_ns.seek(_model.seekTarget);
				}				
			}
		}
		
		private function seekHDHandler(e:HDEvent):void
		{
			_nshd.seek(_model.seekTarget);
		}
		// Handle a resubscribe attempt
		private function handleSubscribeAttempt(e:OvpEvent):void {
			_model.debug("Trying to re-subscribe to the live stream ...");
		}
		// handle BOSS results
		private function bossParsedHandler(e:OvpEvent):void {
			_connectionAuthParameters = _boss.connectAuthParams;
			_streamAuthParameters = _boss.playAuthParams;
			_isLive = _boss.isLive;
			_streamName = _boss.streamName;
			var protocol:String = _boss.protocol != "" && _boss.protocol != null ? _boss.protocol:"any";
			connect(_boss.hostName,protocol);
		}
		// handle multi-bitrate SMIL results
		private function smilParsedHandler(e:OvpEvent):void {
			_isMultiBitrate = true;
			_model.isMultiBitrate = true;
			_dsi = _SMILparser.dsi;
			var protocol:String = _SMILparser.protocol != "" ? _SMILparser.protocol:"any";
			connect(_SMILparser.hostName, protocol);

		}
		private function rssParsedHandler(e:OvpEvent):void {
			_model.playlistItems = _rss.itemArray;
		}
		private function parseErrorHandler(e:OvpEvent):void {
			switch (e.data.errorNumber) {
				case 14 :
					_model.showError(_model.ERROR_HTTP_LOAD_FAILED);
					break;
				case 15 :
					_model.showError(_model.ERROR_BAD_XML);
					break;
				case 16 :
					_model.showError(_model.ERROR_XML_NOT_RSS);
					break;
				case 18 :
					_model.showError(_model.ERROR_XML_NOT_BOSS);
					break;
				case 20 :
					_model.showError(_model.ERROR_LOAD_TIME_OUT);
					break;
			}

		}


		private function debugHandler(e:OvpEvent):void {
			_model.debug(e.data.toString());
		}
		
		private function debugHDHandler(e:HDEvent):void
		{
			_model.debug(e.data.toString());
		}

		private function cuePointMgrSetHandler(e:Event):void {
			_needToSetCuePointMgr = true;

			if(this.isHD)
			{
//				if (_nshd && _model.cuePointManager) {
//					_model.cuePointManager.netStream = netStream;
//					_needToSetCuePointMgr = false;
//				}											
			}
			else
			{
				if (_ns && _model.cuePointManager) {
					_model.cuePointManager.netStream = _ns;
					_needToSetCuePointMgr = false;
				}							
			}
		}

		private function connect(hostName:String, requestedProtocol:String = "any"):void {	
			if(this.isHD)
			{	
				netConnection = new NetConnection();
				if (((hostName + _connectionAuthParameters) == _lastConnectionKey) && !_needsRestart && netConnection.connected ) {
					// rejoice, we can reuse the existing connection;
					connectedHandler();				
				}
				else
				{
					
					netConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
					netConnection.addEventListener(HDEvent.ERROR, onHDError);
					if (! _model.autoStart) {
						_view.hideVideo();
					}
					// Notifier function
					_model.connectionCreated(netConnection, hostName);
					netConnection.connect(null);
					_lastConnectionKey = hostName + _connectionAuthParameters;
				}
			}
			else
			{					
				_ak = new AkamaiConnection();
				if (((hostName + _connectionAuthParameters) == _lastConnectionKey) && !_needsRestart && _ak.connected ) {
					// rejoice, we can reuse the existing connection;
					connectedHandler();				
				} else {
					//_ak = new AkamaiConnection();
					_ak.addEventListener(NetStatusEvent.NET_STATUS,netStatusHandler);
					_ak.addEventListener(OvpEvent.STREAM_LENGTH,handleStreamLength);
					_ak.addEventListener(OvpEvent.ERROR, onError);
					_ak.requestedPort = _successfulPort != null ? _successfulPort:"any";
					requestedProtocol = (requestedProtocol == "rtmpe" || requestedProtocol == "rtmpte") ? "rtmpe,rtmpte":requestedProtocol;
					_ak.requestedProtocol = requestedProtocol == "any" ? (_successfulProtocol != null ? _successfulProtocol:"any") : requestedProtocol;
					
					if (_connectionAuthParameters != "" && _connectionAuthParameters != null) {
						_ak.connectionAuth = _connectionAuthParameters;
					}
					if (! _model.autoStart) {
						_view.hideVideo();
					}
					
					// Notifier function
					_model.connectionCreated(_ak, hostName);
					
					_ak.connect(hostName);
					_lastConnectionKey = hostName + _connectionAuthParameters;
				}
			} // end of this.isHD
		}
	}
}
