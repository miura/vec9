#pragma rtGlobals=1		// Use modern global access method.

#include "Vec9_NoiseRemove"
#include "Vec9_SimuAnal"

//******** windownames**************************

Function/S VectorFieldWindowName()
	SVAR wavename_pref
	NVAR LayerStart,LayerEnd,Unit//,Averaging,Scale
	String VecWin=("VecField_"+wavename_pref+"S"+num2str(LayerStart)+"E"+num2str(LayerEnd)+"U"+num2str(Unit))//+"Avge"+num2str(Averaging)//+"Sc"+num2str(Scale))

	Return VecWin
END

Function/S V_listALLVecWindow()
	String WindowMatching=Winlist("VecField_*",";","")
	return WindowMatching
END

Function/S V_rtnFolderNameFromVecWIn(VecWinName)
	String VecWinName
	String FolderName=VecWinName[9,(strlen(VecWinName)-1)]
	return FolderName
END

//
Function V_WindowExists(graphtype)	//030730		//8 VA, 9 IntA, 10 Vint
	variable graphtype
	String V_WinName=HistWinName(graphtype)
	String WindowMatching=Winlist(V_WinName,";","")
	
	if (WhichListItem(V_WinName, WindowMatching)!=(-1))
		return 1
	else
	 	return 0
	endif
END

Function V_VecWindowExists()	//030730		//8 VA, 9 IntA, 10 Vint
	String V_WinName=VectorFieldWindowName()
	String WindowMatching=Winlist(V_WinName,";","")
	
	if (WhichListItem(V_WinName, WindowMatching)!=(-1))
		return 1
	else
	 	return 0
	endif
END

//************local version************
Function/S VectorFieldWindowName_L(wavename_pref,LayerStart,LayerEnd,Unit)
	STRING wavename_pref
	VARIABLE LayerStart,LayerEnd,Unit//,Averaging,Scale
	String VecWin=("VecField_"+wavename_pref+"S"+num2str(LayerStart)+"E"+num2str(LayerEnd)+"U"+num2str(Unit))//+"Avge"+num2str(Averaging)+"Sc"+num2str(Scale))

	Return VecWin
END 


Function/S SimWindowName()	//030521
	SVAR wavename_pref
	NVAR LayerStart,LayerEnd,Unit//,Averaging,Scale
	String SimWin=("FlowSim_"+wavename_pref+"S"+num2str(LayerStart)+"E"+num2str(LayerEnd)+"U"+num2str(Unit))
	Return SimWin
END

//******** Graph texts

Function/s V_CoordinateInfo()		// from current folder 030729
	String AbsoluteOrRelative
	NVAR/z Dest_X,Dest_Y
	NVAR/z isPosition			
	if (isPosition==0)
		AbsoluteOrRelative="\Z08Absolute"
	else
		AbsoluteOrRelative="\Z08Relative("+num2str(Dest_X)+","+num2str(Dest_Y)+")"
	endif
	return AbsoluteOrRelative
END

//**********************

Function/S HistWinName(param)
	Variable Param	// 0=mag, 1=rad, 2=deg, 3=roi mag, 4= roi deg 5 = speed ranged 6= Noise Removed Hist 7= Noise Removed Hist Roi
					// 8=2DVel_Anglehist 9=2Dbrightness_Anglehist 10=2DVel_Brightnesshist 
	SVAR	wavename_pref
	NVAR	LayerStart,LayerEnd,Unit
	String Appendage="_mag"
	Switch (param)
		Case 0:
			Appendage="_mag"
			break
		case 1:
			appendage="_rad"
			break
		case 2:
			Appendage="_deg"
			break
		case 3:
			Appendage="_magROIWIN"
			break
		case 4:
			Appendage="_degROIWIN"
			break
		case 5:
			Appendage="_degRangeWIN"
			break
		case 6:
			Appendage="_magDeNoise"
			break
		case 7:
			Appendage="_magDeNoiseROI"
			break
		case 8:
			Appendage="_2DVA"
			break
		case 9:
			Appendage="_2DIntA"
			break
		case 10:
			Appendage="_2DVInt"
			break
		case 11:
			Appendage="_RoughDeg"		//030123 for the VEC9_TriDirection_Histo() @Vec9_anal3.ipf
			break
		case 12:	
			Appendage="_FrcMag"		//030812
			break
		case 13:	
			Appendage="_FrcDeg"		//030812
			break
		case 14:
			Appendage="_FrcRoughDeg"		//030812 
			break
		case 15:
			Appendage="_FrcBinaryDeg"		//05011
			break
		default:
			break
	endswitch
	
	String HisWinName=(wavename_pref+"S"+num2str(LayerStart)+"E"+num2str(LayerEnd)+"U"+num2str(Unit)+appendage)
	Return HisWinName
END

//*** this van later be integrated to VEC_graphs.ipf --> moved from 2Dhist.ipf 030505
Function/S V9_2DHistWinName(param)
	Variable Param	// 0=2DVelocity vs angle, 1=2D Intensity vs angle, 2=Velocity vs Intensity
	SVAR	wavename_pref
	NVAR	LayerStart,LayerEnd,Unit
	String Appendage="_mag"
	Switch (param)
		Case 0:
			Appendage="_2DVA"
			break
		case 1:
			appendage="_2DIntA"
			break
		case 2:
			Appendage="_2DVInt"
			break
		default:
			break
	endswitch
	
	String HisWinName=(wavename_pref+"S"+num2str(LayerStart)+"E"+num2str(LayerEnd)+"U"+num2str(Unit)+appendage)
	Return HisWinName
