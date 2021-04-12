#Persistent
#SingleInstance Force
#NoEnv
#Include <Gdip_All>
SetBatchLines -1
DetectHiddenWindows, On
SetWorkingDir, % A_ScriptDir
FileInstall, logo.png, logo.png


pToken := Gdip_Startup()
pegasusWinName := "Pegasus ahk_class Qt5152QWindowOwnDCIcon"
ini := "Pegasus Launcher.ini"
exe := "pegasus-fe.exe"
logo := "logo.png"
useLogo := IniRead(ini, "Options", "use.logo")
logoOffsetX := IniRead(ini, "Options", "logo.offset.x")
logoOffsetY := IniRead(ini, "Options", "logo.offset.y")
args := ""


if (A_Args.Length() > 0) {
	for i, v in A_Args
		args .= A_Args[i] " "
}

MouseMove, % A_ScreenWidth, % A_ScreenHeight, 0
GoSub, Create_GDIP_Window
Run, % args ? exe " " RTrim(args) : exe, % A_ScriptDir
WinWait, % pegasusWinName
WinActivate, % pegasusWinName
WinSet, AlwaysOnTop, On, % pegasusWinName
SetTimer, CheckProcess, 500
return


Create_GDIP_Window:
	alpha := 0
	Gui, New, -Caption +E0x80000 +AlwaysOnTop +ToolWindow +OwnDialogs +HwndhGDI1
	Gui, %hGDI1%: Show, NA
	
	hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	Gdip_SetInterpolationMode(G, 7)
	Gdip_SetSmoothingMode(G, 4)
	pBrush := Gdip_BrushCreateSolid(0xff000000)
	Gdip_FillRectangle(G, pBrush, -2, -2, A_ScreenWidth + 4, A_ScreenHeight + 4)
	Gdip_DeleteBrush(pBrush)
	
	if (useLogo) {
		pBitmap := Gdip_CreateBitmapFromFile(logo)
		iH := Gdip_GetImageHeight(pBitmap)
		iW := Gdip_GetImageWidth(pBitmap)
		Gdip_DrawImage(G, pBitmap, ((A_ScreenWidth - iW) / 2) + logoOffsetX, ((A_ScreenHeight - iH) / 2) + logoOffsetY, iW, iH, 0, 0, iW, iH)
		Gdip_DisposeImage(pBitmap)
	}
	
	Loop
	{
		UpdateLayeredWindow(hGDI1, hdc, 0, 0, A_ScreenWidth, A_ScreenHeight, InStr(alpha, ".") ? Round(alpha) : alpha)
		
		if (alpha >= 255)
			break
		
		alpha += 5.1
		alpha := alpha > 255 ? 255 : alpha
		Sleep, 10
	}
	return

Close_GDIP_Window:
	alpha := 255
	Loop
	{
		UpdateLayeredWindow(hGDI1, hdc, 0, 0, A_ScreenWidth, A_ScreenHeight, InStr(alpha, ".") ? Round(alpha) : alpha)
		
		if (alpha <= 0)
			break
		
		alpha -= 5.1
		alpha := alpha < 0 ? 0 : alpha
		Sleep, 10
	}
	return

CheckProcess:
	Critical, On
	Process, Exist, % exe
	if (!ErrorLevel) {
		SetTimer, CheckProcess, Off
		GoSub, Close_GDIP_Window
		GoSub, CleanUp
		ExitApp
	}
	return

CleanUp:
	SelectObject(hdc, obm)
	DeleteObject(hbm)
	DeleteDC(hdc)
	Gdip_DeleteGraphics(G)
	Gdip_Shutdown(pToken)
	return
	
