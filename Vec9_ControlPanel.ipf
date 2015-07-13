#pragma rtGlobals=1		// Use modern global access method.


//*********************************************************************************
//19 MAR 2002 Kota
// started a module for changing preference on the ROI measurement.
//
//26 JAN 2002	Kota Miura
//Procedures copied from ImageTransform.ipf and was modified for the Vecotor Field program.
//
// 10JUN99 (notes from ImageTransform.ipf)
// Procedure file to add a panel that supports the ImageTransform operation.
// This file should be listed in <All IP Procedures> together with entry on the main Image menu.
// This file requires IGOR versions newer than 3.14.  It will not compile on 3.14 Mac or PC.
//

//*********************************************************************************

Function xVecDoitButtonProc(ctrlName) : ButtonControl
	String ctrlName

	Variable 	isOverwrite
	String 		imageGraphName= WMTopImageGraph()
	String 		flags="",keyword,cmd
	
	// first check for top image: 
	
	if(strlen(imageGraphName)<=0)
		doAlert 0, "You must have a top image to operate on."
		return 0
	endif

	String curDF=GetDataFolder(1)

	// changing to the target datafolder 
	SettingDataFolder(WaveRefIndexed("",0,1))
		
	WAVE/Z srcWave= $WMGetImageWave(imageGraphName)

	if(WaveExists(srcWave)==0)
		doAlert 0, "Could not find a wave associated with top image"
		return 0
	endif
		
	ControlInfo xVecFunctionPop		//OK 010224
	keyword=S_value
	
	strswitch(keyword)
		case "ChangeScaling":
//			NVAR Panel_scale=:VectorFunctions:G_Scaling
			NVAR scale
//			scale=Panel_scale    //this point is the problem
			DrawNewScale_core()
		break
		
		case "ChangeAveraging":
//			NVAR Panel_Averaging=:VectorFunctions:G_Averaging
			NVAR averaging
//			averaging=panel_averaging
			DrawNewAverage_core()
		break
		
		case "Statistics":
			V_turnOFFallFilter()
			NVAR isPosition
			HistAnalCore()
			V9_switchANGLErange()			//030729
			DoWindow/F $VectorFieldWindowName()
			V_Cleardrawings() 		// clear ROI
			V_printResults()
			if (V_CheckForceHistPresence()==1)		//030813
				V_FlowHist()
			endif
		break
		
//		case "Statistics_Range":
//			//VecRangeByAVE()		commented out 030729
//		break
	
	endswitch

	SetDataFolder curDF	
	
End

///*************************************************************************************



Function xVecRelCoordCheckBarProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	NVAR isPosition
	isPosition=checked
	NVAR Dest_X
	NVAR Dest_Y	
	//Variable/G root:VectorFunctions:G_Relative= checked
	if (checked)
		SetVariable xVecXposVar,disable=0		
		SetVariable xVecYposVar,disable=0
	
		SetVariable xVecXposVar,pos={153,26},size={100,19},title="Target X :"
		SetVariable xVecXposVar,value=Dest_X//:VectorFunctions:G_Xpos		
		SetVariable xVecYposVar,pos={272,26},size={100,19},title="Target Y :"
		SetVariable xVecYposVar,value=Dest_Y//:VectorFunctions:G_Ypos
		//isPosition=1		
	else
		SetVariable xVecXposVar,disable=1		
		SetVariable xVecYposVar,disable=1
		//isPosition=0		
	endif
	SetDataFolder curDF
End

//*********************************************************************************
// The following is called when the main keyword popup menu is clicked.  It sets up
// all the controls depending on the user choice of keyword for this operation.
// modified xformNamesPopProc(ctrlName,popNum,popStr) in ImageTransformPanel.ipf
//*********************************************************************************