END

//*******************WINDOW CHECKER ************************** (moved from 2Dhist_anal.ipf 030505)
// this must be updated, to be able to designate all types using loop.
Function V9_checkWindowType(marqueeWin)		//S_marqueeWin	
	String marqueeWin
	String VecField=VectorFieldWindowName()
	String hist2DVA=V9_2DHistWinName(0)
	String hist2DIntA=V9_2DHistWinName(1)
	String hist2DVInt=V9_2DHistWinName(2)
	Variable Windowtype=0
	if (cmpstr(marqueeWin,VecField)==0)
		Windowtype=1
	else
		if (cmpstr(marqueeWin,hist2DVA)==0)
			Windowtype=2
		else
			if (cmpstr(marqueeWin,hist2DIntA)==0)
				Windowtype=3
			else
				if (cmpstr(marqueeWin,hist2DVInt)==0)
					Windowtype=4
				endif
			endif
		endif
	endif
	return Windowtype
END

//*********** For a flexible bin width ********************

Function InitGraphParameters()		//new 020416
	String curDF=GetDataFolder(1)
	if (DataFolderExists(":GraphParameters"))
		SetDataFolder :GraphParameters
	else
		NewDataFolder/O/S :GraphParameters
		//print "new data folder made for graphing"
	endif

	NVAR/z G_binwidth
	if (NVAR_exists(G_binwidth)==0)		
		Variable/G G_binwidth=0.1
	endif
	
	NVAR/z G_binwidthFlow			//030812 for "Work" graph
	if (NVAR_exists(G_binwidthFlow)==0)		
		Variable/G G_binwidthFlow=20
	endif
	NVAR/z	G_noisemethod
	if (NVAR_exists(G_noisemethod)==0)		
		Variable/G G_noisemethod=0			//method for Noise Removal. 0= Fitting, 1=sampling
	endif		

	if (waveexists(W_ROIcoord)==0)		
		Make/N=(2,2) W_ROIcoord
		W_ROIcoord=0
	endif
	if (waveexists(W_ROISize)==0)		
		Make/N=2 W_ROIsize
		wave/z imagematrix=::VX
		W_ROIsize[]=DimSize(imagematrix,p)
	endif
//	V9_setROIfilterCore()		//commented out 030725
	V9_createROIfilterCore()
//	variable i
//	for (i=0;i<5;i+=1)
//		 V3_createFilterCore(i)
//	endfor
	 V9_createFilterCore(0)	//filter2D

	if (waveexists(W_VelRange)==0)		
		Make/N=(2) W_VelRange
		W_VelRange[0]=0
		W_VelRange[1]=5
	endif
	if (waveexists(W_AngleRange)==0)		
		Make/N=(2) W_AngleRange
		W_AngleRange[0]=-180
		W_AngleRange[1]=180
	endif	
//	if (waveexists(W_ThetaRange)==0)		
//		Make/N=(2) W_ThetaRange
//		W_ThetaRange[0]=0
//		W_ThetaRange[1]=360
//	endif
	if (waveexists(W_IntRange)==0)		
		Make/N=(2) W_IntRange
		W_IntRange[0]=0
		W_IntRange[1]=255
	endif

	NVAR/z G_checkVel
	if (NVAR_exists(G_checkVel)==0)		//followings are for the FilterPanel		
		Variable/G G_checkVel=0
	endif
	NVAR/z G_checkAngle
	if (NVAR_exists(G_checkAngle)==0)		
		Variable/G G_checkAngle=0
	endif
	
	NVAR/z G_checkAngleNOT			//for excluding the defined range 030729
	if (NVAR_exists(G_checkAngleNOT)==0)		
		Variable/G G_checkAngleNOT=0
	endif	
	
	NVAR/z G_checkAngleMAX			// 030726 for switching the angle range 0-360 and -180-+180
	if (NVAR_exists(G_checkAngleMAX)==0)		
		Variable/G G_checkAngleMAX=360
	endif

	NVAR/z G_checkAngleMIN			// 030726 
	if (NVAR_exists(G_checkAngleMIN)==0)		
		Variable/G G_checkAngleMIN=0
	endif
			
