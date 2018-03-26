﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using libStreamSDK;
using System.Threading;

namespace thinkgear_testapp_csharp_64
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Started...");

            NativeThinkgear thinkgear = new NativeThinkgear();

            /* Print driver version number */
            Console.WriteLine("Version: " + NativeThinkgear.TG_GetVersion());

            /* Get a connection ID handle to ThinkGear */
            int connectionID = NativeThinkgear.TG_GetNewConnectionId();
            Console.WriteLine("Connection ID: " + connectionID);

            if (connectionID < 0)
            {
                Console.WriteLine("ERROR: TG_GetNewConnectionId() returned: " + connectionID);
                return;
            }

            int errCode = 0;
            /* Set/open stream (raw bytes) log file for connection */
            errCode = NativeThinkgear.TG_SetStreamLog(connectionID, "streamLog.txt");
            Console.WriteLine("errCode for TG_SetStreamLog : " + errCode);
            if (errCode < 0)
            {
                Console.WriteLine("ERROR: TG_SetStreamLog() returned: " + errCode);
                return;
            }

            /* Set/open data (ThinkGear values) log file for connection */
            errCode = NativeThinkgear.TG_SetDataLog(connectionID, "dataLog.txt");
            Console.WriteLine("errCode for TG_SetDataLog : " + errCode);
            if (errCode < 0)
            {
                Console.WriteLine("ERROR: TG_SetDataLog() returned: " + errCode);
                return;
            }

            /* Attempt to connect the connection ID handle to serial port "COM5" */
            string comPortName = "COM3";

            errCode = NativeThinkgear.TG_Connect(connectionID,
                          comPortName,
                          NativeThinkgear.Baudrate.TG_BAUD_57600,
                          NativeThinkgear.SerialDataFormat.TG_STREAM_PACKETS);
            if (errCode < 0)
            {
                Console.WriteLine("ERROR: TG_Connect() returned: " + errCode);
                return;
            }

            /* Read 10 ThinkGear Packets from the connection, 1 Packet at a time */
            int packetsRead = 0;
            while (packetsRead < 10000)
            {

                /* Attempt to read a Packet of data from the connection */
                errCode = NativeThinkgear.TG_ReadPackets(connectionID, 512);
                // Console.WriteLine("TG_ReadPackets returned: " + errCode);
                /* If TG_ReadPackets() was able to read a complete Packet of data... */
                if (errCode == 1)
                {
                    // packetsRead++;

                    /* If attention value has been updated by TG_ReadPackets()... */
                    //if (NativeThinkgear.TG_GetValueStatus(connectionID, NativeThinkgear.DataType.TG_DATA_DELTA) != 0)
                    //{
                        packetsRead++;
                        /* Get and print out the updated attention value */
                        // Console.WriteLine("New RAW value: : " + (int)NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW));
                        Console.WriteLine("New Packet...");
                        Console.WriteLine("RAW...");
                        Console.WriteLine("\tRaw: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW));
                        Console.WriteLine("\tDelta: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_DELTA));
                        Console.WriteLine("\tTheta: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_THETA));
                        Console.WriteLine("\tAlpha: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_ALPHA1));
                        Console.WriteLine("\tBeta: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_BETA1));
                        Console.WriteLine("\tGamma: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_GAMMA1));
                        Console.WriteLine("LOG...");
                        Console.WriteLine("\tRaw: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW)));
                        Console.WriteLine("\tDelta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_DELTA)));
                        Console.WriteLine("\tTheta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_THETA)));
                        Console.WriteLine("\tAlpha: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_ALPHA1)));
                        Console.WriteLine("\tBeta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_BETA1)));
                        Console.WriteLine("\tGamma: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_GAMMA1)));
                        Console.WriteLine();

                        // Thread.Sleep(1000);
                    //} /* end "If attention value has been updated..." */

                } /* end "If a Packet of data was read..." */

            } /* end "Read 10 Packets of data from connection..." */

            Console.WriteLine("auto read test begin:");

            errCode = NativeThinkgear.TG_EnableAutoRead(connectionID, 1);
            if (errCode == 0)
            {
                Console.WriteLine("Auto read trial...");
                packetsRead = 0;
                errCode = NativeThinkgear.MWM15_setFilterType(connectionID, NativeThinkgear.FilterType.MWM15_FILTER_TYPE_60HZ);
                Console.WriteLine("MWM15_setFilterType called: " + errCode);
                while (packetsRead < 2000) // it use as time
                {
                    /* If raw value has been updated ... */
                    if (NativeThinkgear.TG_GetValueStatus(connectionID, NativeThinkgear.DataType.TG_DATA_RAW) != 0)
                    {
                        if (NativeThinkgear.TG_GetValueStatus(connectionID, NativeThinkgear.DataType.MWM15_DATA_FILTER_TYPE) != 0)
                        {
                            Console.WriteLine(" Find Filter Type:  " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.MWM15_DATA_FILTER_TYPE) + " index: " + packetsRead);
                            //break;
                        }
                        /* Get and print out the updated raw value */
                        //NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW);
                        //Console.WriteLine("\tRaw: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW)));
                        //Console.WriteLine("\tDelta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_DELTA)));
                        //Console.WriteLine("\tTheta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_THETA)));
                        //Console.WriteLine("\tAlpha: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_ALPHA1)));
                        //Console.WriteLine("\tBeta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_BETA1)));
                        //Console.WriteLine("\tGamma: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_GAMMA1)));

                        packetsRead++;

                        if (packetsRead == 800 || packetsRead == 1600)  // call twice interval than 1s (512)
                        {
                            errCode = NativeThinkgear.MWM15_getFilterType(connectionID);
                            Console.WriteLine(" MWM15_getFilterType called: " + errCode);
                        }

                    }

                    
                }

                errCode = NativeThinkgear.TG_EnableAutoRead(connectionID, 0); //stop
                Console.WriteLine("auto read test stoped: "+ errCode);
            }
            else
            {
                Console.WriteLine("auto read test failed: " + errCode);
            }

            NativeThinkgear.TG_Disconnect(connectionID); // disconnect test

            /* Clean up */
            NativeThinkgear.TG_FreeConnection(connectionID);

            /* End program */
            Console.ReadLine();

        }
    }
}
