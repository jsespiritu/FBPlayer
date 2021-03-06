﻿//
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
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
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
	import com.akamai.net.f4f.ZStream;	
	import com.akamai.hdcore.samples.utility.Utils;		
	import org.openvideoplayer.components.ui.controlbar.ControlBar;
	import view.ControlbarView;

	/* JSON Deccder */
	import com.adobe.serialization.json.*;
	import com.adobe.serialization.json.JSONDecoder;
	/* --- JSON Deccder */

	/**
	 * Akamai Multi Player - controller working in conjunction with the VideoView
	 */
	public class VideoController extends EventDispatcher {

		private var _model:Model;
		private var _view:VideoView;
		private var _controlBarView; // controlbar view
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
		
		// ----- HD VARIABLES ------
		private var _nshd:HDNetStream;
		private var _nsz:ZStream;
		private var netStream:NetStream;
		private var netConnection:NetConnection;
		
		private var isHD:Boolean = false;
		private var isZStream:Boolean = false;
		
		private var _host:String;
		private var _protocol:String;
		
		private var _triggerCounter:Number = 0;
		private var _adCounter:Number = 0;
		private var _preRollStarted:Boolean = false;
		// -------------------

		public function VideoController(model:Model,view:VideoView):void {
			_model = model;
			_view = view;
			_adPlaying = false;
			_startPlayPending = false;
			_needToSetCuePointMgr = false;
			_controlBarView = new ControlbarView(_model);
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
					this.isHD = false;
					this.isZStream = false;
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
					this.isHD = false;
					this.isZStream = false;
					_mustDetectBandwidth = false;
					_boss.load(_model.src);

					break;
				case _model.TYPE_MEDIA_RSS :
					this.isHD = false;
					this.isZStream = false;
					_mustDetectBandwidth = false;
					_rss.load(_model.src);
					break;
				case _model.TYPE_BOSS_PROGRESSIVE :
					this.isHD = false;
					this.isZStream = false;
					_streamName = _model.src;
					connect(null);
					break;
				case _model.TYPE_AMD_PROGRESSIVE :
					this.isHD = true;
					this.isZStream = false;
					_streamName = _model.src;
					connect(null);
					break;
				case _model.TYPE_AMD_LIVE :
					this.isHD = false;
					this.isZStream = false;
					var liveHost:String = _model.src.split("/")[2] + "/" + _model.src.split("/")[3];
					_streamName = _model.src.slice(_model.src.indexOf(liveHost) + liveHost.length + 1);
					_isLive = true;
					_model.isLive = _isLive;
					protocol = _model.src.indexOf(":") != -1 ? _model.src.slice(0,_model.src.indexOf(":")).toLowerCase():"any";
					connect(liveHost,protocol);
					break;
				case _model.TYPE_MBR_SMIL : /* Http Dynamic HD Streaming */
					this.isHD = true;
					this.isZStream = false;
					if(_model.enableGeoIpRestriction){
						_host = host;
						_protocol = protocol;
						this.getGeoIp(_model.src);
					}
					else{
						_model.isGeoIpAllowed = true;
						connect(host, protocol);							
					}
					break;
				case _model.TYPE_ZSTREAM : /* Secure Zeri Streaming */
					this.isHD = false;
					this.isZStream = true;
					_host = host;
					_protocol = protocol;
					if(_model.enableGeoIpRestriction){
						_host = host;
						_protocol = protocol;
						this.getGeoIp(_model.src);
					}
					else{
						_model.isGeoIpAllowed = true;
						connect(_host, _protocol);							
					}
					break;
			}
		}

		// Handles a successful connection
		private function connectedHandler():void {		
			/* HD Connection Handler */
			if(this.isHD){
				// if disconnected
				if(!netConnection.connected){
					netConnection = new NetConnection();
					netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netSecurityError);
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
					/* SINGLE ITEM */
					if(_model.directPlay)
					{
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
				else{
					/* WITH PLAYLIST XML/RSS */
					_model.singleItemInXML = (_model.playlistItems.length<2)?true:false;
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
			/* Zeri Connection Handler */
			else if(this.isZStream){
				// if disconnected
				if(!netConnection.connected){
					netConnection = new NetConnection();
					netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netSecurityError);
					netConnection.connect(null);
				}
				_model.debug("Connected to " + netConnection.uri);

				// not connected to ZStream
				if(_nsz != null){
					_nsz.close();
					_nsz = null;
				}						
				
				_nsz = new ZStream(netConnection);
				setupZStreamListeners(true);
				
				if (_needToSetCuePointMgr) {
					cuePointMgrSetHandler(null);
				}
				
				volumeChangeHandler(null);
				
				var zclipStartTime:Number=NaN;
				var zclipEndTime:Number=NaN
				var content_with_token:String = _model.src + _model.tokenParam;
				var zplayArgs:Array = [content_with_token, zclipStartTime, zclipEndTime];
				var zname:String = _streamName + (_streamAuthParameters != "" ? "?" + _streamAuthParameters:"");
				
				if(!_model.playlistItems){
					/* single video */
					if(_model.directPlay){
						_nsz.play.apply(this, zplayArgs);
						_view.video.attachNetStream(_nsz);
						
						// Notifier function
						_model.netStreamCreated(_nsz, zname);
						
						_nsz.volume = _model.autoStart ? _model.volume:50;
						_progressTimer.start();
									
						if (_model.autoStart) {
							_model.showPauseButton();
						}
						_view.hideVideo();
					}					
					_model.directPlay = true;
				}
				/*   with playlist (xml/rss) */
				else{
					_model.singleItemInXML = (_model.playlistItems.length<2)?true:false;
					_nsz.play.apply(this, zplayArgs);
					_view.video.attachNetStream(_nsz);
				
					// Notifier function
					_model.netStreamCreated(_nsz, zname);
					
					_nsz.volume = _model.autoStart ? _model.volume:50;
					_progressTimer.start();
					_view.hideVideo();
					if (_model.autoStart) {
						_model.showPauseButton();
					}					
				}
			}			
			/* Akamai Connection Handler */
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
					playStream();
				}
				
			}			

			/* for hd listeners */
			function setupHDListeners(add:Boolean=false):void
			{
				if (add){
					_nshd.addEventListener(HDEvent.IS_BUFFERING, onBuffer);
					_nshd.addEventListener(OvpEvent.DEBUG, debugHDHandler);
					_nshd.addEventListener(HDEvent.METADATA, onHDMetaData);
					_nshd.addEventListener(HDEvent.COMPLETE, onComplete);
					_nshd.addEventListener(HDEvent.ERROR, onHDError);
					_nshd.addEventListener(HDEvent.STREAM_NOT_FOUND, hdNetStreamNotFound);
					_nshd.addEventListener(NetStatusEvent.NET_STATUS, hdNetStreamStatus);
				}
				else{
					_nshd.removeEventListener(HDEvent.IS_BUFFERING, onBuffer);
					_nshd.removeEventListener(HDEvent.DEBUG, debugHDHandler);
					_nshd.removeEventListener(HDEvent.METADATA, onHDMetaData);
					_nshd.removeEventListener(HDEvent.COMPLETE, onComplete);
					_nshd.removeEventListener(HDEvent.ERROR, onHDError);
					_nshd.removeEventListener(HDEvent.STREAM_NOT_FOUND, hdNetStreamNotFound);
					_nshd.removeEventListener(NetStatusEvent.NET_STATUS, hdNetStreamStatus);
				}
			}
			/* end of hd connection */

			/* for zeri listeners */
			function setupZStreamListeners(add:Boolean=true):void{
				if (add){
					_nsz.addEventListener(OvpEvent.COMPLETE, handleComplete);					
					_nsz.addEventListener(OvpEvent.METADATA, handleMetaData);
					_nsz.addEventListener(OvpEvent.IS_BUFFERING, onZStreamBuffer);
					_nsz.addEventListener(OvpEvent.DEBUG, debugHandler);
					_nsz.addEventListener(OvpEvent.ERROR, onError);
					//_nsz.addEventListener(IOErrorEvent.IO_ERROR, zStreamIOError);
					_nsz.addEventListener(NetStatusEvent.NET_STATUS, hdNetStreamStatus);
				}
				else{
					_nsz.removeEventListener(OvpEvent.COMPLETE, handleComplete);
					_nsz.removeEventListener(OvpEvent.NETSTREAM_METADATA, handleMetaData);
					_nsz.removeEventListener(OvpEvent.IS_BUFFERING, onZStreamBuffer);
					_nsz.removeEventListener(OvpEvent.DEBUG, debugHandler);
					_nsz.removeEventListener(OvpEvent.ERROR, onError);
					//_nsz.removeEventListener(IOErrorEvent.IO_ERROR, zStreamIOError);
					_nsz.removeEventListener(NetStatusEvent.NET_STATUS, hdNetStreamStatus);
				}
			} /* end of zeri listener */
			
			function setupListeners(add:Boolean=true):void
			{
				if (add){
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
			_view.displaySpinner(false);
			if(_ns!=null){
				_ns.pause();
				_ns.seek(0);
				_model.endOfItem();
			}
		}
		// HD -----  
		private function onComplete(event:HDEvent):void
		{
			_view.displaySpinner(false);
			//_nshd.seek(0);
			_model.endOfItem();
			_nshd.pause();
			_model.currentIndex = _nshd.currentIndex;
		}
		
		private function handleTransitionComplete(e:OvpEvent):void {
			if (e.data.code == "NetStream.Play.TransitionComplete") {
				_model.currentIndex = _ns.renderingIndex;
			}
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
				//_model.seek(20);
				
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
			
			var totalStreamLength:Number = Number(e.data.streamLength);
			if(_model.maxPlayingTime){
				_model.streamLength = (totalStreamLength > _model.maxPlayingTime ? _model.maxPlayingTime : totalStreamLength);
			}
			else{
				_model.streamLength = totalStreamLength;
			}
		}

//		private function handleHDStreamLength(e:HDEvent):void {
//			_model.streamLength = Number(_nshd.duration);
//		}
		
		private function displayPreroll():void{
			if(!_preRollStarted){
				_view.displayTFCPrerollAd(true);
				_preRollStarted = true;
				var minuteTimer:Timer = new Timer(1000, _model.timeInterval);
				minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
				minuteTimer.start();
			}
		}
		
        private function onTimerComplete(event:TimerEvent):void{
			_view.displayTFCPrerollAd(false);
			_model.tickerDone = true;
			_model.playStart();
        }		
		
		// Updates the UI elements as the  video plays
		private function progressHandler(e:TimerEvent):void {
			this.displayPreroll();
			/* handle ad message count down */
			if(_model.isAdContent){
				var s:Number = Math.floor((_model.time%3600)%60);
				var d:Number = _model.streamLength - s;
				d = Math.floor((d%3600)%60)
				if(d>0){
					_view.displayAdMessage(true, String(d));
				}				
			}
			else{
				_view.displayAdMessage(false);
			}
			
			if(!_model.isAdContent && _model.tickerDone){
				if(  _model.videoStartPoint < _model.streamLength && 
				     _model.videoStartPoint!=0 && 
				     _model.videoStartPoint != _model.videoEndPoint && 
				     _model.videoStartPoint < _model.videoEndPoint
				   ){
					if(_model.videoStartPoint < 6){
						if(int(_model.time) >= (_model.videoStartPoint + _model.videoStartPoint)-1){						
							if(_nsz != null){
								_nsz.volume = (_model.muteState)?0:_model.volume;
							}
							if(_nshd != null){
								_nshd.volume = (_model.muteState)?0:_model.volume;
							}							
						}
						else{
							if(_nsz != null){
								_nsz.volume = 0;
							}							
							if(_nshd != null){
								_nshd.volume = 0;
							}							
						}
					}
					else{
						if(int(_model.time) >= _model.videoStartPoint){						
							if(_nsz != null){
								_nsz.volume = (_model.muteState)?0:_model.volume;
							}
							if(_nshd != null){
								_nshd.volume = (_model.muteState)?0:_model.volume;
							}
						}
						else{
							if(_nsz != null){
								_nsz.volume = 0;
							}							
							if(_nshd != null){
								_nshd.volume = 0;
							}
						}						
					}
					if(_model.tickerDone && _model.videoStartPoint > 0){
						if(_model.time < _model.videoStartPoint && _model.time > 0){							
							if(!_model.videoStartPointTagged){
								_model.videoStartPointTagged = true;
								_model.pause();
								_model.seek(_model.videoStartPoint);								
								_view.replayButton.visible = false;
								_view.replayButtonLink.visible = false;
								_model.play();
							}
						}
						else{
							_view.hideVideo();
						}
						if(int(_model.time) < _model.videoStartPoint){
							_view.hideVideo();
						}
						else{
							_view.showVideo();
						}
						if(_model.videoEndPoint>0){
							if(int(_model.time) > _model.videoEndPoint + (_model.videoStartPoint < 6 ? _model.videoStartPoint -1 : 0)){
								_controlBarView._overlayPauseButton.visible = false;
								if(_nsz != null){
									_nsz.volume = 0;
								}
								if(_nshd != null){
									_model.videoStartPointTagged = false;
									_model.endOfShow = true;
									_model.pause();
									_view.video.clear();
									_view.replayButton.visible = true;
									_view.replayButtonLink.visible = true;
									netConnection.close();
									_nshd.close();
									_nshd = null;
								}
								else if(_nsz != null) {	
									_model.videoStartPointTagged = false;
									_model.endOfShow = true;
									_model.pause();
									netConnection.close();
									_nsz.close();
									_nsz = null;
									_nshd = null;										
									_view.video.clear();
									_view.replayButton.visible = true;
									_view.replayButtonLink.visible = true;								}
								else if (_ns != null){
									_model.videoStartPointTagged = false;
									_model.endOfShow = true;
									_model.seek(_model.videoStartPoint);
									_model.pause();
									_view.video.clear();
									_view.replayButton.visible = true;
									_view.replayButtonLink.visible = true;
									_ak.close();
									_ns.close();
									_ns == null;
								}
							} /* _model.time > _model.videoEndPoint */
						} /* _model.videoEndPoint>0 */
					} /* if videoStartPoint has a value and not more than to the total duration of video  (_model.tickerDone && _model.videoStartPoint > 0)*/
					else{
						_view.hideVideo();
					}
					
				} /* by default video runs 60 sec (_model.videoStartPoint < _model.streamLength && _model.videoStartPoint!=0) */
				else {
					if(_model.time >= _model.maxPlayingTime || _model.time >= _model.streamLength -1){
						_model.endOfShow = true;
						_model.streamLength = 0;
						_model.seek(0);
						_model.time = 0;
						_model.pause();
						_view.video.clear();
						_view.replayButton.visible = true;
						_view.replayButtonLink.visible = true;
						_triggerCounter = 0;
					}
					else{
						if(_triggerCounter < 3){
							_model.playStart();
							_triggerCounter++;
						}
					}
				}
			}
			else{
				_view.showVideo();
				_model.pause();
			}

			if(!this.isHD && !this.isZStream){	
//				if(!_model.isAdContent){
//					if(_model.maxPlayingTime>0){
//						if(_model.time > _model.maxPlayingTime){
//							_model.endOfShow = true;
//							_model.streamLength = 0;
//							_model.seek(0);
//							_model.time = 0;
//							_model.pause();
//						}
//					}					
//				}
				if(_nshd is NetStream){
					netConnection.close();
					_nshd.close();
				}
				if(_nsz is ZStream){
					netConnection.close();
					_nsz.close();
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
			else /* HD and Zeri Streaming */
			{	
//				if(!_model.isAdContent){
//					if(_model.maxPlayingTime>0){
//						if(_model.time > _model.maxPlayingTime){ /* validate playing time */
//							_model.endOfShow = true;
//							_model.streamLength = 0;
//							_model.seek(0);
//							_model.pause();
//							_view.video.clear();
//							_view.video.visible = false;
//						}
//					}					
//				}
				
				if(_ns is AkamaiDynamicNetStream){ /* close exeisting akamai connection */
					_ns.close();
				}
				
				if(this.isZStream){/* Zeri Streaming */				
					if(_nshd is HDNetStream){ /* close hd connection */
						_nshd.close();
					}
					if(_nsz && (_nsz is ZStream)){
						if(_nsz.duration == 0){
							_model.streamLength = 0; 
						}
						
						_model.streamLength = (_model.streamLength<1?_nsz.duration:_model.streamLength);
						_model.currentStreamBitrate = _nsz.getBitrateAtQualitylevel(_nsz.currentIndex);
						_model.bufferLength = _nsz.maximumBitrateAllowed;
						_model.time = _nsz.time;
						_view.invokeResize();
					}
				}/* --- Zeri Streaming */				
							
				if(this.isHD){ /* HD Streaming */	
					if(_nsz is ZStream){ /* close existing zeri connection */
						_nsz.close();						
					}
					if(_nshd && (_nshd is HDNetStream)){
						if(_nshd.duration == 0){
							_model.streamLength = 0; 
						}
						
						_model.streamLength = (_model.streamLength<1?_nshd.duration:_model.streamLength);
						
						_model.time = _nshd.time;
						_view.invokeResize();
					}					
				} /* HD Streaming */				
			} /* -- HD and Zeri Streaming */
		} /* -- progressHandler */
		
		
		private function onBuffer(event:HDEvent):void /* HD Buffering */
		{
			if(event.data){
				pauseHandler(null);
				_model.isBuffering = true;
				if(_model.playingState){
					_model.playStart();
				}
				else{
					_model.pause();
				}
			}
			else{
				//_view.showVideo();
				_model.bufferFull();
			}
		} /* -- HD Buffering */
		
		private function onZStreamBuffer(event:OvpEvent):void{	/* Zeri Buffering */		
			if(event.data as Boolean){ // use this for debugging
			//if(!event.data as Boolean){ // use this for production
				//_view.showVideo();
				_model.bufferFull();
			}
			else
			{
				pauseHandler(null);
				_model.isBuffering = true;
				if(_model.playingState){
					_model.playStart();
				}
				else{
					_model.pause();
				}
			}
		} /* -- Zeri Buffering */
		

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
					//_view.showVideo();
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

		/* HD NetStream Status Handler */
		private function hdNetStreamNotFound(e:HDEvent):void {
			_model.debug(e.toString());
			_model.showError("STREAM NOT FOUND!!!");
		}

		private function hdNetStreamStatus(e:NetStatusEvent):void {
			_model.debug(e.info.code);
			switch(e.info.code){
				case "NetStream.Buffer.Empty":
					_view.displaySpinner(true);
				break;
				case "NetStream.Seek.Notify":
					_view.displaySpinner(true);
				break;
				case "NetStream.Play.Start":
					_view.displaySpinner(false);
//					if(!_model.tickerDone){
//						_model.tickerDone = true;
//						_model.pause();
//						_model.time=_model.videoStartPoint;
//						_model.play();
//					}
				break;
				case "NetStream.Buffer.Full":
				break
				default:
					_view.displaySpinner(false);
				break;
			}
		} /* --- hdNetStreamStatus */				
				
		private function netStatusHandler(e:NetStatusEvent):void {  // Handles NetConnection status events. 
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
		} /* -- netStatasHandler */
		
		private function onHDMetaData(event:HDEvent):void {  // Handles HD metadata that is released by the stream
			if (_view != null && _view.stage != null && _view.stage.displayState != StageDisplayState.FULL_SCREEN) {
				_view.scaleVideo(Number(event.data.width), Number(event.data.height));
			}
			else{
				_view.scaleVideo(_model.defVideoWidth, _model.defVideoHeight);
			}
		}		
		private function handleMetaData(e:OvpEvent):void { // Handles akamai metadata that is released by the stream
			if (_view != null && _view.stage != null && _view.stage.displayState != StageDisplayState.FULL_SCREEN) {
				_view.scaleVideo(Number(e.data["width"]), Number(e.data["height"]));
			}
			else{
				_view.scaleVideo(_model.defVideoWidth, _model.defVideoHeight);
			}
		}

		private function volumeChangeHandler(e:Event):void {
			if(this.isHD){ /* HD Streaming */
				_nshd.soundTransform = new SoundTransform(_model.volume);
			}
			else if(this.isZStream){  /* Zeri Streaming */
				_nsz.soundTransform = new SoundTransform(_model.volume);
			}
			else{
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
		
		private function onError(e:OvpEvent):void {  // Handles any errors dispatched by the connection class.
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
		
		// Handles any errors dispatched by the connection class.
		private function onHDError(e:HDEvent):void {  // HD Error Handler
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
		} /* onHDError */

		private function netSecurityError(e:SecurityErrorEvent):void{
			_model.showError("Net Security Problem!!!");
			_model.debug(e.text);
		}

		// Handle play events
		private function playHandler(e:Event):void {
			if (_needsRestart) {
				_needsRestart = false;
				if(this.isHD || this.isZStream){
					if(!netConnection.connected){
						this.connect(_host, _protocol);
						_model.time = _model.videoStartPoint;
						_model.endOfShow = false;
						_model.videoStartPointTagged = false;
						_model.play();
					}
				}
				else {
					newSourceHandler(null);
				}
			} 
			else {
				if(this.isHD){
					if(!netConnection.connected){
						this.connect(_host, _protocol);
						_model.time = _model.videoStartPoint;
						_model.endOfShow = false;
						_model.play();
					}
					_nshd.resume();
				}
				else if(this.isZStream){
					if(!netConnection.connected){
						this.connect(_host, _protocol);
						_model.time = _model.videoStartPoint;
						_model.endOfShow = false;
						_model.play();
					}
					_nsz.resume()
				}
				else {
					if(!_ak.connected){
						this.connect(_host, _protocol);
						this.connectedHandler();
						_model.time = _model.videoStartPoint;
						_model.endOfShow = false;
						_model.play();
					}
					_ns.resume();
				}
			}
		}
		
		private function pauseHandler(e:Event):void { // Handle pause events
			if(this.isHD){
				if(netConnection.connected)
					_nshd.pause();
			}
			else if(this.isZStream){
				if(netConnection.connected)
					_nsz.pause();
			}
			else {
				if(_ns)
					_ns.pause();
			}
		}
		
		private function seekHandler(e:Event):void {  // Handle seek events
			if (_needsRestart) {
				_needsRestart = false;
				_needsSeek = true;
				newSourceHandler(null);
			} else {
				if(this.isHD && _nshd != null)
					_nshd.seek(_model.seekTarget);
				else if(this.isZStream && _nsz != null)
					_nsz.seek(_model.seekTarget);
				else if(_ns != null)
					_ns.seek(_model.seekTarget);
			}
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

			if(this.isHD){
//				if (_nshd && _model.cuePointManager) {
//					_model.cuePointManager.netStream = netStream;
//					_needToSetCuePointMgr = false;
//				}											
			}
			else if(this.isZStream){
			}
			else{
				if (_ns && _model.cuePointManager) {
					_model.cuePointManager.netStream = _ns;
					_needToSetCuePointMgr = false;
				}							
			}
		}

		private function connect(hostName:String, requestedProtocol:String = "any"):void {	/* connection handling */
			_host = hostName;
			_protocol = requestedProtocol;
			if(this.isHD){	/* HD Connection */
				netConnection = new NetConnection();
				if (((hostName + _connectionAuthParameters) == _lastConnectionKey) && !_needsRestart && netConnection.connected ) {
					// rejoice, we can reuse the existing connection;
					connectedHandler();				
				}
				else{					
					netConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
					netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netSecurityError);
					if (! _model.autoStart) {
						_view.hideVideo();
					}
					// Notifier function
					_model.connectionCreated(netConnection, hostName);
					netConnection.connect(null);
					_lastConnectionKey = hostName + _connectionAuthParameters;
				}
			} /* -- HD Connection */
			else if(this.isZStream){ /* Zeri Connection */
				_view.hideVideo();
				netConnection = new NetConnection();
				if (((hostName + _connectionAuthParameters) == _lastConnectionKey) && !_needsRestart && netConnection.connected ) {
					// rejoice, we can reuse the existing connection;
					connectedHandler();				
				}
				else{
					netConnection.connect(null);
					netConnection.addEventListener(NetStatusEvent.NET_STATUS, hdNetStreamStatus);				
					netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netSecurityError);
					
					this.connectedHandler();
					//netConnection.addEventListener(OvpEvent.ERROR, onError);
					if (! _model.autoStart) {
						_view.hideVideo();
					}
					// Notifier function
					_model.connectionCreated(netConnection, hostName);
					netConnection.connect(null);
					_lastConnectionKey = hostName + _connectionAuthParameters;
				}				
			} /* -- Zeri Connection */
			else {	/* Akamai Connection */
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
			} /* -- Akamai Connection */
		} /* -- Connection Handling */
		/* call geoip API */
		private function getGeoIp(src:String):void{
			var playlist = _model.playlistItems;
			var videoId:String = "";
			if(playlist != null){
				for(var j:uint=0; j < playlist.length; j++){
					if(ItemTO(playlist[j]).media.getContentAt(0).url == src){
						videoId = ItemTO(playlist[j]).videoId == "" ? _model.videoId : ItemTO(playlist[j]).videoId.toString();
					}
				}
			}
			else {
				videoId = _model.videoId;
			}
			var request:URLRequest = new URLRequest(_model.geoIpUrl);
			var variables:URLVariables = new URLVariables();
			var urlloader:URLLoader = new URLLoader();
			variables.methodType = "verifyIPAccess";
			variables.vid = videoId;
			variables.handler = _model.geoIpHandler;
			request.data = variables;
			request.method = URLRequestMethod.GET;
			urlloader.load(request);
			urlloader.addEventListener(Event.COMPLETE, callGeoIpAPI);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR, callGeoIpAPIIOError);			
		} /* end of getGeoIp function */
		private function callGeoIpAPI(event:Event):void{
			var loader:URLLoader = URLLoader(event.target);	
			var geoIpInfo:String = loader.data;
			/* JSON Decode */
			trace("geoip status : " + geoIpInfo);
			var j:JSONDecoder = new JSONDecoder(geoIpInfo,true);
			var info:* = j.getValue();
			if(info.allowed != undefined){
				if(Number(info.allowed) > 0){
					_model.isGeoIpAllowed = true;
					this.isHD = false;
					this.isZStream = true;
					connect(_host, _protocol);							
				}
				else{
					_model.isGeoIpAllowed = false;
					_model.showError(_model.ERROR_COUNTRY_NOT_ALLOWED);
				}
			}
			else{
				_model.showError("Unable to connect to GeoIp API");
			}
			
//			var msg:String = "actiontype" + "~jhe~" + "responsegeoip" + "|jhe|" +
//							  "content" + "~jhe~" + _model.src + "|jhe|" +
//							  "userid" + "~jhe~" + _model.userId + "|jhe|" +
//							  "datetime" + "~jhe~" + _model.getDateTime() + "|jhe|" +
//							  "otherinfo" + "~jhe~" + "geoip_info:" + geoIpInfo; 
//			_model.writeToLog(msg)
		} /* end of callGeoIpAPI function */		
		private function callGeoIpAPIIOError(event:IOErrorEvent):void {
			_model.debug("Unable to generate token.");
		} 
	} /* -- class VideoController */
} /* -- package */