//	NVAR/z G_checkTheta
//	if (NVAR_exists(G_checkTheta)==0)		
//		Variable/G G_checkTheta=0
//	endif
	NVAR/z G_checkInt
	if (NVAR_exists(G_checkInt)==0)		
		Variable/G G_checkInt=0
	endif
	NVAR/z G_checkRoi
	if (NVAR_exists(G_checkRoi)==0)		
		Variable/G G_checkRoi=0
	endif
	NVAR/z G_check2Dstat
	if (NVAR_exists(G_check2Dstat)==0)	//030525	
		Variable/G G_check2Dstat=0
	endif 
	NVAR/z G_checkFilterVecDisplay
	if (NVAR_exists(G_checkFilterVecDisplay)==0)	//030526		
		Variable/G G_checkFilterVecDisplay=0
	endif
	NVAR/z G_checkFiltering
	if (NVAR_exists(G_checkFiltering)==0)	//030526		
		Variable/G G_checkFiltering=0//G_checkVel+G_checkPhai+G_checkTheta+G_checkInt
	endif
	NVAR/z G_checkScale
	if (NVAR_exists(G_checkScale)==0)	//030527		
		Variable/G G_checkScale=0
	endif
	NVAR/z G_checkAveraging
	if (NVAR_exists(G_checkAveraging)==0)	//030527		
		Variable/G G_checkAveraging=0
	endif
	NVAR/z G_checkImgMask
	if (NVAR_exists(G_checkImgMask)==0)	//030527		
		Variable/G G_checkImgMask=0
	endif
	SVAR/z S_ImgMaskName
	if (SVAR_exists(S_ImgMaskName)==0)	//030527		
		String/G S_ImgMaskName="-"
	endif

	NVAR/z G_checkPrintHist				//030730
	if (NVAR_exists(G_checkPrintHist)==0)		
		Variable/G G_checkPrintHist=0
	endif
	
	NVAR/z G_checkSinglePixRemove				//030730
	if (NVAR_exists(G_checkSinglePixRemove)==0)		
		Variable/G G_checkSinglePixRemove=0
	endif	
	
	NVAR/z G_ContinuumRange				//030730
	if (NVAR_exists(G_ContinuumRange)==0)		
		Variable/G G_ContinuumRange=5
	endif
	
	NVAR/z G_backgroundIntensity			//030812 for "Work" graph
	if (NVAR_exists(G_backgroundIntensity)==0)		
		Variable/G G_backgroundIntensity=0
	endif	

	NVAR/z G_speedfactor			//040110 
	if (NVAR_exists(G_speedfactor)==0)		
		Variable/G G_speedfactor=1
	endif				
	
	
													
//	NVAR/z G_checkZAveraging
//	if (NVAR_exists(G_checkZAveraging)==0)	//030527		
//		Variable/G G_checkZAveraging=0
//	endif
//	NVAR/z G_checkFlowSubtraction	
//	if (NVAR_exists(G_checkFlowSubtraction)==0)	//030528		
//		Variable/G G_checkFlowSubtraction=0
//	endif		
			
	SetDataFolder curDF
End


Function GetBinWidth()	//new 020416
	SettingDataFolder(WaveRefIndexed("",0,1)) 
	variable binwidth
	if (DataFolderExists(":GraphParameters"))
		NVAR M_binwidth= :GraphParameters:G_binwidth
		binwidth=M_binwidth	
	else
		binwidth=0.25
		InitGraphParameters()
	endif
	prompt binwidth, "Velocity histogram bin width?"
	DoPrompt "Set Histogram Bin Parameter",binwidth
	if (V_flag)
		Abort "Processing Canceled"
	endif
	NVAR L_binwidth=:GraphParameters:G_binwidth
	L_binwidth=binwidth

END

Function GetBinWidthFlow()	// 030812
	SettingDataFolder(WaveRefIndexed("",0,1)) 
	variable binwidth
	if (DataFolderExists(":GraphParameters"))
		NVAR G_binwidthFlow= :GraphParameters:G_binwidthFlow
		binwidth=G_binwidthFlow	
	else
		binwidth=0.25
		InitGraphParameters()
		NVAR G_binwidthFlow= :GraphParameters:G_binwidthFlow
	endif
	prompt binwidth, "Velocity histogram bin width?"
	DoPrompt "Set Histogram Bin Parameter",binwidth
	if (V_flag)
		Abort "Processing Canceled"
	endif
	//NVAR L_binwidth=:GraphParameters:G_binwidth
	G_binwidthFlow=binwidth

END


Function CheckGraphParametersF()
	SettingDataFolder(WaveRefIndexed("",0,1))
	if (DataFolderExists(":GraphParameters"))
		
	else
		InitGraphParameters()	
	endif
END

//*********************************************************

// Find Out the Index Number of a specific Trace			020327

Function TraceIndex(TargetTraceName)
	String TargetTraceName
	String list = TraceNameList("", ";", 1)
	String TraceName
	Variable index = 0
	do
		TraceName = StringFromList(index, list)
		if (strlen(traceName) == 0)
			break		// No more traces.
		endif
		if (cmpstr(TraceName,TargetTraceName)==0)
			break
		endif
		index += 1
	while(1)	
	print index
	return index
End	

Function TraceNumber()				//returns the number of traces in the graph 
	String list = TraceNameList("", ";", 1)
	String TraceName
	Variable index = 0
	do
		TraceName = StringFromList(index, list)
		if (strlen(traceName) == 0)
			break		// No more traces.
		endif
		index += 1
	while(1)	
	print (index)
	return (index)
End	

Function BringTheFrontTraceBottom()	//020327
	String FrontTrace
	String BottomTrace
	FrontTrace=WaveName("", (TraceNumber()-1), 1 )
	print FrontTrace
	BottomTrace=WaveName("", 0, 1 )
	print BottomTrace
	ReorderTraces $BottomTrace,{$FrontTrace}	
END
//***********Y scaling to 80% of the maximum bar in the histgram****************

Function Hist_Yscaling(HW)
	wave/z HW
	wavestats/Q HW
	SetAxis left 0, (V_max/0.8)
END
//****************************************	
Function TextBox_Hist_AllVecInfo(HW,HistWin,GraphType)
	wave/z HW
	string HistWin
	variable GraphType		//0=Speed; 1= Rad 2=Deg
	String AbsoluteOrRelative=V_CoordinateInfo()
	NVAR G_all_n=:analysis:G_all_n
	NVAR G_allSpeedAve=:analysis:G_allSpeedAve
	NVAR G_allSpeedSdev=:analysis:G_allSpeedSdev
	NVAR G_allAngleX_bar=:analysis:G_allAngleX_bar
	NVAR G_allAngleDeltaDeg=:analysis:G_allAngleDeltaDeg
	NVAR G_allAngleDispersion=:analysis:G_allAngleDispersion
	NVAR G_allAngleRvalue=:analysis:G_allAngleRvalue

	wavestats/Q HW	
	if ((GraphType==0) || (GraphType==12))
