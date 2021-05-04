.386
.model flat,stdcall
option casemap:none

include     \masm32\include\windows.inc
include     \masm32\include\kernel32.inc
include     \masm32\include\user32.inc
include     \masm32\include\gdi32.inc
include     \masm32\include\gdiplus.inc

includelib  \masm32\lib\kernel32.lib
includelib  \masm32\lib\user32.lib
includelib  \masm32\lib\gdi32.lib
includelib  \masm32\lib\gdiplus.lib

WinMain     PROTO :DWORD,:DWORD,:DWORD,:DWORD
UnicodeStr  PROTO :DWORD,:DWORD
