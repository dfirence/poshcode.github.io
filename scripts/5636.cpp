#include <windows.h>
#include <stdio.h>

#pragma comment (lib, "advapi32.lib")

BOOLEAN (__stdcall *RtlTimeToSecondsSince1980)(
    PLARGE_INTEGER Time,
    PULONG         ElapsedSeconds
);

VOID (__stdcall *RtlSecondsSince1980ToTime)(
    ULONG          ElapsedSeconds,
    PLARGE_INTEGER Time
);

int main(void) {
  HKEY       rk;
  FILETIME   now, cur;
  DWORD      sz = sizeof(cur);
  ULONG      sec1, sec2, delta;
  SYSTEMTIME st;
  
  if (!(RtlTimeToSecondsSince1980 = (void *)GetProcAddress(
      GetModuleHandle("ntdll.dll"), "RtlTimeToSecondsSince1980"
  ))) {
    printf("Could not find RtlTimeToSecondsSince1980 entry point.\n");
    exit(1);
  }
  
  if (!(RtlSecondsSince1980ToTime = (void *)GetProcAddress(
      GetModuleHandle("ntdll.dll"), "RtlSecondsSince1980ToTime"
  ))) {
    printf("Could not find RtlSecondsSince1980ToTime entry point.\n");
    exit(1);
  }
  
  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE,
                   "SYSTEM\\CurrentControlSet\\Control\\Windows",
                   0,
                   KEY_QUERY_VALUE,
                   &rk) == ERROR_SUCCESS) {
    if (RegQueryValueEx(rk,
                        "ShutdownTime",
                        NULL,
                        NULL,
                        (BYTE *) &cur,
                        &sz) == ERROR_SUCCESS) {
      GetSystemTimeAsFileTime(&now);
    }
    RegCloseKey(rk);
  }
  
  if (!RtlTimeToSecondsSince1980((PLARGE_INTEGER)&now, &sec1)) return;
  if (!RtlTimeToSecondsSince1980((PLARGE_INTEGER)&cur, &sec2)) return;
  
  delta = sec1 - sec2;
  RtlSecondsSince1980ToTime(delta, (PLARGE_INTEGER)&cur);
  FileTimeToSystemTime(&cur, &st);
  
  printf("uptime v1.1 - System uptime\n");
  printf("Copyright (C) 2014 greg zakharov\n\n");
  printf("%.2u:%.2u:%.2u up %u day%s",
    st.wHour, st.wMinute, st.wSecond, st.wDay -= 1, st.wDay > 1 ? "s" : "\0"
  );
  
  return 0;
}