//		TextBox/W=$HistWin/C/N=AllVecInfo/A=RT AbsoluteOrRelative+"\Z08\rAvg="+num2str(V_avg)+" ±"+num2str(V_sdev)+" Pts="+num2str(V_npnts)+" cAvg="+num2str(VelNoiseRemovedAV(6))+" cPnts="+num2str(nonNoisePnts(6))  //new 020902
		TextBox/W=$HistWin/C/N=AllVecInfo/A=RT AbsoluteOrRelative+"\Z08\rAvg="+num2str(V_avg)+" ±"+num2str(V_sdev)+" Pts="+num2str(V_npnts) //new 020902	//041213 noise info removed
		G_allSpeedAve=V_avg
		G_allSpeedSdev=V_sdev
		G_all_n=V_npnts
	else
		CircularStatistics2D(HW,graphtype) // 2 or 13
		NVAR/z X_bar,delta_deg,r_value,dispersion_s_deg			
		TextBox/W=$HistWin/C/N=AllVecInfo/A=RT AbsoluteOrRelative+"\Z08\rAvg="+num2str(X_bar)+" ±"+num2str(delta_deg)+" Pts="+num2str(V_npnts)+" AD="+num2str(round(dispersion_s_deg))+" r:"+num2str(r_value)//new 030119
		G_allAngleX_bar=X_bar
		G_allAngleDeltaDeg=delta_deg
		G_allAngleDispersion=dispersion_s_deg
		G_allAngleRvalue=r_value
	endif
	TextBox/C/N=AllVecInfo/A=LB/F=0/X=-10.00/Y=-38.00
	if (DataFolderExists("GraphParameters"))
//		NVAR hist2DMask_ON=:analysis:hist2DMask_ON			
//		if (hist2DMask_ON)
//			NVAR windowtype=:analysis:V_windowtype
//			wave/z ROIcoord=:analysis:W_ROIcoord2D
//			switch (windowtype)
//				case 2:
//					TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08Velocity "+num2str(ROIcoord[1][0])+"~"+num2str(ROIcoord[1][1])+"\rAngle "+num2str(ROIcoord[0][0])+"~"+num2str(ROIcoord[0][1])  //new 020902
//					break						
//				case 3:
//					TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08Intensity "+num2str(ROIcoord[1][0])+"~"+num2str(ROIcoord[1][1])+"\rAngle "+num2str(ROIcoord[0][0])+"~"+num2str(ROIcoord[0][1])  //new 020902
//					break
//				case 4:
//					TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08Velocity "+num2str(ROIcoord[1][0])+"~"+num2str(ROIcoord[1][1])+"\rIntensity "+num2str(ROIcoord[0][0])+"~"+num2str(ROIcoord[0][1])  //new 020902
//					break
//				default:
//					TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08"+"No Filtering"//new 020902
//				endswitch
//		else
//			TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08"+"No Filtering"//new 020902
//		endif
		NVAR/z  G_checkVel=:GraphParameters:G_checkVel
		NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
		NVAR/z G_checkAngleNOT=:GraphParameters:G_checkAngleNOT
		NVAR/z G_checkInt=:GraphParameters:G_checkInt
		NVAR G_checkImgMask=:GraphParameters:G_checkImgMask
		NVAR/z G_checkRoi=:GraphParameters:G_checkRoi	
		NVAR/z G_checkSinglePixRemove=:GraphParameters:G_checkSinglePixRemove
		SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName
		NVAR/z G_ContinuumRange=:GraphParameters:G_ContinuumRange

		wave/z wV=:GraphParameters:W_VelRange
		wave/z wA=:GraphParameters:W_AngleRange
		wave/z wI=:GraphParameters:W_IntRange
		wave/z wR=:GraphParameters:W_ROIcoord
		
		String V_txt,A_txt,A0_txt,I_txt,Mask_txt,ROI_txt,SPR_txt
		if (G_checkVel==1)
			V_txt=num2str(wV[0])+" - "+num2str(wV[1])
		else
			V_txt="all"
		endif
		if (G_checkAngle==1)
			if (wA[1]>0)
				A_txt=num2str(wA[0])+" - +"+num2str(wA[1])
			else
				A_txt=num2str(wA[0])+" - "+num2str(wA[1])
			endif
			if (G_checkAngleNOT==1)
				A0_txt="   Angle exclude: "
			else
				A0_txt="   Angle: "
			endif			
		else
			A0_txt="   Angle: "		
			A_txt="all"
		endif
		if  (G_checkInt==1)
			I_txt=num2str(wI[0])+" - "+num2str(wI[1])
		else	
			I_txt="all"
		endif
		if (G_checkImgMask==1) 
			Mask_txt="\Z08"+"Image Mask: "+S_ImgMaskName
		else
			Mask_txt="\Z08"+"No Image Mask Applied"
		endif
		
		if (G_checkRoi==1)
			ROI_txt="  ROI:"+num2str(wR[0][0])+","+num2str(wR[1][0])+","+num2str(wR[0][1])+","+num2str(wR[1][1])+"\r"
		else
			ROI_txt="  no ROI"+"\r"
		endif
		
		if (G_checkSinglePixRemove==1)
			SPR_txt="\Z08 1 Pix Signal Remove- range:±"+num2str(G_ContinuumRange)
		else
			SPR_txt="\Z08 no Single Pix Remove"
		endif
			
		TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08Velocity: "+V_txt+A0_txt+A_txt+"\rIntensity: "+I_txt+"   "+Mask_txt+ROI_txt+SPR_txt  //030729
	else
		TextBox/W=$HistWin/C/N=FilterInfo/A=RT "\Z08"+"No Filtering"//new 020902
	endif			 
	TextBox/C/N=FilterInfo/A=LB/F=0/X=-10.00/Y=-65.00

