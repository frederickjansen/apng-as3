package be.alfredo.fileformats.apng
{
	/**
	 * 
	 * 
	 * @author Frederick Jansen
	 */ 
	internal class FrameControlChunk
	{		
		private var _sequenceNumber:uint;

		/**
		 * Sequence number of the animation chunk, starting from 0
		 */
		public function get sequenceNumber():uint
		{
			return _sequenceNumber;
		}

		
		private var _width:uint;

		/**
		 * Width of the following frame
		 */
		public function get width():uint
		{
			return _width;
		}

		
		private var _height:uint;

		/**
		 * Height of the following frame
		 */
		public function get height():uint
		{
			return _height;
		}

		
		private var _xOffset:uint;

		/**
		 * X position at which to render the following frame
		 */
		public function get xOffset():uint
		{
			return _xOffset;
		}

		
		private var _yOffset:uint;

		/**
		 * Y position at which to render the following frame
		 */
		public function get yOffset():uint
		{
			return _yOffset;
		}

		
		private var _delayNum:uint;

		/**
		 * Frame delay fraction numerator
		 */
		public function get delayNum():uint
		{
			return _delayNum;
		}

		
		private var _delayDen:uint;

		/**
		 * Frame delay fraction denominator
		 */
		public function get delayDen():uint
		{
			return _delayDen;
		}

		
		private var _disposeOp:uint;

		/**
		 * Type of frame area disposal to be done after rendering this frame
		 * Possible values:
		 * 		0           APNG_DISPOSE_OP_NONE
		 * 		1           APNG_DISPOSE_OP_BACKGROUND
		 * 		2           APNG_DISPOSE_OP_PREVIOUS
		 */
		public function get disposeOp():uint
		{
			return _disposeOp;
		}

		
		private var _blendOp:uint;

		/**
		 * Type of frame area rendering for this frame
		 * Possible values:
		 * 		0       APNG_BLEND_OP_SOURCE
		 * 		1       APNG_BLEND_OP_OVER
		 */
		public function get blendOp():uint
		{
			return _blendOp;
		}

		/**
		 * Class constructor
		 */ 
		public function FrameControlChunk( sequenceNumber:uint, width:uint, height:uint, xOffset:uint, yOffset:uint, delayNum:uint, delayDen:uint, disposeOp:uint, blendOp:uint )
		{
			this._sequenceNumber = sequenceNumber;
			this._width = width;
			this._height = height;
			this._xOffset = xOffset;
			this._yOffset = yOffset;
			this._delayNum = delayNum;
			this._delayDen = delayDen;
			this._disposeOp = disposeOp;
			this._blendOp = blendOp;
		}
	}
}