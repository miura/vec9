#pragma rtGlobals=1		// Use modern global access method.


//**************
Function NormalizeHistogram(w,Hw)
	Wave w,Hw
	Variable H_Pnts,H_Avg
	Wavestats/Q w
	H_Pnts=V_npnts
	Hw=Hw/H_Pnts
END

Function NormalizeHistogramNoStat(Hw)
	Wave Hw
	Variable H_total=0
	variable i
	for (i=0;i<numpnts(HW);i+=1)
		H_total+=HW[i]
	endfor
	Hw=Hw/H_total
END

//****************************************************************************
Function HistStatParameterInit()
	//String/G AbsoluteOrRelative="\Z08Absolute"
	NVAR/z isPosition
	if (NVAR_exists(isPosition)==0)
		variable/G isPosition=0
	endif
	NVAR/z Dest_X
	if (NVAR_exists(Dest_X)==0)
		Variable/G Dest_X=0
	endif
	NVAR/z Dest_Y
	if (NVAR_exists(Dest_Y)==0)
		Variable/G Dest_Y=0
	endif
END

//************************************************************************************************************
Function HistAnal() 
	SettingDataFolder(WaveRefIndexed("",0,1))
	//print Nameofwave(WaveRefIndexed("",0,1))
	//	setdatafolder root:
	Variable	parameter
	Prompt	parameter, "Measurement for", Popup "ALL; Angle (degrees); Angle (rad); Speed (arb.)" 
	Variable	Scale//=25
	Variable	Speed_threshold=0
	//Prompt	speed_threshold, "Speed Threholding at:"
	Variable isPositionL
	Prompt	isPositionL, "Angle against:", PopUp "Absolute coordinate (Screen); A Specific Position (a point)" 
//	DoPrompt "Choosing Parameters", parameter, speed_threshold, isPositionL//, Vector1D_name, NewGraph//,scale//,Grid1D_name,scale//,OverWrite_or_not
	DoPrompt "Choosing Parameters", parameter, isPositionL//, Vector1D_name, NewGraph//,scale//,Grid1D_name,scale//,OverWrite_or_not

	if (V_flag)
		Abort "Processing Canceled"
	endif
	NVAR/z isPosition
	if (NVAR_exists(isPosition)==0)
		HistStatParameterInit()
	endif
	NVAR Dest_X,Dest_Y
	Variable L_Dest_X,L_Dest_Y
//	SVAR windowname

	isPositionL=isPositionL-1
	if (isPositionL==1)
		Prompt L_Dest_X, "X position of the Reference Point"
		Prompt L_Dest_Y, "Y position of the Reference Point"
		DoPrompt "Input Reference Point", L_Dest_X, L_Dest_Y
		if (V_flag)
			Abort "Processing Canceled"
		endif
	else		//is Position=0
		L_Dest_X=0
		L_Dest_Y=0
	endif
	NVAR isPosition//=isPositionL
	isPosition=isPositionL
	
	Dest_X=L_Dest_X
	Dest_Y=L_Dest_Y

	//HistAnalCore(parameter,isPositionL,0) // is NOT filtered
	HistAnalCore()
	DoWindow/F $VectorFieldWindowName()
	setdatafolder root:
End

Function V9_histanal_DoBasic()
		//SettingDataFolder(WaveRefIndexed("",0,1))
	//V9_setMaskImagefunc_switch(0)	
	String CurrentPlot=VEC9_Set_CurrentPlotDataFolder()
	NVAR isPosition
	HistAnalCore() // is NOT filtered
	setdatafolder root:	
END



//*************************** Updated Versions 030806 *****************************
Function V_referencePointManage()		//030805
	NVAR isPosition,Dest_X,Dest_Y
	if (isPosition==0)
	//--- removing the reference point
		if ((WhichListItem("Dest_Ywave", (TraceNameList("",";",1)))) >=0)
			RemoveFromGraph Dest_Ywave
		endif
	//---------
	else
		//-------------make a dot at the destination
		Make/O/N=2 Dest_Xwave
		Make/O/N=2 Dest_Ywave
		Dest_Xwave=Dest_X
		//Dest_Xwave[1]=Dest_X	
		Dest_Ywave=Dest_Y
		//Dest_Ywave[1]=Dest_Y	
		DoWindow/F $VectorFieldWindowName()
		if ((WhichListItem("Dest_Ywave", (TraceNameList("",";",1)))) ==-1)
			//print TraceNameList("",";",1)
			AppendToGraph Dest_Ywave vs Dest_Xwave
			ModifyGraph mode(Dest_Ywave)=3,marker(Dest_Ywave)=1,msize(Dest_Ywave)=4,mrkThick(Dest_Ywave)=3
			ModifyGraph rgb(Dest_Ywave)=(32768,40704,65280)
		endif
		//---------------------------------------------------------
	endif
END

//030805
Function V_CalcRelativeAgle(LVX,LVY,Vwave,Rwave)
	wave LVX,LVY,Vwave,Rwave

	NVAR Dest_X,Dest_Y
	Duplicate/o LVX Destination_Vstart,Destination_Vend,temp_co,CosTheta,SDslope,SEslope,Evaluate_Y,Decision1,Decision2,Decision3//,ActualCoordinateX,ActualCoordinateY

	Destination_Vstart[][]=sqroot(Dest_X,Dest_Y,x,y) 
	Destination_Vend[][]=sqroot(Dest_X,Dest_Y,(x+LVX[p][q]),(y+LVY[p][q]))
	
	temp_co=Destination_Vstart*Vwave*2
	CosTheta=( (Destination_Vstart)^2+(Vwave)^2-(Destination_Vend)^2 )/temp_co
	Rwave=acos(CosTheta)
	
	SDslope[][]=((x==Dest_X) ? (99999) : ((Dest_Y-y) / (Dest_X-x)))
	SEslope[][]=(((x+LVX[p][q])==Dest_X) ? (99999) : ((Dest_Y-y-LVY[p][q] ) / (Dest_X-x-LVX[p][q])))
	Evaluate_Y[][]=SDslope[p][q] * (x+LVX[p][q]-Dest_X )+ Dest_Y

	
		// abs(1&&2 || !1&&!2) + 3 = (2+2)= 4 
		// abs(1&&!2 || !1&&2) + !3 = (0+-2) = (-2)
		//other possible answers for above: 0, 2 

	if (SDslope[p][q]==SEslope[p][q])
		Rwave[p][q]=( (Destination_Vend[p][q]>Destination_Vstart[p][q]) ? (3.1415) : (0) )
	else
		Decision1[][]=((SDslope[p][q]>0) ? 1:-1)
		Decision2[][]=((Dest_Y>y) ? 1:-1)
		Decision3[][]=(((Evaluate_Y[p][q])> (y+LVY[p][q])) ? 2:-2)

		Rwave[][]=(( (abs(Decision1[p][q]+Decision2[p][q])+Decision3)==4)? (Rwave[p][q]*(-1)) : (Rwave[p][q])) 
		Rwave[][]=(( (abs(Decision1[p][q]+Decision2[p][q])+Decision3)==(-2))? (Rwave[p][q]*(-1)) : (Rwave[p][q]))
	endif
	killwaves Destination_Vstart,Destination_Vend,temp_co,CosTheta,SDslope,SEslope,Evaluate_Y,Decision1,Decision2,Decision3
END

//030805
Function V_CalcAbsoluteAngle(LVX,tempVY,Vwave,Rwave)
	wave LVX,tempVY,Vwave,Rwave
//	Rwave[][]=acos(tempVY[p][q])/Vwave[p][q]
	Rwave[][]=acos(tempVY[p][q]/Vwave[p][q])
	Rwave[][]=((LVX[p][q] >0) ? (2*pi-Rwave[p][q]) : Rwave[p][q]) 	
	
END

