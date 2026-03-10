# arduino-processing-simple-tank-view
Simple tank view for arduino with processing front end

Uses Arduino board as process controller (see regulator() function). 

## Project Description

This project implements a tank level control system with:
- **Arduino**: Acts as the controller, implementing different regulation algorithms (ON-OFF, ON-OFF with hysteresis, PI/PID)
- **Processing**: Provides a graphical user interface to monitor tank levels, flow rates, and control parameters
- **Modbus RTU**: Communication protocol between Arduino and Processing over serial port

The system simulates a tank with:
- Input flow rate (qi)
- Output flow rate (qu) 
- Level setpoint control
- Real-time visualization
- Multiple regulation modes selectable via dropdown

### Tank Simulation Algorithm

The Processing application simulates the physical behavior of a tank using the following mathematical model:

**Volume Update:**
```
V(t) = V(t-1) + (qi * Δt) - (qu * Δt)
```

Where:
- `V(t)` = Current tank volume [m³]
- `qi` = Input flow rate [m³/s] (received from Arduino via Modbus)
- `qu` = Output flow rate [m³/s] (calculated)
- `Δt` = Time step (default: 0.1s)

**Output Flow Calculation:**
```
qu = √h * C
```

Where:
- `h` = Current tank level [m]
- `C` = Output valve coefficient [dimensionless]

**Level Calculation:**
```
h = V / A
```

Where:
- `A` = Tank cross-sectional area [m²]

**Key Features:**
- Input flow is filtered using a signal filter to smooth Arduino output values
- Volume is constrained between 0 and maximum capacity (Area × MaxLevel)
- The square root relationship for output flow simulates a gravity-fed outlet
- Model refresh rate: 10 Hz (100ms update cycle)

## How to Execute

### Arduino Setup

1. Install in Arduino IDE the **ModbusRTUSlave library version 2.0.6**
   - **IMPORTANT**: The library must be exactly version **2.0.6** - other versions will not work correctly
   - You can install it from Library Manager or download from: https://github.com/CMB27/ModbusRTUSlave
2. Load Arduino sketch (`arduino_sketch.ino`) into your board
3. Connect the Arduino board to your PC via USB

### Processing Setup

1. Install the **ControlP5** library in Processing IDE
2. Install the **Signal filter** library in Processing IDE
3. Open `processing_sketch.pde` sketch in Processing IDE
4. Set the appropriate serial COM port in the code (default is COM4, line 18)
5. Execute the Processing project

### Usage

- **Main Tab**: View real-time data (volume, level, flow rates) and select regulation mode
  - PAR_A: Select regulation type (0=off, 1=on-off, 2=on-off with hysteresis, 3=PI/PID)
  - PAR_B, PAR_C, PAR_D: Configure regulation parameters
- **Setup Tab**: Configure tank parameters and communication settings
- **Debug Tab**: Monitor Modbus communication and register values

## Communication Protocol

The system uses Modbus RTU over serial with the following registers:
- **Read Registers** (from Arduino):
  - Register 0: Counter
  - Register 1: Output value
- **Write Registers** (to Arduino):
  - Register 0: Setpoint
  - Register 1: Measured value
  - Register 2: Parameter A (regulation type - integer)
  - Register 3: Parameter B (regulation parameter - scaled by 100)
  - Register 4: Parameter C (regulation parameter - scaled by 100)
  - Register 5: Parameter D (regulation parameter - scaled by 100)

## Tested With

- Arduino IDE 2.3.2
- **ModbusRTUSlave library version 2.0.6** (⚠️ Version 2.0.6 required!)
- Processing IDE 4.3
- ControlP5 library
- Signal filter library


