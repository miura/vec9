#pragma rtGlobals=1		// Use modern global access method.

Function WMImageRangeAdjustGraph(histw)
	Wave histw

	// specify size in pixels to match user controls
//	Variable x0=324*72/ScreenResolution, y0= 156*72/ScreenResolution
//	Variable x1=732*72/ScreenResolution, y1= 313*72/ScreenResolution

	Display/K=1/L=lnew /W=(x0,y0,x1,y1) histw as "Image Range Adjust"

	String dfSav= GetDataFolder(1)
	SetDataFolder root:Packages:WMImProcess:ImageRange:
	AppendToGraph/L=lnew zminDrag,:zmaxDrag vs xDrag
	SetDataFolder dfSav
	ModifyGraph margin(left)=56
	ModifyGraph mode(hist)=1
	ModifyGraph quickdrag(zminDrag)=1,live(zminDrag)=1
	ModifyGraph quickdrag(zmaxDrag)=1,live(zmaxDrag)=1
	ModifyGraph lSize(zminDrag)=2,lSize(zmaxDrag)=2
	ModifyGraph rgb(hist)=(0,0,0),rgb(zmaxDrag)=(1,4,52428)
	ModifyGraph lblPos(lnew)=47
	ModifyGraph freePos(lnew)=7

	DoWindow/C WMImageRangeGraph

	ControlBar 28
	SetVariable MinVar,pos={17,6},size={92,15},proc=WMContMinMaxVarSetVarProc,title="min:"
	SetVariable MinVar,help={"Set minimum z here or drag left vertical cursor"}
	SetVariable MinVar,limits={0,255,2.55},value= root:Packages:WMImProcess:ImageRange:zmin
	SetVariable MaxVar,pos={119,6},size={91,15},proc=WMContMinMaxVarSetVarProc,title="max:"
	SetVariable MaxVar,help={"Set maximum z here or drag right vertical cursor"}
	SetVariable MaxVar,limits={0,255,2.55},value= root:Packages:WMImProcess:ImageRange:zmax
//***
	Button WMDoRange,pos={276,4},size={50,20},proc=WMContAutoButtonProc,title="Do Range"
	Button WMDoRange,help={"Click to Show Vector in that range."}


	DoUpdate	// get update over with so we don't call WMImageRangeDoHist twice
	SetWindow kwTopWin,hook=WMImageRangeWindowProc
	WMImageRangeWindowProc("EVENT:activate")
EndMacro