//030805
Function V_CalculateAngle(isFiltered,isAveraged)
	Variable isFiltered,isAveraged
	
	wave LVX=$V_returnStatWavenames(isFiltered,isAveraged,0)
	wave LVY=$V_returnStatWavenames(isFiltered,isAveraged,1)
	wave Vwave=$V_returnStatWavenames(0,isAveraged,2)
	wave Rwave=$V_returnStatWavenames(0,isAveraged,3)
	wave Gwave=$V_returnStatWavenames(0,isAveraged,4)
	wave VwaveH=$V_returnStatWavenames(0,isAveraged,5)
	wave RwaveH=$V_returnStatWavenames(0,isAveraged,6)
	wave GwaveH=$V_returnStatWavenames(0,isAveraged,7)
	NVAR isPosition,Dest_X,Dest_Y
	
	V_referencePointManage()
	
	Duplicate LVX tempnull,tempVX
	Duplicate LVY tempVY
	tempnull[][]=0

	tempVX[][]=((tempVX[p][q]==Nan) ? (0) : (tempVX[p][q]) )
	tempVY[][]=((tempVY[p][q]==Nan) ? (0) : (tempVY[p][q]) )
	Vwave[][]=(sqroot(tempnull[p][q],tempnull[p][q],tempVX[p][q],tempVY[p][q]))
	Vwave[][]=((numtype(Vwave[p][q]) == 1) ? NaN :(Vwave[p][q]))			//* delete inf

	if (isPosition==0)
		V_CalcAbsoluteAngle(LVX,tempVY,Vwave,Rwave)
	else
		V_CalcRelativeAgle(LVX,LVY,Vwave,Rwave)
	endif


	Gwave[][]=((Rwave[p][q]!=Nan) ? (Rwave[p][q]/2/3.1415*360): (Nan))

	killwaves tempnull,tempVX,tempVY

	wavestats/Q Vwave
	if (V_max>6)
		//print "Omitted the super large max value and set the max to 400"
		V_max=6
	endif
	//Variable binwidth=0.25
	//Variable binnumber=(trunc(V_max/0.25)+4) //addition of 4 is required for including the max value
	CheckGraphParametersF()								//020416
	NVAR binwidth=:GraphParameters:G_binwidth		//020416
	Variable binnumber=(trunc(V_max/binwidth)+4)
	
	if ((binnumber<20) || (numtype(binnumber)!=0))
	 	binnumber=20
	endif
	
	Histogram/B={0,binwidth,binnumber} Vwave,VwaveH
// ***new lines for the noise removal 020321 ***
//	VelocityNoiseRemoval(L_VecLengthWave,L_VecLengthWaveHIST)			//see vec9_noiseremove.ipf

	if (isPosition==0)
		Histogram/B={0,20,18} Gwave,GwaveH
		Histogram/B={0,0.25,26} Rwave,RwaveH
	else
		Histogram/B={-180,14.4,25} Gwave,GwaveH
		Histogram/B={-3.14,0.33,19} Rwave,RwaveH	
	endif
	NormalizeHistogram(Vwave,VwaveH)
	NormalizeHistogram(Gwave,GwaveH)
	NormalizeHistogram(Rwave,RwaveH)
END

//030805
Function V_GenerateStatWaves()
	Wave VX,VY,VXav,VYav
	NVAR	rnum,cnum,rnum_VXY,cnum_VXY
	rnum=DimSize(VXav, 0)
	cnum=DimSize(VXav, 1)
	rnum_VXY=DimSize(VX, 0)
	cnum_VXY=DimSize(VX, 1)
	Variable isFiltered=0
	make/n=(rnum_VXY,cnum_VXY) $V_returnStatWavenames(isFiltered,0,2)	
	make/n=(rnum_VXY,cnum_VXY) $V_returnStatWavenames(isFiltered,0,3)
	make/n=(rnum_VXY,cnum_VXY) $V_returnStatWavenames(isFiltered,0,4)
	make/n=(rnum,cnum) $V_returnStatWavenames(isFiltered,1,2)
	make/n=(rnum,cnum) $V_returnStatWavenames(isFiltered,1,3)
	make/n=(rnum,cnum) $V_returnStatWavenames(isFiltered,1,4)
	make /n=2 $V_returnStatWavenames(isFiltered,0,5),$V_returnStatWavenames(isFiltered,1,5)
	make /n=2 $V_returnStatWavenames(isFiltered,0,6),$V_returnStatWavenames(isFiltered,1,6)	
	make /n=2 $V_returnStatWavenames(isFiltered,0,7),$V_returnStatWavenames(isFiltered,1,7)
END

//030805
Function V_VelAngleCalc(isFiltered)
	Variable isFiltered
	//Variable NewGraph=0	
	NVAR averageshift,averaging
	String windowname_mag,windowname_deg,windowname_rad,presentWindows
	variable i

	
	CheckGraphParametersF()			//020416
	if (!DataFolderExists("Analysis"))
		V9_initializeAnalysisFolder()
	endif

	Wave/Z Vwave=$V_returnStatWavenames(0,0,2)	
	if (waveexists(Vwave)==0)
		V_GenerateStatWaves()
		//NewGraph=1
		Wave Vwave=$V_returnStatWavenames(0,0,2)
	else
		NVAR rnum,cnum
		for (i=2;i<5;i+=1)
			Redimension /N=(rnum,cnum) $V_returnStatWavenames(0,1,i)
		endfor
	endif
	
	for (i=2;i<5;i+=1)
		//average shift sould be recalculated
		SetScale/P x averageshift,averaging,"", $V_returnStatWavenames(0,1,i)
		SetScale/P y averageshift,averaging,"", $V_returnStatWavenames(0,1,i)
	endfor
	
	//wave/z Vwave=$V_returnStatWavenames(0,0,2)
	wave/z VwaveH=$V_returnStatWavenames(0,0,5)
	wave/z GwaveH=$V_returnStatWavenames(0,0,7)
	
	V_CalculateAngle(isFiltered,0)
	//VelocityNoiseRemovalNorm(Vwave,VWaveH)		//commented out 041213
	//GradNoiseRemoval(GWaveH,VWaveH,6)		//commented out 041213
	V_CalculateAngle(isFiltered,1)

END

//030805
Function V_showHists()
	SVAR wavename_pref
	NVAR isPosition
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )

	Wave/Z Vwave=$V_returnStatWavenames(0,0,2)
	wave/z Gwave=$V_returnStatWavenames(0,0,4)		

	wave/z VwaveH=$V_returnStatWavenames(0,0,5)
	wave/z GwaveH=$V_returnStatWavenames(0,0,7)

	Wave/Z VwaveAV=$V_returnStatWavenames(0,1,2)			
	Wave/Z GwaveAV=$V_returnStatWavenames(0,1,4)			
	
	if ((waveexists(VWave)) && (WhichListItem(HistWinName(0), presentWindows)==(-1)))
		SpeedHistShow(VWave,VWaveH,0)
		AppendAveragedVector(VWaveAV,0)
		//AppendNoiseRemovedHist(VWaveH)		//new 020321		commented out 041213
	else
		DoWindow/F $HistWinName(0)	//mag
		TextBox_Hist_AllVecInfo(VWave,HistWinName(0),0)
		TextBox_Hist_AveragedInfo(VWaveAV,HistWinName(0),0)
	endif	
		
	if ((waveexists(GWave)) && (WhichListItem(HistWinName(2), presentWindows)==(-1)))
		GradHistShow(GWave,GWaveH,2)
		AppendAveragedVector(GWaveAV,2)
		//AppendNoiseRemovedHist(GWaveH)		//new 020326		commented out 041213
	else
		DoWindow/F $HistWinName(2)	//grad
		TextBox_Hist_AllVecInfo(Gwave,HistWinName(2),2)
		TextBox_Hist_AveragedInfo(GWaveAV,HistWinName(2),2)
		if (isPosition)
			SetAxis bottom -190,190 
		else
			SetAxis bottom -10,370 
		endif	
	endif
	//if ((waveexists(RadWave)) && (WhichListItem(HistWinName(1), presentWindows)==(-1)))
	//	RadHistShow(RadWave,RadWaveHIST)
	//	AppendAveragedVector(RadWaveAV,1)
	//endif
//	NVAR G_AllStatFinished		// added on 020129 .. for a permission in ROI routine.
//	G_AllStatFinished=1
	
END

//030805 rewritten
Function HistAnalCore()
	variable isFiltered=0
	V_VelAngleCalc(isFiltered)
	V_showHists()
END

Function Calculate_AVstats()
	Wave/z RWaveAV=$StatAvnameProc("rad")
	Wave/z GWaveAV=$StatAvnameProc("deg")
	Wave/z VWaveAV=$StatAvnameProc("mag")

	NVAR rnum
	NVAR cnum
	rnum=DimSize(VXav, 0)
	cnum=DimSize(VXav, 1)

	Redimension /N=(rnum,cnum) $nameofwave(RWaveAV),$nameofwave(GwaveAV),$nameofwave(VwaveAV)
	V_CalculateAngle(0,1)
END



Function V_generateROIStatWaves()
			String ROI_magHname,ROI_degHname,ROI_magAVHname,ROI_degAVHname
			ROI_magHname=RoiStatHistName("mag")
			ROI_degHname=RoiStatHistName("deg")
			ROI_magAVHname=RoiAVStatHistName("mag")
			ROI_degAVHname=RoiAVStatHistName("deg")
			wave/z ROI_magH=$ROI_magHname
			if (waveexists($ROI_magHname)==0)
				Make/o/n=2 $ROI_magHname,$ROI_degHname,$ROI_magAVHname,$ROI_degAVHname
			endif
END


//*************** 030806 re-make 
Function ROI_statistics() : GraphMarquee

	if (V_Store_ROIcore()==1)
		String saveDF=GetDataFolder(1)
		SetToTopImageDataFolder()	
				
		NVAR unit,rnum_VXY,cnum_VXY
		SVAR wavename_pref
		wave w_mag=$StatnameProc("mag")//$MagWaveName
		wave w_deg=$StatnameProc("deg")//$DegWaveName
		wave w_magAV=$StatAvnameProc("mag")//$MagAVWaveName
		wave w_degAV=$StatAvnameProc("deg")//$DegAVWaveName

		V9_applyROIfilter()
		V_generateROIStatWaves()