Function xVecFunctionPopBarProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	SettingDataFolder(WaveRefIndexed("",0,1))
	killControl xVecScalingVar
	killControl xVecAveragingVar
	killControl xVecScalingVar
	killControl xVecThresholdVar
	killControl xVecRelCoordCheck
	KillControl xVecR_MinVar
	KillControl xVecR_MaxVar
	
	if (popNUM != 3)
		KillControl xVecXposVar
		KillControl xVecYposVar
	endif
	
	NVAR scale,averaging,isPosition

	xVecRelCoordCheckBarProc("CheckBoxControl",isPosition)
	if (popNUM != 3)
		KillControl xVecXposVar
		KillControl xVecYposVar
	endif
	strswitch(popstr)
		case "ChangeScaling":
			SetVariable xVecXposVar,disable=1		
			SetVariable xVecYposVar,disable=1
			SetVariable xVecScalingVar,pos={200,3},size={150,21},title="Scaling:"
			SetVariable xVecScalingVar,limits={0.5,100,0.5},value=Scale//:VectorFunctions:G_Scaling
		break
		
		case "ChangeAveraging":
			SetVariable xVecXposVar,disable=1		
			SetVariable xVecYposVar,disable=1
			SetVariable xVecAveragingVar,pos={200,3},size={150,21},title="Averaging:"
			SetVariable xVecAveragingVar,limits={3,105,2},value=Averaging//:VectorFunctions:G_Averaging
		break
		
		case "Statistics":
			//SetVariable xVecThresholdVar,pos={300,10},size={100,19},title="Threshold:"
			//SetVariable xVecThresholdVar,value= root:VectorFunctions:G_Threshold
			CheckBox xVecRelCoordCheck,pos={152,7},size={250,20},proc=xVecRelCoordCheckBarProc,title="Relative Coordinate",value=isPosition
			CheckBox xVecRelCoordCheck,help={"When checked, vector angle is measured against a specific point."}			
		break
// commented out 030729
//		case "Statistics_Range":
////			SetVariable xVecThresholdVar,pos={26,70},size={100,19},title="Threshold:"
////			SetVariable xVecThresholdVar,value= root:VectorFunctions:G_Threshold
//			SetVariable xVecR_MinVar,pos={153,26},size={130,20},title="Range min:"
//			SetVariable xVecR_MinVar,value= root:VectorFunctions:avVrange_min
//			SetVariable xVecR_MaxVar,pos={272,25},size={100,20},title=" max:"
//			SetVariable xVecR_MaxVar,value= root:VectorFunctions:avVrange_max
////			CheckBox xVecRelCoordCheck,pos={23,45},size={250,20},proc=xVecRelCoordCheckProc,title="Relative Coordinate",value=xVecRelCoordCheck
////			CheckBox xVecRelCoordCheck,help={"When checked, vector angle is measured against a specific point."}			
//		break
					
	endswitch
End

//*********************************************************************************
// The following is used to tickle the main popup so that the remaining controls in the window are in sync
// with the selection in the popup.
//020124 modified by Kota Miura
//*********************************************************************************

Function updateXvecBar()
		ControlInfo xVecFunctionPop		 
		xVecFunctionPopBarProc("",V_value,S_Value)
End

//******************************************
// cleaning the control panel

Function xVecR_MinMaxVar_KillControls()
	KillControl xVecR_MinVar
	KillControl xVecR_MaxVar
END

Function xVecThresholdVar_KillControls()
	KillControl xVecThresholdVar
END

Function xVecRelCoordCheck_KillControls()
	KillControl xVecRelCoordCheck
END




//********************************************
Function VectorFieldBar() 
	String curDF=GetDataFolder(1)

	// changing to the target datafolder 
	SettingDataFolder(WaveRefIndexed("",0,1))
	//DoWindow/F VecField_Panel
	String/G imageGraphName= WMTopImageGraph()  // this can be substituted with "$VectorFieldWindowName()"
	
	//if( V_Flag==1 )
	//	AutoPositionWindow/E/M=1/R=$imageGraphName	
	//	return 0
	//endif
	NVAR/z isPosition
	if (NVAR_exists(isPosition)==0)
		HistStatParameterInit()
	endif
	//VectorFieldPanelInit()
	PauseUpdate; Silent 1		// building window...
	//NewPanel/k=1 /W=(415,96,650,244) as "Vector Field"
	ControlBar 50
	//DoWindow/C VecField_Panel
	Button xVecDoitButton,pos={13,28},size={50,15},proc=xVecDoitButtonProc,title="do It"
	PopupMenu xVecFunctionPop,pos={10,3},size={160,19},proc=xVecFunctionPopBarProc,title="Function:"
	PopupMenu xVecFunctionPop,mode=1,value= #"\"ChangeScaling;ChangeAveraging;Statistics\""//;Statistics_Range\""
	//CheckBox xformOverWriteCheck,pos={23,45},size={250,20},title="Overwrite source wave",value=0
	//Button xformHelp,pos={181,115},size={50,20},proc=xformHelpProc,title="Help"
	//ModifyPanel/w=VectorFieldWindowName() fixedsize=1
	updateXvecBar()
	//AutoPositionWindow/E/M=1/R=$imageGraphName

	SetDataFolder curDF	
