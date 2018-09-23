# flogpp
A cpp code analyzer inspired by seattlerb/flog

## Description
flogpp reports the most tortured code in a pain report.  The higher the score,
the more pain the code is in.

## Features
* Can pass specific files on the command line.
* If no files given, will recursively search under current directory to find
  files (with extensions .c, .cpp, .cc, .cxx, .h, and .hh)

## Synopsis
```shell
> cd flogpp && ./lib/flogpp
  1791.0: Flog total
   895.0: Flog average/file
    20.0: Flog average/function

   200.0: handleHttpClient (test/files/CloudFS_replicator.c:235)
   114.0: OTCloseProvider (test/files/eudora_tcp.c:361)
    88.0: data_callback (test/files/CloudFS_replicator.c:311)
    80.0: OTTCPConnectTrans (test/files/eudora_tcp.c:158)
    51.0: OTTCPSendTrans (test/files/eudora_tcp.c:164)
    49.0: OTPPPDialingInformation (test/files/eudora_tcp.c:488)
    47.0: OTWaitForChars (test/files/eudora_tcp.c:274)
    43.0: initStream (test/files/CloudFS_replicator.c:138)
```