//		String ROI_magHname,ROI_degHname,ROI_magAVHname,ROI_degAVHname
//		ROI_magHname=RoiStatHistName("mag")
//		ROI_degHname=RoiStatHistName("deg")
//		ROI_magAVHname=RoiAVStatHistName("mag")
//		ROI_degAVHname=RoiAVStatHistName("deg")

		Wave ROI_magH=$RoiStatHistName("mag")
		Wave ROI_degH=$RoiStatHistName("deg")
		Wave ROI_magAVH=$RoiAVStatHistName("mag")
		Wave ROI_degAVH=$RoiAVStatHistName("deg")
		
		wave/z ROIcoord=:GraphParameters:W_ROIcoord
		Variable Left=ROIcoord[0][0]
		Variable Bottom=ROIcoord[1][0]
		Variable Right=ROIcoord[0][1]
		Variable Top=ROIcoord[1][1]		
			
		Duplicate/o/R=[Left,Right][Bottom,Top]  w_mag W_mag1D
		Duplicate/o/R=(Left,Right)(Bottom,Top)  w_magAV W_magAV1D
		Duplicate/o/R=[Left,Right][Bottom,Top] w_deg W_deg1D
		Duplicate/o/R=(Left,Right)(Bottom,Top) w_degAV W_degAV1D

		Variable ROI_width=Dimsize(W_mag1D,0)
		Variable ROI_height=Dimsize(W_mag1D,1)
		Variable ROIav_height=Dimsize(W_magAV1D,0)
		Variable ROIav_width=Dimsize(W_magAV1D,1)
						
		Redimension/N=(ROI_width*ROI_height) W_mag1D
		Redimension/N=(ROI_width*ROI_height) W_deg1D
		Redimension/N=(ROIav_height*ROIav_width) W_magAV1D
		Redimension/N=(ROIav_height*ROIav_width) W_degAV1D

		//--make histogram waves of  non averaged
		wavestats/Q W_mag1D
		CheckGraphParametersF()								//020416
		NVAR binwidth=:GraphParameters:G_binwidth		//020416
		Variable binnumber=(trunc(V_max/binwidth)+4)
		if ((binnumber<30) || (numtype(binnumber)!=0))
	 		binnumber=30
	 	endif
		Histogram/B={0,binwidth,binnumber} W_mag1D,ROI_magH
		NormalizeHistogram(W_mag1D,ROI_magH)
		VelocityNoiseRemovalNorm(W_mag1D,ROI_magH)		//new 020321
		Histogram/B={0,binwidth,binnumber} W_magAV1D,ROI_magAVH
		NormalizeHistogram(W_magAV1D,ROI_magAVH)

		NVAR isPosition
		if (isPosition==0)
			Histogram/B={0,20,18} W_deg1D,ROI_degH
			Histogram/B={0,20,18} W_degAV1D,ROI_degAVH
		else
			Histogram/B={-180,20,18} W_deg1D,ROI_degH
			Histogram/B={-180,20,18} W_degAV1D,ROI_degAVH
		endif
		NormalizeHistogram(W_deg1D,ROI_degH)
		GradNoiseRemoval(ROI_degH,ROI_magH,7)
		NormalizeHistogram(W_degAV1D,ROI_degAVH)

	//------histogram wave of averaged made


		String ROI_magHwin=HistWinName(3)
		String ROI_degHwin=HistWinName(4)
		if (WinType(ROI_magHwin)==0)
			ROISpeedHistShow(W_mag1D,ROI_magH)
			TextBox_Hist_RoiInfo(W_mag1D,ROI_magHwin,0)
			//ROIstat_toWave(V_avg,V_sdev,V_npnts,VelNoiseRemovedAV(7),nonNoisePnts(7)) //temporally
			AppendAveragedVectorROI(W_magAV1D,ROI_magAVH,3)
			AppendNoiseRemovedHist(ROI_magH)
			TextBox_Hist_RoiAVInfo(W_magAV1D,ROI_magHwin,0) 

		else
			DoWindow/F $ROI_magHwin
			TextBox_Hist_RoiInfo(W_mag1D,ROI_magHwin,0)
			//ROIstat_toWave(V_avg,V_sdev,V_npnts,VelNoiseRemovedAV(7),nonNoisePnts(7)) //temporally
			TextBox_Hist_RoiAVInfo(W_magAV1D,ROI_magHwin,0) 
		endif

		if (WinType(ROI_degHwin)==0)
			RoiGradHistShow(W_deg1D,ROI_degH)
			TextBox_Hist_RoiInfo(W_deg1D,ROI_degHwin,2)
			AppendAveragedVectorROI(W_degAV1D,ROI_degAVH,4)
			AppendNoiseRemovedHist(ROI_degH)			//new 020326
			//BringTheFrontTraceBottom()					//new 020327
			TextBox_Hist_RoiAVInfo(W_degAV1D,ROI_degHwin,2) 

		else
			DoWindow/F $ROI_degHwin
			TextBox_Hist_RoiInfo(W_deg1D,ROI_degHwin,2)
			TextBox_Hist_RoiAVInfo(W_degAV1D,ROI_degHwin,2)
			//Hist_Yscaling(ROI_degAVH)
		endif

		//if (WinType(HistWinName(7))==1)			//commented out 041213
		//	TextBox_Hist_NoiseLessInfo(7)
		//endif

			
			//print "Average is "+num2str(V_avg)
			//print "SD is"+num2str(V_adev)	
		killwaves W_mag1D,W_magAV1D,W_deg1D,W_degAV1D
	endif

	SetDataFolder saveDF
End


//**************************************************
//030813
// For getting Flow
// Flow= Sigma(Intensity[][] x Velocity[][]) / Average Intensity
Function V_getAverageIntensityFiltered()
	wave w_img=$V9_returnSrcwave(3)
	wave VX
	wave filter=$(":GraphParameters:"+V9_returnFiltername(0))
	
	Duplicate/O VX tempFilteredImg	
	variable offset
	NVAR unit
	NVAR G_backgroundIntensity=:GraphParameters:G_backgroundIntensity
	offset=((unit==3) ? 1 : 0)
	tempFilteredImg[][]=((numtype(filter)==0) ? (w_img[p+offset][q+offset]-G_backgroundIntensity) : Nan) //030818 -G_backgroundIntensity added
	tempFilteredImg[][]=((tempFilteredImg[p][q]<0) ? 0 : tempFilteredImg[p][q])	
	wavestats/q tempFilteredImg
	Killwaves tempFilteredImg
	return (V_avg*V_npnts)


END

Function/S V_PrepTempIntensityFiltered()		//030818
	wave w_img=$V9_returnSrcwave(3)
	wave VX
	wave filter=$(":GraphParameters:"+V9_returnFiltername(0))
	
	Duplicate/O VX tempFilteredImg	
	variable offset
	NVAR unit
	NVAR G_backgroundIntensity=:GraphParameters:G_backgroundIntensity	
	offset=((unit==3) ? 1 : 0)
	tempFilteredImg[][]=((numtype(filter)==0) ? (w_img[p+offset][q+offset]-G_backgroundIntensity)  : Nan)
	tempFilteredImg[][]=((tempFilteredImg[p][q]<0) ? 0 : tempFilteredImg[p][q])
	return "tempFilteredImg"
END


///**************************************************
Function GetBackgroundInt()	// 030812
	SettingDataFolder(WaveRefIndexed("",0,1)) 
	variable bi
	if (DataFolderExists(":GraphParameters"))
		NVAR G_backgroundIntensity= :GraphParameters:G_backgroundIntensity
		bi=G_backgroundIntensity	
	else
		bi=0
		InitGraphParameters()
		NVAR G_backgroundIntensity= :GraphParameters:G_backgroundIntensity
	endif
	prompt bi, "Background  Intensity?"
	DoPrompt "Set Background  Intensity",bi
	if (V_flag)
		Abort "Processing Canceled"
	endif
	//NVAR L_binwidth=:GraphParameters:G_binwidth
	G_backgroundIntensity=bi

END

// Speed Factor calculation:
// Reference frame per sec =a
// Modified frame per sec =b : speed v
// speed factor = b/a
// speed in terms of reference fps: b/a * v
Function GetSpeedFactor()	// 040111
	SettingDataFolder(WaveRefIndexed("",0,1)) 
	variable sf
	if (DataFolderExists(":GraphParameters"))
		NVAR G_speedfactor= :GraphParameters:G_speedfactor
		sf=G_speedfactor	
	else
		sf=1
		InitGraphParameters()
		NVAR G_speedfactor= :GraphParameters:G_speedfactor
	endif
	prompt sf, "Speed Factor?"
	DoPrompt "Set Speed Factor",sf
	if (V_flag)
		Abort "Processing Canceled"
	endif
	//NVAR L_binwidth=:GraphParameters:G_binwidth
	G_speedfactor=sf