// commented out 030729	
//	if (DataFolderExists("Analysis"))
//		NVAR ImageMask_ON=:analysis:ImageMask_ON
//		if (ImageMask_ON)
//			SVAR S_maskingName=:analysis:S_maskingName
//			TextBox/W=$HistWin/C/N=MaskInfo/A=RT "\Z08"+"Image Mask: "+S_maskingName//new 020902	
//		else
//			TextBox/W=$HistWin/C/N=MaskInfo/A=RT "\Z08"+"No Image Mask Applied"//new 020902	
//		endif
//	else
//		TextBox/W=$HistWin/C/N=MaskInfo/A=RT "\Z08"+"No Image Mask Applied"//new 020902	
//	endif
//	TextBox/C/N=MaskInfo/A=LB/F=0/X=-10.00/Y=-70.00
END
//**********************************
Function TextBox_Hist_AveragedInfo(HW,HistWIn,GraphType)
	wave/z HW
	string HistWin
	variable GraphType
	NVAR Averaging

	NVAR G_AV_n=:analysis:G_AV_n
	NVAR G_AVSpeedAve=:analysis:G_AVSpeedAve
	NVAR G_AVSpeedSdev=:analysis:G_AVSpeedSdev
	NVAR G_AVAngleX_bar=:analysis:G_AVAngleX_bar
	NVAR G_AVAngleDeltaDeg=:analysis:G_AVAngleDeltaDeg
	NVAR G_AVAngleDispersion=:analysis:G_AVAngleDispersion
	NVAR G_AVAngleRvalue=:analysis:G_AVAngleRvalue
		
	wavestats/Q HW
	if (Graphtype==0)
		TextBox/W=$HistWin/C/N=AverageInfo/A=LT "\Z08Fav- "+num2str(Averaging)+" avAvg="+num2str(V_avg)+" ±"+num2str(V_sdev)+" avPts="+num2str(V_npnts)  //020902
		G_AVSpeedAve=V_avg
		G_AVSpeedSdev=V_sdev
		G_AV_n=V_npnts
	else
		CircularStatistics2D(HW,GraphType)
		NVAR/z X_bar,delta_deg,r_value,dispersion_s_deg			
		TextBox/W=$HistWin/C/N=AverageInfo/A=LT "\Z08Fav- "+num2str(Averaging)+" avAvg="+num2str(X_bar)+" ±"+num2str(delta_deg)+" avPts="+num2str(V_npnts)+" AD="+num2str(round(dispersion_s_deg))+" r:"+num2str(r_value)  //020902
		G_AVAngleX_bar=X_bar
		G_AVAngleDeltaDeg=delta_deg
		G_AVAngleDispersion=dispersion_s_deg
		G_AVAngleRvalue=r_value	
	endif		
	TextBox/C/N=AverageInfo/A=LB/F=0/X=-10.00/Y=-45.00
END
//**********************************
Function TextBox_Hist_RoiInfo(HW,HistWIn,GraphType) 
	wave/z HW
	string HistWin
	Variable Graphtype
//	Variable left,right,top,bottom
	wave/z ROIcoord=:GraphParameters:W_ROIcoord
	Variable Left=ROIcoord[0][0]
	Variable Bottom=ROIcoord[1][0]
	Variable Right=ROIcoord[0][1]
	Variable Top=ROIcoord[1][1]			
	NVAR Averaging,isPosition
	String AbsoluteOrRelative=V_CoordinateInfo()

	if (GraphType==0)
		Wavestats/Q HW
		TextBox/W=$HistWin/C/N=infos/A=RB/X=0.00/Y=-50.00 AbsoluteOrRelative+"\rAvg="+num2str(V_avg)+"\r±"+num2str(V_sdev)+"\rPts="+num2str(V_npnts)+"\rcAvg="+num2str(VelNoiseRemovedAV(7))+"\rcPnts="+num2str(nonNoisePnts(7))
	else
		Wavestats/Q HW
		CircularStatistics2D(HW,0)  //0 means the wave is in deg
		NVAR/z X_bar,delta_deg,r_value,dispersion_s_deg	
		TextBox/W=$HistWin/C/N=infos/A=RB/X=0.00/Y=-50.00 AbsoluteOrRelative+"\rAvg="+num2str(X_bar)+"\r±"+num2str(delta_deg)+"\rPts="+num2str(V_npnts) //+"\rcAvg="+num2str(VelNoiseRemovedAV(7))+"\rcPnts="+num2str(nonNoisePnts(7))
	endif
	TextBox/W=$HistWin/C/N=Position/A=LT/X=20.00/Y=-5.00 "\Z07position=("+num2str(left)+","+num2str(right)+","+num2str(top)+","+num2str(bottom)+")"


