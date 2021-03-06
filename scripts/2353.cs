using System;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;


namespace mklink
{
    class mklink
    {
        [DllImport("kernel32.dll")]
        static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, int dwFlags);

        static void Main(string[] args)
        {
            int dirlink = 0;
            int c = 0;
            string[] paths = new string[0];
            
            Console.WriteLine("MKLINK - Create a symbolic or directory link. MKLINK -help for usage. Created in 2010 by James Gentile.");

            foreach (string a in args)
            {
                if ((System.String.Compare(a, "-help", true) == 0) || (System.String.Compare(a, "-H", true) == 0))
                {
                    Console.WriteLine("MKLINK [/D] <Symbolic Link> <file or directory source>");
                    return;
                }
                if (System.String.Compare(a, @"/d", true) == 0)
                {
                    dirlink = 1;
                    continue;
                }
                Array.Resize(ref paths, paths.Length + 1);
                paths[c] = a;
                c++;
            }

            if (paths.Length != 2)
            {
                Console.WriteLine("Requires a <symbolic link> and <file or directory> source.");
                return;
            }
            try
            {
                if (CreateSymbolicLink(paths[0], paths[1], dirlink))
                    Console.WriteLine("Symblic link created for " + paths[0] + " <<===>> " + paths[1]);
            }
            catch (Exception e) 
            {
                Console.WriteLine("Error creating symbolic link: " + e.Message);
            }            
        }
    }
}