END

// 030812 for deriving the flow
// in the current folder

Function V_getFlow()
	//SetToTopImageDataFolder()
	wave w_mag=$StatnameProc("mag")
	wave w_img=$V9_returnSrcwave(3)
	duplicate/O w_mag $StatnameProc("flw")		//for the new stat mag*int: 2D wave. 
	wave/z w_flw=$StatnameProc("flw")
	variable offset
	NVAR unit
	offset=((unit==3) ? 1 : 0)
	NVAR G_backgroundIntensity=:GraphParameters:G_backgroundIntensity
	NVAR G_speedfactor=:GraphParameters:G_speedfactor	
	//w_flw[][]=w_mag[p][q]*(w_img[p+offset][q+offset]-G_backgroundIntensity)		
	w_flw[][]=w_mag[p][q]*(w_img[p+offset][q+offset]-G_backgroundIntensity)*G_speedfactor	// 040111 modified above
	
END

// 030812 then make histogram: instead of counting all vector equally "1", calculate the number by flw.
// in the current folder
Function V_getFlowDirection()
	//SetToTopImageDataFolder()
	wave w_mag=$StatnameProc("mag")
	wave w_deg=$StatnameProc("deg")
	wave w_flw=$StatnameProc("flw")
	NVAR isPosition

	Make/O/N=2 $(StatnameProc("flw")+"H")
	wave/z w_flwH=$(StatnameProc("flw")+"H")
	w_flwH=0
	wavestats/q w_flw
	NVAR binwidth=:GraphParameters:G_binwidthFlow		//030812 new global variable
	Variable binnumber=(trunc(V_max/binwidth)+4)
	
	if ((binnumber<20) || (numtype(binnumber)!=0))
	 	binnumber=20
	endif
	Histogram/B={0,binwidth,binnumber} w_flw,w_flwH
	Make/O/N=36 $(StatnameProc("flw")+"dirH")
	wave/z w_flwDH=$(StatnameProc("flw")+"dirH")
	w_flwDH=0
	if (isPosition==0)
		SetScale/P x 5,10,"", w_flwDH
	else
		SetScale/P x -175,10,"", w_flwDH
	endif
	variable i,j,Hwidth,Hheight
	Hwidth=DimSize(w_deg,0)
	Hheight=DimSize(w_deg,1)
	for (j=0;j<Hheight;j+=1)
		for (i=0;i<Hwidth;i+=1)
			if (numtype(w_deg[i][j])==0)
				w_flwDH[x2pnt(w_flwDH,w_deg[i][j])]+=w_flw[i][j]
			endif
		endfor
	endfor
	
	// Graphs
	SVAR wavename_pref
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if (WhichListItem(HistWinName(12), presentWindows)==(-1))	
		SpeedHistShow(w_flw,w_flwH,12)
	else
		DoWindow/f $HistWinName(12)
		TextBox_Hist_AllVecInfo(w_flw,HistWinName(12),12)
	endif
	V9_updateSpeedSigma()
	NVAR G_allSpeedSigma=:Analysis:G_allSpeedSigma		//this actually is the Sigma Of  AllVecs(Int * Speed) since TextBox_Hist_AllVecInfo is done in the above
	variable IntSigma=V_getAverageIntensityFiltered()
	variable AvgFlow=G_allSpeedSigma/IntSigma
	TextBox/W=$HistWinName(12)/C/N=Sigma/A=RT "\Z08Total Flow="+num2str(G_allSpeedSigma)+"\rAve Flow Rate="+num2str(AvgFlow)
	  
	if (WhichListItem(HistWinName(13), presentWindows)==(-1))	
		GradHistShow(w_deg,w_flwDH,13)
	else
		DoWindow/f $HistWinName(13)
		TextBox_Hist_AllVecInfo(w_deg,HistWinName(13),13)
	endif
END

//030812
Function V_FlowHist()
	SetToTopImageDataFolder()
	V9_initializeAnalysisFolder()
	V_getFlow()
	V_getFlowDirection()
	//V_CheckFrcRoughDir()		//030813
	VEC9_TriDirectionForce_Histo()
	VEC9_BiDirectionForce_Histo()	//060511
END

Function V_CheckForceHistPresence()
	SVAR wavename_pref
	variable isPresent=0
	String presentWindows=WinList((wavename_pref+"*"), ";", "" )
	if ( (WhichListItem(HistWinName(12), presentWindows)!=(-1)) || (WhichListItem(HistWinName(13), presentWindows)!=(-1)) )
		isPresent=1
	endif
	return isPresent
END





//*********** MEASUREMENT results OUTPUT (in the History window)


Function V_printResults()		//030729
	NVAR G_all_n=:analysis:G_all_n
	NVAR G_allSpeedAve=:analysis:G_allSpeedAve
	NVAR G_allSpeedSdev=:analysis:G_allSpeedSdev
	NVAR G_allAngleX_bar=:analysis:G_allAngleX_bar
	NVAR G_allAngleDeltaDeg=:analysis:G_allAngleDeltaDeg
	NVAR G_allAngleDispersion=:analysis:G_allAngleDispersion
	NVAR G_allAngleRvalue=:analysis:G_allAngleRvalue
	
	NVAR G_AV_n=:analysis:G_AV_n
	NVAR G_AVSpeedAve=:analysis:G_AVSpeedAve
	NVAR G_AVSpeedSdev=:analysis:G_AVSpeedSdev
	NVAR G_AVAngleX_bar=:analysis:G_AVAngleX_bar
	NVAR G_AVAngleDeltaDeg=:analysis:G_AVAngleDeltaDeg
	NVAR G_AVAngleDispersion=:analysis:G_AVAngleDispersion
	NVAR G_AVAngleRvalue=:analysis:G_AVAngleRvalue
	
	printf "\r***********STAT RESULTS***************\r"
	print VectorFieldWindowName()
	print V_FilterCondition()
	print "All Vectors:"
	printf "	n=%g\r",G_all_n
	printf "	Velocity [pix/frame]= %g ±%g\r",G_allSpeedAve,G_allSpeedSdev
	printf "	Mean Direction [deg] =%g ±%g (0.99 confidence limits)  \r", G_allAngleX_bar,G_allAngleDeltaDeg
	printf "	Angular Deviation [deg] %g  ",G_allAngleDispersion	
	print "	Concentration parameter r "+num2str(G_allAngleRvalue)

	print "\rAveraged Vectors:"
	printf "	n=%g\r",G_AV_n
	printf "	Velocity [pix/frame]= %g ±%g\r",G_AVSpeedAve,G_AVSpeedSdev
	printf "	Mean Direction [deg] =%g ±%g (0.99 confidence limits)  \r", G_AVAngleX_bar,G_AVAngleDeltaDeg
	printf "	Angular Deviation [deg] %g  ",G_AVAngleDispersion	
	print "	Concentration parameter r "+num2str(G_AVAngleRvalue)
	
END

Function/s V_FilterCondition()
		NVAR/z  G_checkVel=:GraphParameters:G_checkVel
		NVAR/z G_checkAngle=:GraphParameters:G_checkAngle
		NVAR/z G_checkAngleNOT=:GraphParameters:G_checkAngleNOT
		NVAR/z G_checkInt=:GraphParameters:G_checkInt
		NVAR G_checkImgMask=:GraphParameters:G_checkImgMask
		NVAR/z G_checkRoi=:GraphParameters:G_checkRoi	
		SVAR S_ImgMaskName=:GraphParameters:S_ImgMaskName
		wave/z wV=:GraphParameters:W_VelRange
		wave/z wA=:GraphParameters:W_AngleRange
		wave/z wI=:GraphParameters:W_IntRange
		wave/z wR=:GraphParameters:W_ROIcoord		
		String V_txt,A_txt,A0_txt,I_txt,Mask_txt,ROI_txt
		String condition
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
				A0_txt="		Angle exclude: "
			else
				A0_txt="		Angle: "
			endif			
		else
			A0_txt="		Angle: "		
			A_txt="all"
		endif

		if  (G_checkInt==1)
			I_txt=num2str(wI[0])+" - "+num2str(wI[1])
		else	
			I_txt="all"
		endif

		if (G_checkImgMask==1) 
			Mask_txt=" Image Mask: "+S_ImgMaskName
		else
			Mask_txt=" No Image Mask Applied"
		endif

		if (G_checkRoi==1)
			ROI_txt="		ROI:"+num2str(wR[0][0])+","+num2str(wR[1][0])+","+num2str(wR[0][1])+","+num2str(wR[1][1])+"\r"
		else
			ROI_txt="		no ROI\r"
		endif		
		condition="Velocity: "+V_txt+A0_txt+A_txt+"		Intensity: "+I_txt+"\r"+Mask_txt+ROI_txt   //030729
	return condition	
END


