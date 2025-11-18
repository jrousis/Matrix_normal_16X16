// Visual Micro is in vMicro>General>Tutorial Mode
// 
/*
    Name:       Normal_16X16.ino

    Main normar 16X16 normal boards protject

    Created:	9/3/2023 9:18:50 μμ
    Author:     ROUSIS_FACTORY\user
*/
// Visual Micro is in vMicro>General>Tutorial Mode
// 
#define PIXELS_X 96
#define PIXELS_Y 16
#define PIXELS_ACROSS 96      //pixels across x axis (base 2 size expected)
#define PIXELS_DOWN	16      //pixels down y axis

#include <Arduino.h>
#include <RousisMatrix16.h>
#include <fonts/Big_font.h>
#include <fonts/SystemFont5x7_greek.h>
#include "BluetoothSerial.h"
#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled! Please run `make menuconfig` to and enable it
#endif
BluetoothSerial SerialBT;

const char Company[] = { "Rousis" };
const char Device[] = { "Matrix16" };
const char Version[] = { "V.1.1" };
const char Init_start[] = { "ROUSIS SYSTEMS" };
static char  receive_packet[256] = { 0 };
//uint8_t incoming_bytes = 0;
uint16_t  _cnt_byte = 0;
uint16_t packet_cnt = 0;
uint8_t Address = 1;
byte Select_font = '0';
bool messages_enable = false;
bool test_enable = false;
uint8_t flash_l1 = 0;
uint8_t flash_l2 = 0;
uint8_t double_line = 0;
char page[128] = { 0 };
char page_b[256] = { 0 };
bool flash_on = false;
uint8_t flash_cnt = 0;
uint16_t center_1l = 0;
uint16_t center_2l = 0;
uint8_t char_count_1L = 0; uint8_t char_count_2L = 0;

//RousisMatrix16 myLED(PIXELS_X, PIXELS_Y, 12, 14, 27, 26, 25, 33); 
RousisMatrix16 myLED(PIXELS_X, PIXELS_Y, 12, 14, 27, 32, 25, 33);    // Uncomment if not using OE pin

#define LED_PIN 22
#define BUZZER 15
#define RS485_PIN_DIR 4
#define RXD2 16
#define TXD2 17

HardwareSerial rs485(1);
#define RS485_WRITE     1
#define RS485_READ      0

hw_timer_t* timer = NULL;
hw_timer_t* flash_timer = NULL;
portMUX_TYPE timerMux = portMUX_INITIALIZER_UNLOCKED;
portMUX_TYPE falshMux = portMUX_INITIALIZER_UNLOCKED;
// Code with critica section
void IRAM_ATTR onTime() {
    portENTER_CRITICAL_ISR(&timerMux);
    myLED.scanDisplay();
    //digitalWrite (LED_PIN, !digitalRead(LED_PIN)) ;
    portEXIT_CRITICAL_ISR(&timerMux);
}

void IRAM_ATTR FlashInt()
{
    portENTER_CRITICAL_ISR(&falshMux);

    if (flash_on)
    {
        if (double_line)
        {
            myLED.drawString(center_1l, 0, page, char_count_1L, 2);
        }
        else {
            if (flash_l1) { myLED.drawString(center_1l, 0, page, char_count_1L, 1); }
            if (flash_l2) { myLED.drawString(center_2l, 9, page_b, char_count_2L, 1); }
        }
        flash_on = false;
    }
    else {
        if (double_line)
        {
            if (flash_l1) { myLED.clearDisplay(); }
        }
        else {
            if (flash_l1) { myLED.drawFilledBox(0, 0, PIXELS_X, 8, GRAPHICS_OFF); }
            if (flash_l2) { myLED.drawFilledBox(0, 9, PIXELS_X, 16, GRAPHICS_OFF); }
        }
        flash_on = true;
    }

    portEXIT_CRITICAL_ISR(&falshMux);
}

TaskHandle_t Task0;

