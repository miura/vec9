#pragma rtGlobals=1		// Use modern global access method.

//030122 Kota Miura
// for measureing multiple of stacks with velocity-intensity filtering.

Function MultiMeasureAngle(prefix,intensityMIN,intensityMAX,speedMIN,speedMAX,imagepath)
	string Prefix,imagepath
	variable intensityMIN,intensityMAX,speedMIN,speedMAX
	setdatafolder root:
	String suffix="_I"+num2str(intensityMIN)+"I"+num2str(intensityMAX)+"_V"+num2str(speedMIN)+"V"+num2str(speedMAX)
	String Vav_name=Prefix+"VelAvg"+suffix
	String Vsd_name=Prefix+"VelSD"+suffix
	String Vsk_name=Prefix+"VelSkw"+suffix
	String Vku_name=Prefix+"VelKur"+suffix
		
	String Aav_name=Prefix+"AngAvg"+suffix
	String Acl_name=Prefix+"AngCLim"+suffix
	String Aad_name=Prefix+"AngAdev"+suffix
	String Ar_name=Prefix+"AngRv"+suffix
	
	string MATlist=WaveList("*MAT*", ";", "" )
	print MATList
	Variable ListNum=ItemsInList(MATlist)
	String CurrentMAT
	variable L_unit=3,L_LayerStart=10,L_LayerEnd=49		//the values can be controlled here.
	Make/O/N=(ListNum) $Vav_name,$Vsd_name,$Aav_name,$Acl_name,$Aad_name,$Ar_name,$Vsk_name,$Vku_name	
	wave/z Vav=$Vav_name,Vsd=$Vsd_name,Aav=$Aav_name,Acl=$Acl_name,Aad=$Aad_name,Ar=$Ar_name
	wave/z Vsk=$Vsk_name,Vku=$Vku_name
	Make/O/N=40 LatPlusHist,LatMinusHist
	wave/z LatPlusHist,LatMinusHist
	LatPlusHist=0
	LatMinusHist=0
	Variable i
		variable j=0,k=0		//030129
	for (i=0;i<ListNum;i+=1)
		CurrentMAT=StringFromList(i,MATlist)
		//print CurrentMAT
		String L_wavename_pref=(CurrentMAT[3,(strlen(CurrentMAT)-1)])
		String L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
		DoWindow/F  $L_windowname		
		//SetDataFolder VEC9_FolderName(CurrentMAT,L_unit,L_LayerStart,L_LayerEnd)
		V9_VIfilter_2Dplot_core(intensityMIN,intensityMAX,speedMIN,speedMAX)

		wave/z GradWave=$(StatnameProc("deg"))
		wave/z VecLengthWave=$(StatnameProc("mag"))
		wavestats/q VecLengthWave
		Vav[i]=V_avg
		Vsd[i]=V_sdev
		Vsk[i]=V_skew
		Vku[i]=V_kurt
		CircularStatistics2D(GradWave,2)
		NVAR/z X_bar,delta_deg,r_value,dispersion_s_deg
		Aav[i]=X_bar
		Acl[i]=delta_deg
		Aad[i]=dispersion_s_deg
		Ar[i]=r_value				
		DoWindow/F $(HistWinName(0))
		TextBox/C/N=text0/F=0/A=RT "\\Z07Skewness:"+num2str(Vsk[i])+"\rKurtosis:"+num2str(Vku[i])
		SetAxis bottom 0,2
		SetAxis Left 0,0.4  
		SavePICT/O/P=$imagepath/T="TIFF"/B=144
//--030129
		wave/z a_population_fact=root:celltyp
		wave/z VH=$(StatHISTnameProc("mag"))
		if (a_population_fact[i]==1)
			LatPlusHist[]=LatPlusHist[p]+VH[p]
			j+=1
		else
			LatMinusHist[]=LatMinusHist[p]+VH[p]
			k+=1
		endif
	endfor
	print j
	print k
	Latplushist=latplushist/j
	Latminushist=latminushist/k
	
	setdatafolder root:
//	display 	$(nameofwave(Vav)) vs $(nameofwave(Aav))
//	ModifyGraph mode=3,marker=8//,rgb(aAav)=(0,0,65280)
//	ErrorBars $(nameofwave(Vav)) XY,wave=($(nameofwave(Aad)),$(nameofwave(Aad))),wave=($(nameofwave(Vsd)),$(nameofwave(Vsd)))
//
//	display 	$(nameofwave(Vav)) vs $(nameofwave(Ar))
//	ModifyGraph mode=3,marker=8//,rgb(aAav)=(0,0,65280)
//	ErrorBars $(nameofwave(Vav)) Y,wave=($(nameofwave(Vsd)),$(nameofwave(Vsd)))
END

//temporary function 030122 
Function removeAvgTraceNoise()//prefix,intensityMIN,intensityMAX,speedMIN,speedMAX,imagepath)

	setdatafolder root:
	
	string MATlist=WaveList("*MAT*", ";", "" )
	Variable ListNum=ItemsInList(MATlist)
	String CurrentMAT
	variable L_unit=3,L_LayerStart=10,L_LayerEnd=49		//the values can be controlled here.
	Variable i
	for (i=0;i<ListNum;i+=1)
		CurrentMAT=StringFromList(i,MATlist)
		//print CurrentMAT
		String L_wavename_pref=(CurrentMAT[3,(strlen(CurrentMAT)-1)])
		String L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