//**************************************************************************
Function sqroot_wave(a,b,c,d)
	wave a,b,c,d
	return ((a-c)^2+(b-d)^2)^(0.5)
end

Function sqroot(a,b,c,d)
	Variable a,b,c,d
	return ((a-c)^2+(b-d)^2)^(0.5)
end




///*********** UN used any more 030806 *********

////*************************************
////** should already be in the local folder
//
//Function CalculateAngleAbsolute(L_VecLengthWave,L_VX,L_VY,L_RadWave,L_GradWave,L_VecLengthWaveHIST,L_GradWaveHIST,L_RadWaveHIST)
//	Wave L_VecLengthWave,L_VX,L_VY,L_RadWave,L_GradWave,L_VecLengthWaveHIST,L_GradWaveHIST,L_RadWaveHIST
//	
////--- removing the reference point
//	if ((WhichListItem("Dest_Ywave", (TraceNameList("",";",1)))) >=0)
//		RemoveFromGraph Dest_Ywave
//	endif
////---------
//	Duplicate L_VX tempnull,tempVX
//	Duplicate L_VY tempVY
//	tempnull[][]=0
//	//print "Angle Coordinate: absolute"
//	tempVX[][]=((tempVX[p][q]==Nan) ? (0) : (tempVX[p][q]) )
//	tempVY[][]=((tempVY[p][q]==Nan) ? (0) : (tempVY[p][q]) )
//	L_VecLengthWave[][]=(sqroot(tempnull[p][q],tempnull[p][q],tempVX[p][q],tempVY[p][q]))
//	L_VecLengthWave[][]=((numtype(L_VecLengthWave[p][q]) == 1) ? NaN :(L_VecLengthWave[p][q]))			//* delete inf
////	L_RadWave[][]=((L_VecLengthWave[p][q]>L_speed_threshold) ? (acos((tempVY[p][q])/L_VeclengthWave[p][q])) : (Nan))
//	L_RadWave[][]=acos(tempVY[p][q]/L_VeclengthWave[p][q])
//	L_RadWave[][]=((L_VX[p][q] >0) ? (2*pi-L_RadWave[p][q]) : L_RadWave[p][q]) 
//	L_GradWave[][]=((L_Radwave[p][q]!=Nan) ? (L_RadWave[p][q]/2/3.1415*360): (Nan))
//	//below is for the thresholding
////	L_VecLengthWave[][]=(((L_VecLengthWave[p][q]>L_speed_threshold) && (L_VecLengthWave[p][q]!=inf)) ? (L_VecLengthWave[p][q]) : (NaN))
//		
//	killwaves tempnull,tempVX,tempVY
//
//	wavestats/Q L_VecLengthWave
//	if (V_max>10)
//		//print "Omitted the super large max value and set the max to 400"
//		V_max=10
//	endif
//	//Variable binwidth=0.25
//	//Variable binnumber=(trunc(V_max/0.25)+4) //addition of 4 is required for including the max value
//	CheckGraphParametersF()								//020416
//	NVAR binwidth=:GraphParameters:G_binwidth		//020416
//	Variable binnumber=(trunc(V_max/binwidth)+4)
//	
//	if ((binnumber<20) || (numtype(binnumber)!=0))
//	 	binnumber=20
//	endif
//	
//	Histogram/B={0,binwidth,binnumber} L_VecLengthWave,L_VecLengthWaveHIST
//// ***new lines for the noise removal 020321 ***
////	VelocityNoiseRemoval(L_VecLengthWave,L_VecLengthWaveHIST)			//see vec9_noiseremove.ipf
//
//	Histogram/B={0,20,18} L_GradWave,L_GradWaveHIST
//	Histogram/B={0,0.25,26} L_RadWave,L_RadWaveHIST
//	NormalizeHistogram(L_VecLengthWave,L_VecLengthWaveHIST)
//	NormalizeHistogram(L_GradWave,L_GradWaveHIST)
//	NormalizeHistogram(L_RadWave,L_RadWaveHIST)
//END
//
////**************************************************************
//Function CalculateAngleRelative(L_VecLengthWave,L_VX,L_VY,L_RadWave,L_GradWave,L_VecLengthWaveHIST,L_GradWaveHIST,L_RadWaveHIST)//,L_Speed_threshold)
//	Wave L_VecLengthWave,L_VX,L_VY,L_RadWave,L_GradWave,L_VecLengthWaveHIST,L_GradWaveHIST,L_RadWaveHIST
//	//NVAR L_Speed_Threshold=gSpeed_Threshold
//	NVAR Dest_X,Dest_Y//,Averaging
//	SVAR windowname
//
//	//-------------make a dot at the destination
//	Make/O/N=2 Dest_Xwave
//	Make/O/N=2 Dest_Ywave
//	Dest_Xwave[0]=Dest_X
//	Dest_Xwave[1]=Dest_X	
//	Dest_Ywave[0]=Dest_Y
//	Dest_Ywave[1]=Dest_Y	
//	DoWindow/F $VectorFieldWindowName()
//	if ((WhichListItem("Dest_Ywave", (TraceNameList("",";",1)))) ==-1)
//		//print TraceNameList("",";",1)
//		AppendToGraph Dest_Ywave vs Dest_Xwave
//		ModifyGraph mode(Dest_Ywave)=3,marker(Dest_Ywave)=1,msize(Dest_Ywave)=4,mrkThick(Dest_Ywave)=3
//		ModifyGraph rgb(Dest_Ywave)=(32768,40704,65280)
//	endif
//	//---------------------------------------------------------
//	
//	Duplicate L_VX tempnull,tempVX
//	Duplicate L_VY tempVY
//	tempnull[][]=0
//	//print "Relative Coordinate"
//	tempVX[][]=((tempVX[p][q]==Nan) ? (0) : (tempVX[p][q]) )
//	tempVY[][]=((tempVY[p][q]==Nan) ? (0) : (tempVY[p][q]) )
//	L_VecLengthWave[][]=(sqroot(tempnull[p][q],tempnull[p][q],tempVX[p][q],tempVY[p][q]))
//	L_VecLengthWave[][]=((numtype(L_VecLengthWave[p][q]) == 1) ? NaN :(L_VecLengthWave[p][q]))
//	
//	Duplicate/o L_VX Destination_Vstart,Destination_Vend,temp_co,CosTheta,SDslope,SEslope,Evaluate_Y,Decision1,Decision2,Decision3//,ActualCoordinateX,ActualCoordinateY
//
//	Destination_Vstart[][]=sqroot(Dest_X,Dest_Y,x,y) 
//	Destination_Vend[][]=sqroot(Dest_X,Dest_Y,(x+L_VX[p][q]),(y+L_VY[p][q]))
//	
//	temp_co=Destination_Vstart*L_VecLengthWave*2
//	CosTheta=( (Destination_Vstart)^2+(L_VecLengthWave)^2-(Destination_Vend)^2 )/temp_co
//	L_RadWave=acos(CosTheta)
////	L_RadWave[][]=((L_VecLengthWave[p][q]>L_speed_threshold) ? (L_RadWave[p][q]) : (Nan))
//	
//	SDslope[][]=((x==Dest_X) ? (99999) : ((Dest_Y-y) / (Dest_X-x)))
//	SEslope[][]=(((x+L_VX[p][q])==Dest_X) ? (99999) : ((Dest_Y-y-L_VY[p][q] ) / (Dest_X-x-L_VX[p][q])))
//	Evaluate_Y[][]=SDslope[p][q] * (x+L_VX[p][q]-Dest_X )+ Dest_Y
//
//	
//		// abs(1&&2 || !1&&!2) + 3 = (2+2)= 4 
//		// abs(1&&!2 || !1&&2) + !3 = (0+-2) = (-2)
//		//other possible answers for above: 0, 2 
//
//	if (SDslope[p][q]==SEslope[p][q])
//		L_RadWave[p][q]=( (Destination_Vend[p][q]>Destination_Vstart[p][q]) ? (3.1415) : (0) )
//	else
//		Decision1[][]=((SDslope[p][q]>0) ? 1:-1)
//		Decision2[][]=((Dest_Y>y) ? 1:-1)
//		Decision3[][]=(((Evaluate_Y[p][q])> (y+L_VY[p][q])) ? 2:-2)
//
//		L_RadWave[][]=(( (abs(Decision1[p][q]+Decision2[p][q])+Decision3)==4)? (L_RadWave[p][q]*(-1)) : (L_RadWave[p][q])) 
//		L_RadWave[][]=(( (abs(Decision1[p][q]+Decision2[p][q])+Decision3)==(-2))? (L_RadWave[p][q]*(-1)) : (L_RadWave[p][q]))
////		if ((abs(Decision1[][]+Decision2[][]))==4)
////			L_RadWave[][]=(L_RadWave[p][q]*(-1))
////		endif
////		if ((abs(Decision1[][]+Decision2[][]))==(-2))
////			L_RadWave[][]=(L_RadWave[p][q]*(-1))
////		endif
//		//RadWave[][]=( (SDslope[p][q]==SEslope[p][q]) ? ( (Destination_Vend[p][q]>Destination_Vstart[p][q]) ? (3.1415) : (0) ) : (RadWave[p][q]))
//		//L_RadWave[][]=( ( ( ((SDslope[p][q]>0) && (Dest_Y>y)) || ((SDslope[p][q]<0) && (Dest_Y< y)) ) && (Evaluate_Y[p][q] > (y+L_VY[p][q])) ) ? (L_RadWave[p][q]*(-1)) : (L_RadWave[p][q]) )
//		//L_RadWave[][]=( ( ( ((SDslope[p][q]>0) && (Dest_Y<y)) || ((SDslope[p][q]<0) && (Dest_Y> y)) ) && (Evaluate_Y[p][q] < (y+L_VY[p][q])) ) ? (L_RadWave[p][q]*(-1)) : (L_RadWave[p][q]) )
//	endif
//	
//	L_GradWave[][]=((L_Radwave[p][q]!=Nan) ? (L_RadWave[p][q]/2/3.1415*360): (Nan))
//		
//	killwaves tempnull,tempVX,tempVY,Destination_Vstart,Destination_Vend,temp_co,CosTheta,SDslope,SEslope,Evaluate_Y,Decision1,Decision2,Decision3
//	
//	wavestats/Q L_VecLengthWave
//	if (V_max>6)
//		print "Omitted the super large max value and set the max to 400"
//		V_max=6
//	endif
//	//Variable binwidth=0.25
//	CheckGraphParametersF()								//020416
//	NVAR binwidth=:GraphParameters:G_binwidth		//020416
//	Variable binnumber=(trunc(V_max/binwidth)+4)
//	if ((binnumber<20) || (numtype(binnumber)!=0))
//	 	binnumber=20
//	 endif
//	 	
//	Histogram/B={0,binwidth,binnumber} L_VecLengthWave,L_VecLengthWaveHIST
//	Histogram/B={-180,14.4,25} L_GradWave,L_GradWaveHIST
//	Histogram/B={-3.14,0.33,19} L_RadWave,L_RadWaveHIST
//	NormalizeHistogram(L_VecLengthWave,L_VecLengthWaveHIST)
//	NormalizeHistogram(L_GradWave,L_GradWaveHIST)
//	NormalizeHistogram(L_RadWave,L_RadWaveHIST)
//END
//
////**************************
//
//// for recalculating modified average vector
//
//Function Calculate_AVstats_old()
//	String RadWavename_av=StatAvnameProc("rad")
//	String GradWavename_av=StatAvnameProc("deg")
//	String VecLengthWavename_av=StatAvnameProc("mag")
//
//	String RadWavename_avHIST=StatAvHISTnameProc("rad")
//	String GradWavename_avHIST=StatAvHISTnameProc("deg")
//	String VecLengthWavename_avHIST=StatAvHISTnameProc("mag")
//
//	Wave/Z RadWaveAV=$RadWavename_av
//	Wave/Z GradWaveAV=$GradWavename_av
//	Wave/Z VecLengthWaveAV=$VecLengthWavename_av
//	Wave/Z RadWaveAVHIST=$RadWavename_avHIST
//	Wave/Z GradWaveAVHIST=$GradWavename_avHIST
//	Wave/Z VecLengthWaveAVHIST=$VecLengthWavename_avHIST
//
//	NVAR rnum
//	NVAR cnum
//	rnum=DimSize(VXav, 0)
//	cnum=DimSize(VXav, 1)
//
//	Redimension /N=(rnum,cnum) $RadWavename_av,$GradWavename_av,$VecLengthWavename_av
//	
//	NVAR isPosition
//	if (isPosition==1) //relative angle of vectors against a point
//		CalculateAngleRelative(VecLengthWaveAV,VXav,VYav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)//,gSpeed_threshold)
//	else			//angle against the screen
//		CalculateAngleAbsolute(VecLengthWaveAV,VXav,VYav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)
//	endif		
//END

