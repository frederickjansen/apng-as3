package be.alfredo.io
{
	import flash.utils.ByteArray;

	/**
	 * The BitArray class extends the standard ByteArray, adding
	 * methods to deal with data on a bit instead of byte level.
	 *
	 * @author Frederick
	 */
	public class BitArray extends ByteArray
	{
		/**
		 * Holds all the values necessary for bitmasking.
		 *
		 * @private
		 */
		private static const SHIFTS:Vector.<uint> = Vector.<uint>( [
			0x00,
			0x01,		0x03,		0x07,		0x0F,		0x1F,		0x3F,		0x7F, 		0xFF,
			0x01FF,		0x03FF,		0x07FF,		0x0FFF,		0x1FFF,		0x3FFF,		0x7FFF,		0xFFFF,
			0x01FFFF,	0x03FFFF,	0x07FFFF,	0x0FFFFF,	0x1FFFFF,	0x3FFFFF,	0x7FFFFF,	0xFFFFFF,
			0x01FFFFFF,	0x03FFFFFF,	0x07FFFFFF,	0x0FFFFFFF,	0x1FFFFFFF,	0x3FFFFFFF,	0x7FFFFFFF,	0xFFFFFFFF
		]);


		/**
		 * @private
		 */
		private var _bitPosition:uint;


		/**
		 * Holds the position of the next bit to be read. The range
		 * is always from 0 to (and including) 7. Anything larger
		 * gets reduced to that range.
		 *
		 * @param 	value	 The new bitPosition value
		 */
		public function set bitPosition( value:uint ):void
		{
			while( value > 7 )
			{
				value -= 8;
			}
			_bitPosition = value;
		}


		/**
		 * Set the bit position back to zero each time the byte
		 * position changes.
		 *
		 * @param	value	New position of the ByteArray
		 */

		override public function set position(value:uint):void
		{
			super.position = value;
			_bitPosition = 0;
		}


		/**
		 * Class constructor
		 */
		public function BitArray( data:ByteArray = null, offset:uint = 0 )
		{
			super();
			if( data ) data.readBytes( this, offset, data.bytesAvailable - offset );
			bitPosition = 0;
		}

		/**
		 * Read a single bit from a byte.
		 * Bits are always read from left to right. So on byte
		 * 1000 0000, readBit() will return 1 the first time,
		 * while bitPosition goes from 1 to 2.
		 *
		 * @return	val	The value of the bit.
		 */
		public function readBit():Boolean
		{
			var byte:uint = this.readUnsignedByte();
			var val:Boolean = (( ( byte >> ( 7 - _bitPosition ) ) & 0x01 ) == 1);

			// Go back to the start of the byte if we're not reading the last bit
			if( _bitPosition != 7 )
			{
				var tempBitPosition:uint = _bitPosition;
				position--;
				_bitPosition = ++tempBitPosition;
			}
			else
			{
				_bitPosition = 0;
			}
			return val;
		}

		/**
		 * Read an unsigned integer from a specified amount of bits.
		 * The standard readUnsignedInt method only allows you to read
		 * 32 bits at a time. This makes it impossible to read numbers
		 * that are stored in a 24-bit or even 9-bit space, without using
		 * bitshifts and temporary variables. That logic has been moved
		 * into this method.
		 *
		 * @param	length	Amount of bits you want to read.
		 * @return	val		The resulting uint.
		 */

		public function readUnsignedBits( length:uint ):uint
		{
			var val:uint = 0;
			var temp:int = length;

			while (temp + _bitPosition > 0)
			{
				val <<= 8;
				val |= this.readUnsignedByte();
				temp -= 8;
			}

			bitPosition = _bitPosition + length;

			// If bitPosition isn't 0 we've read too many bytes and need to go back one spot
			if (_bitPosition)
			{
				// When we reduce the position, we lose the bitPosition so we keep a temporary copy
				const oldBitPosition:uint = _bitPosition;
				position--;
				_bitPosition = oldBitPosition;

				val = (val >> (8 - _bitPosition)) & SHIFTS[length];
			}
			else
			{
				// If bitPosition is 0, we're right aligned and don't need to shift
				val &= SHIFTS[length];
			}

			return val;
		}

		/**
		 * Read a signed integer from a specified amount of bits.
		 * This method makes use of readUnsignedBits to reads its
		 * value and adjusts it based on the sign.
		 *
		 * @param	length	Amount of bits you want to read.
		 * @return	int		The resulting int.
		 * @see				readUnsignedBits
		 */

		public function readSignedBits( length:uint ):int
		{
			if( !this.readBit() )
			{
				return this.readUnsignedBits( length - 1 );
			}
			else
			{
				return this.readUnsignedBits( length - 1 ) - ( 1 << (length - 1) );
			}

		}

		/**
		 * Read a rice coded value.
		 *
		 * @param	parameter	Size of the least significant bits
		 * @return	int			The decoded rice value
		 */
		public function readSignedRice( parameter:uint ):int
		{
			var msb:uint	= this.readUnary( 1 );
			var lsb:uint	= this.readUnsignedBits( parameter );
			var value:uint	= (msb << parameter) | lsb;

			if( value & 1 ) // signed, value next to lsb instead of msb
			{
				// signed rice values are equal to (value * -1) - 1
				// shifting to get the sign out of the way
				value = -(value >> 1 ) - 1;
			}
			else
			{
				value = value >> 1;
			}

			return value;
		}

		/**
		 * Reads a non-negative unary coded value,
		 * with either 0 or 1 as the stop bit.
		 *
		 * @param	stop	0 or 1 as the stop value
		 * @return	uint	The decoded unary value
		 */
		public function readUnary( stop:uint ):uint
		{
			var value:uint = 0;
			if( stop == 0 )
			{
				while( this.readBit() )
				{
					value++;
				}
			}
			else
			{
				while( !this.readBit() )
				{
					value++;
				}
			}
			return value;
		}

		/**
		 * Decode UTF-8 coded value
		 *
		 * @return	uint	The decoded value
		 */
		public function readUnsignedUTF8():uint
		{
			var value:uint, i:uint;

			i = this.readUnary( 0 );
			value = this.readUnsignedBits( 7 - i );

			for( ; i > 1; i--)
			{
				value <<= 6;
				value |= (this.readUnsignedBits( 8 ) & 0x3F);
			}
			return value;
		}

		/**
		 * Align byte to the right
		 */
		public function byteAlignRight():void
		{
			if( _bitPosition != 0 )
			{
				this.position++;
			}
		}
	}
}