void setup()
{
    // Serial.begin(115200);
    SerialBT.begin("Rousis Display"); //Bluetooth device name
    //Serial.println("The device started, now you can pair it with bluetooth!");

    myLED.displayEnable();     // This command has no effect if you aren't using OE pin
    myLED.selectFont(Big_font); //font1

    uint8_t cpuClock = ESP.getCpuFreqMHz();
    //myLED.displayBrightness(0);
    // 
    myLED.displayBrightness(100);
    //myLED.normalMode();    
    // Configure the Prescaler at 80 the quarter of the ESP32 is cadence at 80Mhz
    // 80000000 / 80 = 1000 tics / seconde
    timer = timerBegin(0, 20, true);
    timerAttachInterrupt(timer, &onTime, true);
    Serial.println("Initialize LED matrix display");
    // Sets an alarm to sound every second
    timerAlarmWrite(timer, 10000, true);
    timerAlarmEnable(timer);

    flash_timer = timerBegin(1, cpuClock, true);
    timerAttachInterrupt(flash_timer, &FlashInt, true);
    timerAlarmWrite(flash_timer, 100000, true);
    timerAlarmEnable(flash_timer);

    delay(200);

    rs485.begin(9600, SERIAL_8N1, RXD2, TXD2);
    pinMode(RS485_PIN_DIR, OUTPUT);
    digitalWrite(RS485_PIN_DIR, RS485_READ);
    Serial.println("Display Initial Message");

    myLED.clearDisplay();
    myLED.drawString(0, 0, "ROUSIS LTD", 10, 2);
    delay(3000);

    myLED.clearDisplay();
    myLED.drawString(0, 0, Init_start, sizeof(Init_start), 2);
    delay(100);

    //create a task that will be executed in the Task1code() function, with priority 1 and executed on core 0
    xTaskCreatePinnedToCore(
        Task0code,   /* Task function. */
        "Task0",     /* name of task. */
        10000,       /* Stack size of task */
        NULL,        /* parameter of the task */
        0,           /* priority of the task */
        &Task0,      /* Task handle to keep track of created task */
        0);          /* pin task to core 0 */
    delay(500);
}