////L_parameter defines which kind of graph to be shown. 1 shows all 3.
////L_isPosition selects the coordinate for measuring the angle. isPosition=0: absolute, angle against the screen coordinate. 
//// isPosition_1: angle against a certain point given by the user.
//// initial analysis will be done by absolute. giving a point can be done later as an option.
// //L_isFiltered: 0 is row data. 1 is data filtered with upper and lower limit.

//Function HistAnalCore_OLD(L_parameter,L_isPosition,L_isFiltered)
//	Variable L_parameter, L_isPosition,L_isFiltered
//	Variable NewGraph=0	
//	NVAR	rnum,cnum,rnum_VXY,cnum_VXY,unit,averaging,averageshift,LayerStart,LayerEnd,Dest_X,Dest_Y
//	SVAR	wavename_pref
//	String RadWavename,GradWavename,VecLengthWavename,RadWavenameHIST,GradWavenameHIST,VecLengthWavenameHIST
//	String RadWavename_av,GradWavename_av,VecLengthWavename_av,RadWavename_avHIST,GradWavename_avHIST,VecLengthWavename_avHIST
//	String windowname_mag,windowname_deg,windowname_rad,presentWindows
//	//String/G AbsoluteOrRelative
//	//SVAR 	AbsoluteOrRelative
//	Wave/z VX,VY,VXav,VYav
//	
//	CheckGraphParametersF()			//020416
//	if (!DataFolderExists("Analysis"))
//		V9_initializeAnalysisFolder()
//	endif
//// commented out 030730	
////	NVAR hist2DMask_ON=:analysis:hist2DMask_ON
////	if (L_isFiltered)
////		hist2DMask_ON=1
////	else
////		hist2DMask_ON=0
////	endif
//
////	if (waveexists(N15S_base)==0)		//new 020321
////		LoadLib_SigmoidParam()
////	endif
//	
//	rnum=DimSize(VXav, 0)
//	cnum=DimSize(VXav, 1)
//	rnum_VXY=DimSize(VX, 0)
//	cnum_VXY=DimSize(VX, 1)
////	if (L_isPosition==0)
////		AbsoluteOrRelative="\Z08Absolute"
////	else
////		AbsoluteOrRelative="\Z08Relative("+num2str(Dest_X)+","+num2str(Dest_Y)+")"
////	endif
//
//	
////*	RadWavename=wavename_pref+"U"+num2str(Unit)+"_rad"
//	RadWavename=StatnameProc("rad")
//	GradWavename=StatnameProc("deg")
//	VecLengthWavename=StatnameProc("mag")
//
//	RadWavenameHIST=StatHISTnameProc("rad")
//	GradWavenameHIST=StatHISTnameProc("deg")
//	VecLengthWavenameHIST=StatHISTnameProc("mag")
//	
//	RadWavename_av=RadWavename+"av"
//	GradWavename_av=GradWavename+"av"
//	VecLengthWavename_av=VecLengthWavename+"av"
//
//	RadWavename_avHIST=RadWavename+"avH"
//	GradWavename_avHIST=GradWavename+"avH"
//	VecLengthWavename_avHIST=VecLengthWavename+"avH"
//
//	//if (exists(VecLengthWavename)==0 || (speed_threshold!=0))
//	if (exists(VecLengthWavename)==0)
//		//make/n=(rnum_im,cnum_im) VX_thr, VY_thr, VXav_thr, VYav_thr
//		make/n=(rnum_VXY,cnum_VXY) $RadWavename
//		make/n=(rnum_VXY,cnum_VXY) $GradWavename
//		make/n=(rnum_VXY,cnum_VXY) $VecLengthWavename
//		make/n=(rnum,cnum) $RadWavename_av
//		make/n=(rnum,cnum) $GradWavename_av
//		make/n=(rnum,cnum) $VecLengthWavename_av
//		make /n=2 $RadWavenameHIST,$RadWavename_avHIST
//		make /n=2 $GradWavenameHIST,$GradWavename_avHIST	
//		make /n=2 $VecLengthWavenameHIST,$VecLengthWavename_avHIST
//
//		NewGraph=1
//	else
//		Redimension /N=(rnum,cnum) $RadWavename_av,$GradWavename_av,$VecLengthWavename_av
//	endif
//	
//	
//	Wave/Z RadWave=$RadWavename
//	Wave/Z GradWave=$GradWavename
//	Wave/Z VecLengthWave=$VecLengthWavename
//	Wave/Z RadWaveHIST=$RadWavenameHIST
//	Wave/Z GradWaveHIST=$GradWavenameHIST
//	Wave/Z VecLengthWaveHIST=$VecLengthWavenameHIST
//	Wave/Z VXav,VYav
//
//	Wave/Z RadWaveAV=$RadWavename_av
//	Wave/Z GradWaveAV=$GradWavename_av
//	Wave/Z VecLengthWaveAV=$VecLengthWavename_av
//	Wave/Z RadWaveAVHIST=$RadWavename_avHIST
//	Wave/Z GradWaveAVHIST=$GradWavename_avHIST
//	Wave/Z VecLengthWaveAVHIST=$VecLengthWavename_avHIST
//
//	SetScale/P x averageshift,averaging,"", RadWaveAV
//	SetScale/P y averageshift,averaging,"", RadWaveAV
//	SetScale/P x averageshift,averaging,"", GradWaveAV
//	SetScale/P y averageshift,averaging,"", GradWaveAV	
//	SetScale/P x averageshift,averaging,"", VecLengthWaveAV
//	SetScale/P y averageshift,averaging,"", VecLengthWaveAV	
//			
////------------------------------------------- down to here was consumed merely for naming the waves
//
//	//VecLengthWave[][]=((VXav[p][q]!=0 && VYav[p][q]!=0) ? (sqroot(tempnull[p][q],tempnull[p][q],VXav[p][q],VYav[p][q])) : (0))
//	//(011203 not to use averaged wave for the measurement of the speed) VecLengthWave[][]=(sqroot(tempnull[p][q],tempnull[p][q],VXav[p][q],VYav[p][q]))
//	if (L_isFiltered==0) 
//		if (L_isPosition==1) //relative angle of vectors against a point
//				CalculateAngleRelative(VecLengthWave,VX,VY,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)//,gSpeed_threshold)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//				CalculateAngleRelative(VecLengthWaveAV,VXav,VYav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)//,gSpeed_threshold)
//		else			//angle against the screen
//				CalculateAngleAbsolute(VecLengthWave,VX,VY,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//				CalculateAngleAbsolute(VecLengthWaveAV,VXav,VYav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)
//		endif		
//	else
//		if (L_isPosition==1) //relative angle of vectors against a point
//				CalculateAngleRelative(VecLengthWave,VX_filtered,VY_filtered,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)//,gSpeed_threshold)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//				CalculateAngleRelative(VecLengthWaveAV,VX_filteredav,VY_filteredav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)//,gSpeed_threshold)
//		else			//angle against the screen
//				CalculateAngleAbsolute(VecLengthWave,VX_filtered,VY_filtered,RadWave,GradWave,VecLengthWaveHIST,GradWaveHIST,RadWaveHIST)
//				VelocityNoiseRemovalNorm(VecLengthWave,VecLengthWaveHIST)
//				GradNoiseRemoval(GradWaveHIST,VecLengthWaveHIST,6)
//				CalculateAngleAbsolute(VecLengthWaveAV,VX_filteredav,VY_filteredav,RadWaveAV,GradWaveAV,VecLengthWaveAVHIST,GradWaveAVHIST,RadWaveAVHIST)
//		endif		
//	endif
//	
//	presentWindows=WinList((wavename_pref+"*"), ";", "" )
//	//print "present windows are "+presentWindows
//
////	if ((NewGraph==1) || (WhichListItem(HistWinName(0), presentWindows)==(-1))|| (WhichListItem(HistWinName(1), presentWindows)==(-1))|| (WhichListItem(HistWinName(2), presentWindows)==(-1)))
//	if ((NewGraph==1) || (WhichListItem(HistWinName(0), presentWindows)==(-1))|| (WhichListItem(HistWinName(2), presentWindows)==(-1)))
//
//		switch(L_Parameter)
//			case 1:
//				if ((waveexists(GradWave)) && (WhichListItem(HistWinName(2), presentWindows)==(-1)))
//					GradHistShow(GradWave,GradWaveHIST,2)
//					AppendAveragedVector(GradWaveAV,2)
//					AppendNoiseRemovedHist(GradWaveHIST)		//new 020326
//					//BringTheFrontTraceBottom()					//new 020327
//				endif
//				//if ((waveexists(RadWave)) && (WhichListItem(HistWinName(1), presentWindows)==(-1)))
//				//	RadHistShow(RadWave,RadWaveHIST)
//				//	AppendAveragedVector(RadWaveAV,1)
//				//endif
//				if ((waveexists(VecLengthWave)) && (WhichListItem(HistWinName(0), presentWindows)==(-1)))
//					SpeedHistShow(VecLengthWave,VecLengthWaveHIST,0)
//					AppendAveragedVector(VecLengthWaveAV,0)
//					AppendNoiseRemovedHist(VecLengthWaveHIST)		//new 020321
//// thresholding doesn't mean anymore after the implementation of "ranging" 020321
////					if (gSpeed_Threshold==0)
////						Tag/W=$(HistWinName(0))/C/N=thres/O=-90/A=MB/X=0.00/Y=-35.00 $VecLengthWavenameHIST, 0,"\\Z07No Thrshld"
////					else
////						Tag/W=$(HistWinName(0))/C/N=thres/O=-90/A=MB/X=0.00/Y=-35.00 $VecLengthWavenameHIST, gSpeed_Threshold,("\\Z07Thrshld"+num2str(gSpeed_Threshold))
////					endif
//
//				endif
//				break
//			case 2:
//				if ((waveexists(GradWave)) && (WhichListItem(HistWinName(2), presentWindows)==(-1)))
//					GradHistShow(GradWave,GradWaveHIST,2)
//					AppendAveragedVector(GradWaveAV,2)
//					AppendNoiseRemovedHist(GradWaveHIST)		//new 020326
//					//BringTheFrontTraceBottom()					//new 020327
//				endif
//				break
//			case 3:
//				if ((waveexists(RadWave)) && (WhichListItem(HistWinName(1), presentWindows)==(-1)))
//					RadHistShow(RadWave,RadWaveHIST)
//					AppendAveragedVector(RadWaveAV,1)
//				endif
//				break
//			case 4:
//				if ((waveexists(VecLengthWave)) && (WhichListItem(HistWinName(0), presentWindows)==(-1)))
//					SpeedHistShow(VecLengthWave,VecLengthWaveHIST,0)
//					AppendAveragedVector(VecLengthWaveAV,0)
//					AppendNoiseRemovedHist(VecLengthWaveHIST)			//new 020321
//// thresholding doesn't mean anymore after the implementation of "ranging" 020321
////					if (gSpeed_Threshold==0)
////						Tag/W=$(HistWinName(0))/C/N=thres/O=-90/A=MT/X=0.00/Y=-35.00 $VecLengthWavenameHIST, 0,"\\Z07No Thrshld"
////					else
////						Tag/W=$(HistWinName(0))/C/N=thres/O=-90/A=MT/X=0.00/Y=-35.00 $VecLengthWavenameHIST, gSpeed_Threshold,("\\Z07Thrshld"+num2str(gSpeed_Threshold))
////					endif
//				endif
//				break				
//
//			default:
//				break
//		endswitch
//		//print "made graph"
//	else
//		DoWindow/F $HistWinName(0)	//mag
//		TextBox_Hist_AllVecInfo(VecLengthWave,HistWinName(0),0)
//		TextBox_Hist_AveragedInfo(VecLengthWaveAV,HistWinName(0),0)
//		//if (gSpeed_Threshold!=0)
//			//Tag/W=$(HistWinName(0))/C/N=thres/O=90/A=MB/X=0.00/Y=-35.00 $VecLengthWavenameHIST, gSpeed_Threshold,("\\Z07Thrshld"+num2str(gSpeed_Threshold))
//		//endif
//		//Hist_Yscaling(VecLengthWaveAVHIST)
//		
//		//DoWindow/F $HistWinName(1)	//rad
//		//TextBox_Hist_AllVecInfo(RadWave,HistWinName(1))
//		//TextBox_Hist_AveragedInfo(RadWaveAV,HistWinName(1))
//		//Hist_Yscaling(RadWaveAVHIST)
//		
//		DoWindow/F $HistWinName(2)	//grad
//		TextBox_Hist_AllVecInfo(GradWave,HistWinName(2),2)
//		TextBox_Hist_AveragedInfo(GradWaveAV,HistWinName(2),2)
//		//NVAR isPosition
//		if (L_isPosition)
//			SetAxis bottom -190,190 
//		else
//			SetAxis bottom -10,370 
//		endif
//		//Hist_Yscaling(GradWaveAVHIST)
//		//print "text changed"
//	endif
//
////	NVAR G_AllStatFinished		// added on 020129 .. for a permission in ROI routine.
////	G_AllStatFinished=1
//END
//
////***************************************************************************
 //***************************************************************************