END

//**********************************

Function TextBox_Hist_RoiAVInfo(HW,HistWIn,Graphtype) 
	wave/z HW
	string HistWin
	Variable Graphtype
	NVAR Averaging
	WaveStats/Q HW
	//TextBox/W=$HistWin/C/N=AVinfos/A=LT "\Z07Fav- "+num2str(Averaging)+"\rAvg="+num2str(V_avg)+"\r±"+num2str(V_sdev)+"\rPts="+num2str(V_npnts)
	if (GraphType==0)
		Wavestats/Q HW
		TextBox/W=$HistWin/C/N=AVinfos/A=LB/X=0.00/Y=-50.00 "\Z07Fav- "+num2str(Averaging)+"\rAvg="+num2str(V_avg)+"\r±"+num2str(V_sdev)+"\rPts="+num2str(V_npnts)
	else
		Wavestats/Q HW
		CircularStatistics2D(HW,0)
		NVAR/z X_bar,delta_deg,r_value,dispersion_s_deg	
		TextBox/W=$HistWin/C/N=AVinfos/A=LB/X=0.00/Y=-50.00 "\Z07Fav- "+num2str(Averaging)+"\rAvg="+num2str(X_bar)+"\r±"+num2str(delta_deg)+"\rPts="+num2str(V_npnts)
	endif
END

//030813
Function TextBox_ForceRoughHist_Info()
	NVAR G_AwayForce=:analysis:G_AwayForce
	NVAR G_AwayForceRatio=:analysis:G_AwayForceRatio
	NVAR G_NormalForce=:analysis:G_NormalForce
	NVAR G_NormalForceRatio=:analysis:G_NormalForceRatio
	NVAR G_TowardsForce=:analysis:G_TowardsForce
	NVAR G_TowardsForceRatio=:analysis:G_TowardsForceRatio

	NVAR G_AwayFlow=:analysis:G_AwayFlow
	NVAR G_AwayFlowRatio=:analysis:G_AwayFlowRatio
	NVAR G_TowardsFlow=:analysis:G_TowardsFlow
	NVAR G_TowardsFlowRatio=:analysis:G_TowardsFlowRatio
	NVAR G_NormalFlow=:analysis:G_NormalFlow
	NVAR G_NormalFlowRatio	=:analysis:G_NormalFlowRatio		
	
	String Text
	String TextAway,TextNormal,TextTowards
	textAway="\Z07Away: Ave.Speed"+num2str(G_AwayFlow)+" ("+num2str(G_AwayFlowRatio)+")"+ "  Flow Rate: "+num2str(G_AwayForce)+"    ("+num2str(G_AwayForceRatio)+")\r"
	textNormal="Normal: Ave.Speed"+num2str(G_NormalFlow)+" ("+num2str(G_NormalFlowRatio)+")"+ "  Flow Rate: "+num2str(G_NormalForce)+"    ("+num2str(G_NormalForceRatio)+")\r"
	textTowards="Towards: Ave.Speed"+num2str(G_TowardsFlow)+" ("+num2str(G_TowardsFlowRatio)+")"+ "  Flow Rate: "+num2str(G_TowardsForce)+"    ("+num2str(G_TowardsForceRatio)+")"

//	text="\Z08Away: "+num2str(G_AwayForce)+"    ("+num2str(G_AwayForceRatio)+")" +"\rNormal: "+num2str(G_NormalForce)+"    ("+num2str(G_NormalForceRatio)+")" +"\rTowards: "+num2str(G_TowardsForce)+"    ("+num2str(G_TowardsForceRatio)+")"
	text=TextAway+TextNormal+TextTowards
	DoWindow/F $HistWinName(14)
	TextBox/W=$HistWinName(14)/C/N=ForceInfo/A=MB text
	TextBox/W=$HistWinName(14)/C/N=ForceInfo/F=0/X=-10.00/Y=-50.00
	print text
	
END
//**********************************

//graph type 0 or 12
Function SpeedHistShow(VecLengthWave,VecLengthWaveHIST,Graphtype)
	Wave/Z VecLengthWave,VecLengthWaveHIST
	variable Graphtype
	String L_Windowname
	String histname=NameOfWave(VecLengthWaveHIST)
	print HistWinName(Graphtype)
	Display /W=(500,50,750,300) ,VecLengthWaveHIST
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph nticks(bottom)=10
	ModifyGraph minor(bottom)=1
	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
	String LabelLeft="vector (\\s("+histname+")all)"
	Label left LabelLeft
	if (Graphtype==12)
		Label bottom "Flow [Velocity · Intensity]"
	else
		Label bottom "Speed [arb]"
	endif
	ModifyGraph margin(bottom)=100
	ModifyGraph lblMargin(bottom)=70
	SetAxis/A/N=1 left
	DoWindow/C $HistWinName(Graphtype)
	TextBox_Hist_AllVecInfo(VecLengthWave,HistWinName(Graphtype),Graphtype)
End

//**************
Function GradHistShow(GradWave,GradWaveHIST,Graphtype)
	Wave GradWave,GradWaveHIST
	variable Graphtype
	//String Windowname
	print HistWinName(Graphtype)		
	Display /W=(500,320,750,570) GradWaveHIST
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph nticks(bottom)=10
	ModifyGraph minor(bottom)=1
	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
	if (graphtype==13)
		Label left "Flow Rate [proteins/sec]"
	else
		Label left "vector"
	endif
	Label bottom "Angle [deg]"
	ModifyGraph zero(bottom)=1
	ModifyGraph margin(bottom)=100
	ModifyGraph lblMargin(bottom)=70
	SetAxis/A/N=1 left
	DoWindow/C $HistWinName(Graphtype)
	TextBox_Hist_AllVecInfo(GradWave,HistWinName(Graphtype),Graphtype)
	//Hist_Yscaling(GradWaveHIST)
