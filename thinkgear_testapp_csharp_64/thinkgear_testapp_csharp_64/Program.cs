using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using libStreamSDK;

namespace thinkgear_testapp_csharp_64
{
    class Program
    {
        static void Main (string[] args)
        {
            #region INITIALIZE
            bool toFile = false;
            String userId;
            int userStatus = -1;
            double seconds = 0.0f;
            int packetsRead = -1;
            int currentPacket = 0;
            int currentTrial = 1;
            int maxTrials = -1;
            int trialOffset = 0;
            int sampleRate = 512;
            DateTime previousTime;
            String savePath = "data/output.csv";
            String idPath = "data/ids.csv";

            Console.WriteLine ("[INFO] Initializing headset...");

            NativeThinkgear thinkgear = new NativeThinkgear ();
            Console.WriteLine ("Version: " + NativeThinkgear.TG_GetVersion ());
            /* Get a connection ID handle to ThinkGear */
            int connectionID = NativeThinkgear.TG_GetNewConnectionId ();
            Console.WriteLine ("Connection ID: " + connectionID);
            if (connectionID < 0)
            {
                Console.WriteLine ("ERROR: TG_GetNewConnectionId() returned: " + connectionID);
                return;
            }
            int errCode = 0;
            /* Set/open stream (raw bytes) log file for connection */
            errCode = NativeThinkgear.TG_SetStreamLog (connectionID, "streamLog.txt");
            Console.WriteLine ("errCode for TG_SetStreamLog : " + errCode);
            if (errCode < 0)
            {
                Console.WriteLine ("[ERROR] TG_SetStreamLog() returned: " + errCode);
                return;
            }
            /* Set/open data (ThinkGear values) log file for connection */
            errCode = NativeThinkgear.TG_SetDataLog (connectionID, "dataLog.txt");
            Console.WriteLine ("errCode for TG_SetDataLog : " + errCode);
            if (errCode < 0)
            {
                Console.WriteLine ("[ERROR] TG_SetDataLog() returned: " + errCode);
                return;
            }
            /* Attempt to connect the connection ID handle to serial port "COM5" */
            string comPortName = "COM3";
            errCode = NativeThinkgear.TG_Connect (connectionID,
                comPortName,
                NativeThinkgear.Baudrate.TG_BAUD_57600,
                NativeThinkgear.SerialDataFormat.TG_STREAM_PACKETS);
            if (errCode < 0)
            {
                Console.WriteLine ("[ERROR] TG_Connect() returned: " + errCode);
                return;
            }
            Console.WriteLine ("[INFO] Initializing headset finsihed.");
            #endregion

            Console.Write ("[INPUT] Enter ID: ");
            userId = Console.ReadLine ();
            // while ()
            // {
            //     //! look up from db / file
            // }

            Console.Write ("[INPUT] Enter number of trials: ");
            maxTrials = int.Parse (Console.ReadLine ());
            while (maxTrials < 1)
            {
                Console.Write ("Invalid number of trials, try again: ");
                maxTrials = int.Parse (Console.ReadLine ());
            }

            Console.Write ("[INPUT] Enter status for trials (0=closed, 1=open): ");
            userStatus = int.Parse (Console.ReadLine ());
            while (userStatus != 1 && userStatus != 0)
            {
                Console.Write ("Invalid status value, try again (0=closed, 1=open): ");
                userStatus = int.Parse (Console.ReadLine ());
            }

            //! Get trial offset based on data

            /* Read 10 ThinkGear Packets from the connection, 1 Packet at a time */
            Console.WriteLine ("[INFO] Starting data collection in 3 seconds...");
            Thread.Sleep (3000);
            packetsRead = 0;
            currentPacket = 0;
            while (currentTrial < maxTrials)
            {
                /* Attempt to read a Packet of data from the connection */
                errCode = NativeThinkgear.TG_ReadPackets (connectionID, 1);
                /* If TG_ReadPackets() was able to read a complete Packet of data... */
                if (errCode == 1)
                {
                    /* The raw data was updated since the last call */
                    if (NativeThinkgear.TG_GetValueStatus (connectionID, NativeThinkgear.DataType.TG_DATA_RAW) != 0)
                    {
                        /* Skip the first 2 seconds to avoid bad data */
                        if (currentPacket < sampleRate * 2)
                        {
                            Console.WriteLine ("[INFO] Skipping Packet " + currentPacket);
                            packetsRead++;
                            currentPacket++;
                            continue;
                        }
                        if (currentPacket % sampleRate == 0)
                        {
                            currentPacket = 0;
                            // userStatus = -1;
                            currentTrial++;
                            previousTime = DateTime.Now;
                            seconds = (DateTime.Now - previousTime).TotalSeconds;
                            // Console.WriteLine ("Seconds: " + seconds);
                            // while (userStatus != 1 && userStatus != 0)
                            // {
                            //     Console.Write ("Trial: " + _t + " Packet: " + packetsRead + " Enter status (0 closed, 1 open): ");
                            //     userStatus = int.Parse (Console.ReadLine ());
                            // }
                            // Console.WriteLine ("Starting trial for status: " + userStatus + "...");
                            // Thread.Sleep (2000);
                        }
                        float _raw = NativeThinkgear.TG_GetValue (connectionID, NativeThinkgear.DataType.TG_DATA_RAW);
                        DateTime _time = DateTime.Now;
                        Trial _currentTrial = new Trial (userId, userStatus, currentTrial, _raw, packetsRead, _time);
                        Console.WriteLine ("Packet=" + packetsRead + " UserID=" + userId + " Status=" + userStatus + " Local_Trial=" + currentTrial + " Total_Trial=" + (currentTrial + trialOffset));
                        if (toFile)
                        {
                            InsertTrialData (_currentTrial, savePath);
                        }
                        packetsRead++;
                        currentPacket++;
                    }

                } /* end "If a Packet of data was read..." */

            } /* end "Read 10 Packets of data from connection..." */

            NativeThinkgear.TG_Disconnect (connectionID); // disconnect test
            /* Clean up */
            NativeThinkgear.TG_FreeConnection (connectionID);
            /* End program */
            Console.ReadLine ();

        }

