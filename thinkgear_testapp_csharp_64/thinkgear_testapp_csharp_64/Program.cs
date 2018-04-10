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
        static void Main(string[] args)
        {
            while (true)
            {
                bool toFile = true;
                string userId = "";
                int userStatus = -1;
                int maxTrials = -1;
                int sampleRate = 512;
                string savePath = Path.Combine("..", "..", "data", "output_raw.csv");
                // string savePath = "data/output_raw.csv";
                string idPath = Path.Combine("..", "..", "data", "ids.csv");
                // string idPath = "data/ids.csv";
                string backupPath = "data";
                StreamWriter writer = new StreamWriter(savePath, true);

                #region INPUT
                bool _idFound = false;
                while (!_idFound)
                {
                    Console.Write("[INPUT] Enter ID: ");
                    userId = Console.ReadLine();
                    _idFound = ValidateId(idPath, userId);
                    if (!_idFound)
                    {
                        Console.Write("[ERROR] Invalid id try again.");
                    }
                }
                Console.Write("[INPUT] Enter number of trials: ");
                maxTrials = int.Parse(Console.ReadLine());
                while (maxTrials < 1)
                {
                    Console.Write("[ERROR] Invalid number of trials, try again: ");
                    maxTrials = int.Parse(Console.ReadLine());
                }

                Console.Write("[INPUT] Enter status for trials (0=closed, 1=open): ");
                userStatus = int.Parse(Console.ReadLine());
                while (userStatus != 1 && userStatus != 0)
                {
                    Console.Write("[ERROR] Invalid status value, try again (0=closed, 1=open): ");
                    userStatus = int.Parse(Console.ReadLine());
                }
                #endregion
                CollectData(userId, maxTrials, userStatus, savePath, sampleRate, toFile, writer);
                writer.Close();
            }
        }

        public static void CollectData(string userId, int numTrials, int trialStatus, string savePath, int sampleRate, bool toFile, StreamWriter writer)
        {
            #region INITIALIZE

            Console.WriteLine("[INFO] Finding trial offset...");
            int trialOffset = GetTrialOffset(savePath, userId, trialStatus);
            DateTime previousTime;
            double seconds = 0.0f;
            int currentTrial = 0;
            int packetsRead = 0;
            int currentPacket = 0;
            string comPortName = "COM3";

            Console.WriteLine("[INFO] Starting data collection in 3 seconds...");
            Thread.Sleep(3000);

            Console.WriteLine("[INFO] Initializing headset...");
            NativeThinkgear thinkgear = new NativeThinkgear();
            Console.WriteLine("[INFO] Version: " + NativeThinkgear.TG_GetVersion());
            /* Get a connection ID handle to ThinkGear */
            int connectionID = NativeThinkgear.TG_GetNewConnectionId();
            Console.WriteLine("[INFO] Connection ID: " + connectionID);
            if (connectionID < 0)
            {
                Console.WriteLine("[ERROR] TG_GetNewConnectionId() returned: " + connectionID);
                return;
            }
            int errCode = 0;
            /* Set/open stream (raw bytes) log file for connection */
            errCode = NativeThinkgear.TG_SetStreamLog(connectionID, "streamLog.txt");
            Console.WriteLine("[INFO] errCode for TG_SetStreamLog : " + errCode);
            if (errCode < 0)
            {
                Console.WriteLine("[ERROR] TG_SetStreamLog() returned: " + errCode);
                return;
            }
            /* Set/open data (ThinkGear values) log file for connection */
            errCode = NativeThinkgear.TG_SetDataLog(connectionID, "dataLog.txt");
            Console.WriteLine("[INFO] errCode for TG_SetDataLog : " + errCode);
            if (errCode < 0)
            {
                Console.WriteLine("[ERROR] TG_SetDataLog() returned: " + errCode);
                return;
            }
            /* Attempt to connect the connection ID handle to serial port "COM5" */
            errCode = NativeThinkgear.TG_Connect(connectionID,
                comPortName,
                NativeThinkgear.Baudrate.TG_BAUD_57600,
                NativeThinkgear.SerialDataFormat.TG_STREAM_PACKETS);
            if (errCode < 0)
            {
                Console.WriteLine("[ERROR] TG_Connect() returned: " + errCode);
                return;
            }
            Console.WriteLine("[INFO] Initializing headset finsihed.");
            #endregion

            #region PROCESS
            List<Trial> trialList = new List<Trial>();
            while (currentTrial < numTrials)
            {
                /* Attempt to read a Packet of data from the connection */
                errCode = NativeThinkgear.TG_ReadPackets(connectionID, 1);
                /* If TG_ReadPackets() was able to read a complete Packet of data... */
                if (errCode == 1)
                {
                    /* The raw data was updated since the last call */
                    if (NativeThinkgear.TG_GetValueStatus(connectionID, NativeThinkgear.DataType.TG_DATA_RAW) != 0)
                    {
                        /* Skip the first 2 seconds to avoid bad data */
                        if (packetsRead < sampleRate * 2)
                        {
                            Console.Write("\r[INFO] Skipping Packet (" + currentPacket + "/" + sampleRate * 2 + ")");
                            packetsRead++;
                            currentPacket++;
                            continue;
                        }
                        if (currentPacket % sampleRate == 0)
                        {
                            currentPacket = 0;
                            currentTrial++;
                            previousTime = DateTime.Now;
                            seconds = (DateTime.Now - previousTime).TotalSeconds;
                            if (toFile && trialList.Count > 0)
                                InsertTrialData(trialList, savePath);
                            trialList.Clear();
                        }
                        //! Set up data for Trial
                        float _raw = NativeThinkgear.TG_GetValue(connectionID, NativeThinkgear.DataType.TG_DATA_RAW);
                        DateTime _time = DateTime.Now;
                        Trial _currentTrial = new Trial(userId, trialStatus, currentTrial + trialOffset, _raw, currentPacket, _time);
                        trialList.Add(_currentTrial);
                        Console.WriteLine("[TRIAL] Trial=" + currentTrial + " Packet=" + currentPacket + " UserID=" + userId + " Status=" + trialStatus + " Total_Trial=" + (currentTrial + trialOffset));
                        if (toFile)
                        {
                            writer.WriteLine(_currentTrial);
                        }
                        //! Update trackers
                        packetsRead++;
                        currentPacket++;
                    }

                } /* end "If a Packet of data was read..." */

            } /* end "Read 10 Packets of data from connection..." */

            #endregion

            #region DISCONNECT
            NativeThinkgear.TG_Disconnect(connectionID); // disconnect test
            /* Clean up */
            NativeThinkgear.TG_FreeConnection(connectionID);
            /* End program */
            Console.ReadLine();
            #endregion
        }

        // public static void InsertTrialData(Trial trial, string filePath, StreamWriter writer)
        // {
        //     writer.WriteLine(trial)
        //     using(var tw = new StreamWriter(filePath, true))
        //     {
        //         tw.WriteLine(trial);
        //     }
        // }
        public static void InsertTrialData(List<Trial> trialList, string filePath)
        {
            using(var tw = new StreamWriter(filePath, true))
            {
                foreach (Trial _t in trialList)
                    tw.WriteLine(_t);
            }
        }

        public static bool ValidateId(string filePath, string id)
        {
            using(var reader = new StreamReader(filePath))
            {
                List<string> ids = new List<string>();
                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    var values = line.Split(',');
                    ids.Add(values[0]);
                }
                if (ids.Contains(id))
                    return true;
                else
                    return false;
            }
        }
        public static int GetTrialOffset(string filePath, string id, int status)
        {
            using(var reader = new StreamReader(filePath))
            {
                List<int> trials = new List<int>();
                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    var values = line.Split(',');
                    if (values[0] == id && int.Parse(values[1]) == status && !trials.Contains(int.Parse(values[2])))
                        trials.Add(int.Parse(values[2]));
                }
                //! get max of list
                int max;
                if (trials.Count > 0)
                    max = trials.Max();
                else
                    max = 0;

                //! return max as offset
                return max;
            }
        }
        public static void BackupSave(string filePath, string backupPath)
        {
            string baseName = "output_raw_backup";
            int count = 1;
            string end = ".csv";
            bool found = false;

            string[] files = Directory.GetFiles(backupPath);
            while (!found)
            {
                string path = backupPath + "/" + baseName + count.ToString() + end;
                foreach (string fileName in files)
                {
                    if (path == Path.GetFileName(fileName))
                    {
                        count++;
                        break;
                    }
                    found = true;
                }
            }
        }
    }
}