EndMacro

Function V9_VectorFieldBarRemove() 
	killcontrol xVecDoitButton
	killcontrol xVecFunctionPop
	killControl xVecScalingVar
	killControl xVecAveragingVar
	killControl xVecScalingVar
	killControl xVecThresholdVar
	killControl xVecRelCoordCheck
	KillControl xVecR_MinVar
	KillControl xVecR_MaxVar
	KillControl xVecXposVar
	KillControl xVecYposVar	
	controlbar 0
END


//********************************************* under construction

//Function xRoiSetDoitButtonProc()
//END

//Function RoiPreferencePanel()
//	String saveDF=GetDataFolder(1)
//	String waveDF=GetWavesDataFolder(w,1 )
//	//SetDataFolder waveDF
//
//	PauseUpdate; Silent 1		// building window...
//	NewPanel/k=1 /W=(415,96,650,244) as "Roi Measurement Setting"
//	DoWindow/C Roi_Measurement_Setting_Panel
//	Button xRoiSetDoitButton,pos={180,115},size={50,20},proc=xRoiSetDoitButtonProc,title="Do It"	
//	CheckBox RoiSetCheck,pos={23,45},size={250,20},proc=RoiSetCheckProc,title="Roi Measurement: from Filtered?",value=xVecRelCoordCheck
//	CheckBox RoiSetCheck,pos={23,45},size={250,20},title="Overwrite source wave",value=0	
//	SetDataFolder saveDF
//END


//*********** UNUSED 030729

// commented out 030729
//********************************************
//Function VectorFieldPanel() 
//	String curDF=GetDataFolder(1)
//
//	// changing to the target datafolder 
//	SettingDataFolder(WaveRefIndexed("",0,1))
//	DoWindow/F VecField_Panel
//	String/G imageGraphName= WMTopImageGraph()  // this can be substituted with "$VectorFieldWindowName()"
//	
//	if( V_Flag==1 )
//		AutoPositionWindow/E/M=1/R=$imageGraphName	
//		return 0
//	endif
//	
//	VectorFieldPanelInit()
//	PauseUpdate; Silent 1		// building window...
//	NewPanel/k=1 /W=(415,96,650,244) as "Vector Field"
//	DoWindow/C VecField_Panel
//	Button xVecDoitButton,pos={180,115},size={50,20},proc=xVecDoitButtonProc,title="Do It"
//	PopupMenu xVecFunctionPop,pos={19,9},size={160,19},proc=xVecFunctionPopProc,title="Function:"
//	PopupMenu xVecFunctionPop,mode=1,value= #"\"ChangeScaling;ChangeAveraging;Statistics\""//;Statistics_Range\""
//	//CheckBox xformOverWriteCheck,pos={23,45},size={250,20},title="Overwrite source wave",value=0
//	//Button xformHelp,pos={181,115},size={50,20},proc=xformHelpProc,title="Help"
//	ModifyPanel fixedsize=1
//	updateXvecPanel()
//	AutoPositionWindow/E/M=1/R=$imageGraphName
//
//	SetDataFolder curDF	
//EndMacro