End

//*****************
Function RadHistShow(RadWave,RadWaveHIST)
	Wave RadWave,RadWaveHIST
	String Windowname
	NVAR unit,LayerStart,LayerEnd,averaging,scale//,V_avg,V_sdev,V_npnts
	SVAR wavename_pref
		
	Display /W=(250,320,500,570) RadWaveHIST
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph nticks(bottom)=10
	ModifyGraph minor(bottom)=1
	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
	Label left "vector"
	Label bottom "Angle [rad]"
	ModifyGraph zero(bottom)=1
	SetAxis/A/N=1 left
	ModifyGraph margin(bottom)=100
	ModifyGraph lblMargin(bottom)=70

	DoWindow/C $HistWinName(1)
	TextBox_Hist_AllVecInfo(RadWave,HistWinName(1),1)
	Hist_Yscaling(RadWaveHIST)
End

//*******************
Function AppendAveragedVector(AveragedVector,param)
	Wave/z AveragedVector
	Variable Param
	String L_WaveName=nameofwave(Averagedvector)+"H"
	Wave/z AveragedvectorH=$L_wavename
	AppendToGraph AveragedVectorH
	ModifyGraph rgb($L_WaveName)=(0,0,65280)
	ModifyGraph mode=5
	TextBox_Hist_AveragedInfo(AveragedVector,HistWinName(param),param)
END
//**********************************

Function ROISpeedHistShow(VecLengthWave,VecLengthWaveHIST)
	Wave/Z VecLengthWave,VecLengthWaveHIST
	String histname=NameOfWave(VecLengthWaveHIST)
	Display /W=(600,50,850,300) ,VecLengthWaveHIST
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph nticks(bottom)=10
	ModifyGraph minor(bottom)=1
	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
	String LabelLeft="vector (\\s("+histname+")all)"
	Label left LabelLeft
	//Label left "vector"
	Label bottom "Speed [arb]"
	ModifyGraph margin(bottom)=90
	SetAxis/A/N=1 left
	NVAR isPosition
//	if (isPosition)
//		SetAxis bottom -190,190 
//	else
//		SetAxis bottom -10,370 
//	endif
	String ROI_magHwin=HistWinName(3)
	DoWindow/C $ROI_magHwin
End

//**************
Function RoiGradHistShow(GradWave,GradWaveHIST)
	Wave GradWave,GradWaveHIST
	String Windowname
		
	Display /W=(600,320,850,570) GradWaveHIST
	ModifyGraph mode=5
	ModifyGraph lSize=2
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph mirror=2
	ModifyGraph nticks(bottom)=10
	ModifyGraph minor(bottom)=1
	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
	Label left "vector"
	Label bottom "Angle [deg]"
	ModifyGraph zero(bottom)=1
	ModifyGraph margin(bottom)=90
	SetAxis/A/N=1 left
	
	//Hist_Yscaling(GradWaveHIST)
	String ROI_degHwin=HistWinName(4)
	DoWindow/C $ROI_degHwin
End

//*****************************************
Function AppendAveragedVectorROI(w_av,w_avH,param)	//w_av = deg or mag
	Wave/z w_av,w_avH
	Variable Param
	String name_w
	//String name_w_avH="ROI_"+nameofwave(w_av)
	//Wave/z AveragedvectorH=$L_wavename
	name_w=nameofwave(w_avH)
	AppendToGraph w_avH
	ModifyGraph rgb($name_w)=(0,0,65280)
	ModifyGraph mode=5
	//TextBox_Hist_AveragedInfo(w_av,HistWinName(param))
END

//******

//**************


Function TriHistGradHistShow(GradWave,GradWaveHIST,Textwave)
	Wave GradWave,GradWaveHIST,TextWave
	String Windowname
		
	Display /W=(250,320,500,570) GradWaveHIST vs Textwave
//	ModifyGraph mode=5
//	ModifyGraph lSize=2
//	ModifyGraph tick=2
//	ModifyGraph zero(bottom)=1
//	ModifyGraph mirror=2
//	ModifyGraph nticks(bottom)=10
//	ModifyGraph minor(bottom)=1
//	ModifyGraph sep(bottom)=2
	ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
	ModifyGraph lblLatPos(left)=7
	Label left "vector"
	Label bottom "Direction"
	//ModifyGraph zero(bottom)=1
	ModifyGraph margin(bottom)=100
	ModifyGraph lblMargin(bottom)=70
	SetAxis/A/E=1/N=1 left
	ModifyGraph fSize(bottom)=8

	DoWindow/C $HistWinName(11)
	TextBox_Hist_AllVecInfo(GradWave,HistWinName(11),2)
	//Hist_Yscaling(GradWaveHIST)
End


//**************************Utility
Function BringtheStatsForward()
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
 	if (WhichListItem(HistWinName(0), presentWindows)!=(-1))	
		DoWindow/F $HistWinName(0)	//mag
	else
		print "No Speed Stat Window. should do the stat again!"	
	endif
 	if (WhichListItem(HistWinName(2), presentWindows)!=(-1))	
		DoWindow/F $HistWinName(2)	//deg
	else
		print "No Angle Stat Window. should do the stat again!"	
	endif
	SetDataFolder curDF	
	
