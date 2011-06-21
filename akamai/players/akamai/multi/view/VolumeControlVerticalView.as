package view
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	[ Event( name="volumeChange", type="flash.events.Event") ]
	
	public class VolumeControlVerticalView extends Sprite
	{
		[Embed(source='/assets/volumeKnob.png')]
    	private static var volumeKnobPNG:Class;
    	
		private var scrubBack:Sprite;
		private var scrubFront:Sprite;
		private var knob:Button;
		private var dragging:Boolean;
		private var _volume:Number;
		
		public function VolumeControlVerticalView()
		{
			super();
			init();
		}
		public function get volume():Number
		{
			return _volume;
		}
		private function init():void
		{
			this.addEventListener(Event.ADDED_TO_STAGE,onAddedToStage);
			//Draw background
			this.graphics.beginFill(0x12297e);
			this.graphics.drawRect(0,0,30,100);
			scrubBack = new Sprite();
			scrubBack.graphics.beginFill(0x222222);
			scrubBack.graphics.drawRect(0,0,20,95);
			scrubBack.x = 5;
			scrubBack.y = 5;
			addChild(scrubBack);
			scrubFront = new Sprite();
			scrubFront.graphics.beginFill(0x4a5787);
			scrubFront.graphics.drawRect(0,0,20,95);
			scrubFront.x = 5;
			scrubFront.y = 5;
			addChild(scrubFront);
			knob = new Button(20,8,new volumeKnobPNG());
			knob.addEventListener(MouseEvent.MOUSE_DOWN,onKnobDown);
			knob.addEventListener(MouseEvent.MOUSE_UP,onKnobUp);
			knob.x=5;
			knob.y=5;
			addChild(knob);
			this.addEventListener(Event.ENTER_FRAME,updateScrubFront);
		}
		private function updateScrubFront(event:Event):void
		{
			if (dragging)
			{
				_volume = -1*(knob.y - 93)/88;
				dispatchEvent(new Event("volumeChange"));
			}
			scrubFront.y = knob.y + 5;
			scrubFront.height = 100 - scrubFront.y;
		}
		private function onAddedToStage(event:Event):void
		{
			this.stage.addEventListener(MouseEvent.MOUSE_UP,onKnobUp);
		}
		private function onKnobDown(event:MouseEvent):void
		{
			knob.startDrag(true,new Rectangle(5,5,0,88));
			dragging = true;
		}
		private function onKnobUp(event:MouseEvent):void
		{
			knob.stopDrag();
			dragging = false;
		}
		
	}
}