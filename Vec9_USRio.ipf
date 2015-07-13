#pragma rtGlobals=1		// Use modern global access method.


//***********************************************************************************************
Function DrawNewScale()
	setdatafolder root:
	//prompt	Vector1D_name, "Choose the Vector Wave", Popup TraceNameList("",";",1)
	Variable	L_Scale=25
	Prompt	L_scale, "New Scale:"
	DoPrompt "Choosing Parameters", L_scale//,Grid1D_name,scale//,OverWrite_or_not
	if (V_flag)
		Abort "Processing Canceled"
	endif
	print GetWavesDataFolder(WaveRefIndexed("",0,1),1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	NVAR scale
	scale=L_scale
	DrawNewScale_core()
	setdatafolder root:
End


//**********************************************************************************************
Function DrawNewAverage()
	setdatafolder root:
	Variable	L_averaging
	Prompt L_averaging, "New Averaging?", popup "3;5;7;9;11;13;15;17;19;21;23;"
	DoPrompt "Choosing Parameters", L_averaging
	if (V_flag)
		Abort "Processing Canceled"
	endif
	
	SettingDataFolder(WaveRefIndexed("",0,1))
	L_averaging =L_averaging*2+1	//correction for the popup menue
//	NVAR unit,LayerStart,LayerEnd,averaging,scale,rnum,cnum
//	SVAR wavename_pref
	NVAR averaging
	averaging=L_averaging
	DrawNewAverage_core()
	setdatafolder root:
End

//*************************************************************************

Function V_Show_Roi_Center() : GraphMarquee		//030505 show coordinate module

	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	GetMarquee left, bottom
	if (V_Flag == 0)
		Print "There is no marquee"
	else
		Variable windowtype=V9_checkWindowType(S_marqueeWin)
		if (windowtype==1)
			if (!DataFolderExists("Analysis"))
				V9_initializeAnalysisFolder()
			endif			
			wave/z ROIcoord2D=:Analysis:W_ROIcoord2D
			wave/z ROIsize2D=:Analysis:W_ROIsize2D

					
			ROIcoord2D={{V_Left,V_bottom}, {V_right,V_top}}
			//V9_correctROIcoord(ROIcoord2D,windowtype,isPosition)			<-- this is for the 2D hist
			ROIsize2D=ROIcoord2D[p][1]-ROIcoord2D[p][0]
			variable X_center,Y_center
			X_center=ROIcoord2D[0][0]+ROIsize2D[0]/2		
			Y_center=ROIcoord2D[1][0]+ROIsize2D[1]/2		
			printf "ROI center:: X: %g Y: %g\r", X_center,Y_center
		else
			setdatafolder "root:"
			abort "Select vector field window!"
		endif
	endif
END


Function V_AverageIntensity() : GraphMarquee		//030505 show coordinate module

	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	GetMarquee left, bottom
	if (V_Flag == 0)
		Print "There is no marquee"
	else
		Variable windowtype=V9_checkWindowType(S_marqueeWin)
		if (windowtype==1)
			if (!DataFolderExists("Analysis"))
				V9_initializeAnalysisFolder()
			endif			
			wave/z ROIcoord2D=:Analysis:W_ROIcoord2D
			wave/z ROIsize2D=:Analysis:W_ROIsize2D

					
			ROIcoord2D={{V_Left,V_bottom}, {V_right,V_top}}
			//V9_correctROIcoord(ROIcoord2D,windowtype,isPosition)			<-- this is for the 2D hist
			ROIsize2D=ROIcoord2D[p][1]-ROIcoord2D[p][0]
			wave  img_w=$V9_returnSrcwave(3)
			variable AvInt,IntSD
			Imagestats/G={ROIcoord2D[0][0],ROIcoord2D[0][1],ROIcoord2D[1][0],ROIcoord2D[1][1]} img_w
			printf "Average Intensity: %g ±%g\r", V_avg,V_sdev
			printf "Min %g  Max %g",V_min,V_max
		else
			setdatafolder "root:"
			abort "Select vector field window!"
		endif
	endif
END