END

//**************************
Function KillRelatedWindows()
	String curDF=GetDataFolder(1)
	SettingDataFolder(WaveRefIndexed("",0,1))
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
 	if (WhichListItem(HistWinName(0), presentWindows)!=(-1))	
		DoWindow/K $HistWinName(0)	//mag
	endif
	
	Variable i=2
	do
 		if (WhichListItem(HistWinName(i), presentWindows)!=(-1))	
			DoWindow/K $HistWinName(i)	//deg
		endif
 		i+=1
 	while (i<8)
	
SetDataFolder curDF	
	
END

//**************************
Function KillRoiStatWindows()
//	String curDF=GetDataFolder(1)
//	SettingDataFolder(WaveRefIndexed("",0,1))
	String presentWindows=WinList(("*ROIWIN"), ";", "" )
	Variable ItemNumber=ItemsInList(presentWindows)
	Variable i=0
	String HistWinN
	do
 		HistWinN=StringFromList(i,presentWindows)
			DoWindow/K $HistWinN
		i+=1
 	while (i<ItemNumber)
	
//SetDataFolder curDF	
	
END



//**** Unused 030806

//**********************************
//Function UpdateTextBox_Hist_RoiInfo(HW,HistWIn)//,left,right,top,bottom) 
//	wave/z HW
//	string HistWin
//	//Variable left,right,top,bottom
//	variable Left=:GraphParameters:W_ROIcoord[0][0]
//	variable Bottom=:GraphParameters:W_ROIcoord[1][0]
//	variable Right=:GraphParameters:W_ROIcoord[0][1]
//	variable Top=:GraphParameters:W_ROIcoord[1][1]	
//	NVAR Averaging,isPosition
//	String AbsoluteOrRelative=V_CoordinateInfo()
//	Wavestats/Q HW
//	TextBox/W=$HistWin/C/N=infos/A=RT AbsoluteOrRelative+"\rAvg="+num2str(V_avg)+"\r±"+num2str(V_sdev)+"\rPts="+num2str(V_npnts)+"\rcAvg="+num2str(VelNoiseRemovedAV(7))+"\rcPnts="+num2str(nonNoisePnts(7))
//	TextBox/C/N=infos/A=RB/X=0.00/Y=-50.00
//	TextBox/C/W=$HistWin/N=Position/A=LT/X=20.00/Y=-5.00 "\Z07position=("+num2str(left)+","+num2str(right)+","+num2str(top)+","+num2str(bottom)+")"
//END

//************* UNUSED anymore 

//// following graph creation macro was used in VecRangeByAVE() @anal2.ipf commented out 030729

//Function RangeGradHistShow(GradWave,GradWaveHIST)		//030729 to be unused
//	Wave GradWave,GradWaveHIST
//	String Windowname
//	//NVAR unit,LayerStart,LayerEnd,averaging,scale,gSpeed_Threshold//,V_avg,V_sdev,V_npnts
//	//SVAR wavename_pref
//	String Range_degHwin=HistWinName(5)
//	if (WhichListItem(HistWinName(5),WinList("*", ";", "" ))==-1)
//	
//		Display /W=(650,320,900,570) GradWaveHIST
//		ModifyGraph mode=5
//		ModifyGraph lSize=2
//		ModifyGraph tick=2
//		ModifyGraph zero(bottom)=1
//		ModifyGraph mirror=2
//		ModifyGraph nticks(bottom)=10
//		ModifyGraph minor(bottom)=1
//		ModifyGraph sep(bottom)=2
//		ModifyGraph lblMargin(left)=7,lblMargin(bottom)=6
//		ModifyGraph lblLatPos(left)=7
//		Label left "vector"
//		Label bottom "Angle [deg]"
//		ModifyGraph zero(bottom)=1
//		ModifyGraph margin(bottom)=90
//		SetAxis/A/N=1 left
//
//		DoWindow/C $Range_degHwin
//	else
//		DoWindow/F $Range_degHwin
//	endif
//	NVAR isPosition
//	if (isPosition==0)
//		SetAxis bottom 0,360
//	else
//		SetAxis bottom -180,180	
//	endif
//
//	//Hist_Yscaling(GradWaveHIST)
//
//End

////**********************************
//// following graph creation macro was used in VecRangeByAVE() @anal2.ipf commented out 030729
//
//Function TextBox_Hist_RangeInfo(HW) 
//	wave/z HW
//	string HistWin=HistWinName(5)
//	NVAR L_min=root:VectorFunctions:avVrange_min
//	NVAR L_max=root:VectorFunctions:avVrange_max
//	NVAR Averaging,isPosition
//	SVAR AbsoluteOrRelative
//	Wavestats/Q HW
//	TextBox/W=$HistWin/C/N=infos/A=RT AbsoluteOrRelative+"\rAvg="+num2str(V_avg)+"\rsd="+num2str(V_sdev)+"\rPts="+num2str(V_npnts)//+"\rThrshld="+num2str(gSpeed_Threshold)
//	TextBox/W=$HistWin/C/N=infos/A=RB/X=0.00/Y=-50.00
//	TextBox/W=$HistWin/C/N=Range/A=LT/X=0/Y=130 "\Z07Velocity Range=("+num2str(L_min)+" ~ "+num2str(L_max)+")"
//		
//END