void Task0code(void* pvParameters) {
    uint8_t cnt_bytes;
    uint8_t i = 0;
    //cnt_bytes = incoming_bytes;
    char b = 0;
    uint8_t bright = 0;
    uint16_t cnt_page_byte = 0;
    uint8_t line_2 = 0;
    uint8_t delay_page = 1;
    uint8_t bold = 0;
    uint8_t space_px = 1;

    myLED.clearDisplay();
    myLED.selectFont(SystemFont5x7_greek); //Big_font
    //myLED.selectFont(Big_font); //
    myLED.drawString(0, 9, "Empty...", 8, 1);

    for (;;) {  //create an infinate loop  
        // while (messages_enable == false){}
        if (!test_enable) { messages_enable = true; }

        //for ( i = 0; i < sizeof(page); i++){page[i] = 0;}
        // 
       // while (messages_enable == false){}

        cnt_page_byte = 0;
        while (messages_enable && cnt_page_byte < packet_cnt && packet_cnt)
        {
            b = receive_packet[cnt_page_byte++];
            if (b != 0x55) { messages_enable = false; }
            b = receive_packet[cnt_page_byte++];
            if (b != 0xAA) { messages_enable = false; }
            b = receive_packet[cnt_page_byte++];
            if (b != 0x00 && b != Address) { messages_enable = false; } // check Adddress
            b = receive_packet[cnt_page_byte++];
            if (b != 0xA1) { messages_enable = false; }
            b = receive_packet[cnt_page_byte++];
            if (b != 0x02) { messages_enable = false; }

            bool page_en = true;
            while (messages_enable && page_en && cnt_page_byte < packet_cnt)
            {
                b = receive_packet[cnt_page_byte++];
                if (b == 0xE0)
                {
                    bright = receive_packet[cnt_page_byte++];
                }

                if (b == 4) {
                    page_en = false;
                    messages_enable = false;
                    break;
                }

                if (b == 1)
                {
                    delay_page = 1; Select_font = 0; double_line = 0; bold = 0; flash_l1 = 0; flash_l2 = 0; line_2 = 0;
                    //Starting the page reading
                    for (i = 0; i < sizeof(page); i++) { page[i] = 0; }
                    for (uint16_t a = 0; a < sizeof(page_b); a++) { page_b[a] = 0; }

                    delay_page = receive_packet[cnt_page_byte++] & 0x0f;
                    uint8_t function_byte = receive_packet[cnt_page_byte++];
                    if (function_byte & 0b00100000) { double_line = 1; }
                    if (function_byte & 0b01000000) { if (line_2) { flash_l2 = 1; } else { flash_l1 = 1; } }
                    char_count_1L = 0; char_count_2L = 0;

                    //i = 0;
                    b = 0xff;
                    while (messages_enable && cnt_page_byte < packet_cnt && b != 0)
                    {
                        b = receive_packet[cnt_page_byte++];
                        switch (b)
                        {
                        case 0xd6:
                            Select_font = receive_packet[cnt_page_byte++];
                            break;
                        case 0x05:
                            line_2 = 1;
                            function_byte = receive_packet[cnt_page_byte++];
                            if (function_byte & 0b01000000) { if (line_2) { flash_l2 = 1; } else { flash_l1 = 1; } }
                            //cnt_page_byte++; //??? function 2
                            break;
                        default:
                            if (line_2 && b)
                            {
                                page_b[char_count_2L++] = b;
                                //char_count_2L++;
                                //if (char_count_2L >= 128) { break; }
                            }
                            else if (b)
                            {
                                page[char_count_1L++] = b;
                                //char_count_1L++;
                                //if (char_count_1L >= 128) { break; }
                            }
                            break;
                        }
                    }

                    if (double_line) {
                        myLED.selectFont(Big_font);
                        space_px = 2;
                    }
                    else
                    {
                        myLED.selectFont(SystemFont5x7_greek);
                        space_px = 1;
                    }

                    if (bright) { myLED.displayBrightness((255 / 16) * bright); }
                    uint16_t Legth_page = 0;
                    uint16_t Legth_page_b = 0;
                    for (size_t a = 0; a < char_count_1L; a++)
                    {
                        Legth_page += myLED.charWidth(page[a]) + space_px;
                    }
                    //int Legth_page = find_center_1l(page);
                    center_1l = (PIXELS_X - (Legth_page - 1)) / 2;
                    if (line_2)
                    {
                        for (size_t a = 0; a < char_count_2L; a++)
                        {
                            Legth_page_b += myLED.charWidth(page_b[a]) + space_px;
                        }
                        center_2l = (PIXELS_X - (Legth_page_b - 1)) / 2;
                    }
                    //if (ι)
                    if (char_count_1L || char_count_2L)
                    {
                        myLED.clearDisplay();
                        delay_page++;

                        if (double_line)
                        {
                            if (Legth_page > PIXELS_X)
                            {
                                flash_l1 = 0;
                                myLED.scrollingString(0, 0, page, char_count_1L, 2);
                            }
                            else {
                                myLED.drawString(center_1l, 0, page, char_count_1L, 2);
                                delay((delay_page) * 1000);
                            }
                        }
                        else
                        {
                            if (Legth_page_b > PIXELS_X)
                            {
                                flash_l2 = 0;
                                myLED.drawString(center_1l, 0, page, char_count_1L, 1);
                                myLED.scrollingString(0, 9, page_b, char_count_2L, 1);
                            }
                            else
                            {
                                myLED.drawString(center_1l, 0, page, char_count_1L, 1);
                                myLED.drawString(center_2l, 9, page_b, char_count_2L, 1);
                                delay((delay_page) * 1000);
                            }
                        }

                    }

                    Serial.println("Display page : ");
                    Serial.print("Line 1: ");
                    Serial.print(page);
                    Serial.print(" - Chars: ");
                    Serial.println(char_count_1L);
                    Serial.print("Line 2: ");
                    Serial.print(page_b);
                    Serial.print(" - Chars: ");
                    Serial.println(char_count_2L);
                    Serial.print("Brightness: ");
                    Serial.println(bright);
                    Serial.print("Page Delay : ");
                    Serial.println(delay_page);
                    Serial.print("Double line : ");
                    Serial.println(double_line);
                    Serial.print("Flash : ");
                    Serial.print(flash_l1); Serial.println(flash_l2);
                    Serial.println("........................................");

                }
            }


            //i--;



            /*for (i = 0; i < sizeof(page); i++)
            {
                page[i++] = 0;
                page_b[i++] = 0;
            } */
            //i = 0;
            //char_count_1L = 0; char_count_2L = 0;

        }
        vTaskDelay(10);
        //messages_enable = true;
    }
}

