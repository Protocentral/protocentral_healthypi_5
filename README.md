# HealthyPi 5 

![HealthyPi 5](docs/images/healthypi5.jpg)

Don't have one? You can pre-order now at [Crowd Supply](https://www.crowdsupply.com/protocentral/healthypi-5)

HealthyPi 5 is the latest evolution of the HealthyPi series. It is a robust, feature-rich, open-source development board that allows you to explore many different biosignals with minimal effort. Whether you need a simple monitor for a specific vital sign or a complete health-sensor platform, HealthyPi 5 is an extensible solution to to your health-data challenges. Out of the box, it can handle electrocardiogram (ECG), respiration, photoplethysmography (PPG), oxygen saturation (SpO₂), and body temperature data. And it’s easy to upgrade as well! Using the Qwiic connectors on the Pro-Carrier Board, you can leverage external sensor modules to capture and analyze additional biosignals, such as galvanic skin response (GSR), electroencephalogram (EEG), and electromyogram (EMG) data.

## Features

* RP2040 dual-core ARM Cortex M0 microcontroller
* ESP32C3 RISC-V module with BLE and Wi-Fi support
* MAX30001 analog front end for ECG and respiration measurement
* AFE4400 analog front end for PPG
* MAX30205 temperature sensor via onboard Qwiic/I²C connectors
* 40-pin Raspberry Pi HAT connector (also used to connect our Display Add-On Module)
* 1x USB Type-C connector for communication with a computer and programming the RP2040
* 1x USB Type-C connector for programming and debugging the ESP32 module
* Onboard MicroSD card slot
* On-board Li-Ion battery management with charging through USB

## Repository Contents

* /gui - Processing GUI for HealthyPi 5
* /hardware - Eagle design files (.brd, .sch, pdfs)
* /python - Python scripts for HealthyPi 5 (_Work in Progress_)
* If you're looking for the firmware for the HealthyPi 5, it's located in its own repository [here](https://github.com/Protocentral/protocentral_healthypi_5_firmware).

## License Information

This product is open source! Please see the LICENSE.md file for more information.

## Getting Started
_Getting Started Guide coming soon..._

## License Information

![License](license_mark.svg)

This product is open source! Both, our hardware and software are open source and licensed under the following licenses:

Hardware
---------

**All hardware is released under the [CERN-OHL-P v2](https://ohwr.org/cern_ohl_p_v2.txt)** license.

Copyright CERN 2020.

This source describes Open Hardware and is licensed under the CERN-OHL-P v2.

You may redistribute and modify this documentation and make products
using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).
This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2
for applicable conditions

Software
--------

**All software is released under the MIT License(http://opensource.org/licenses/MIT).**

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Documentation
-------------
**All documentation is released under [Creative Commons Share-alike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/).**
![CC-BY-SA-4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

You are free to:

* Share — copy and redistribute the material in any medium or format
* Adapt — remix, transform, and build upon the material for any purpose, even commercially.
The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:

* Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
* ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

Please check [*LICENSE.md*](LICENSE.md) for detailed license descriptions.