//		DoWindow/F  $L_windowname		
//		SetDataFolder $(VEC9_FolderName(CurrentMAT,L_unit,L_LayerStart,L_LayerEnd))
		String FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)
		SetDataFolder $("root:"+Foldername)

		DoWindow/F $(HistWinName(0))
		RemoveFromGraph $(StatAvHISTnameProc("mag"))
		//RemoveFromGraph $(MagHistNoiseLessName())
//		SetAxis bottom 0,2 
//		SavePICT/O/P=$imagepath/T="TIFF"/B=144
	endfor

	
	setdatafolder root:
END

//not used
// when current folder is root and need to get a name of the folder for the specific MAT, following function returns the foldername.
Function/s VEC9_FolderName(CurrentMAT,L_unit,L_LayerStart,L_LayerEnd)
	String CurrentMAT
	Variable L_unit,L_LayerStart,L_LayerEnd
	String L_wavename_pref=(CurrentMAT[3,(strlen(CurrentMAT)-1)])
	String FolderName=L_wavename_pref+"S"+num2str(L_LayerStart)+"E"+num2str(L_LayerEnd)+"U"+num2str(L_unit)
	return FolderName
END

Function Vec9_displayVvsAngle(prefix,prefix1,intensityMIN,intensityMAX,speedMIN,speedMAX)
	string Prefix,prefix1
	variable intensityMIN,intensityMAX,speedMIN,speedMAX
	setdatafolder root:
	String suffix="_I"+num2str(intensityMIN)+"I"+num2str(intensityMAX)+"_V"+num2str(speedMIN)+"V"+num2str(speedMAX)
	String Vav_name=Prefix+"VelAvg"+suffix
	String Vsd_name=Prefix+"VelSD"+suffix
	String Aav_name=Prefix+"AngAvg"+suffix
	String Acl_name=Prefix+"AngCLim"+suffix
	String Aad_name=Prefix+"AngAdev"+suffix
	String Ar_name=Prefix+"AngRv"+suffix
	
	String Vav_name1=Prefix1+"VelAvg"+suffix
	String Vsd_name1=Prefix1+"VelSD"+suffix
	String Aav_name1=Prefix1+"AngAvg"+suffix
	String Acl_name1=Prefix1+"AngCLim"+suffix
	String Aad_name1=Prefix1+"AngAdev"+suffix
	String Ar_name1=Prefix1+"AngRv"+suffix
	wave/z Vav=$Vav_name,Vsd=$Vsd_name,Aav=$Aav_name,Acl=$Acl_name,Aad=$Aad_name,Ar=$Ar_name
	wave/z Vav1=$Vav_name1,Vsd1=$Vsd_name1,Aav1=$Aav_name1,Acl1=$Acl_name1,Aad1=$Aad_name1,Ar1=$Ar_name1
	
	display 	$(nameofwave(Vav)) vs $(nameofwave(Aav))
	AppendToGraph 	$(nameofwave(Vav1)) vs $(nameofwave(Aav1))

	ModifyGraph mode=3,marker=8,rgb($(nameofwave(Vav1)))=(0,0,65280)
	ErrorBars $(nameofwave(Vav)) XY,wave=($(nameofwave(Aad)),$(nameofwave(Aad))),wave=($(nameofwave(Vsd)),$(nameofwave(Vsd)))
	ErrorBars $(nameofwave(Vav1)) XY,wave=($(nameofwave(Aad1)),$(nameofwave(Aad1))),wave=($(nameofwave(Vsd1)),$(nameofwave(Vsd1)))
	Label left "Speed [pix/frame]"
	Label bottom "Mean Direction [degrees]"
	TextBox/C/N=text0/A=RT ("\\Z08Int "+num2str(intensityMIN)+" ~ "+num2str(intensityMAX)+"\rVelocity "+num2str(speedMIN)+"~"+num2str(speedMAX))
	Legend/C/N=text1/J/F=0/A=MT "\\s("+nameofwave(Vav)+")"+prefix+"\r\\s("+nameofwave(Vav1)+")"+prefix1
	display 	$(nameofwave(Vav)) vs $(nameofwave(Ar))
	appendtograph $(nameofwave(Vav1)) vs $(nameofwave(Ar1))
	ModifyGraph mode=3,marker=8,rgb($(nameofwave(Vav1)))=(0,0,65280)
	ErrorBars $(nameofwave(Vav)) Y,wave=($(nameofwave(Vsd)),$(nameofwave(Vsd)))
	ErrorBars $(nameofwave(Vav1)) Y,wave=($(nameofwave(Vsd1)),$(nameofwave(Vsd1)))
	Label left "Speed [pix/frame]"
	Label bottom "Concentraiton of Direction (r Value)"
	TextBox/C/N=text0/A=RT ("\\Z08Int "+num2str(intensityMIN)+" ~ "+num2str(intensityMAX)+"\rVelocity "+num2str(speedMIN)+"~"+num2str(speedMAX))
	Legend/C/N=text1/J/F=0/A=MT "\\s("+nameofwave(Vav)+")"+prefix+"\r\\s("+nameofwave(Vav1)+")"+prefix1

