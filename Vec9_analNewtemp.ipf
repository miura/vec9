#pragma rtGlobals=1		// Use modern global access method.


//redoing anal_functions 030804 kota

//*************************************
//** should already be in the local folder

//030805
Function/s V_returnStatWavenames(isFiltered,isAveraged,param)	// param 0, VX 1, VY, 2, Velwave, 3 Radwave 4, Gradwave, 5, VelwaveH, 6 RadwaveH 7, GradwaveH 
	variable isFiltered,isAveraged,param
	if (isFiltered==0)
		if (isAveraged==0)
			switch(param)	// numeric switch
				case 0:		
					return "VX"
					break
				case 1:		
					return "VY"
					break
				case 2:		
					return StatnameProc("mag")
					break
				case 3:		
					return StatnameProc("rad")
					break
				case 4:		
					return StatnameProc("deg")
					break
				case 5:		
					return StatHISTnameProc("mag")
					break
				case 6:		
					return StatHISTnameProc("rad")
					break
				case 7:		
					return StatHISTnameProc("deg")
					break
				default:		
						
			endswitch
		else
			switch(param)	// numeric switch
				case 0:		
					return "VXav"
					break
				case 1:		
					return "VYav"
					break
				case 2:		
					return StatAvnameProc("mag")
					break
				case 3:		
					return StatAvnameProc("rad")
					break
				case 4:		
					return StatAvnameProc("deg")
					break
				case 5:		
					return StatAvHISTnameProc("mag")
					break
				case 6:		
					return StatAvHISTnameProc("rad")
					break
				case 7:		
					return StatAvHISTnameProc("deg")
					break
				default:		
						
			endswitch		
		
		endif
	else
		if (isAveraged==0)
			switch(param)	// numeric switch
				case 0:		
					return "VX_filtered"
					break
				case 1:		
					return "VY_filtered"
					break
				case 2:		
					return StatnameProc("mag")
					break
				case 3:		
					return StatnameProc("rad")
					break
				case 4:		
					return StatnameProc("deg")
					break
				case 5:		
					return StatHISTnameProc("mag")
					break
				case 6:		
					return StatHISTnameProc("rad")
					break
				case 6:		
					return StatHISTnameProc("deg")
					break
				default:		
						
			endswitch
		else
			switch(param)	// numeric switch
				case 0:		
					return "VX_filteredav"
					break
				case 1:		
					return "VY_filteredav"
					break
				case 2:		
					return StatAvnameProc("mag")
					break
				case 3:		
					return StatAvnameProc("rad")
					break
				case 4:		
					return StatAvnameProc("deg")
					break
				case 5:		
					return StatAvHISTnameProc("mag")
					break
				case 6:		
					return StatAvHISTnameProc("rad")
					break
				case 7:		
					return StatAvHISTnameProc("deg")
					break
				default:		
						
			endswitch		
		
		endif		
	
	
	endif
END	
	
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
	VelocityNoiseRemovalNorm(Vwave,VWaveH)
	GradNoiseRemoval(GWaveH,VWaveH,6)
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
		SpeedHistShow(VWave,VWaveH)
		AppendAveragedVector(VWaveAV,0)
		AppendNoiseRemovedHist(VWaveH)		//new 020321
	else
		DoWindow/F $HistWinName(0)	//mag
		TextBox_Hist_AllVecInfo(VWave,HistWinName(0),0)
		TextBox_Hist_AveragedInfo(VWaveAV,HistWinName(0),0)
	endif	
		
	if ((waveexists(GWave)) && (WhichListItem(HistWinName(2), presentWindows)==(-1)))
		GradHistShow(GWave,GWaveH)
		AppendAveragedVector(GWaveAV,2)
		AppendNoiseRemovedHist(GWaveH)		//new 020326
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