// Add the main program code into the continuous loop() function
void loop()
{
    /*Serial.printf("Hello world\r\n");
    digitalWrite(RS485_PIN_DIR, RS485_WRITE);
    rs485.printf("Hello world\r\n");*/

    //delay(20);
   // digitalWrite(RS485_PIN_DIR, RS485_READ);
    /*if (SerialBT.available()) {
        Serial.write(SerialBT.read());
    }*/
    uint8_t header_cnt[4] = { 0,0,0,0 };
    bool loop_stop = false;
    unsigned long startedWaiting = millis();
    uint16_t receiving_count = 0;

    if (rs485.available())
    {
        uint8_t unstruction = 0;
        byte get_byte;
        do {
            get_byte = rs485.read();
            if (get_byte == 0xCA)
            {

                _cnt_byte = 0; packet_cnt = 0;
                loop_stop = true;
                while (millis() - startedWaiting <= 300 && loop_stop) {
                    if (rs485.available())
                    {
                        header_cnt[_cnt_byte++] = rs485.read();
                        if (_cnt_byte >= 4)
                        {
                            unstruction = 1;
                            _cnt_byte = header_cnt[2] << 8;
                            _cnt_byte |= header_cnt[3];
                            packet_cnt = _cnt_byte;
                            delay(10);
                            /*for (size_t i = 0; i < sizeof(receive_packet); i++)
                            {
                                receive_packet[i] = 0xff;
                            }*/
                            //break;
                            get_byte = 0;
                            loop_stop = false;
                        }
                        startedWaiting = millis();
                    }

                }
            }

            if (get_byte == 0x01 && unstruction == 0x01) // receive the main packet 
            {
                _cnt_byte--; // incoming_bytes--;
                while (millis() - startedWaiting <= 300)
                {
                    if (rs485.available())
                    {
                        receive_packet[receiving_count++] = rs485.read();
                        _cnt_byte--;
                        if (_cnt_byte == 0)
                        {
                            packet_cnt--;
                            for (size_t i = (packet_cnt); i < (sizeof(receive_packet) - 1); i++) //
                            {
                                receive_packet[i] = 0xff;
                            }
                            unstruction = 0xA1;


                            Serial.println("Receved_packet:");
                            uint8_t line_br = 0;
                            for (size_t i = 0; i < sizeof(receive_packet); i++) //
                            {
                                Serial.print(receive_packet[i], HEX);

                                line_br++;
                                if (line_br > 31) {
                                    line_br = 0;
                                    Serial.println();
                                }
                                else {
                                    Serial.print(" ");
                                }

                            }
                            Serial.println();
                            Serial.println("_________________________________");
                            // analyse_receive_pages(incoming_bytes);

                            delay(10);
                            Replay_OK();
                            //messages_enable = true;
                            messages_enable = false;
                            break;
                        }
                        startedWaiting = millis();
                    }
                }
            }
            else if (get_byte == 0x01)
            {
                //Serial.println("Start receiving packet...");

                _cnt_byte = 2;
                while (millis() - startedWaiting <= 300) {
                    if (rs485.available())
                    {
                        get_byte = rs485.read();
                        if (_cnt_byte == 2 && get_byte == 0x55)
                        {
                            _cnt_byte = 3;
                        }
                        else if (_cnt_byte == 3 && get_byte == 0xAA)
                        {
                            _cnt_byte = 4;
                        }
                        else if (_cnt_byte == 4 && (Address == get_byte || get_byte == 0))
                        {
                            _cnt_byte = 5;
                        }
                        else if (_cnt_byte == 5)
                        {
                            unstruction = get_byte;
                            _cnt_byte = 0;
                            startedWaiting = millis();
                            break;
                        }
                        startedWaiting = millis();
                    }
                }

                if (unstruction == 0xA3) { // instruction receive loop
                    delay(10);
                    //Serial.println("Instruction to check online...");
                    char Sent_Pckt[] = { 0xAA, 0x55, '2', 'L' };
                    char Sign_ID[] = { "/Matrix48X8/M3/V7.1/Rousis" };
                    digitalWrite(RS485_PIN_DIR, RS485_WRITE);
                    for (size_t i = 0; i < sizeof(Sent_Pckt); i++)
                    {
                        rs485.write(Sent_Pckt[i]);
                    }
                    for (size_t i = 0; i < sizeof(Sign_ID); i++)
                    {
                        rs485.write(Sign_ID[i]);
                    }
                    rs485.flush();
                    digitalWrite(RS485_PIN_DIR, RS485_READ);
                    _cnt_byte = 0;
                    unstruction = 0;
                }

                if (unstruction == 0xAF) { // instruction test
                    delay(10);
                    test_enable = true;
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_OFF);
                    delay(500);
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_ON);
                    delay(500);
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_OFF);
                    delay(500);
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_ON);
                    delay(500);
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_OFF);
                    delay(500);
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_ON);
                    delay(500);
                    myLED.drawFilledBox(0, 0, PIXELS_X, 16, GRAPHICS_OFF);
                    delay(500);

                    Replay_OK();
                    test_enable = false;
                    _cnt_byte = 0;
                    unstruction = 0;
                }
            }
        } while (rs485.available() > 0);
    }
    delay(10);
}