// commented out 030729
//Function xVecFunctionPopProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//
//	killControl xVecScalingVar
//	killControl xVecAveragingVar
//	killControl xVecScalingVar
//	killControl xVecThresholdVar
//	killControl xVecRelCoordCheck
//	KillControl xVecR_MinVar
//	KillControl xVecR_MaxVar
//	
//	if (popNUM != 3)
//		KillControl xVecXposVar
//		KillControl xVecYposVar
//	endif
//	
//	NVAR xVecRelCoordCheck=root:VectorFunctions:G_Relative
////	Variable/G xVecRelCoordCheck=root:VectorFunctions:G_Relative
//	xVecRelCoordCheckProc("CheckBoxControl",xVecRelCoordCheck)
//	if (popNUM != 3)
//		KillControl xVecXposVar
//		KillControl xVecYposVar
//	endif
//	strswitch(popstr)
//		case "ChangeScaling":
//			SetVariable xVecXposVar,disable=1		
//			SetVariable xVecYposVar,disable=1
//			SetVariable xVecScalingVar,pos={26,40},size={150,21},title="Scaling:"
//			SetVariable xVecScalingVar,limits={0.5,30,0.5},value= root:VectorFunctions:G_Scaling
//		break
//		
//		case "ChangeAveraging":
//			SetVariable xVecXposVar,disable=1		
//			SetVariable xVecYposVar,disable=1
//			SetVariable xVecAveragingVar,pos={26,40},size={150,21},title="Averaging:"
//			SetVariable xVecAveragingVar,limits={3,105,2},value= root:VectorFunctions:G_Averaging
//		break
//		
//		case "Statistics":
//			SetVariable xVecThresholdVar,pos={26,70},size={100,19},title="Threshold:"
//			SetVariable xVecThresholdVar,value= root:VectorFunctions:G_Threshold
//			CheckBox xVecRelCoordCheck,pos={23,45},size={250,20},proc=xVecRelCoordCheckProc,title="Relative Coordinate",value=xVecRelCoordCheck
//			CheckBox xVecRelCoordCheck,help={"When checked, vector angle is measured against a specific point."}			
//		break
//
//// commented out 030729
////		case "Statistics_Range":
//////			SetVariable xVecThresholdVar,pos={26,70},size={100,19},title="Threshold:"
//////			SetVariable xVecThresholdVar,value= root:VectorFunctions:G_Threshold
////			SetVariable xVecR_MinVar,pos={26,70},size={100,19},title="Range min:"
////			SetVariable xVecR_MinVar,value= root:VectorFunctions:avVrange_min
////			SetVariable xVecR_MaxVar,pos={128,70},size={100,19},title=" max:"
////			SetVariable xVecR_MaxVar,value= root:VectorFunctions:avVrange_max
//////			CheckBox xVecRelCoordCheck,pos={23,45},size={250,20},proc=xVecRelCoordCheckProc,title="Relative Coordinate",value=xVecRelCoordCheck
//////			CheckBox xVecRelCoordCheck,help={"When checked, vector angle is measured against a specific point."}			
////		break
//					
//	endswitch
//End

// commented out 030729
//Function updateXvecPanel()
//		ControlInfo xVecFunctionPop		 
//		xVecFunctionPopProc("",V_value,S_Value)
//End

// commented out 030729
//Function xVecStatPopProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//
//	killControl xVecXposVar
//	killControl xVecYposVar
//	killControl xVecThresholdVar
//	
//	strswitch(popstr)
//		//case "Absolute":
//		//	SetVariable xVecThresholdVar,pos={26,70},size={100,17},title="Threshold:"
//		//	SetVariable xVecThresholdVar,value= root:VectorFunctions:G_Threshold
//			//PopupMenu xformCmapPop,pos={25,73},size={146,19},title="CMap Wave:"
//			//PopupMenu xformCmapPop,mode=1,value= #"rgbWaveList()"
//		//break
//
//		case "Relative":
//			SetVariable xVecThresholdVar,pos={26,70},size={100,19},title="Threshold:"
//			SetVariable xVecThresholdVar,value= root:VectorFunctions:G_Threshold
//			SetVariable xVecXposVar,pos={26,100},size={100,19},title="Target X :"
//			SetVariable xVecXposVar,value=root:VectorFunctions:G_Xpos		
//			SetVariable xVecYposVar,pos={26,125},size={100,19},title="Target Y :"
//			SetVariable xVecYposVar,value=root:VectorFunctions:G_Ypos		
//		break
//
//	endswitch
//End

// commented out 030729
//Function xVecRelCoordCheckProc(ctrlName,checked) : CheckBoxControl
//	String ctrlName
//	Variable checked
//	
//	Variable/G root:VectorFunctions:G_Relative= checked
//	if (checked)
//		SetVariable xVecXposVar,disable=0		
//		SetVariable xVecYposVar,disable=0
//	
//		SetVariable xVecXposVar,pos={26,100},size={100,19},title="Target X :"
//		SetVariable xVecXposVar,value=root:VectorFunctions:G_Xpos		
//		SetVariable xVecYposVar,pos={26,125},size={100,19},title="Target Y :"
//		SetVariable xVecYposVar,value=root:VectorFunctions:G_Ypos
//	else
//		SetVariable xVecXposVar,disable=1		
//		SetVariable xVecYposVar,disable=1
//	endif
//End

//Function VectorFieldPanelInit()
//	String curDF=GetDataFolder(1)
//	SettingDataFolder(WaveRefIndexed("",0,1))
//	NewDataFolder/O/S :VectorFunctions
//	NVAR/z G_scaling
//	if (NVAR_exists(G_scaling)==0)
//		Variable/G G_scaling=25
//	endif
//	
//	NVAR/z G_averaging
//	if (NVAR_exists(G_averaging)==0)	
//		Variable/G G_averaging=5
//	endif
//
//	SetDataFolder curDF
//End
