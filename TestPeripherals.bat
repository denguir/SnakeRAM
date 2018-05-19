:: first argument: absolute path to the directory that contains avrdude (optional)

@echo off
echo ---------------------------------------------------------------------------------------
echo ---------------------------------------------------------------------------------------
echo Sensors and Microsystem Electronics
echo Practical assignment: micro-controller design
echo ---------------------------------------------------------------------------------------
echo ---------------------------------------------------------------------------------------
echo.
echo This script uploads a program for testing the peripherals on the microcontroller board.
echo Make sure the microcontroller board is connected to this computer!!!
echo ---------------------------------------------------------------------------------------
echo.

:: Get the COM port number.
for /f "usebackq" %%B in (`wmic path Win32_SerialPort Where "Caption LIKE '%%Genuino%%'" Get DeviceID ^| FINDSTR "COM"`) do set comport=%%B
if [%comport%] == [] (
	for /f "usebackq" %%B in (`wmic path Win32_SerialPort Where "Caption LIKE '%%Serial%%'" Get DeviceID ^| FINDSTR "COM"`) do set comport=%%B
)
echo.
echo The COM port number of the microcontroller board is %comport%.

:: Set the first argument (typically the solution directory) as working directory.
set SolDir=%1
if "%~1"=="" (
	echo stay in the current working directory
) else (
	%SolDir:~1,2%
	cd %1
	echo Working directory: %SolDir%
)

:: Copy the content of TestPeripherals.hex to the Genuino Uno's program memory.
avrdude\avrdude -C "avrdude\avrdude.conf" -p atmega328p -c arduino -P %comport% -b 115200 -U flash:w:"TestPeripherals.hex":i

pause

:: Troubleshooting
:: 1) Open the device manager and verify that the Genuino Uno is recognized under the same name. If this is not the case, you can modify its name on rule 17.
:: 2) An alternative for FINDSTR COM is FIND "COM", but this command might be deprecated.