        public static void InsertTrialData (Trial trial, String filePath)
        {
            using (var tw = new StreamWriter (filePath, true))
            {
                tw.WriteLine (trial);
            }
        }
        // public static void RunTrial ()
        // {
        //     NativeThinkgear.TG_ReadPackets (connectionID);
        // }
    }
}

// #region AUTO_READ
//             if (false)
//             {
//                 errCode = NativeThinkgear.TG_EnableAutoRead (connectionID, 1);
//                 if (errCode == 0)
//                 {
//                     Console.WriteLine ("Auto read trial...");
//                     packetsRead = 0;
//                     errCode = NativeThinkgear.MWM15_setFilterType (connectionID, NativeThinkgear.FilterType.MWM15_FILTER_TYPE_60HZ);
//                     Console.WriteLine ("MWM15_setFilterType called: " + errCode);
//                     while (packetsRead < 2000) // it use as time
//                     {
//                         /* If raw value has been updated ... */
//                         if (NativeThinkgear.TG_GetValueStatus (connectionID, NativeThinkgear.DataType.TG_DATA_RAW) != 0)
//                         {
//                             if (NativeThinkgear.TG_GetValueStatus (connectionID, NativeThinkgear.DataType.MWM15_DATA_FILTER_TYPE) != 0)
//                             {
//                                 Console.WriteLine (" Find Filter Type:  " + NativeThinkgear.TG_GetValue (connectionID, NativeThinkgear.DataType.MWM15_DATA_FILTER_TYPE) + " index: " + packetsRead);
//                                 //break;
//                             }
//                             /* Get and print out the updated raw value */
//                             NativeThinkgear.TG_GetValue (connectionID, NativeThinkgear.DataType.TG_DATA_RAW);
//                             packetsRead++;

//                             if (packetsRead == 800 || packetsRead == 1600) // call twice interval than 1s (512)
//                             {
//                                 errCode = NativeThinkgear.MWM15_getFilterType (connectionID);
//                                 Console.WriteLine (" MWM15_getFilterType called: " + errCode);
//                             }

//                         }

//                     }

//                     errCode = NativeThinkgear.TG_EnableAutoRead (connectionID, 0); //stop
//                     Console.WriteLine ("auto read test stoped: " + errCode);
//                 }
//                 else
//                 {
//                     Console.WriteLine ("auto read test failed: " + errCode);
//                 }
//             }
//             #endregion

// if(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW) > 60)
// {
//    Thread.Sleep(5000);
// }
// Console.WriteLine("\tDelta: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_DELTA));
// Console.WriteLine("\tTheta: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_THETA));
// Console.WriteLine("\tAlpha: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_ALPHA1));
// Console.WriteLine("\tBeta: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_BETA1));
// Console.WriteLine("\tGamma: " + NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_GAMMA1));
// Console.WriteLine("LOG...");
// Console.WriteLine("\tRaw: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW)));
// Console.WriteLine("\tDelta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_DELTA)));
// Console.WriteLine("\tTheta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_THETA)));
// Console.WriteLine("\tAlpha: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_ALPHA1)));
// Console.WriteLine("\tBeta: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_BETA1)));
// Console.WriteLine("\tGamma: " + Math.Log10(NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_GAMMA1)));
// Console.WriteLine();
// Thread.Sleep(1000);