//Function ROI_statistics() : GraphMarquee
//	String igName= WMTopImageGraph() //imagecommon
//	
//	if( strlen(igName) == 0 )
//		DoAlert 0,"No image plot found"
//		return 0
//	endif
//
//	DoWindow/F $igName
//	Wave w= $WMGetImageWave(igName)	//imagecommon full path to the image: fetches the name of the top graph containing an image
//	String saveDF=GetDataFolder(1)
//	String waveDF=GetWavesDataFolder(w,1 )
//	SetDataFolder waveDF
//	//--from here, work is within the target local data folder
//	//NVAR/z L_RoiSet=root:VectorFunctions:G_RoiSet				//020319 for measureing filterd wave.
//				
//		NVAR unit,rnum_VXY,cnum_VXY
//		SVAR wavename_pref
//
//		String MagWaveName=StatnameProc("mag")
//		String DegWaveName=StatnameProc("deg")
//		String MagAVWaveName=StatAvnameProc("mag")
//		String DegAVWaveName=StatAvnameProc("deg")
//		wave w_mag=$MagWaveName
//		wave w_deg=$DegWaveName
//		wave w_magAV=$MagAVWaveName
//		wave w_degAV=$DegAVWaveName
//
//		NVAR/z isPosition
//		printf "processing %s\r", WMTopImageName()		//imagecommon
//		GetMarquee left, bottom
//		if (V_Flag == 0)
//			Print "There is no marquee"
//		else
//
//			if (Unit==3)
//				V_Left=trunc(V_Left-1)
//				V_Right=trunc(V_Right-1)
//				V_bottom=trunc(V_bottom-1)
//				V_top=trunc(V_top-1)
//			endif // otherwise, unit=2 and can be remained same
//		
//			String ROI_magHname,ROI_degHname,ROI_magAVHname,ROI_degAVHname
//			ROI_magHname=RoiStatHistName("mag")
//			ROI_degHname=RoiStatHistName("deg")
//			ROI_magAVHname=RoiAVStatHistName("mag")
//			ROI_degAVHname=RoiAVStatHistName("deg")
//
//			Make/o/n=2 $ROI_magHname,$ROI_degHname,$ROI_magAVHname,$ROI_degAVHname
//			Wave ROI_magH=$ROI_magHname
//			Wave ROI_degH=$ROI_degHname
//			Wave ROI_magAVH=$ROI_magAvHname
//			Wave ROI_degAVH=$ROI_degAVHname
//			
//			//--non averaged
//			Duplicate/o/R=[V_left,V_right][V_bottom,V_top] w_mag w_mag_lowpass
//			//print nameofwave(w_mag)
//			wavestats/Q w_mag_lowpass
//			
//			Variable lowpass=0
//			if (V_max>10)
//				printf "Highest speed Vector: %f\r", V_max
//				print "deleted super largevalues (>10) "
//				w_mag_lowpass[][]=((w_mag_lowpass[p][q]>10) ? Nan : w_mag_lowpass[p][q])
//				Lowpass=1
//				Duplicate/o  w_mag_lowpass W_mag1D		///R=[V_left,V_right][V_bottom,V_top]
//			else
//				Duplicate/o/R=[V_left,V_right][V_bottom,V_top]  w_mag W_mag1D
//			endif
//			//Killwaves w_mag_lowpass
//			
//			//-------averaged
//			Duplicate/o/R=(V_left,V_right)(V_bottom,V_top) w_magAV w_mag_lowpassAV
//			wavestats/Q w_mag_lowpassAV
//			Variable lowpassAV=0
//			if (V_max>10)
//				print "Omitted the super largevalue averaged (>100) "
//				w_mag_lowpassAV[][]=((w_mag_lowpassAV[p][q]>10) ? Nan : w_mag_lowpassAV[p][q])
//				LowpassAV=1
//				Duplicate/o  w_mag_lowpassAV W_magAV1D		///R=[V_left,V_right][V_bottom,V_top]
//			else
//				Duplicate/o/R=(V_left,V_right)(V_bottom,V_top)  w_magAV W_magAV1D
//			endif
//			//KillWaves w_mag_lowpassAV
//
//			Duplicate/o/R=[V_left,V_right][V_bottom,V_top] w_deg W_deg1D
//			Duplicate/o/R=(V_left,V_right)(V_bottom,V_top) w_degAV W_degAV1D
//
//			Variable ROI_width=V_right-V_left
//			Variable ROI_height=V_top-V_bottom
//			Variable ROIav_height=Dimsize(W_magAV1D,0)
//			Variable ROIav_width=Dimsize(W_magAV1D,1)
//						
//			Redimension/N=(ROI_width*ROI_height) W_mag1D
//			Redimension/N=(ROI_width*ROI_height) W_deg1D
//			Redimension/N=(ROIav_height*ROIav_width) W_magAV1D
//			Redimension/N=(ROIav_height*ROIav_width) W_degAV1D
//			//print "roi AVE cell number is"
//			//print (ROIav_height*ROIav_width)
//		//--make histogram waves of  non averaged
//			wavestats/Q W_mag1D
////			Variable binwidth=0.25
////			Variable binnumber=(trunc(V_max/0.25)+4)
//			CheckGraphParametersF()								//020416
//			NVAR binwidth=:GraphParameters:G_binwidth		//020416
//			Variable binnumber=(trunc(V_max/binwidth)+4)
//			if ((binnumber<20) || (numtype(binnumber)!=0))
//		 		binnumber=20
//		 	endif
//
//			Histogram/B={0,binwidth,binnumber} W_mag1D,ROI_magH
//			NormalizeHistogram(W_mag1D,ROI_magH)
//			VelocityNoiseRemovalNorm(W_mag1D,ROI_magH)		//new 020321
//			
//			if (isPosition==0)
//				Histogram/B={0,20,18} W_deg1D,ROI_degH
//			else
//				Histogram/B={-180,20,18} W_deg1D,ROI_degH
//			endif
//			NormalizeHistogram(W_deg1D,ROI_degH)
//			GradNoiseRemoval(ROI_degH,ROI_magH,7)
//		//------histogram wave of non-averaged made
//			
//		//--make histogram waves of averaged 
////		***** following lines commented out 020416 **********
////			wavestats/Q W_magAV1D
////			binwidth=0.25
////			binnumber=(trunc(V_max/0.25)+4)
////			if ((binnumber<20) || (numtype(binnumber)!=0))
////		 		binnumber=20
////		 	endif
//
//			Histogram/B={0,binwidth,binnumber} W_magAV1D,ROI_magAVH
//			NormalizeHistogram(W_magAV1D,ROI_magAVH)
//			if (isPosition==0)
//				Histogram/B={0,20,18} W_degAV1D,ROI_degAVH
//			else
//				Histogram/B={-180,20,18} W_degAV1D,ROI_degAVH
//			endif
//			NormalizeHistogram(W_degAV1D,ROI_degAVH)
//		//------histogram wave of averaged made
//
//			String ROI_magHwin=HistWinName(3)
//			String ROI_degHwin=HistWinName(4)
//			//print ROI_magHwin
//			//print ROI_degHwin
//			if (WinType(ROI_magHwin)==0)
//				ROISpeedHistShow(W_mag1D,ROI_magH)
//				TextBox_Hist_RoiInfo(W_mag1D,ROI_magHwin,V_left,V_right,V_bottom,V_top)
//				wavestats/Q W_mag1D
//				ROIstat_toWave(V_avg,V_sdev,V_npnts,VelNoiseRemovedAV(7),nonNoisePnts(7)) //temporaly
//				AppendAveragedVectorROI(W_magAV1D,ROI_magAVH,3)
//				AppendNoiseRemovedHist(ROI_magH)
//				TextBox_Hist_RoiAVInfo(W_magAV1D,ROI_magHwin) 
//
//			else
//				DoWindow/F $ROI_magHwin
//				UpdateTextBox_Hist_RoiInfo(W_mag1D,ROI_magHwin,V_left,V_right,V_bottom,V_top)
//				wavestats/Q W_mag1D
//				ROIstat_toWave(V_avg,V_sdev,V_npnts,VelNoiseRemovedAV(7),nonNoisePnts(7)) //temporaly
//				TextBox_Hist_RoiAVInfo(W_magAV1D,ROI_magHwin) 
//				//Hist_Yscaling(ROI_magAVH)
//			endif
//
//			if (WinType(ROI_degHwin)==0)
//				RoiGradHistShow(W_deg1D,ROI_degH)
//				TextBox_Hist_RoiInfo(W_deg1D,ROI_degHwin,V_left,V_right,V_bottom,V_top)
//
//				AppendAveragedVectorROI(W_degAV1D,ROI_degAVH,4)
//				AppendNoiseRemovedHist(ROI_degH)			//new 020326
//				//BringTheFrontTraceBottom()					//new 020327
//				TextBox_Hist_RoiAVInfo(W_degAV1D,ROI_degHwin) 
//
//			else
//				DoWindow/F $ROI_degHwin
//				UpdateTextBox_Hist_RoiInfo(W_deg1D,ROI_degHwin,V_left,V_right,V_bottom,V_top)
//				TextBox_Hist_RoiAVInfo(W_degAV1D,ROI_degHwin)
//				//Hist_Yscaling(ROI_degAVH)
//			endif
//
//			if (WinType(HistWinName(7))==1)
//				TextBox_Hist_NoiseLessInfo(7)
//			endif
//
//			
//			//print "Average is "+num2str(V_avg)
//			//print "SD is"+num2str(V_adev)	
//
//		endif
//	SetDataFolder saveDF
//End
