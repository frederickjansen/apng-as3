package
{
	import be.alfredo.fileformats.apng.APNGPlayer;
	
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	
	public class Main extends Sprite
	{

		private var apngPlayer:APNGPlayer;
		//private var slider:Slider;
		//private var toggleButton:PushButton;
		
		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			apngPlayer = new APNGPlayer();
			apngPlayer.addEventListener( APNGPlayer.APNG_LOADED, onApngLoaded );
//			apngPlayer.load( new URLRequest( "../libs/APNG-Icos4D.png" ) );
			apngPlayer.load( new URLRequest( "../libs/bouncing_beach_ball.png" ) );
//			apngPlayer.load( new URLRequest( "../libs/image_paeth.png" ) );
//			apngPlayer.load( new URLRequest( "../libs/apng.png" ) );
			
			apngPlayer.x = 10;
			addChild(apngPlayer);
		}
		
		protected function onApngLoaded(event:Event):void
		{
			/*slider = new Slider();
			slider.minimum = 0;
			slider.maximum = apngPlayer.numFrames - 1;
			slider.addEventListener( Event.CHANGE, onSliderChange );
			slider.x = 10;
			slider.y = 150;
			addChild(slider);
			
			toggleButton = new PushButton( null, 10, 170, "Pause", clickHandler );
			toggleButton.toggle = true;
			toggleButton.selected = true;
			addChild( toggleButton );*/
			
			apngPlayer.play();
		}
		
		/*private function clickHandler( event:MouseEvent ):void
		{
			if( toggleButton.selected )
			{
				toggleButton.label = "Pause";
				apngPlayer.play();
			}
			else
			{
				toggleButton.label = "Play";
				apngPlayer.stop();
			}
		}
		
		protected function onSliderChange(event:Event):void
		{
			apngPlayer.gotoAndStop( uint( slider.value ) );
			toggleButton.label = "Play";
			toggleButton.selected = false;
		}*/
		
	}
}