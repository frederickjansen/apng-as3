package be.alfredo.fileformats.apng
{
	import be.alfredo.io.BitArray;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	/**
	 * Decoder for the APNG file format
	 * 
	 * @author Frederick Jansen
	 */
	public class APNGDecoder extends EventDispatcher
	{
		/*************************************************************************************
		 * 
		 * 									PRIVATE
		 * 
		 * ***********************************************************************************/
		
		/**
		 * The incoming APNG to decode.
		 * @private
		 */ 
		private var file:BitArray;
		
		/**
		 * Set to true when the IEND chunk is encountered. This will 
		 * stop the application from trying to read unavailable data.
		 * @private
		 */ 
		private var eof:Boolean = false;
		
		/**
		 * The acTL chunk needs to be present in all animated PNGs. 
		 * Set to true if the PNG is animated.
		 * @private
		 */ 
		private var acTL:Boolean = false;
		
		/**
		 * If no fcTL chunk is found before the IDAT chunk (first frame), 
		 * the first frame isn't a part of the animation. 
		 */ 
		private var fcTLBeforeIDAT:Boolean = false;
		
		/**
		 * Temporary variable to hold one frame of the animation, including 
		 * all extra data.
		 * @private
		 */ 
		private var pngFrame:APNGFrame;
		
		/**
		 * The number of the frame we're expecting to load, starting with 0
		 * It increments before a fcTL chunk is found, so it's set at -1
		 * @private
		 */ 
		private var currentFrame:int = -1;

		/**
		 * The amount of bytes necessary for each pixel
		 * @private
		 */
		private var bytesPerPixel:int;
		
		private var _width:uint;
		private var _height:uint;
		private var _bitDepth:uint;
		private var _colourType:uint;
		private var _compressionMethod:uint;
		private var _filterMethod:uint;
		private var _interlaceMethod:uint;
		
		private var _numFrames:uint;
		private var _numPlays:uint;
		private var _frames:Vector.<APNGFrame>;
		
		/**
		 * No filter method used
		 * @private
		 */ 
		private static const FILTER_METHOD_NONE:uint = 0;
		
		/**
		 * Sub filter method, comparison of the current pixel 
		 * with the one to the left
		 * @private
		 */ 
		private static const FILTER_METHOD_SUB:uint = 1;
		
		/**
		 * Up filter method, comparison of the current pixel 
		 * with the one to the top
		 * @private
		 */ 
		private static const FILTER_METHOD_UP:uint = 2;
		
		/**
		 * Average filter method, comparison of the current pixel 
		 * with the average of the left and top pixel
		 * @private
		 */ 
		private static const FILTER_METHOD_AVERAGE:uint = 3;
		
		/**
		 * Paeth filter method, comparison of the current pixel 
		 * with the left, top and top left pixel
		 * @private
		 */ 
		private static const FILTER_METHOD_PAETH:uint = 4;
		

		/*************************************************************************************
		 * 
		 * 									PUBLIC
		 * 
		 * ***********************************************************************************/
		
		/**
		 * Width of the image
		 */ 
		public function get width():uint
		{
			return _width;
		}
		
		/**
		 * Height of the image
		 */ 
		public function get height():uint
		{
			return _height;
		}
		
		/**
		 * Bits per sample, returns 1, 2, 4, 8 or 16
		 */ 
		public function get bitDepth():uint
		{
			return _bitDepth;
		}
		
		/**
		 * Colour type of the image
		 * 0: Greyscale
		 * 2: Truecolour (RGB)
		 * 3: Indexed-colour
		 * 4: Greyscale with alpha
		 * 6: Truecolour with alpha (RGBA)
		 */ 
		public function get colourType():uint
		{
			return _colourType;
		}
		
		/**
		 * Compression method used, only 0 is defined (deflate/inflate)
		 */ 
		public function get compressionMethod():uint
		{
			return _compressionMethod;
		}
		
		/**
		 * Filter method used, only 0 is defined (adaptive filtering with 
		 * 5 basic filter types)
		 */ 
		public function get filterMethod():uint
		{
			return _filterMethod;
		}
		
		/**
		 * The interlace method of the image
		 */ 
		public function get interlaceMethod():uint
		{
			return _interlaceMethod;
		}

		/**
		 * The amount of frames in an animation, according to the 
		 * acTL chunk.
		 */
		public function get numFrames():uint
		{
			return _numFrames;
		}
		
		/**
		 * The amount of times a PNG should loop, dictated by the 
		 * acTL chunk.
		 */
		public function get numPlays():uint
		{
			return numPlays;
		}
		
		/**
		 * All frames of the animation, including extra data
		 */ 
		public function get frames():Vector.<APNGFrame>
		{
			return _frames;
		}
		
		/**
		 * The animation has been loaded
		 */ 
		public static const ANIMATION_LOADED:String = "animation_loaded";
		
		
		/**
		 * Class constructor, read in the APNG file
		 */
		public function APNGDecoder( data:ByteArray )
		{
			file = new BitArray( data );
		}
		
		/**
		 * Start decoding an APNG file
		 */ 
		public function startDecoding():void
		{
			var header:String = "";
			var headerPart:uint;
			for( var i:uint = 0; i < 8; i++ )
			{
				headerPart = file.readUnsignedByte();
				if( headerPart < 17 )
				{
					header += "0" + headerPart.toString(16);
				}
				else
				{
					header += headerPart.toString(16);
				}
			}
			
			// Mandatory header for all PNG files
			if( header.toUpperCase() == "89504E470D0A1A0A" )
			{
				/*frames = new Vector.<APNGFrame>();
				pngFrame = new APNGFrame( null );
				frames[currentFrame] = pngFrame;*/
				parseChunks();
			}
			else
			{
				throw new Error( "Not a valid PNG file" )
			}
		}
		
		/**
		 * Parse all image chunks 
		 */ 
		private function parseChunks():void
		{
			var chunkLength:uint = file.readUnsignedInt();
			var chunkType:uint = file.readUnsignedInt();
			
			var tempData:ByteArray = new ByteArray();
			file.readBytes( tempData, 0, chunkLength );
			var chunkData:BitArray = new BitArray( tempData );
			tempData = null;
			
			switch( chunkType )
			{
				case 0x49484452:	//IHDR
					parseHeader( chunkData );
					break;
				case 0x6163544C:	//acTL
					acTL = true;
					parseAnimationControlChunk( chunkData );
					break;
				case 0x6663544C:	//fcTL
					currentFrame++;
					fcTLBeforeIDAT = true;
					parseFrameControlChunk( chunkData);
					break;
				case 0x66644154:	//fdAT
					parseImage( chunkData, true );
					break;
				case 0x49444154:	//IDAT
					if( !acTL )
					{
						throw new Error( "Not an animated PNG." );
					}
					else if( !fcTLBeforeIDAT )
					{
						// If no fcTL chunk is found before the first image, don't include it in the animation
						break;
					}
					else
					{
						parseImage( chunkData );
					}
					break;
				case 0x49454E44:	//IEND
					eof = true;
					break;
				default:
					break;
			}
			
			// Parse the next chunk if we haven't reached IEND yet
			if( !eof )
			{
				var crc:uint = file.readUnsignedInt();
				parseChunks();
			}
			else
			{
				dispatchEvent( new Event( ANIMATION_LOADED ) );
			}
			chunkData = null;
		}
		
		/**
		 * Parse the image header
		 * 
		 * @param	data	BitArray of image header
		 */ 
		private function parseHeader( data:BitArray ):void
		{			
			_width = data.readUnsignedInt();
			_height = data.readUnsignedInt();
			_bitDepth = data.readUnsignedByte();
			_colourType = data.readUnsignedByte();
			_compressionMethod = data.readUnsignedByte();
			_filterMethod = data.readUnsignedByte();
			_interlaceMethod = data.readUnsignedByte();
			
			determineBytesPerPixel();
		}
		
		/**
		 * Set the amount of pixels per byte by looking at the 
		 * colour type and bit depth of a channel.
		 */ 
		private function determineBytesPerPixel():void
		{
			if( bitDepth == 8 && colourType == 6 )		// RGBA
			{
				bytesPerPixel = 4;
			}
			else if( bitDepth == 8 && colourType == 2 )	// RGB
			{
				bytesPerPixel = 3;
			}
			else
			{
				throw new Error( "The combination of bit depth " + bitDepth + " and colour type" + colourType + " is not supported." );
			}
		}
		
		/**
		 * Parse the acTL chunk, which contains information about the 
		 * animation.
		 * 
		 * @param	data	 BitArray representing an Animation Control Chunk
		 * @see		<a href="https://wiki.mozilla.org/APNG_Specification#.60acTL.60:_The_Animation_Control_Chunk">Animation Control Chunk</a>
		 */ 
		private function parseAnimationControlChunk( data:BitArray ):void
		{
			_numFrames = data.readUnsignedInt();
			
			// TODO: Implement numPlays into the player
			_numPlays = data.readUnsignedInt();
			
			// We now know how many frames the animation is made out of, so we instantiate a fixed-length vector
			_frames = new Vector.<APNGFrame>( numFrames, true );
		}
		
		/**
		 * Parse the fcTL chunk, which contains information on how 
		 * to render the frame.
		 * 
		 * @param	data	 BitArray representing a Frame Control Chunk
		 * @see		<a href="https://wiki.mozilla.org/APNG_Specification#.60fcTL.60:_The_Frame_Control_Chunk">Frame Control Chunk</a>
		 */ 
		private function parseFrameControlChunk( data:BitArray ):void
		{			
			var sequenceNumber:uint	=	data.readUnsignedInt();
			var width:uint			=	data.readUnsignedInt();
			var height:uint			=	data.readUnsignedInt();
			var xOffset:uint		=	data.readUnsignedInt();
			var yOffset:uint		=	data.readUnsignedInt();
			var delayNum:uint		=	data.readUnsignedShort();
			var delayDen:uint		=	data.readUnsignedShort();
			var disposeOp:uint		=	data.readUnsignedByte();
			var blendOp:uint		=	data.readUnsignedByte();
			
			var totalDelay:uint;
			if( delayDen == 0 )
			{	
				// The denominator is in hundreds of a second
				totalDelay = delayNum * 10;
			}
			else
			{
				// Denominator represents the fraction of a second
				// Since Flash uses milliseconds for timers, we use 1000 as the regular number
				// Smaller fractions make the delay larger, so we take the inverse of the the denominator
				totalDelay = (1 / (delayDen / 1000)) * delayNum;
			}
			
			var frameControlChunk:FrameControlChunk = new FrameControlChunk( sequenceNumber, width, height, xOffset, yOffset, delayNum, delayDen, disposeOp, blendOp );
			pngFrame = new APNGFrame( frameControlChunk, totalDelay );
			_frames[currentFrame] = pngFrame;
		}
		
		/**
		 * Uncompress the image data and read it to reconstruct the image
		 * 
		 * @param	data	BitArray of the image data
		 * @param	fdAT	Boolean indicating whether we're dealing with an fdAT 
		 * 					or IDAT chunk
		 */ 
		private function parseImage( data:BitArray, fdAT:Boolean = false ):void
		{
			// Currently not used, but is supposed to be ascending order according to spec
			// If not, first frame should be shown
			var sequence:uint;
			
			// fdAT chunks have a sequence number prepended to the data stream
			// which isn't present in IDAT chunks
			if( fdAT )
			{
				// remove the sequence number before trying to uncompress the data stream
				sequence = data.readUnsignedInt();
				var compressedData:ByteArray = new ByteArray();
				data.readBytes( compressedData );
				compressedData.uncompress();
				data = null;
				data = new BitArray( compressedData );
				compressedData = null;
			}
			else
			{
				sequence = NaN;
				data.uncompress();
			}
			
			// TODO: Support for different Colour Types
			switch( _colourType )
			{
				case 2:							// RGB
					createTrueColorImage( data );
				case 6:							// RGBA
					createTrueColorImage( data );
					break;
				default:
					throw new Error( "Colour Type not supported" );
					break;
			}
		}
		
		/**
		 * This is where the actual image is calculated.
		 * A PNG encoder will try to optimise the image data by 
		 * correlating pixel values, which benefits the subsequent 
		 * LZW encoding pass. The correlation is done on a byte 
		 * level, not per pixel. So the red channel (first byte) 
		 * of pixel one is used to calculate the red channel of 
		 * the next pixel.
		 * In the first loop we restore all bytes to 
		 * their original value. A second loop will modify the 
		 * pixels from RGB(A) to (A)RGB and set them individually on 
		 * a BitmapData object.
		 * Previously processed bytes are temporarily kept for the 
		 * decorrelation process, even if they're not needed in a 
		 * filter immediately.
		 * 
		 * @param	data	The encoded image data
		 */ 
		private function createTrueColorImage( data:BitArray ):void
		{
			var image:BitmapData = new BitmapData( _width, _height, true, 0x00000000 );	
			// Width of the frame, not of the total image
			var fWidth:uint = _frames[currentFrame].frameControlChunk.width;
			var fHeight:uint = _frames[currentFrame].frameControlChunk.height;
			var x:uint = 0;
			var y:uint = 0;
			var filterType:uint;
			var c:uint;
			var byteWidth:uint = fWidth * bytesPerPixel;
			var currentColour:uint;
			var currentColourRow:Vector.<uint> = new Vector.<uint>( byteWidth, true );
			var previousColourRow:Vector.<uint> = new Vector.<uint>( byteWidth, true );
			var pixels:BitArray = new BitArray();
			var colour:uint;
			
			image.lock();
			
			for( y = 0; y < fHeight; y++ )
			{
				filterType = data.readByte();
				if( filterType == FILTER_METHOD_NONE )
				{
					for( x = 0; x < byteWidth; x++ )
					{
						c = data.readUnsignedByte();
						// This equals modulo 256
						// Since the difference between two pixels can be negative but all 
						// data still needs to be stored in one unsigned byte, the result 
						// is always added to one larger bit (256 in this case), then the 
						// modulo of the same value is taken. This eliminates all negative 
						// values, while keeping the result correct.
						c = c & 0xFF;
						pixels.writeByte( c );
						currentColourRow[x] = c;
					}
				}
				else if( filterType == FILTER_METHOD_SUB )
				{
					for ( x = 0; x < byteWidth; x++ )
					{
						c = data.readUnsignedByte();
						
						// No left pixel
						if( x < bytesPerPixel )
						{
							currentColour = c;
						}
						else
						{
							currentColour = c + currentColourRow[x - bytesPerPixel];
						}
						currentColour = currentColour & 0xFF;
						pixels.writeByte( currentColour );
						currentColourRow[x] = currentColour;
					}
				}
				else if( filterType == FILTER_METHOD_UP )
				{
					for ( x = 0; x < byteWidth; x++ )
					{
						c = data.readUnsignedByte();
						
						// top row, so let's ignore the non-existant upper pixels
						if( y == 0 )
						{
							currentColour = c;
						}
						else
						{
							currentColour = c + previousColourRow[x];
						}
						currentColour = currentColour & 0xFF;
						pixels.writeByte( currentColour );
						currentColourRow[x] = currentColour;
					}
				}
				else if( filterType == FILTER_METHOD_AVERAGE )
				{
					for( x = 0; x < byteWidth; x++ )
					{
						c = data.readUnsignedByte();
						
						// No top or left pixels
						if( x < bytesPerPixel && y == 0 )
						{
							currentColour = c;
						}
						// Not the top row, so we can average between the previous row and 0
						else if( x < bytesPerPixel && y != 0 )
						{
							currentColour = c + uint((previousColourRow[x] / 2));
						}
						// Top row, but with left pixels
						else if( y == 0 )
						{
							currentColour = c + uint( (currentColourRow[x - bytesPerPixel] / 2) );
						}
						// Left and top pixels available
						else
						{
							currentColour = c + uint( ((currentColourRow[x - bytesPerPixel] + previousColourRow[x]) / 2) );
						}
						currentColour = currentColour & 0xFF;
						pixels.writeByte( currentColour );
						currentColourRow[x] = currentColour;
					}
				}
				else if( filterType == FILTER_METHOD_PAETH )
				{					
					for( x = 0; x < byteWidth; x++ )
					{
						c = data.readUnsignedByte();
						
						// No top, left or top left pixel
						if( x < bytesPerPixel && y == 0 )
						{
							currentColour = c;
						}
						// Only top row, no left or upper left
						else if( x < bytesPerPixel && y != 0 )
						{
							currentColour = c + paethPredictor( 0, previousColourRow[x], 0 );
						}
						// Left pixels available
						else if( y == 0 )
						{
							currentColour = c + paethPredictor( currentColourRow[x - bytesPerPixel], 0, 0 );
						}
						// All pixels are available
						else
						{
							currentColour = c + paethPredictor( currentColourRow[x - bytesPerPixel], previousColourRow[x], previousColourRow[x - bytesPerPixel] );
						}
						currentColour = currentColour & 0xFF;
						pixels.writeByte( currentColour );
						currentColourRow[x] = currentColour;
					}
				}
				// Copy array without reference
				previousColourRow = currentColourRow.concat();
				x = 0;
			}
			
			pixels.position = 0;
			
			var xOffset:uint = _frames[currentFrame].frameControlChunk.xOffset;
			var yOffset:uint = _frames[currentFrame].frameControlChunk.yOffset;
			
			if( colourType == 6 ) // RGBA
			{
				for( y = 0; y < fHeight; y++ )
				{
					for( x = 0; x < fWidth; x++ )
					{
						colour = pixels.readUnsignedInt();
						// PNG colours are stored RGBA, Flash expects ARGB
						colour = (colour >>> 8) | ((colour & 0xFF) << 24);
						image.setPixel32( x + xOffset, y + yOffset, colour );
					}
				}
			}
			else if( colourType == 2 ) // RGB
			{
				for( y = 0; y < fHeight; y++ )
				{
					for( x = 0; x < fWidth; x++ )
					{
						colour = pixels.readUnsignedBits( 24 );
						image.setPixel( x + xOffset, y + yOffset, colour );
					}
				}
			}
			
			image.unlock();
			if( _frames[currentFrame].frameControlChunk.blendOp == 0 )
			{
				/*var tempImage:BitmapData = new BitmapData( fWidth, fHeight );
				tempImage.draw( _frames[currentFrame - 1].images[0], null, null, BlendMode.ADD );
				tempImage.draw( image, null, null, BlendMode.ADD );*/
				image.draw( _frames[currentFrame - 1].images[0], null, null, BlendMode.ADD );				
			}
			_frames[currentFrame].images.push( image );
			
			image = null;
			pixels.clear();
			pixels = null;
			previousColourRow = null;
			currentColourRow = null;
		}
		
		/**
		 * Calculate the Paeth predictor for a given colour of a pixel.
		 * 
		 * @param	left		The matching colour of the pixel left of the current one
		 * @param	above		The matching colour of the pixel above the current one
		 * @param	upperLeft	The matching colour of the pixel to the left and top of the current one
		 * @return	uint		The Paeth Predictor
		 */ 
		private function paethPredictor( left:uint, above:uint, upperLeft:uint ):uint
		{
			var p:int;
			var pLeft:int;
			var pAbove:int;
			var pUpperLeft:int;
			
			p = left + above - upperLeft;
			pLeft = (p - left) > 0 ? (p - left) : (left - p);
			pAbove = (p - above) > 0 ? (p - above) : (above - p);
			pUpperLeft = (p - upperLeft) > 0 ? (p - upperLeft) : (upperLeft - p);
			
			if( pLeft <= pAbove && pLeft <= pUpperLeft )
			{
				return left;
			}
			else if( pAbove <= pUpperLeft )
			{
				return above;
			}
			else
			{
				return upperLeft;
			}
		}
	}
}