void analyse_receive_pages(uint8_t cnt_bytes) {
    //uint8_t cnt_page_byte = 0;
    //char page[128] = {0};
    //byte b = 0;
    //uint8_t i = 0;
    //uint8_t characters = 0;
    //
    //while (cnt_page_byte < cnt_bytes)
    //{
    //    while (b != 1)
    //    {
    //        b = receive_packet[++cnt_page_byte];
    //        if (b == 4) { return; }
    //    }
    //    cnt_page_byte += 2;
    //    while (b != 0)
    //    {
    //        b = receive_packet[++cnt_page_byte];
    //        switch (b)
    //        {
    //        case 0xd6:
    //            Select_font = receive_packet[++cnt_page_byte];
    //            break;
    //        default:
    //            page[i++] = b;
    //            characters++;
    //            break;
    //        }

    //        if (i >= 128)
    //        {
    //            break;
    //        }
    //    }

    //    i--;
    //    int Legth_page = 0;
    //    for (size_t a = 0; a < i; a++)
    //    {
    //        Legth_page += myLED.charWidth(page[a]) + 1;
    //    }
    //    //int Legth_page = find_center(page);
    //    Legth_page = (PIXELS_X - (Legth_page - 1)) / 2;
    //    myLED.clearDisplay();
    //    myLED.drawString(Legth_page, 0, page, i);

    //    Serial.print("Display page : ");
    //    Serial.println(page);
    //    Serial.print("Page characters : ");
    //    Serial.println(i);
    //    Serial.print("Legth : ");
    //    Serial.println(Legth_page);
    //    Serial.println("........................................");

    //    for (i = 0; i < sizeof(page); i++)
    //    {
    //        page[i++] = 0;
    //    }
    //    i = 0;
    //    delay(2000);
    //}
}

void Replay_OK(void) {
    char Sent_Pckt[] = { 0xAA, 0x55,'O', 'K', '!' };
    //[01,55,AA] “OK!” [04]

    //char Sent_Pckt[] = { 0xAA, 0x55, '2', 'L' };
    //char Sign_ID[] = { "/Matrix48X8/M3/V7.1/Rousis" };
    digitalWrite(RS485_PIN_DIR, RS485_WRITE);
    for (size_t i = 0; i < sizeof(Sent_Pckt); i++)
    {
        rs485.write(Sent_Pckt[i]);
    }
    /*
    for (size_t i = 0; i < sizeof(Sign_ID); i++)
    {
        rs485.write(Sign_ID[i]);
    }*/
    //rs485.write(4);
    //delay(60);
    rs485.flush();
    digitalWrite(RS485_PIN_DIR, RS485_READ);
}