END


// 040629
// asked about the p-values for the distribution difference in two conditions, following is
// teh program for retrieving all velocities (non averaged)
// modified "MultiMeasureAngle"

Function MultiGetVel(prefix,intensityMIN,intensityMAX,speedMIN,speedMAX,imagepath)
	string Prefix,imagepath
	variable intensityMIN,intensityMAX,speedMIN,speedMAX
	setdatafolder root:
	String suffix="_I"+num2str(intensityMIN)+"I"+num2str(intensityMAX)+"_V"+num2str(speedMIN)+"V"+num2str(speedMAX)
//	String Vav_name=Prefix+"VelAvg"+suffix
//	String Vsd_name=Prefix+"VelSD"+suffix
//	String Vsk_name=Prefix+"VelSkw"+suffix
//	String Vku_name=Prefix+"VelKur"+suffix
//		
//	String Aav_name=Prefix+"AngAvg"+suffix
//	String Acl_name=Prefix+"AngCLim"+suffix
//	String Aad_name=Prefix+"AngAdev"+suffix
//	String Ar_name=Prefix+"AngRv"+suffix
	
	string MATlist=WaveList("*MAT*", ";", "" )
	print MATList
	Variable ListNum=ItemsInList(MATlist)
	String CurrentMAT
	variable L_unit=3,L_LayerStart=10,L_LayerEnd=49		//the values can be controlled here.
	//Make/O/N=(ListNum) $Vav_name,$Vsd_name,$Aav_name,$Acl_name,$Aad_name,$Ar_name,$Vsk_name,$Vku_name	
	//wave/z Vav=$Vav_name,Vsd=$Vsd_name,Aav=$Aav_name,Acl=$Acl_name,Aad=$Aad_name,Ar=$Ar_name
	//wave/z Vsk=$Vsk_name,Vku=$Vku_name
	Make/O/N=40 LatPlusHist,LatMinusHist
	Make/o/N=1 LatVelPlus,LatVelMinus
	wave/z LatPlusHist,LatMinusHist,LatVelPlus,LatVelMinus
	LatPlusHist=0
	LatMinusHist=0
	Variable i
		variable j=0,k=0		//030129
	variable VecRows,VecCols
	for (i=0;i<ListNum;i+=1)
		setdatafolder root:
		CurrentMAT=StringFromList(i,MATlist)
		//print CurrentMAT
		String L_wavename_pref=(CurrentMAT[3,(strlen(CurrentMAT)-1)])
		String L_windowname=VectorFieldWindowName_L(L_wavename_pref,L_LayerStart,L_LayerEnd,L_Unit)
		string L_foldername=L_wavename_pref+"s"+num2str(L_LayerStart)+"e"+num2str(L_LayerEnd)+"u"+num2str(L_Unit)
		//DoWindow/F  $L_windowname		
		//V9_VIfilter_2Dplot_core(intensityMIN,intensityMAX,speedMIN,speedMAX)

		//wave/z GradWave=$(StatnameProc("deg"))
		setdatafolder $L_foldername
		wave/z VecLengthWave=$(StatnameProc("mag"))
		VecRows=dimsize(VecLengthWave,0)
		VecCols=dimsize(VecLengthWave,1)
		//Duplicate/o $nameofwave(VecLengthWave) tempVel1D
		//Make/o/N=(VecRows*VecCols) tempVel1D tempVel1D
		//redimension/n=(VecRows*VecCols)  tempVel1D
		
		wavestats/q VecLengthWave
//		Vav[i]=V_avg
//		Vsd[i]=V_sdev
//		Vsk[i]=V_skew
//		Vku[i]=V_kurt
		//CircularStatistics2D(GradWave,2)
		//NVAR/z X_bar,delta_deg,r_value,dispersion_s_deg
		//Aav[i]=X_bar
		//Acl[i]=delta_deg
		//Aad[i]=dispersion_s_deg
		//Ar[i]=r_value				
		//DoWindow/F $(HistWinName(0))
		//TextBox/C/N=text0/F=0/A=RT "\\Z07Skewness:"+num2str(Vsk[i])+"\rKurtosis:"+num2str(Vku[i])
		//SetAxis bottom 0,2
		//SetAxis Left 0,0.4  
		//SavePICT/O/P=$imagepath/T="TIFF"/B=144
//--030129
		
		wave/z a_population_fact=root:celltyp
		wave/z VH=$(StatHISTnameProc("mag"))
		if (a_population_fact[i]==1)
			LatPlusHist[]=LatPlusHist[p]+VH[p]
			j+=1
		else
			LatMinusHist[]=LatMinusHist[p]+VH[p]
			k+=1
		endif
	endfor
	//print j
	//print k
	Latplushist=latplushist/j
	Latminushist=latminushist/k
	
	setdatafolder root:
END