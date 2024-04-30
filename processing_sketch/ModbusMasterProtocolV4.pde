class ModbusPort
{
  Serial serial_port;
 
  final int READ_COIL_STATUS = 1; // Reads the ON/OFF status of discrete outputs (0X references, coils) in the slave.
  final int READ_INPUT_STATUS = 2; // Reads the ON/OFF status of discrete inputs (1X references) in the slave.
  final int READ_HOLDING_REGISTERS = 3; // Reads the binary contents of holding registers (4X references) in the slave.
  final int READ_INPUT_REGISTERS = 4; // Reads the binary contents of input registers (3X references) in the slave. Not writable.
  final int FORCE_MULTIPLE_COILS = 15; // Forces each coil (0X reference) in a sequence of coils to either ON or OFF.
  final int PRESET_MULTIPLE_REGISTERS = 16; // Presets values into a sequence of holding registers (4X references).
  
   // State Machine States
  final int IDLE = 1;
  final int WAITING_FOR_REPLY = 2;
  final int WAITING_FOR_TURNAROUND = 3;
  
  int state;

  // frame[] is used to recieve and transmit packages. 
  // The maximum number of bytes in a modbus packet is 255
  final int BUFFER_SIZE = 255;
  int[] frame = new int[BUFFER_SIZE]; 
  int buffer;
  int timeout;
  int polling;
  int retry_count;
 
  /* It must be noted in order to overcome the inter-character 
     time out and the delays prevalent in the Processing/Java 
     environment when using the serial library (RXTX-lib) the 
     inter-character time out has been increased to 30ms diverging 
     from the modbus standard. To increase the packet rate transfer 
     from the FTDI chip the latency-timer has to be decreased from 
     16ms to 1ms and the usb transfer size has to be decreased from 
     4096 to 256 bytes. This can be done from device manager in port settings. 
     
     So if you are experiencing packet errors then increase the T1_5
     inter-character time out variable.
   */
  int T1_5 = 30; // inter character time out in milliseconds
  int delayStart;
  
  Packet[] packets; 
  int packet_index;
  int total_no_of_packets;
  Packet packet; // global active packet
  
  ModbusPort(Serial serial_port, int timeout, int polling, int retry_count, Packet[] packets, int total_no_of_packets)
  {
    this.serial_port = serial_port;
    this.timeout = timeout;
    this.polling = polling;
    this.retry_count = retry_count;
    this.packets = packets;
    this.total_no_of_packets = total_no_of_packets;
    state = IDLE;
    delayStart = 0;
    packet_index = 0;
  } 
  
  // Modbus Master State Machine
  void update() 
  {
    switch (state)
    {
      case IDLE:
      idle();
      break;
      case WAITING_FOR_REPLY:
      waiting_for_reply();
      break;
      case WAITING_FOR_TURNAROUND:
      waiting_for_turnaround();
      break;
    }
  }
  
  private void idle() 
  {
    // Initialize the connection_status variable to the
    // total_no_of_packets. This value cannot be used as 
    // an index (and normally you won't). Returning this 
    // value to the main sketch informs the user that the 
    // previously scanned packet has no connection error.
	
    int connection_status = total_no_of_packets;	
    int failed_connections = 0;
    boolean current_connection;
	
    do
    {			
      if (packet_index == total_no_of_packets) // wrap around to the beginning
        packet_index = 0;
		
      packet = packets[packet_index]; // get the next packet
		
      // get the current connection status
      current_connection = packet.connection;
		
      if (!current_connection)
      {
	connection_status = packet_index;
			
	// If all the connection attributes are false return
	// immediately to the main sketch
	if (++failed_connections == total_no_of_packets)
	  return;
      }
		
      packet_index++;
			
    }while (!current_connection); // while a packet has no connection get the next one
		
    constructPacket();
  }
  
  private void constructPacket()
  {	 
    packet.requests++;
    frame[0] = packet.id;
    frame[1] = packet.function;
    frame[2] = packet.address >> 8; // address High
    frame[3] = packet.address & 0xFF; // address Low
    // For functions 1 & 2 data is the number of points
    // For functions 3, 4 & 16 data is the number of registers
    // For function 15 data is the number of coils
    frame[4] = packet.data >> 8; // MSB
    frame[5] = packet.data & 0xFF; // LSB

    int frameSize;
  
    // construct the frame according to the modbus function  
    if (packet.function == PRESET_MULTIPLE_REGISTERS) 
      frameSize = construct_F16();   
    else if (packet.function == FORCE_MULTIPLE_COILS)
      frameSize = construct_F15();
    else // else functions 1,2,3 & 4 is assumed. They all share the exact same request format.
      frameSize = 8; // the request is always 8 bytes in size for the above mentioned functions.
      
    int crc16 = calculateCRC(frameSize - 2);	
    frame[frameSize - 2] = crc16 >> 8; // split crc into 2 bytes
    frame[frameSize - 1] = crc16 & 0xFF;
    sendPacket(frameSize);
    
    state = WAITING_FOR_REPLY; // state change
         
    // if broadcast is requested (id == 0) for function 15 or 16 then override 
    // the previous state and force a success since the slave won't respond
    if (packet.id == 0)
      processSuccess();
  }
  
  private int construct_F16()
  {
    int no_of_bytes = packet.data * 2;
    frame[6] = no_of_bytes; // number of bytes
    int index = 7; // user data starts at index 7
    int no_of_registers = packet.data;
    int temp;
    for (int i = 0; i < no_of_registers; i++)
    {
      temp = packet.register_array[i]; // get the data
      frame[index] = temp >> 8;
      index++;
      frame[index] = temp & 0xFF;
      index++;
    }
    int frameSize = 9 + no_of_bytes; // first 7 bytes of the array + 2 bytes CRC + noOfBytes
    return frameSize;
  }
  
  private int construct_F15()
  {
    // function 15 coil information is packed LSB first until the first 16 bits are completed
    // It is received the same way..
    int no_of_registers = packet.data / 16;
    int no_of_bytes = no_of_registers * 2; 
    
    // if the number of points dont fit in even 2byte amounts (one register) then use another register and pad 
    if (packet.data % 16 > 0) 
    {
      no_of_registers++;
      no_of_bytes++;
    }
    
    frame[6] = no_of_bytes;   
    int bytes_processed = 0;
    int index = 7; // user data starts at index 7
    int temp;
    
    for (int i = 0; i < no_of_registers; i++)
    {
      temp = packet.register_array[i]; // get the data
      frame[index] = temp & 0xFF; 
      bytes_processed++;
        
      if (bytes_processed < no_of_bytes)
      {
        frame[index + 1] = temp >> 8;
        bytes_processed++;
        index += 2;
      }
    }
    int frameSize = 9 + no_of_bytes; // first 7 bytes of the array + 2 bytes CRC + noOfBytes 
    return frameSize;
  }
  
  // get the serial data from the buffer
  void waiting_for_reply()
  {
    if (serial_port.available() > 0) // is there something to check?
    {
      boolean overflowFlag = false;
      buffer = 0;
      while (serial_port.available() > 0)
      {
        // The maximum number of bytes is limited to the serial buffer size 
        // of BUFFER_SIZE. If more bytes is received than the BUFFER_SIZE the 
        // overflow flag will be set and the serial buffer will be read until
        // all the data is cleared from the receive buffer, while the slave is 
        // still responding.
        if (overflowFlag) 
          serial_port.read();
        else
        {
          if (buffer == BUFFER_SIZE)
            overflowFlag = true;
      
          frame[buffer] = serial_port.read();
          buffer++;
        }
        // This is not 100% correct but it will suffice.
        // worst case scenario is if more than one character time expires
        // while reading from the buffer then the buffer is most likely empty
        // If there are more bytes after such a delay it is not supposed to
        // be received and thus will force a frame_error.
        delay(T1_5); // inter character time out
      }
      
      // The minimum buffer size from a slave can be an exception response of
      // 5 bytes. If the buffer was partially filled set a frame_error.
      // The maximum number of bytes in a modbus packet is 256 bytes.
   
      if ((buffer < 5) || overflowFlag)
        processError();       
      
      // Modbus over serial line datasheet states that if an unexpected slave 
      // responded the master must do nothing and continue with the time out.
      // This seems silly cause if an incorrect slave responded you would want to
      // have a quick turnaround and poll the right one again. If an unexpected 
      // slave responded it will most likely be a frame error in any event
      else if (frame[0] != packet.id) // check id returned
        processError();
      else
        processReply();
    }
    else if ((millis() - delayStart) > timeout) // check timeout
    {
      processError();
      state = IDLE; //state change, override processError() state
    }
  }
  
  private void processReply()
  {
    // combine the crc Low & High bytes
    int received_crc = ((frame[buffer - 2] << 8) | frame[buffer - 1]); 
    int calculated_crc = calculateCRC(buffer - 2);
  
    if (calculated_crc == received_crc) // verify checksum
    {
      // To indicate an exception response a slave will 'OR' 
      // the requested function with 0x80 
      if ((frame[1] & 0x80) == 0x80) // extract 0x80
      {
        packet.exception_errors++;
        processError();
      }
      else
      {
        switch (frame[1]) // check function returned
        {
          case READ_COIL_STATUS:
          case READ_INPUT_STATUS:
          process_F1_F2();
          break;
          case READ_INPUT_REGISTERS:
          case READ_HOLDING_REGISTERS:
          process_F3_F4(); 
          break;
          case FORCE_MULTIPLE_COILS:
          case PRESET_MULTIPLE_REGISTERS:
          process_F15_F16();
          break;
          default: // illegal function returned
          processError();
          break;
        }
      }
    } 
    else // checksum failed
    {
      processError();
    }
  }
  
  private void process_F1_F2()
  {
    // packet.data for function 1 & 2 is actually the number of boolean points
    int no_of_registers = packet.data / 16;
    int number_of_bytes = no_of_registers * 2; 
         
    // if the number of points dont fit in even 2byte amounts (one register) then use another register and pad 
    if (packet.data % 16 > 0) 
    {
      no_of_registers++;
      number_of_bytes++;
    }
              
    if (frame[2] == number_of_bytes) // check number of bytes returned
    { 
      int bytes_processed = 0;
      int index = 3; // start at the 4th element in the frame and combine the Lo byte  
      int temp;
      for (int i = 0; i < no_of_registers; i++)
      {
        temp = frame[index]; 
        bytes_processed++;
        if (bytes_processed < number_of_bytes)
        {
          temp = (frame[index + 1] << 8) | temp;
          bytes_processed++;
          index += 2;
        }
        packet.register_array[i] = temp;
      }
      processSuccess(); 
    }
    else // incorrect number of bytes returned 
      processError();
  }
  
  private void process_F3_F4()
  {
    // check number of bytes returned - unsigned int == 2 bytes
    // data for function 3 & 4 is the number of registers
    if (frame[2] == (packet.data * 2)) 
    {
      int index = 3;
      for (int i = 0; i < packet.data; i++)
      {
        // start at the 4th element in the frame and combine the Lo byte 
        packet.register_array[i] = (frame[index] << 8) | frame[index + 1]; 
        index += 2;
      }
      processSuccess(); 
    }
    else // incorrect number of bytes returned  
      processError(); 
  }
  
  private void process_F15_F16()
  {
    // Functions 15 & 16 have the exact same response from the slave
    // which is an echo of the query
    int recieved_address = ((frame[2] << 8) | frame[3]);
    int recieved_data = ((frame[4] << 8) | frame[5]);
    if ((recieved_address == packet.address) && (recieved_data == packet.data))
      processSuccess();
    else
      processError();
  }
  
  void waiting_for_turnaround()
  {
    if ((millis() - delayStart) >= polling)
      state = IDLE;
  }

  private void processError()
  {
    packet.retries++;
    packet.failed_requests++;
  
    // if the number of retries have reached the max number of retries 
    // allowable, stop requesting the specific packet
    if (packet.retries == retry_count)
    {
      packet.connection = false;
      packet.retries = 0;
    }
    state = WAITING_FOR_TURNAROUND;
    delayStart = millis(); // start the turnaround delay
  }
  
  private void processSuccess()
  {
    packet.successful_requests++; // transaction sent successfully
    packet.retries = 0; // if a request was successful reset the retry counter
    state = WAITING_FOR_TURNAROUND;
    delayStart = millis(); // start the turnaround delay
  }
  
  private int calculateCRC(int bufferSize) 
  {
    int temp, temp2, flag;
    temp = 0xFFFF;
    for (int i = 0; i < bufferSize; i++)
    {
      temp = temp ^ frame[i];
      for (int j = 1; j <= 8; j++)
      {
        flag = temp & 0x0001;
        temp >>= 1;
        if (flag == 1)
          temp ^= 0xA001;
      }
    }
    // Reverse byte order. 
    temp2 = temp >> 8;
    temp = (temp << 8) | temp2;
    temp &= 0xFFFF;
    return temp; // the returned value is already swopped - crcLo byte is first & crcHi byte is last
  }

  private void sendPacket(int bufferSize)  
  {
    serial_port.clear();
    
    // This is where the magic happens!
    // Initially the delay between characters were too great
    // when int's were being transmitted by indexing the
    // frame array. Java does not have an unsigned char 
    // to work with numbers from 0 - 255 it only has a byte type
    // which expects 127 to -128. This does not actually matter
    // since the number is still 8bits. It's only the protocol
    // that reconstructs the frame on the other side that dictates 
    // if it's signed or not. From modbus perspective it's still 
    // an 8bit byte value that being received and transmitted.
    
    // The write() method in the serial class expects any type
    // but the fastest type that will be transfered to the Serial
    // buffer is bytes or more specifically an array of bytes.
    // By casting the frame array containing our data to a byte
    // array of the exact size that we want to transmit we can
    // overcome the delay between the transmission of characters.
    // We can do this because the data in frame will never exceed
    // the value of an 8 bit byte.
    
    byte[] byteFrame = new byte[bufferSize];
    
    for (int i = 0; i < bufferSize; i++)
      byteFrame[i] = (byte)frame[i];  
 
      serial_port.write(byteFrame);
    delayStart = millis(); // initialize timeout delay	
  }
}

class Packet
{
  // specific packet info
  int id, function, address;
  
  // For functions 1 & 2 data is the number of points
  // For functions 3, 4 & 16 data is the number of registers
  // For function 15 data is the number of coils
  int data; 
  int[] register_array;
  
  // non specific modbus information
  int requests;
  int successful_requests;
  int failed_requests;
  int exception_errors;
  int retries;
  boolean connection; // comms status of the packet
    
  Packet(int id, int function, int address, int data, int[] register_array)
  {
    this.id = id;
    this.function = function;
    this.address = address;
    this.data = data;
    this.register_array = register_array;
    connection = true; // enable packet requesting
  } 
}
